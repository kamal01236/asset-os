import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

QueryExecutor openAppDatabase() {
  return driftDatabase(name: 'asset_os');
}
