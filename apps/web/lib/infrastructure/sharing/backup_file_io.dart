import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Writes [json] to a temp file and opens the Android share sheet.
Future<void> saveBackupFile(String json, String filename) async {
  final Directory dir = await getTemporaryDirectory();
  final File file = File('${dir.path}/$filename');
  await file.writeAsString(json, flush: true);
  await Share.shareXFiles(
    <XFile>[XFile(file.path, mimeType: 'application/json', name: filename)],
  );
}

/// Prompts the native file picker for a `.json` backup and reads its contents.
///
/// Returns null when the user cancels or no readable path is available.
Future<String?> pickBackupFile() async {
  final FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: <String>['json'],
  );
  final String? path = result?.files.single.path;
  if (path == null) {
    return null;
  }
  return File(path).readAsString();
}
