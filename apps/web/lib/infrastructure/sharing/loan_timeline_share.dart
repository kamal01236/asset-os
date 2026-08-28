import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'image_download.dart';
import 'widget_screenshot.dart';

/// Builds a filename for a loan timeline PNG download.
String loanTimelineShareFilename(String loanId, DateTime generatedAt) {
  final String shortId =
      loanId.length <= 8 ? loanId : loanId.substring(0, 8);
  final String stamp = DateFormat('yyyyMMdd-HHmm').format(generatedAt);
  return 'hando-loan-$shortId-$stamp.png';
}

/// Renders [snapshot] off-screen, captures PNG, and triggers browser download.
Future<bool> shareLoanTimelinePng({
  required BuildContext context,
  required Widget snapshot,
  required String filename,
  double pixelRatio = 2,
}) async {
  final GlobalKey boundaryKey = GlobalKey();
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (BuildContext overlayContext) {
      return Positioned(
        left: -20000,
        top: 0,
        child: RepaintBoundary(
          key: boundaryKey,
          child: snapshot,
        ),
      );
    },
  );

  final OverlayState overlay = Overlay.of(context);
  overlay.insert(entry);
  try {
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    final Uint8List? bytes =
        await captureWidgetToPng(boundaryKey, pixelRatio: pixelRatio);
    if (bytes == null) {
      return false;
    }
    downloadPngBytes(bytes, filename);
    return true;
  } finally {
    entry.remove();
  }
}
