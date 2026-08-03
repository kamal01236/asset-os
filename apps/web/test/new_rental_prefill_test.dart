import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:asset_os/app_shell.dart';
import 'package:asset_os/core/db/app_database.dart';
import 'package:asset_os/core/l10n/l10n_ext.dart';
import 'package:asset_os/core/models/self_customer.dart';
import 'package:asset_os/core/providers/app_providers.dart';
import 'package:asset_os/core/repositories/local_repository.dart';
import 'package:asset_os/core/theme/app_theme.dart';

Future<ProviderContainer> _bootTestContainer() async {
  SharedPreferences.setMockInitialValues(const <String, Object>{});
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  final AppDatabase db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final LocalRepository repository = await bootstrapRepository(
    database: db,
    preferences: preferences,
  );
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      sharedPreferencesProvider.overrideWithValue(preferences),
      databaseProvider.overrideWithValue(db),
      repositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _pumpFlow(
  WidgetTester tester, {
  required ProviderContainer container,
  required Widget home,
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.build(),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: home,
      ),
    ),
  );
  // Bounded pumps: stream providers + async prefill (avoid pumpAndSettle hangs).
  await tester.pump();
  for (int i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('initialInventoryItemIds seeds available selection only', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await _bootTestContainer();
    await _pumpFlow(
      tester,
      container: container,
      home: const NewRentalFlowScreen(
        initialInventoryItemIds: <String>['INV-2001', 'INV-2002'],
      ),
    );

    expect(find.text('Step 1 of 5'), findsOneWidget);
    expect(find.text('Phone number'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '6666666666');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Step 2 of 5'), findsOneWidget);
    expect(find.text('Select items'), findsOneWidget);

    final CheckboxListTile dslr = tester.widget(
      find.widgetWithText(CheckboxListTile, 'DSLR'),
    );
    expect(dslr.value, isTrue);
    expect(find.widgetWithText(CheckboxListTile, 'Drill Kit'), findsNothing);
    expect(find.widgetWithText(CheckboxListTile, 'Tripod'), findsOneWidget);
  });

  testWidgets('initialCustomerId skips party and shows inventory search', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await _bootTestContainer();
    await _pumpFlow(
      tester,
      container: container,
      home: const NewRentalFlowScreen(
        initialCustomerId: 'CUS-1001',
        initialInventoryItemIds: <String>['INV-2001'],
      ),
    );

    expect(find.text('Step 1 of 4'), findsOneWidget);
    expect(find.text('Phone number'), findsNothing);
    expect(find.text('Select items'), findsOneWidget);
    expect(find.text('Search by name or category'), findsOneWidget);

    final CheckboxListTile dslr = tester.widget(
      find.widgetWithText(CheckboxListTile, 'DSLR'),
    );
    expect(dslr.value, isTrue);

    await tester.enterText(find.byType(TextField).first, 'tripod');
    await tester.pump();
    expect(find.widgetWithText(CheckboxListTile, 'DSLR'), findsNothing);
    expect(find.widgetWithText(CheckboxListTile, 'Tripod'), findsOneWidget);
  });

  testWidgets('SELF prefill requires nickname before continue', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await _bootTestContainer();
    await _pumpFlow(
      tester,
      container: container,
      home: const NewRentalFlowScreen(
        initialCustomerId: kSelfCustomerId,
      ),
    );

    expect(find.text('Step 1 of 5'), findsOneWidget);
    expect(find.text('Phone number'), findsNothing);
    expect(find.text('Nickname for this rental'), findsOneWidget);
    expect(find.text(kSelfCustomerName), findsOneWidget);

    FilledButton continueButton = tester.widget(
      find.widgetWithText(FilledButton, 'Continue'),
    );
    expect(continueButton.onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, 'Raju');
    await tester.pump();

    continueButton = tester.widget(
      find.widgetWithText(FilledButton, 'Continue'),
    );
    expect(continueButton.onPressed, isNotNull);

    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Step 2 of 5'), findsOneWidget);
    expect(find.text('Select items'), findsOneWidget);
  });

  testWidgets('Inventory detail Issue CTA opens prefilled rental flow', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await _bootTestContainer();
    await _pumpFlow(
      tester,
      container: container,
      home: const InventoryDetailScreen(itemId: 'INV-2001'),
    );

    expect(find.text('Issue'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Issue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.widgetWithText(AppBar, 'New Rental'), findsOneWidget);
    expect(find.text('Step 1 of 5'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '6666666666');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final CheckboxListTile dslr = tester.widget(
      find.widgetWithText(CheckboxListTile, 'DSLR'),
    );
    expect(dslr.value, isTrue);
  });

  testWidgets('Customer detail Issue CTA skips party step', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await _bootTestContainer();
    await _pumpFlow(
      tester,
      container: container,
      home: const CustomerDetailScreen(customerId: 'CUS-1001'),
    );

    expect(find.text('Issue'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Issue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.widgetWithText(AppBar, 'New Rental'), findsOneWidget);
    expect(find.text('Step 1 of 4'), findsOneWidget);
    expect(find.text('Phone number'), findsNothing);
    expect(find.text('Select items'), findsOneWidget);
    expect(find.text('Search by name or category'), findsOneWidget);
  });
}
