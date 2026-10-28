import 'dart:typed_data';

import 'label_ocr_stub.dart'
    if (dart.library.js_interop) 'label_ocr_web.dart' as platform;

class LabelOcrService {
  Future<String> readLabel({
    required Uint8List bytes,
    required String mimeType,
  }) {
    if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
      throw ArgumentError('Choose an image no larger than 10 MB.');
    }

    if (mimeType != 'image/jpeg' && mimeType != 'image/png') {
      throw ArgumentError('Choose a JPG or PNG image.');
    }

    return platform.readLabel(
      bytes: bytes,
      mimeType: mimeType,
    );
  }
}