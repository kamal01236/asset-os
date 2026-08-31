import 'package:drift/drift.dart';

import '../app_database.dart';

/// Incremental upgrades from [kSchemaBaselineVersion] onward (one case per version).
Future<void> runForwardMigration(
  AppDatabase db,
  Migrator m,
  int toVersion,
) async {
  switch (toVersion) {
    // v25+ — add exactly one case per schema bump.
    default:
      break;
  }
}
