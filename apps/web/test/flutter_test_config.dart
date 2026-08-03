import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';

/// Loads system SQLite for Drift `NativeDatabase` under `flutter test` (WSL/Linux).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  if (Platform.isLinux) {
    open.overrideFor(OperatingSystem.linux, () {
      const String so0 = '/usr/lib/x86_64-linux-gnu/libsqlite3.so.0';
      if (File(so0).existsSync()) {
        return DynamicLibrary.open(so0);
      }
      return DynamicLibrary.open('libsqlite3.so');
    });
  }
  await testMain();
}
