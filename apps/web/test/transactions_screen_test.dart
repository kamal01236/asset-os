@Tags(['widget', 'loans', 'shell'])
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/core/l10n/l10n_ext.dart';
import 'package:asset_os/core/models/entities.dart';
import 'package:asset_os/core/providers/app_providers.dart';
import 'package:asset_os/core/theme/app_theme.dart';
import 'package:asset_os/features/loans/loan_create_screen.dart';
import 'package:asset_os/features/orders/new_order_flow_screen.dart';
import 'package:asset_os/features/orders/rental_detail_nav.dart';
import 'package:asset_os/features/transactions/transactions_screen.dart';

import 'support/test_harness.dart';

Rental _rental(Customer customer, DateTime now) => Rental(
      id: 'REN-1',
      customerId: customer.id,
      startedAt: now,
      dueAt: now.add(const Duration(days: 1)),
      qrCode: 'r1',
      lines: const <RentalLine>[],
      timeline: const <RentalEvent>[],
    );

MoneyLoan _loan(Customer customer, DateTime now) => MoneyLoan(
      id: 'MLN-1',
      customerId: customer.id,
      direction: MoneyLoanDirection.given,
      principalPaise: 500000,
      currencyCode: 'INR',
      interestKind: MoneyInterestKind.simple,
      rateBps: 1200,
      ratePeriod: MoneyRatePeriod.monthly,
      interestStartedAt: now,
      status: MoneyLoanStatus.pending,
      createdAt: now,
    );

Future<ProviderContainer> _containerWithTxns() async {
  final DateTime now = DateTime(2026, 8, 6);
  const Customer customer = Customer(
    id: 'CUS-1',
    name: 'Priya Patel',
    phone: '6666666666',
    isTrusted: true,
    qrCode: 'c1',
  );
  final ProviderContainer base = await bootContainer(
    prefs: <String, Object>{
      kEnabledResourceTypesPrefsKey: encodeEnabledResourceTypes(
        const <ResourceType>[ResourceType.rental, ResourceType.financial],
      ),
    },
  );
  // Rebuild with stream overrides on top of harness overrides.
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      sharedPreferencesProvider.overrideWithValue(
        base.read(sharedPreferencesProvider),
      ),
      databaseProvider.overrideWithValue(base.read(databaseProvider)),
      repositoryProvider.overrideWithValue(base.read(repositoryProvider)),
      needsIndustryOnboardingProvider.overrideWith((ref) => false),
      rentalsProvider.overrideWith((ref) async* {
        yield <Rental>[_rental(customer, now)];
      }),
      moneyLoansProvider.overrideWith((ref) async* {
        yield <MoneyLoan>[_loan(customer, now)];
      }),
      customersProvider.overrideWith((ref) async* {
        yield <Customer>[customer];
      }),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _pump(
  WidgetTester tester,
  ProviderContainer container,
) async {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  registerRentalDetailScreenFactory(
    ({required String rentalId}) => Text(rentalId),
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
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('merged list shows Order and Loan type badges', (tester) async {
    final ProviderContainer container = await _containerWithTxns();
    await _pump(tester, container);

    expect(find.text('Order'), findsOneWidget);
    expect(find.text('Loan'), findsOneWidget);
    expect(find.text('Priya Patel'), findsWidgets);
  });

  testWidgets('Loans filter hides orders', (tester) async {
    final ProviderContainer container = await _containerWithTxns();
    await _pump(tester, container);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Loans'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Loan'), findsOneWidget);
    expect(find.text('Order'), findsNothing);
  });

  testWidgets('New chooser offers Order and Loan routes', (tester) async {
    final ProviderContainer container = await _containerWithTxns();
    await _pump(tester, container);

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'New'));
    await tester.tap(find.widgetWithText(FilledButton, 'New'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('New order'), findsOneWidget);
    expect(find.text('New loan'), findsOneWidget);

    await tester.tap(find.text('New loan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(LoanCreateScreen), findsOneWidget);
  });

  testWidgets('New chooser New order opens order flow', (tester) async {
    final ProviderContainer container = await _containerWithTxns();
    await _pump(tester, container);

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'New'));
    await tester.tap(find.widgetWithText(FilledButton, 'New'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('New order'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(NewOrderFlowScreen), findsOneWidget);
  });
}
