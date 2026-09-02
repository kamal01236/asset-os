import 'backup_file_stub.dart'
    if (dart.library.js_interop) 'backup_file_web.dart'
    if (dart.library.io) 'backup_file_io.dart' as impl;

/// Saves a JSON backup: browser download on web, share sheet on Android,
/// no-op in VM/tests. Resolves once the file is handed off to the platform.
Future<void> saveBackupFile(String json, String filename) {
  return impl.saveBackupFile(json, filename);
}

/// Lets the user pick a backup file and returns its text contents, or null if
/// the picker was cancelled / unavailable. Web-only + Android; no-op in VM.
Future<String?> pickBackupFile() {
  return impl.pickBackupFile();
}
