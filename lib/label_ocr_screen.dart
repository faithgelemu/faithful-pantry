
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'camera_capture_screen.dart';
import 'crop_label_screen.dart';
import 'services/label_ocr_service.dart';
import 'utils/ocr_date_parser.dart';

class LabelOcrScreen extends StatefulWidget {
  const LabelOcrScreen({super.key});

  @override
  State<LabelOcrScreen> createState() => _LabelOcrScreenState();
}

class _LabelOcrScreenState extends State<LabelOcrScreen> {
  final picker = ImagePicker();
  final service = LabelOcrService();

  Uint8List? originalBytes;
  Uint8List? imageBytes;

  String? mimeType;
  String? recognisedText;
  String? errorMessage;

  List<OcrDateSuggestion> suggestions = [];
  bool isBusy = false;

  String dateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String? detectImageType(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }

    const pngSignature = [137, 80, 78, 71, 13, 10, 26, 10];

    if (bytes.length >= pngSignature.length) {
      var matches = true;

      for (var i = 0; i < pngSignature.length; i++) {
        if (bytes[i] != pngSignature[i]) {
          matches = false;
          break;
        }
      }

      if (matches) return 'image/png';
    }

    return null;
  }

  void validateImage(Uint8List bytes) {
    if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
      throw ArgumentError('Choose an image no larger than 10 MB.');
    }

    if (detectImageType(bytes) == null) {
      throw ArgumentError('Choose a JPG or PNG image.');
    }
  }

  void showError(String message) {
    if (!mounted) return;

    setState(() {
      errorMessage = message;
    });
  }

  Future<void> cropAndSelect(Uint8List source) async {
    validateImage(source);

    if (!mounted) return;

    final cropped = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        builder: (_) => CropLabelScreen(bytes: source),
      ),
    );

    // Cancelling keeps any previously selected image unchanged.
    if (cropped == null || !mounted) return;

    validateImage(cropped);

    setState(() {
      originalBytes = source;
      imageBytes = cropped;
      mimeType = detectImageType(cropped);
      recognisedText = null;
      suggestions = [];
      errorMessage = null;
    });
  }

  Future<void> choosePhoto() async {
    if (isBusy) return;

    setState(() {
      isBusy = true;
      errorMessage = null;
    });

    try {
      final photo = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (photo == null || !mounted) return;

      if (await photo.length() > 10 * 1024 * 1024) {
        throw ArgumentError('Choose an image no larger than 10 MB.');
      }

      final bytes = await photo.readAsBytes();

      if (!mounted) return;

      await cropAndSelect(bytes);
    } on ArgumentError catch (error) {
      showError(
        error.message?.toString() ?? 'Check the selected image.',
      );
    } catch (_) {
      showError(
        'Unable to open the photo. Try another JPG or PNG image.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isBusy = false;
        });
      }
    }
  }

  Future<void> takePhoto() async {
    if (isBusy) return;

    setState(() {
      isBusy = true;
      errorMessage = null;
    });

    try {
      final bytes = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(
          builder: (_) => const CameraCaptureScreen(),
        ),
      );

      if (bytes == null || !mounted) return;

      await cropAndSelect(bytes);
    } on ArgumentError catch (error) {
      showError(
        error.message?.toString() ?? 'Check the captured image.',
      );
    } catch (_) {
      showError(
        'Unable to use this photo. Try again or choose an existing image.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isBusy = false;
        });
      }
    }
  }

  Future<void> adjustCrop() async {
    final source = originalBytes;

    if (isBusy || source == null) return;

    setState(() {
      isBusy = true;
      errorMessage = null;
    });

    try {
      await cropAndSelect(source);
    } on ArgumentError catch (error) {
      showError(
        error.message?.toString() ?? 'Check the cropped image.',
      );
    } catch (_) {
      showError('Unable to adjust the crop. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          isBusy = false;
        });
      }
    }
  }

  Future<void> readPhoto() async {
    if (isBusy || imageBytes == null || mimeType == null) return;

    setState(() {
      isBusy = true;
      errorMessage = null;
      recognisedText = null;
      suggestions = [];
    });

    try {
      final text = await service.readLabel(
        bytes: imageBytes!,
        mimeType: mimeType!,
      );

      final dates = OcrDateParser.findDates(text);

      if (!mounted) return;

      setState(() {
        recognisedText = text;
        suggestions = dates;
      });
    } catch (_) {
      showError(
        'Unable to read the photo. Check your connection '
        'and try again, or enter the date manually.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isBusy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !isBusy,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Read an expiry label'),
          automaticallyImplyLeading: !isBusy,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Let’s read the label',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Choose or photograph a label, then crop around '
                  'its printed date.',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: isBusy ? null : choosePhoto,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(
                    imageBytes == null
                        ? 'Choose label photo'
                        : 'Change photo',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: isBusy ? null : takePhoto,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Take photo'),
                ),
                if (imageBytes != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Selected label area',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      imageBytes!,
                      height: 220,
                      fit: BoxFit.contain,
                      semanticLabel: 'Cropped food label',
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          'Preview unavailable. Try another photo.',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: isBusy ? null : adjustCrop,
                    icon: const Icon(Icons.crop),
                    label: const Text('Adjust crop'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: isBusy ? null : readPhoto,
                    icon: const Icon(Icons.document_scanner_outlined),
                    label: const Text('Read selected area'),
                  ),
                ],
                if (isBusy) ...[
                  const SizedBox(height: 20),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  Text(
                    'Please wait. The first recognition may take '
                    'longer while files download.',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      errorMessage!,
                      style: TextStyle(
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                ],
                if (recognisedText != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Review before choosing',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Compare the suggestion with the photo. '
                    'It could be a packing date rather than expiry. '
                    'Numeric dates use UK day/month/year. '
                    'Use by and Best before have different meanings.',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (suggestions.isEmpty)
                    Text(
                      'No supported complete date found. Adjust '
                      'the crop, try a clearer photo, or go back '
                      'to enter the date manually.',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    ...suggestions.map((suggestion) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                dateLabel(suggestion.date),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Read as: ${suggestion.originalText}',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                'Label: ${suggestion.label}',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (suggestion.assumedDay)
                                Text(
                                  'Day not printed — last day of month used. '
                                  'Check the label before confirming.',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              if (suggestion.assumedYear)
                                Text(
                                  'Year missing — current year assumed.',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: isBusy
                                    ? null
                                    : () {
                                        Navigator.of(context).pop(
                                          suggestion.date,
                                        );
                                      },
                                child: const Text('Use this date'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 12),
                  ExpansionTile(
                    title: const Text('Recognised text'),
                    childrenPadding: const EdgeInsets.all(16),
                    children: [
                      SelectableText(
                        recognisedText!.isEmpty
                            ? 'No text recognised.'
                            : recognisedText!,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Nothing is saved here. You can correct the '
                    'selected date in the grocery form.',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
