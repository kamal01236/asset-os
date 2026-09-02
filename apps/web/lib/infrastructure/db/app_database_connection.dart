import 'package:drift/drift.dart';

import 'app_database_connection_stub.dart'
    if (dart.library.js_interop) 'app_database_connection_web.dart'
    if (dart.library.io) 'app_database_connection_native.dart' as impl;

QueryExecutor openAppDatabase() => impl.openAppDatabase();
