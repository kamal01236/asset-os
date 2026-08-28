@Tags(['unit'])
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/infrastructure/sharing/image_download.dart';

void main() {
  test('downloadPngBytes stub is a no-op', () {
    expect(
      () => downloadPngBytes(Uint8List.fromList(<int>[1, 2, 3]), 'test.png'),
      returnsNormally,
    );
  });
}
