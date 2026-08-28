import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Captures a [RepaintBoundary] widget to PNG bytes.
Future<Uint8List?> captureWidgetToPng(
  GlobalKey boundaryKey, {
  double pixelRatio = 2,
}) async {
  final RenderObject? renderObject =
      boundaryKey.currentContext?.findRenderObject();
  if (renderObject is! RenderRepaintBoundary) {
    return null;
  }
  final ui.Image image = await renderObject.toImage(pixelRatio: pixelRatio);
  final ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (byteData == null) {
    return null;
  }
  return byteData.buffer.asUint8List();
}
