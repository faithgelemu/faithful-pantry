import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'services/label_ocr_service.dart';
import 'utils/ocr_date_parser.dart';
import 'camera_capture_screen.dart';

class LabelOcrScreen extends StatefulWidget {
  const LabelOcrScreen({super.key});

  @override
  State<LabelOcrScreen> createState() => _LabelOcrScreenState();
}

class _LabelOcrScreenState extends State<LabelOcrScreen> {
  final picker = ImagePicker();
  final service = LabelOcrService();

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
      final type = detectImageType(bytes);

      if (type == null) {
        throw ArgumentError('Choose a JPG or PNG image.');
      }

      if (!mounted) return;

      setState(() {
        imageBytes = bytes;
        mimeType = type;
        recognisedText = null;
        suggestions = [];
      });
    } on ArgumentError catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.message?.toString();
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Unable to open the photo. Please try again.';
      });
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

  final bytes = await Navigator.of(context).push<Uint8List>(
    MaterialPageRoute(
      builder: (_) => const CameraCaptureScreen(),
    ),
  );

  if (bytes == null || !mounted) return;

  final type = detectImageType(bytes);

  if (type == null || bytes.length > 10 * 1024 * 1024) {
    setState(() {
      errorMessage =
          'Choose a JPG or PNG photo no larger than 10 MB.';
    });
    return;
  }

  setState(() {
    imageBytes = bytes;
    mimeType = type;
    recognisedText = null;
    suggestions = [];
    errorMessage = null;
  });
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
      if (!mounted) return;

      setState(() {
        errorMessage =
            'Unable to read the photo. Check your connection '
            'and try again, or enter the date manually.';
      });
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
                const Text(
                  'Let’s read the label',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Choose a clear, close-up JPG or PNG of the date. '
                  'Recognition runs in your browser; OCR library '
                  'and language files require downloads.',
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
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      imageBytes!,
                      height: 220,
                      fit: BoxFit.contain,
                      semanticLabel: 'Selected food label',
                      errorBuilder: (context, error, stackTrace) {
                        return const Text(
                          'Preview unavailable. Try another photo.',
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: isBusy ? null : readPhoto,
                    icon: const Icon(Icons.document_scanner_outlined),
                    label: const Text('Read label'),
                  ),
                ],
                if (isBusy) ...[
                  const SizedBox(height: 20),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  const Text(
                    'Please wait. The first recognition '
                    'may take longer while files download.',
                  ),
                ],
                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
                if (recognisedText != null) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Review before choosing',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Check the photo carefully. A detected date '
                    'could be a packing date rather than expiry. '
                    'Numeric dates are interpreted as UK day/month/year. '
                    'Keep the distinction between Use by and Best before.',
                  ),
                  const SizedBox(height: 12),
                  if (suggestions.isEmpty)
                    const Text(
                      'No supported complete date found. '
                      'Try a clearer photo or go back to enter it manually.',
                    )
                  else
                    ...suggestions.map((suggestion) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                dateLabel(suggestion.date),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Read as: ${suggestion.originalText}',
                              ),
                              if (suggestion.assumedYear)
                                const Text(
                                  'Year missing — current year assumed.',
                                ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: () {
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Nothing is saved here. You can correct the '
                    'selected date in the grocery form.',
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