import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Writes report HTML to a temp file and opens the Android share sheet.
void printHtmlDocument(String html) {
  if (!Platform.isAndroid) {
    return;
  }
  _shareReport(html);
}

Future<void> _shareReport(String html) async {
  final Directory dir = await getTemporaryDirectory();
  final File file = File('${dir.path}/hando-report.html');
  await file.writeAsString(html, flush: true);
  await Share.shareXFiles(
    <XFile>[
      XFile(
        file.path,
        mimeType: 'text/html',
        name: 'hando-report.html',
      ),
    ],
  );
}
