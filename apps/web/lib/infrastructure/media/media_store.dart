import 'dart:typed_data';

import 'media_store_stub.dart'
    if (dart.library.js_interop) 'media_store_web.dart'
    if (dart.library.io) 'media_store_io.dart' as impl;

/// Persists image bytes outside SQLite; returns a relative path / store key.
Future<String> saveImageBytes(String id, Uint8List bytes) {
  return impl.saveImageBytes(id, bytes);
}

Future<Uint8List?> readImageBytes(String id) {
  return impl.readImageBytes(id);
}

Future<void> deleteImage(String id) {
  return impl.deleteImage(id);
}

String resolveMediaPath(String filePath) {
  return impl.resolvePath(filePath);
}
