import 'dart:js_interop';
import 'dart:typed_data';

@JS('faithfulPantryReadLabel')
external JSPromise<JSString> _readLabel(
  JSUint8Array bytes,
  JSString mimeType,
);

Future<String> readLabel({
  required Uint8List bytes,
  required String mimeType,
}) async {
  final result = await _readLabel(
    bytes.toJS,
    mimeType.toJS,
  ).toDart;

  return result.toDart;
}