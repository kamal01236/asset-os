import 'dart:typed_data';

final Map<String, Uint8List> _memory = <String, Uint8List>{};

Future<String> saveImageBytes(String id, Uint8List bytes) async {
  _memory[id] = Uint8List.fromList(bytes);
  return 'web-media/$id';
}

Future<Uint8List?> readImageBytes(String id) async {
  return _memory[id];
}

Future<void> deleteImage(String id) async {
  _memory.remove(id);
}

String resolvePath(String id) => 'web-media/$id';
