import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  State<CameraCaptureScreen> createState() =>
      _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen>
    with WidgetsBindingObserver {
  CameraController? controller;
  Uint8List? capturedBytes;

  bool isStarting = false;
  bool isCapturing = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> releaseCamera() async {
    final previous = controller;
    controller = null;

    if (previous != null) {
      await previous.dispose();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      if (controller == null) return;

      unawaited(releaseCamera());

      if (mounted) {
        setState(() {
          errorMessage =
              'Camera paused. Tap Enable camera to start again.';
        });
      }
    }
  }

  Future<void> startCamera() async {
    if (isStarting || isCapturing || controller != null) return;

    setState(() {
      isStarting = true;
      errorMessage = null;
      capturedBytes = null;
    });

    CameraController? pendingController;

    try {
      final cameras = await availableCameras();

      if (!mounted) return;

      if (cameras.isEmpty) {
        throw StateError('No camera was found on this device.');
      }

      final selected = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final camera = CameraController(
        selected,
        ResolutionPreset.high,
        enableAudio: false,
      );

      pendingController = camera;
      await camera.initialize();

      if (!mounted) return;

      final lifecycle = WidgetsBinding.instance.lifecycleState;

      if (lifecycle != null &&
          lifecycle != AppLifecycleState.resumed) {
        throw StateError(
          'Return to the app and tap Enable camera again.',
        );
      }

      setState(() {
        controller = camera;
      });

      // The screen now owns this controller.
      pendingController = null;
    } on CameraException catch (error) {
      if (!mounted) return;

      final permissionDenied =
          error.code.toLowerCase().contains('denied') ||
          error.code.toLowerCase().contains('permission') ||
          error.code.toLowerCase().contains('restricted');

      setState(() {
        errorMessage = permissionDenied
            ? 'Camera access was not allowed. You can enable it '
                'in browser site settings, or go back and choose a photo.'
            : 'Unable to start the camera. Check that it is available '
                'and not being used by another application.';
      });
    } on StateError catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            'Unable to open the camera. Use HTTPS or localhost, '
            'or go back and choose an existing photo.';
      });
    } finally {
      if (pendingController != null) {
        await pendingController.dispose();
      }

      if (mounted) {
        setState(() {
          isStarting = false;
        });
      }
    }
  }

  Future<void> capturePhoto() async {
    final camera = controller;

    if (camera == null ||
        !camera.value.isInitialized ||
        isStarting ||
        isCapturing) {
      return;
    }

    setState(() {
      isCapturing = true;
      errorMessage = null;
    });

    try {
      final photo = await camera.takePicture();

      if (await photo.length() > 10 * 1024 * 1024) {
        throw StateError(
          'The photo is too large. Choose an image under 10 MB instead.',
        );
      }

      final bytes = await photo.readAsBytes();

      await releaseCamera();

      if (!mounted) return;

      setState(() {
        capturedBytes = bytes;
      });
    } on StateError catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            'Unable to take the photo. Try again or choose an existing image.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isCapturing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(releaseCamera());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camera = controller;
    final bytes = capturedBytes;
    final busy = isStarting || isCapturing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Photograph the label'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Keep the date close, sharp and well lit. '
                'Only camera access is requested; no audio is recorded.',
              ),
              const SizedBox(height: 20),
              if (bytes != null)
                Image.memory(
                  bytes,
                  height: 300,
                  fit: BoxFit.contain,
                  semanticLabel: 'Captured label photo',
                )
              else if (camera != null && camera.value.isInitialized)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CameraPreview(camera),
                ),
              if (busy) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
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
              const SizedBox(height: 20),
              if (bytes != null) ...[
                FilledButton.icon(
                  onPressed: busy
                      ? null
                      : () => Navigator.of(context).pop(bytes),
                  icon: const Icon(Icons.check),
                  label: const Text('Use photo'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: busy ? null : startCamera,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retake photo'),
                ),
              ] else if (camera != null)
                FilledButton.icon(
                  onPressed: busy ? null : capturePhoto,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Capture photo'),
                )
              else
                FilledButton.icon(
                  onPressed: busy ? null : startCamera,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Enable camera'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}