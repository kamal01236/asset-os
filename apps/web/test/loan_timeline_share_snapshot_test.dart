@Tags(['widget', 'loans'])
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/domain/config/app_branding.dart';
import 'package:asset_os/domain/models/entities.dart';
import 'package:asset_os/infrastructure/l10n/l10n_ext.dart';
import 'package:asset_os/application/providers/app_providers.dart';
import 'package:asset_os/application/local_repository.dart';
import 'package:asset_os/presentation/theme/app_theme.dart';
import 'package:asset_os/presentation/features/loans/loan_timeline_share_snapshot.dart';

import 'support/test_harness.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('LoanTimelineShareSnapshot shows header and timeline heading', (
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
      note: 'PAY-SNAP',
    );

    final MoneyLoan loan = (await repo.listMoneyLoans())
        .firstWhere((MoneyLoan l) => l.id == loanId);
    final LoanScenario scenario =
        computeLoanScenario(loan: loan, now: DateTime(2026, 3, 1));
    final DateTime generatedAt = DateTime(2026, 3, 1, 14, 30);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: LoanTimelineShareSnapshot(
              loan: loan,
              scenario: scenario,
              customerName: customer.name,
              generatedAt: generatedAt,
            ),
          ),
        ),
      ),
    );
    await pumpFrames(tester, frames: 10);

    expect(find.text(kAppDisplayName), findsOneWidget);
    expect(find.text(customer.name), findsWidgets);
    expect(find.text('Timeline'), findsOneWidget);
    expect(find.text('Particulars'), findsOneWidget);
    expect(find.text('Payment'), findsOneWidget);
    expect(find.textContaining('PAY-SNAP'), findsOneWidget);
    expect(find.textContaining('Bal '), findsWidgets);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
