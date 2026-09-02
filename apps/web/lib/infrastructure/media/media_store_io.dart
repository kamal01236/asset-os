import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Directory? _testPhotosRoot;

Future<Directory> _photosDir() async {
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    _testPhotosRoot ??=
        Directory.systemTemp.createTempSync('hando_media_test');
    final Directory photos = Directory(p.join(_testPhotosRoot!.path, 'photos'));
    if (!await photos.exists()) {
      await photos.create(recursive: true);
    }
    return photos;
  }
  final Directory docs = await getApplicationDocumentsDirectory();
  final Directory photos = Directory(p.join(docs.path, 'photos'));
  if (!await photos.exists()) {
    await photos.create(recursive: true);
  }
  return photos;
}

Future<String> saveImageBytes(String id, Uint8List bytes) async {
  final Directory dir = await _photosDir();
  final File file = File(p.join(dir.path, '$id.jpg'));
  await file.writeAsBytes(bytes, flush: true);
  return p.join('photos', '$id.jpg');
}

Future<Uint8List?> readImageBytes(String id) async {
  final Directory dir = await _photosDir();
  final File file = File(p.join(dir.path, '$id.jpg'));
  if (!await file.exists()) {
    return null;
  }
  return file.readAsBytes();
}

Future<void> deleteImage(String id) async {
  final Directory dir = await _photosDir();
  final File file = File(p.join(dir.path, '$id.jpg'));
  if (await file.exists()) {
    await file.delete();
  }
}

String resolvePath(String relativePath) => relativePath;
