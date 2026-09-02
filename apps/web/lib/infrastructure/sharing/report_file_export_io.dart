import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> saveReportFile(
  Uint8List bytes,
  String filename,
  String mimeType,
) async {
  final Directory dir = await getTemporaryDirectory();
  final File file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes, flush: true);
  await Share.shareXFiles(
    <XFile>[XFile(file.path, mimeType: mimeType, name: filename)],
  );
}

Future<void> saveReportText(String text, String filename) async {
  final Directory dir = await getTemporaryDirectory();
  final File file = File('${dir.path}/$filename');
  await file.writeAsString(text, flush: true);
  await Share.shareXFiles(
    <XFile>[
      XFile(
        file.path,
        mimeType: 'text/csv',
        name: filename,
      ),
    ],
  );
}
