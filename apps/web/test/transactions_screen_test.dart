@Tags(['widget', 'loans', 'shell'])
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
import 'package:asset_os/features/loans/loan_create_screen.dart';
import 'package:asset_os/features/transactions/transactions_screen.dart';

import 'support/test_harness.dart';

Future<void> _seedOrderAndLoan(LocalRepository repo) async {
  await repo.addInventory(
    name: 'Drill Kit',
    category: 'Tools',
    units: 2,
    billingMode: BillingMode.daily,
    rateAmount: 10000,
  );
  final InventoryItem item = (await repo.listInventory()).first;
  final Customer customer = await ensureCustomer(repo, name: 'Priya Patel');
  await repo.createRental(
    customer: customer,
    lines: <RentalLineInput>[
      RentalLineInput(
        itemId: item.id,
        instanceName: 'Drill 1',
        shortCode: 'DRL-01',
      ),
    ],
    durationUnits: 2,
  );
  await repo.createMoneyLoan(
    customerId: customer.id,
    direction: MoneyLoanDirection.given,
    principalPaise: 500000,
    interestStartedAt: DateTime.now(),
    rateBps: 1200,
  );
}

Future<ProviderContainer> _pumpTransactions(
  WidgetTester tester, {
  Map<String, Object> prefs = const <String, Object>{},
}) async {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final ProviderContainer container = await bootContainer(prefs: prefs);
  ensureRentalDetailNavRegistered();
  await _seedOrderAndLoan(container.read(repositoryProvider));
  await container
      .read(enabledResourceTypesProvider.notifier)
      .setTypes(const <ResourceType>[
    ResourceType.rental,
    ResourceType.financial,
  ]);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const Scaffold(body: TransactionsScreen()),
      ),
    ),
  );
  await pumpFrames(tester, frames: 20);
  return container;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('merged list shows Order and Loan type badges', (
    WidgetTester tester,
  ) async {
    await _pumpTransactions(tester);

    expect(find.text('Order'), findsWidgets);
    expect(find.text('Loan'), findsWidgets);
    expect(find.text('Priya Patel'), findsWidgets);
  });

  testWidgets('Loans filter hides orders', (WidgetTester tester) async {
    await _pumpTransactions(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Loans'));
    await pumpFrames(tester);

    expect(find.text('Loan'), findsWidgets);
    expect(find.text('Order'), findsNothing);
  });

  testWidgets('New chooser offers Order and Loan routes', (
    WidgetTester tester,
  ) async {
    await _pumpTransactions(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'New'));
    await pumpFrames(tester);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('New order'), findsOneWidget);
    expect(find.text('New loan'), findsOneWidget);

    await tester.tap(find.text('New order'));
    await pumpFrames(tester, frames: 20);
    expect(find.byType(NewOrderFlowScreen), findsOneWidget);

    await tester.pageBack();
    await pumpFrames(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'New'));
    await pumpFrames(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('New loan'));
    await pumpFrames(tester, frames: 20);
    expect(find.byType(LoanCreateScreen), findsOneWidget);
  });

  testWidgets('pure financial New skips chooser and opens loan', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final ProviderContainer container = await bootContainer(
      prefs: <String, Object>{
        kEnabledResourceTypesPrefsKey: encodeEnabledResourceTypes(
          const <ResourceType>[ResourceType.financial],
        ),
      },
    );
    ensureRentalDetailNavRegistered();
    final LocalRepository repo = container.read(repositoryProvider);
    final Customer customer = await ensureCustomer(repo);
    await repo.createMoneyLoan(
      customerId: customer.id,
      direction: MoneyLoanDirection.given,
      principalPaise: 100000,
      interestStartedAt: DateTime.now(),
    );
    await container.read(enabledResourceTypesProvider.notifier).setTypes(
          const <ResourceType>[ResourceType.financial],
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.dark,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(body: TransactionsScreen()),
        ),
      ),
    );
    await pumpFrames(tester, frames: 20);

    await tester.tap(find.widgetWithText(FilledButton, 'New'));
    await pumpFrames(tester, frames: 20);
    expect(find.byType(LoanCreateScreen), findsOneWidget);
    expect(find.text('New order'), findsNothing);
  });
}
