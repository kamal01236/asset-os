@Tags(['widget', 'loans'])
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/infrastructure/l10n/l10n_ext.dart';
import 'package:asset_os/domain/models/entities.dart';
import 'package:asset_os/application/providers/app_providers.dart';
import 'package:asset_os/application/local_repository.dart';
import 'package:asset_os/presentation/theme/app_theme.dart';
import 'package:asset_os/presentation/features/loans/loan_detail_screen.dart';

import 'support/test_harness.dart';

Future<void> _pumpDetail(
  WidgetTester tester, {
  required ProviderContainer container,
  required String loanId,
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: container.read(themeModeProvider),
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: LoanDetailScreen(loanId: loanId),
      ),
    ),
  );
  await pumpFrames(tester, frames: 20);
}

Future<void> _tearDownDetail(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 1));
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets(
    'summary shows Total and Pending principal after disbursement',
    (WidgetTester tester) async {
      final ProviderContainer container = await bootContainer();
      final LocalRepository repo = container.read(repositoryProvider);
      final Customer customer = await ensureCustomer(repo);

      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final DateTime start = DateTime(2026, 1, 1);
      final String loanId = await repo.createMoneyLoan(
        customerId: customer.id,
        direction: MoneyLoanDirection.given,
        principalPaise: 1000000, // ₹10,000
        interestStartedAt: start,
        rateBps: 0,
      );
      await repo.addMoneyLoanPrincipal(
        loanId: loanId,
        amountPaise: 500000, // ₹5,000
        entryAt: start,
        note: 'DISB-1',
      );

      await _pumpDetail(tester, container: container, loanId: loanId);

      expect(find.text('Total principal'), findsOneWidget);
      expect(find.text('Pending principal'), findsOneWidget);
      expect(find.text('Total interest'), findsNothing);
      expect(find.text('Pending interest'), findsNothing);
      expect(find.text('Paid'), findsOneWidget);
      expect(find.text('Adjustments'), findsOneWidget);
      expect(find.text('₹15000'), findsWidgets);
      expect(find.text('Original principal'), findsNothing);

      await _tearDownDetail(tester);
    },
  );

  testWidgets(
    'summary always shows Total and Pending principal without disbursement',
    (WidgetTester tester) async {
      final ProviderContainer container = await bootContainer();
      final LocalRepository repo = container.read(repositoryProvider);
      final Customer customer = await ensureCustomer(repo);

      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final String loanId = await repo.createMoneyLoan(
        customerId: customer.id,
        direction: MoneyLoanDirection.given,
        principalPaise: 250000, // ₹2,500
        interestStartedAt: DateTime(2026, 1, 1),
        rateBps: 0,
      );

      await _pumpDetail(tester, container: container, loanId: loanId);

      expect(find.text('Total principal'), findsOneWidget);
      expect(find.text('Pending principal'), findsOneWidget);
      expect(find.text('₹2500'), findsWidgets);
      expect(find.text('Original principal'), findsNothing);

      await _tearDownDetail(tester);
    },
  );

  testWidgets('HI locale shows कुल मूलधन and लंबित मूलधन after disbursement', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await bootContainer();
    final LocalRepository repo = container.read(repositoryProvider);
    final Customer customer = await ensureCustomer(repo);

    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final DateTime start = DateTime(2026, 1, 1);
    final String loanId = await repo.createMoneyLoan(
      customerId: customer.id,
      direction: MoneyLoanDirection.given,
      principalPaise: 1000000,
      interestStartedAt: start,
      rateBps: 0,
    );
    await repo.addMoneyLoanPrincipal(
      loanId: loanId,
      amountPaise: 500000,
      entryAt: start,
      note: 'DISB-2',
    );

    await _pumpDetail(
      tester,
      container: container,
      loanId: loanId,
      locale: const Locale('hi'),
    );

    expect(find.text('कुल मूलधन'), findsOneWidget);
    expect(find.text('लंबित मूलधन'), findsOneWidget);
    expect(find.text('कुल ब्याज'), findsNothing);
    expect(find.text('लंबित ब्याज'), findsNothing);
    expect(find.text('₹15000'), findsWidgets);
    expect(find.text('प्रारंभिक मूलधन'), findsNothing);

    await _tearDownDetail(tester);
  });

  testWidgets('pending loan repayment row shows edit affordance', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await bootContainer();
    final LocalRepository repo = container.read(repositoryProvider);
    final Customer customer = await ensureCustomer(repo);

    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final String loanId = await repo.createMoneyLoan(
      customerId: customer.id,
      direction: MoneyLoanDirection.given,
      principalPaise: 100000,
      interestStartedAt: DateTime(2026, 1, 1),
      rateBps: 0,
    );
    await repo.addMoneyLoanEntry(
      loanId: loanId,
      entryAt: DateTime(2026, 2, 1),
      amountPaise: 25000,
      kind: MoneyLoanEntryKind.repayment,
      note: 'PAY-EDIT',
    );

    await _pumpDetail(tester, container: container, loanId: loanId);

    expect(find.byTooltip('Edit entry'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'Edit entry\..*amount.*balance')),
      findsWidgets,
    );

    await _tearDownDetail(tester);
  });

  testWidgets('edit sheet opens prefilled for repayment', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await bootContainer();
    final LocalRepository repo = container.read(repositoryProvider);
    final Customer customer = await ensureCustomer(repo);

    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final String loanId = await repo.createMoneyLoan(
      customerId: customer.id,
      direction: MoneyLoanDirection.given,
      principalPaise: 100000,
      interestStartedAt: DateTime(2026, 1, 1),
      rateBps: 0,
    );
    await repo.addMoneyLoanEntry(
      loanId: loanId,
      entryAt: DateTime(2026, 2, 1),
      amountPaise: 25000,
      kind: MoneyLoanEntryKind.repayment,
      note: 'PAY-EDIT',
    );

    await _pumpDetail(tester, container: container, loanId: loanId);

    await tester.tap(find.byTooltip('Edit entry'));
    await pumpFrames(tester, frames: 10);

    expect(find.text('Edit payment'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Delete entry'), findsOneWidget);

    await _tearDownDetail(tester);
  });

  testWidgets('closed loan hides edit affordance on timeline', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await bootContainer();
    final LocalRepository repo = container.read(repositoryProvider);
    final Customer customer = await ensureCustomer(repo);

    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final String loanId = await repo.createMoneyLoan(
      customerId: customer.id,
      direction: MoneyLoanDirection.given,
      principalPaise: 100000,
      interestStartedAt: DateTime(2026, 1, 1),
      rateBps: 0,
    );
    await repo.addMoneyLoanEntry(
      loanId: loanId,
      entryAt: DateTime(2026, 2, 1),
      amountPaise: 100000,
      kind: MoneyLoanEntryKind.repayment,
      note: 'PAY-FULL',
    );
    await repo.closeMoneyLoan(loanId, closedAt: DateTime(2026, 2, 1));

    await _pumpDetail(tester, container: container, loanId: loanId);

    expect(find.byTooltip('Edit entry'), findsNothing);

    await _tearDownDetail(tester);
  });

  testWidgets('pending loan shows equal-width action labels', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await bootContainer();
    final LocalRepository repo = container.read(repositoryProvider);
    final Customer customer = await ensureCustomer(repo);

    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final String loanId = await repo.createMoneyLoan(
      customerId: customer.id,
      direction: MoneyLoanDirection.given,
      principalPaise: 100000,
      interestStartedAt: DateTime(2026, 1, 1),
      rateBps: 0,
    );

    await _pumpDetail(tester, container: container, loanId: loanId);

    expect(find.text('Add payment'), findsOneWidget);
    expect(find.text('Add to principal'), findsOneWidget);
    expect(find.text('Add adjustment'), findsOneWidget);
    expect(find.text('Keep pending'), findsOneWidget);
    expect(find.text('Mark closed'), findsOneWidget);
    expect(find.text('Capitalize interest'), findsNothing);

    await _tearDownDetail(tester);
  });

  testWidgets('timeline heading shows share affordance', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await bootContainer();
    final LocalRepository repo = container.read(repositoryProvider);
    final Customer customer = await ensureCustomer(repo);

    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final String loanId = await repo.createMoneyLoan(
      customerId: customer.id,
      direction: MoneyLoanDirection.given,
      principalPaise: 100000,
      interestStartedAt: DateTime(2026, 1, 1),
      rateBps: 0,
    );

    await _pumpDetail(tester, container: container, loanId: loanId);

    expect(find.text('Timeline'), findsOneWidget);
    expect(find.byTooltip('Share timeline'), findsOneWidget);
    expect(find.byIcon(Icons.share_outlined), findsOneWidget);

    await _tearDownDetail(tester);
  });

  testWidgets('ledger timeline shows amount and Bal for seeded loan', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await bootContainer();
    final LocalRepository repo = container.read(repositoryProvider);
    final Customer customer = await ensureCustomer(repo);

    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final String loanId = await repo.createMoneyLoan(
      customerId: customer.id,
      direction: MoneyLoanDirection.given,
      principalPaise: 100000,
      interestStartedAt: DateTime(2026, 1, 1),
      rateBps: 0,
    );
    await repo.addMoneyLoanEntry(
      loanId: loanId,
      entryAt: DateTime(2026, 2, 1),
      amountPaise: 25000,
      kind: MoneyLoanEntryKind.repayment,
      note: 'LEDGER-PAY',
    );

    await _pumpDetail(tester, container: container, loanId: loanId);

    expect(find.text('Date'), findsOneWidget);
    expect(find.text('Particulars'), findsOneWidget);
    expect(find.text('Amount'), findsOneWidget);
    expect(find.text('Bal'), findsOneWidget);
    expect(find.text('Principal'), findsOneWidget);
    expect(find.text('Payment'), findsOneWidget);
    expect(find.text('01/01/2026'), findsWidgets);
    expect(find.text('01/02/2026'), findsOneWidget);
    expect(find.text('+₹1000'), findsOneWidget);
    expect(find.text('−₹250'), findsOneWidget);
    expect(find.text('₹1000'), findsWidgets);
    expect(find.text('₹750'), findsWidgets);
    expect(find.text('Bal ₹1000'), findsNothing);
    expect(find.text('Pending now'), findsWidgets);
    expect(find.textContaining('LEDGER-PAY'), findsOneWidget);

    await _tearDownDetail(tester);
  });
}
