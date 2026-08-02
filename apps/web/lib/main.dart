import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_shell.dart';
import 'core/config/app_branding.dart';
import 'core/db/app_database.dart';
import 'core/providers/app_providers.dart';
import 'core/repositories/local_repository.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  final AppDatabase database = AppDatabase();
  final LocalRepository repository = await bootstrapRepository(
    database: database,
    preferences: preferences,
  );

  runApp(
    ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(preferences),
        databaseProvider.overrideWithValue(database),
        repositoryProvider.overrideWithValue(repository),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppDisplayName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: const AppShell(),
    );
  }
}
