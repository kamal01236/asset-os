import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Saves PNG bytes to a temp file and opens the Android share sheet.
void downloadPngBytes(Uint8List bytes, String filename) {
  if (!Platform.isAndroid) {
    return;
  }
  _sharePng(bytes, filename);
}

Future<void> _sharePng(Uint8List bytes, String filename) async {
  final Directory dir = await getTemporaryDirectory();
  final File file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes, flush: true);
  await Share.shareXFiles(
    <XFile>[XFile(file.path, mimeType: 'image/png', name: filename)],
  );
}
