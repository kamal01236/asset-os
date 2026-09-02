import 'package:drift/drift.dart';

import '../app_database.dart';

/// Incremental upgrades from [kSchemaBaselineVersion] onward (one case per version).
Future<void> runForwardMigration(
  AppDatabase db,
  Migrator m,
  int toVersion,
) async {
  switch (toVersion) {
    case 25:
      await m.createTable(db.mediaAttachments);
      break;
    // v26+ — add exactly one case per schema bump.
    default:
      break;
  }
}
