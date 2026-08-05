@Tags(['widget', 'orders'])
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/core/l10n/l10n_ext.dart';
import 'package:asset_os/core/models/entities.dart';
import 'package:asset_os/core/providers/app_providers.dart';
import 'package:asset_os/core/repositories/local_repository.dart';
import 'package:asset_os/core/theme/app_theme.dart';
import 'package:asset_os/features/orders/new_order_flow_screen.dart';

import 'support/test_harness.dart';

Future<void> _pumpOrder(
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

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('parent qty 2 expands labels and creates two rental lines', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await bootContainer(seedDemo: true);
    final LocalRepository repo = container.read(repositoryProvider);
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpOrder(
      tester,
      container: container,
      home: const NewOrderFlowScreen(
        initialCustomerId: 'CUS-1001',
        initialInventoryItemIds: <String>['INV-2001'],
      ),
    );

    expect(find.text('Quantity'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('qty-inc-0')));
    await tester.pump();
    await pumpFrames(tester);

    expect(find.textContaining('DSLR #'), findsNWidgets(2));
    // Qty may exceed shown available — + stays enabled past stock.
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey<String>('qty-inc-0')))
          .onPressed,
      isNotNull,
    );

    final Finder fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '1');
    await tester.enterText(fields.at(1), 'Body A');
    await tester.enterText(fields.at(2), 'CAM-A1');
    await tester.enterText(fields.at(3), 'Body B');
    await tester.enterText(fields.at(4), 'CAM-B1');
    await tester.pump();
    await pumpFrames(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pump();
    await pumpFrames(tester);
    expect(find.text('Order summary'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Generate Order'));
    await tester.pump();
    await pumpFrames(tester, frames: 20);

    final List<Rental> rentals = await repo.listRentals();
    expect(
      rentals.any(
        (Rental r) =>
            r.lines.length == 2 &&
            r.lines.every((RentalLine l) => l.itemId == 'INV-2001') &&
            r.lines.map((RentalLine l) => l.shortCode).toSet().containsAll(
                  <String>{'CAM-A1', 'CAM-B1'},
                ),
      ),
      isTrue,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('individual qty 2 auto-labels two lines', (
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

    await _pumpOrder(
      tester,
      container: container,
      home: const NewOrderFlowScreen(
        initialCustomerId: 'CUS-1001',
        initialInventoryItemIds: <String>['INV-2003'],
      ),
    );

    expect(find.textContaining('auto short code'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('qty-inc-0')));
    await tester.pump();
    await pumpFrames(tester);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey<String>('qty-value-0'))).data,
      '2',
    );

    final Finder fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '1');
    await tester.pump();
    await pumpFrames(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pump();
    await pumpFrames(tester);
    expect(find.text('Order summary'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Generate Order'));
    await tester.pump();
    await pumpFrames(tester, frames: 20);

    final List<Rental> rentals = await repo.listRentals();
    expect(
      rentals.any(
        (Rental r) =>
            r.lines.length == 2 &&
            r.lines.every((RentalLine l) => l.itemId == 'INV-2003') &&
            r.lines.every((RentalLine l) => l.instanceName == 'Tripod') &&
            r.lines.map((RentalLine l) => l.shortCode).toSet().length == 2,
      ),
      isTrue,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('qty can exceed available across two lines of same item', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await bootContainer(seedDemo: true);
    final LocalRepository repo = container.read(repositoryProvider);
    await repo.updateInventory(
      id: 'INV-2001',
      name: 'DSLR',
      category: 'Camera',
      units: 4,
      requiresUnitIdentity: true,
    );

    tester.view.physicalSize = const Size(800, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpOrder(
      tester,
      container: container,
      home: const NewOrderFlowScreen(
        initialCustomerId: 'CUS-1001',
        initialInventoryItemIds: <String>['INV-2001', 'INV-2001'],
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('qty-inc-0')));
    await tester.pump();
    await pumpFrames(tester);

    // Available is 3 after units=4 with 1 already rented in demo; order can
    // still push past that — both + buttons stay enabled.
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey<String>('qty-inc-0')))
          .onPressed,
      isNotNull,
    );
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey<String>('qty-inc-1')))
          .onPressed,
      isNotNull,
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey<String>('qty-value-0'))).data,
      '2',
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey<String>('qty-value-1'))).data,
      '1',
    );

    await tester.tap(find.byKey(const ValueKey<String>('qty-inc-1')));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const ValueKey<String>('qty-value-1'))).data,
      '2',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  test('createRental multi-qty same item decrements stock', () async {
    final LocalRepository repo = await bootRepo();
    await repo.addInventory(
      name: 'Novels',
      category: 'Library',
      units: 5,
      rateAmount: 5000,
      requiresUnitIdentity: true,
    );
    final InventoryItem novels = (await repo.listInventory())
        .firstWhere((InventoryItem i) => i.name == 'Novels');
    final Customer customer = await ensureCustomer(repo);

    await repo.createRental(
      customer: customer,
      lines: <RentalLineInput>[
        RentalLineInput(
          itemId: novels.id,
          instanceName: 'Harry Potter',
          shortCode: 'NOV-1',
        ),
        RentalLineInput(
          itemId: novels.id,
          instanceName: 'The Hobbit',
          shortCode: 'NOV-2',
        ),
        RentalLineInput(
          itemId: novels.id,
          instanceName: 'Dune Book',
          shortCode: 'NOV-3',
        ),
      ],
    );

    final InventoryItem after = (await repo.listInventory())
        .firstWhere((InventoryItem i) => i.id == novels.id);
    expect(after.availableUnits, 2);
    final Rental created = (await repo.listRentals()).first;
    expect(created.lines, hasLength(3));
  });

  test('createRental oversell clamps available to zero', () async {
    final LocalRepository repo = await bootRepo();
    await repo.addInventory(
      name: 'Lenses',
      category: 'Camera',
      units: 1,
      rateAmount: 10000,
      requiresUnitIdentity: true,
    );
    final InventoryItem lenses = (await repo.listInventory())
        .firstWhere((InventoryItem i) => i.name == 'Lenses');
    final Customer customer = await ensureCustomer(repo);

    await repo.createRental(
      customer: customer,
      lines: <RentalLineInput>[
        RentalLineInput(
          itemId: lenses.id,
          instanceName: 'Lens A',
          shortCode: 'LEN-A1',
        ),
        RentalLineInput(
          itemId: lenses.id,
          instanceName: 'Lens B',
          shortCode: 'LEN-B1',
        ),
      ],
    );

    final InventoryItem after = (await repo.listInventory())
        .firstWhere((InventoryItem i) => i.id == lenses.id);
    expect(after.availableUnits, 0);
    expect(after.totalUnits, 1);
    expect((await repo.listRentals()).first.lines, hasLength(2));

    // Units remain editable anytime, including after oversell.
    await repo.updateInventory(
      id: lenses.id,
      name: 'Lenses',
      category: 'Camera',
      units: 4,
      requiresUnitIdentity: true,
    );
    final InventoryItem edited = (await repo.listInventory())
        .firstWhere((InventoryItem i) => i.id == lenses.id);
    expect(edited.totalUnits, 4);
    expect(edited.availableUnits, 3);
  });
}
