import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

class CropLabelScreen extends StatefulWidget {
  const CropLabelScreen({
    super.key,
    required this.bytes,
  });

  final Uint8List bytes;

  @override
  State<CropLabelScreen> createState() => _CropLabelScreenState();
}

class _CropLabelScreenState extends State<CropLabelScreen> {
  final cropController = CropController();

  bool isReady = false;
  bool isCropping = false;
  String? errorMessage;

  void cropImage() {
    if (!isReady || isCropping) return;

    setState(() {
      isCropping = true;
      errorMessage = null;
    });

    try {
      cropController.crop();
    } catch (_) {
      showCropError();
    }
  }

  void showCropError() {
    if (!mounted) return;

    setState(() {
      isCropping = false;
      errorMessage =
          'Unable to crop this image. Try adjusting the selection '
          'or go back and choose another photo.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isCropping,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Select the expiry label'),
          automaticallyImplyLeading: !isCropping,
        ),
        body: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Drag the corners to include only the printed date '
                  'and its Use by or Best before wording. '
                  'Leave a small margin around the text.',
                  style: TextStyle(height: 1.5),
                ),
              ),
              Expanded(
                child: Crop(
                  image: widget.bytes,
                  controller: cropController,
                  baseColor: const Color(0xFFF8FAF5),
                  maskColor: const Color(0xAA123C25),
                  progressIndicator: const Center(
                    child: CircularProgressIndicator(),
                  ),
                  onStatusChanged: (status) {
                    if (!mounted) return;

                    setState(() {
                      isReady = status == CropStatus.ready;
                    });
                  },
                  onCropped: (result) {
                    if (!mounted) return;

                    switch (result) {
                      case CropSuccess(:final croppedImage):
                        if (croppedImage.isEmpty ||
                            croppedImage.length > 10 * 1024 * 1024) {
                          setState(() {
                            isCropping = false;
                            errorMessage =
                                'The cropped image must be under 10 MB. '
                                'Select a smaller area or use another photo.';
                          });
                          return;
                        }

                        Navigator.of(context).pop(croppedImage);

                      case CropFailure():
                        showCropError();
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (errorMessage != null) ...[
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    FilledButton.icon(
                      onPressed: isReady && !isCropping
                          ? cropImage
                          : null,
                      icon: isCropping
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.crop),
                      label: Text(
                        isCropping ? 'Cropping...' : 'Use selected area',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}