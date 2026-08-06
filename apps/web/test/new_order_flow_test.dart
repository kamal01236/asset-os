@Tags(['widget', 'orders'])
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/app_shell.dart';
import 'package:asset_os/core/l10n/l10n_ext.dart';
import 'package:asset_os/core/models/entities.dart';
import 'package:asset_os/core/providers/app_providers.dart';
import 'package:asset_os/core/repositories/local_repository.dart';
import 'package:asset_os/core/theme/app_theme.dart';
import 'package:asset_os/core/widgets/ui_primitives.dart';

import 'support/test_harness.dart';

Future<void> _pumpFlow(
  WidgetTester tester, {
  required ProviderContainer container,
  required Widget home,
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: container.read(themeModeProvider),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: home,
      ),
    ),
  );
  await pumpFrames(tester);
}

Future<void> _settle(WidgetTester tester, {int ticks = 15}) async {
  for (int i = 0; i < ticks; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

/// Fill prefilled unit-identity lines so Continue / Generate is enabled.
/// Field order per line: duration, instance name, short code.
Future<void> _fillTwoUnitLines(WidgetTester tester) async {
  final Finder fields = find.byType(TextField);
  expect(fields.evaluate().length >= 6, isTrue);
  await tester.enterText(fields.at(0), '1');
  await tester.enterText(fields.at(1), 'Body A');
  await tester.enterText(fields.at(2), 'CAM-A1');
  await tester.enterText(fields.at(3), '3');
  await tester.enterText(fields.at(4), 'Trip X');
  await tester.enterText(fields.at(5), 'TRP-X1');
  await tester.pump();
  await _settle(tester, ticks: 8);
}

Future<void> _fillOneUnitLine(WidgetTester tester) async {
  final Finder fields = find.byType(TextField);
  expect(fields.evaluate().length >= 3, isTrue);
  await tester.enterText(fields.at(0), '1');
  await tester.enterText(fields.at(1), 'Body A');
  await tester.enterText(fields.at(2), 'CAM-A1');
  await tester.pump();
  await _settle(tester, ticks: 8);
}

Future<void> _continueToSummary(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
  await tester.pump();
  await _settle(tester, ticks: 8);
  expect(find.text('Order summary'), findsOneWidget);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  ensureRentalDetailNavRegistered();

  testWidgets('Generate Order creates rental with two prefilled lines', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await bootContainer(seedDemo: true);
    final LocalRepository repo = container.read(repositoryProvider);

    // Taller surface so both order lines (with Rent/Sell controls) stay built.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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

    // requiresUnitIdentity: duration then instance/short per line; advance collapsed.
    // Rent/Sell/Job live under More options; sale amount hidden while Rent is selected.
    await _fillTwoUnitLines(tester);

    final FilledButton continueBtn = tester.widget(
      find.widgetWithText(FilledButton, 'Continue'),
    );
    expect(continueBtn.onPressed, isNotNull);

    await _continueToSummary(tester);

    // DSLR ₹1500/day × 1 + Tripod ₹200/day × 3 = ₹2100.
    expect(find.byKey(const ValueKey<String>('order-summary-total')), findsOneWidget);
    expect(find.textContaining('Order total: ₹2100'), findsOneWidget);

    final FilledButton generate = tester.widget(
      find.widgetWithText(FilledButton, 'Generate Order'),
    );
    expect(generate.onPressed, isNotNull);

    await tester.tap(find.widgetWithText(FilledButton, 'Generate Order'));
    await tester.pump();
    await _settle(tester, ticks: 25);

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

    // Opens created order detail instead of bare pop.
    expect(find.byType(RentalDetailScreen), findsOneWidget);
    expect(find.textContaining(shortOrderId(created.id)), findsWidgets);

    // Flush Drift stream-cancel timers after detail is torn down.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('blank order shows items then customer then summary', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await bootContainer(seedDemo: true);
    final LocalRepository repo = container.read(repositoryProvider);

    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpFlow(
      tester,
      container: container,
      home: const NewOrderFlowScreen(
        initialInventoryItemIds: <String>['INV-2001'],
      ),
    );

    expect(find.widgetWithText(AppBar, 'New Order'), findsOneWidget);
    expect(find.text('Step 1 of 3'), findsOneWidget);
    expect(find.text('Line 1'), findsOneWidget);
    expect(find.text('Add line'), findsOneWidget);
    expect(find.text('Phone number'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);

    await _fillOneUnitLine(tester);

    final FilledButton continueButton = tester.widget(
      find.widgetWithText(FilledButton, 'Continue'),
    );
    expect(continueButton.onPressed, isNotNull);

    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Step 2 of 3'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Phone number'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Back'), findsOneWidget);

    final Finder customerFields = find.byType(TextField);
    await tester.enterText(customerFields.at(0), '6666666666');
    await tester.pump();
    await tester.enterText(customerFields.at(1), 'Priya Patel');
    await tester.pump();
    await _settle(tester);

    final FilledButton continueCustomer = tester.widget(
      find.widgetWithText(FilledButton, 'Continue'),
    );
    expect(continueCustomer.onPressed, isNotNull);

    await _continueToSummary(tester);
    expect(find.text('Step 3 of 3'), findsOneWidget);
    expect(find.textContaining('Priya Patel'), findsOneWidget);

    final FilledButton generate = tester.widget(
      find.widgetWithText(FilledButton, 'Generate Order'),
    );
    expect(generate.onPressed, isNotNull);

    await tester.tap(find.widgetWithText(FilledButton, 'Generate Order'));
    await tester.pump();
    await _settle(tester, ticks: 20);

    final List<Rental> rentals = await repo.listRentals();
    expect(
      rentals.any(
        (Rental r) =>
            r.customerId == 'CUS-1001' &&
            r.lines.any((RentalLine l) => l.itemId == 'INV-2001'),
      ),
      isTrue,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('initialCustomerId skips customer and shows form', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await bootContainer(seedDemo: true);
    await _pumpFlow(
      tester,
      container: container,
      home: const NewOrderFlowScreen(
        initialCustomerId: 'CUS-1001',
        initialInventoryItemIds: <String>['INV-2001'],
      ),
    );

    expect(find.text('Step 1 of 2'), findsNothing);
    expect(find.text('Step 1 of 3'), findsNothing);
    expect(find.text('Phone number'), findsNothing);
    expect(find.text('Line 1'), findsOneWidget);
    expect(find.textContaining('DSLR'), findsWidgets);
    expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);
  });

  testWidgets('typeahead selects existing customer on customer step', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await bootContainer(seedDemo: true);
    final LocalRepository repo = container.read(repositoryProvider);
    final List<Customer> matches =
        await repo.searchCustomersByNameOrPhone('Pri');
    expect(matches.any((Customer c) => c.name.contains('Priya')), isTrue);

    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpFlow(
      tester,
      container: container,
      home: const NewOrderFlowScreen(
        initialInventoryItemIds: <String>['INV-2001'],
      ),
    );

    await _fillOneUnitLine(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.enterText(find.byType(TextField).at(1), 'Pri');
    await tester.pump();
    await _settle(tester, ticks: 30);

    // Suggestion row uses name · phone; also accept bare name if layout differs.
    final Finder suggestion = find.textContaining('Priya Patel');
    expect(suggestion, findsWidgets);
    await tester.tap(suggestion.last);
    await tester.pump();

    final FilledButton continueBtn = tester.widget(
      find.widgetWithText(FilledButton, 'Continue'),
    );
    expect(continueBtn.onPressed, isNotNull);
  });

  testWidgets('create new customer requires name and phone on customer step', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await bootContainer(seedDemo: true);

    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpFlow(
      tester,
      container: container,
      home: const NewOrderFlowScreen(
        initialInventoryItemIds: <String>['INV-2001'],
      ),
    );

    await _fillOneUnitLine(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final Finder fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '5555512345');
    await tester.enterText(fields.at(1), 'New Guest');
    await tester.pump();

    final FilledButton continueBtn = tester.widget(
      find.widgetWithText(FilledButton, 'Continue'),
    );
    expect(continueBtn.onPressed, isNotNull);
  });

  testWidgets('no-phone path uses Unknown without requiring name', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await bootContainer(seedDemo: true);

    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpFlow(
      tester,
      container: container,
      home: const NewOrderFlowScreen(
        initialInventoryItemIds: <String>['INV-2001'],
      ),
    );

    await _fillOneUnitLine(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();

    expect(find.text('Unknown customer'), findsOneWidget);
    expect(find.text('Phone number'), findsNothing);

    FilledButton continueBtn = tester.widget(
      find.widgetWithText(FilledButton, 'Continue'),
    );
    expect(continueBtn.onPressed, isNotNull);

    await tester.enterText(find.byType(TextField).first, 'Raju');
    await tester.pump();
    continueBtn = tester.widget(
      find.widgetWithText(FilledButton, 'Continue'),
    );
    expect(continueBtn.onPressed, isNotNull);
  });

  testWidgets('Inventory detail Issue CTA opens New Order on items step', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await bootContainer(seedDemo: true);
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
    expect(find.text('Step 1 of 3'), findsOneWidget);
    expect(find.text('Line 1'), findsOneWidget);
    expect(find.text('Phone number'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);
  });

  testWidgets('Customer detail Issue CTA skips customer step', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await bootContainer(seedDemo: true);
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
    expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);
  });

  testWidgets('summary Generate stays enabled when stock drops below qty', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await bootContainer(seedDemo: true);
    final LocalRepository repo = container.read(repositoryProvider);

    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpFlow(
      tester,
      container: container,
      home: const NewOrderFlowScreen(
        initialCustomerId: 'CUS-1001',
        initialInventoryItemIds: <String>['INV-2001'],
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('qty-inc-0')));
    await tester.pump();
    await pumpFrames(tester);

    final Finder fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '1');
    await tester.enterText(fields.at(1), 'Body A');
    await tester.enterText(fields.at(2), 'CAM-A1');
    await tester.enterText(fields.at(3), 'Body B');
    await tester.enterText(fields.at(4), 'CAM-B1');
    await tester.pump();
    await _settle(tester, ticks: 8);

    await _continueToSummary(tester);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Generate Order'),
          )
          .onPressed,
      isNotNull,
    );

    // Live stock shrinks while summary is open (need 2, available becomes 1).
    await repo.updateInventory(
      id: 'INV-2001',
      name: 'DSLR',
      category: 'Camera',
      units: 2,
      requiresUnitIdentity: true,
    );
    await _settle(tester, ticks: 12);

    expect(find.textContaining('Not enough stock'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Generate Order'),
          )
          .onPressed,
      isNotNull,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('summary bill total matches qty × unit charges', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await bootContainer(seedDemo: true);
    final LocalRepository repo = container.read(repositoryProvider);
    await repo.updateInventory(
      id: 'INV-2003',
      name: 'Tripod',
      category: 'Camera',
      units: 3,
      requiresUnitIdentity: false,
    );

    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpFlow(
      tester,
      container: container,
      home: const NewOrderFlowScreen(
        initialCustomerId: 'CUS-1001',
        initialInventoryItemIds: <String>['INV-2003'],
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('qty-inc-0')));
    await tester.pump();
    await pumpFrames(tester);

    final Finder fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '2');
    await tester.pump();
    await _settle(tester, ticks: 8);

    await _continueToSummary(tester);

    // Tripod ₹200/day × 2 days × qty 2 = ₹800.
    expect(find.text('Qty 2 · Rent'), findsOneWidget);
    expect(find.textContaining('Order total: ₹800'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Generate Order'));
    await tester.pump();
    await _settle(tester, ticks: 20);

    final List<Rental> rentals = await repo.listRentals();
    expect(
      rentals.any(
        (Rental r) =>
            r.lines.length == 2 &&
            r.lines.every((RentalLine l) => l.itemId == 'INV-2003') &&
            r.baseAmount == 80000,
      ),
      isTrue,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('More options hides Sell when only rental types enabled', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await bootContainer(
      seedDemo: true,
      prefs: <String, Object>{
        kEnabledResourceTypesPrefsKey: 'rental',
      },
    );

    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpFlow(
      tester,
      container: container,
      home: const NewOrderFlowScreen(
        initialCustomerId: 'CUS-1001',
        initialInventoryItemIds: <String>['INV-2001'],
      ),
    );

    await tester.tap(find.text('More options'));
    await tester.pump();
    await _settle(tester, ticks: 8);

    expect(find.text('Rent'), findsWidgets);
    expect(find.text('Sell'), findsNothing);
    expect(find.text('Job'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('More options shows Sell when sale type enabled', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await bootContainer(
      seedDemo: true,
      prefs: <String, Object>{
        kEnabledResourceTypesPrefsKey: 'rental,sale',
      },
    );

    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpFlow(
      tester,
      container: container,
      home: const NewOrderFlowScreen(
        initialCustomerId: 'CUS-1001',
        initialInventoryItemIds: <String>['INV-2001'],
      ),
    );

    await tester.tap(find.text('More options'));
    await tester.pump();
    await _settle(tester, ticks: 8);

    expect(find.text('Sell'), findsOneWidget);
    expect(find.text('Job'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
