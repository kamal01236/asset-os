import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:asset_os/app_shell.dart';
import 'package:asset_os/core/db/app_database.dart';
import 'package:asset_os/core/l10n/l10n_ext.dart';
import 'package:asset_os/core/models/entities.dart';
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
  await tester.pump();
  for (int i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('Generate Order creates rental with two prefilled lines', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await _bootTestContainer();
    final LocalRepository repo = container.read(repositoryProvider);

    await _pumpFlow(
      tester,
      container: container,
      home: const NewOrderFlowScreen(
        initialCustomerId: 'CUS-1001',
        initialInventoryItemIds: <String>['INV-2001', 'INV-2003'],
      ),
    );

    expect(find.text('Line 1'), findsOneWidget);
    expect(find.text('Line 2'), findsOneWidget);

    // requiresUnitIdentity: instance/short/duration per line + optional deposit.
    final Finder fields = find.byType(TextField);
    expect(fields.evaluate().length >= 6, isTrue);
    await tester.enterText(fields.at(0), 'Body A');
    await tester.enterText(fields.at(1), 'CAM-A1');
    await tester.enterText(fields.at(2), '1');
    await tester.enterText(fields.at(3), 'Trip X');
    await tester.enterText(fields.at(4), 'TRP-X1');
    await tester.enterText(fields.at(5), '3');
    await tester.pump();
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    final FilledButton generate = tester.widget(
      find.widgetWithText(FilledButton, 'Generate Order'),
    );
    expect(generate.onPressed, isNotNull);

    await tester.tap(find.widgetWithText(FilledButton, 'Generate Order'));
    await tester.pump();
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }

    final List<Rental> rentals = await repo.listRentals();
    final Rental created = rentals.firstWhere(
      (Rental r) =>
          r.lines.length == 2 &&
          r.lines.any((RentalLine l) => l.itemId == 'INV-2003'),
    );
    expect(created.lines.map((RentalLine l) => l.itemId).toSet(), <String>{
      'INV-2001',
      'INV-2003',
    });
    expect(created.baseAmount, 210000);
    expect(created.totalAmount, 210000);

    // Flush Drift stream-cancel timers after the flow route pops.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('phone customer then form shows Add line', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await _bootTestContainer();
    await _pumpFlow(
      tester,
      container: container,
      home: const NewOrderFlowScreen(),
    );

    expect(find.widgetWithText(AppBar, 'New Order'), findsOneWidget);
    expect(find.text('Step 1 of 2'), findsOneWidget);
    expect(find.text('Phone number'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '6666666666');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Step 2 of 2'), findsOneWidget);
    expect(find.text('Add line'), findsOneWidget);
    expect(find.text('Line 1'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Generate Order'), findsOneWidget);
  });

  testWidgets('initialCustomerId skips customer and shows form', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await _bootTestContainer();
    await _pumpFlow(
      tester,
      container: container,
      home: const NewOrderFlowScreen(
        initialCustomerId: 'CUS-1001',
        initialInventoryItemIds: <String>['INV-2001'],
      ),
    );

    expect(find.text('Step 1 of 2'), findsNothing);
    expect(find.text('Phone number'), findsNothing);
    expect(find.text('Line 1'), findsOneWidget);
    expect(find.textContaining('DSLR'), findsWidgets);
    expect(find.widgetWithText(FilledButton, 'Generate Order'), findsOneWidget);
  });

  testWidgets('SELF prefill requires nickname before continue', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await _bootTestContainer();
    await _pumpFlow(
      tester,
      container: container,
      home: const NewOrderFlowScreen(
        initialCustomerId: kSelfCustomerId,
      ),
    );

    expect(find.text('Step 1 of 2'), findsOneWidget);
    expect(find.text('Phone number'), findsNothing);
    expect(find.text('Nickname for this order'), findsOneWidget);
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
    expect(find.text('Step 2 of 2'), findsOneWidget);
    expect(find.text('Line 1'), findsOneWidget);
  });

  testWidgets('Inventory detail Issue CTA opens New Order flow', (
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

    expect(find.widgetWithText(AppBar, 'New Order'), findsOneWidget);
    expect(find.text('Step 1 of 2'), findsOneWidget);
  });

  testWidgets('Customer detail Issue CTA skips customer step', (
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

    expect(find.widgetWithText(AppBar, 'New Order'), findsOneWidget);
    expect(find.text('Phone number'), findsNothing);
    expect(find.text('Line 1'), findsOneWidget);
  });
}
