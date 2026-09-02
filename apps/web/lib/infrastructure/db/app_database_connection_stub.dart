import 'package:drift/drift.dart';

/// Fallback when neither web nor IO platform libraries are available.
QueryExecutor openAppDatabase() {
  throw UnsupportedError('openAppDatabase requires web or native platform');
}
