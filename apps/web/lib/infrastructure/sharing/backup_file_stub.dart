/// VM / test stub — file save + pick are platform-only.
Future<void> saveBackupFile(String json, String filename) async {}

/// VM / test stub — always returns null (no file picker).
Future<String?> pickBackupFile() async => null;
