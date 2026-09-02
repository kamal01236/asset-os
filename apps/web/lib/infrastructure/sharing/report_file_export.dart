import 'dart:typed_data';

import 'report_file_export_stub.dart'
    if (dart.library.js_interop) 'report_file_export_web.dart'
    if (dart.library.io) 'report_file_export_io.dart' as impl;

/// Saves report bytes: browser download on web, share sheet on Android, no-op in VM.
Future<void> saveReportFile(
  Uint8List bytes,
  String filename,
  String mimeType,
) {
  return impl.saveReportFile(bytes, filename, mimeType);
}

/// Saves UTF-8 text (CSV) via the same platform handoff as [saveReportFile].
Future<void> saveReportText(String text, String filename) {
  return impl.saveReportText(text, filename);
}
