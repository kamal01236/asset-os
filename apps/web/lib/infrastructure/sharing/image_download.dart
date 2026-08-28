import 'dart:typed_data';

import 'image_download_stub.dart'
    if (dart.library.js_interop) 'image_download_web.dart' as browser;

/// Download PNG bytes in the browser; no-op on VM / tests.
void downloadPngBytes(Uint8List bytes, String filename) {
  browser.downloadPngBytes(bytes, filename);
}
