import 'dart:typed_data';

import 'image_download_stub.dart'
    if (dart.library.js_interop) 'image_download_web.dart'
    if (dart.library.io) 'image_download_io.dart' as browser;

/// Download PNG bytes on web (browser) or Android (share sheet); no-op in VM tests.
void downloadPngBytes(Uint8List bytes, String filename) {
  browser.downloadPngBytes(bytes, filename);
}
