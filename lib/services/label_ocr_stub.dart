import 'dart:typed_data';

Future<String> readLabel({
  required Uint8List bytes,
  required String mimeType,
}) async {
  throw UnsupportedError(
    'Label recognition is currently available in the web app only.',
  );
}