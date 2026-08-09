import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:asset_os/infrastructure/db/app_database.dart';
import 'package:asset_os/domain/models/entities.dart';
import 'package:asset_os/application/providers/app_providers.dart';
import 'package:asset_os/application/local_repository.dart';

/// In-memory Drift repo. Default skips demo seed for fast domain tests.
Future<LocalRepository> bootRepo({bool seedDemo = false}) async {
  SharedPreferences.setMockInitialValues(const <String, Object>{});
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  final AppDatabase db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final LocalRepository repository = LocalRepository(db, preferences);
  await repository.initialize(seedDemo: seedDemo);
  return repository;
}

/// ProviderContainer with overridden DB/repo. Use [seedDemo]: true for shell smokes.
Future<ProviderContainer> bootContainer({
  bool seedDemo = false,
  Map<String, Object> prefs = const <String, Object>{},
  AppDatabase? database,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  final AppDatabase db = database ?? AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final LocalRepository repository = await bootstrapRepository(
    database: db,
    preferences: preferences,
    seedDemo: seedDemo,
  );
  // Empty harness boots need the template gate; demo seed skips it.
  final bool needsOnboarding = !seedDemo;
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      sharedPreferencesProvider.overrideWithValue(preferences),
      databaseProvider.overrideWithValue(db),
      repositoryProvider.overrideWithValue(repository),
      needsIndustryOnboardingProvider.overrideWith((ref) => needsOnboarding),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Ensure a named customer exists (empty-DB fixture helper).
Future<Customer> ensureCustomer(
  LocalRepository repository, {
  String phone = '6666666666',
  String name = 'Priya Patel',
}) {
  return repository.upsertCustomerByPhone(phone: phone, fallbackName: name);
}

/// Bounded pump for StreamProvider-heavy shells (avoids unbounded pumpAndSettle).
Future<void> pumpFrames(
  WidgetTester tester, {
  int frames = 12,
  Duration step = const Duration(milliseconds: 20),
}) async {
  await tester.pump();
  for (int i = 0; i < frames; i++) {
    await tester.pump(step);
  }
}
