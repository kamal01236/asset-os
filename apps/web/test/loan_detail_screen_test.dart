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
    'summary Principal shows remaining after disbursement and Original when different',
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

      expect(find.text('Principal'), findsOneWidget);
      expect(find.text('₹15000'), findsWidgets);
      expect(find.text('Original principal'), findsOneWidget);
      expect(find.text('₹10000'), findsOneWidget);

      await _tearDownDetail(tester);
    },
  );

  testWidgets(
    'summary omits Original principal when remaining equals create amount',
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

      expect(find.text('Principal'), findsOneWidget);
      expect(find.text('₹2500'), findsWidgets);
      expect(find.text('Original principal'), findsNothing);

      await _tearDownDetail(tester);
    },
  );

  testWidgets('HI locale shows प्रारंभिक मूलधन when principal changed', (
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

    expect(find.text('मूलधन'), findsWidgets);
    expect(find.text('प्रारंभिक मूलधन'), findsOneWidget);
    expect(find.text('₹15000'), findsWidgets);
    expect(find.text('₹10000'), findsOneWidget);

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
}
