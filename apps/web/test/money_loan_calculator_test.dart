@Tags(['unit', 'pricing', 'loans'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/core/loans/loan_balance.dart';
import 'package:asset_os/core/loans/loan_models.dart';
import 'package:asset_os/core/repositories/local_repository.dart';

import 'support/test_harness.dart';

void main() {
  group('accrueInterestPaise', () {
    test('simple monthly accrues over 30 days', () {
      // 2% monthly on ₹10,000 for 30 days ≈ ₹200
      final int interest = accrueInterestPaise(
        principalPaise: 1000000,
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 1, 31),
        kind: MoneyInterestKind.simple,
        rateBps: 200,
        ratePeriod: MoneyRatePeriod.monthly,
      );
      expect(interest, 20000);
    });

    test('compound exceeds simple over multi-period', () {
      final int simple = accrueInterestPaise(
        principalPaise: 1000000,
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 4, 1),
        kind: MoneyInterestKind.simple,
        rateBps: 200,
        ratePeriod: MoneyRatePeriod.monthly,
      );
      final int compound = accrueInterestPaise(
        principalPaise: 1000000,
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 4, 1),
        kind: MoneyInterestKind.compound,
        rateBps: 200,
        ratePeriod: MoneyRatePeriod.monthly,
      );
      expect(compound, greaterThan(simple));
    });

    test('yearly simple accrues over 365 days', () {
      final int interest = accrueInterestPaise(
        principalPaise: 1000000,
        from: DateTime(2025, 1, 1),
        to: DateTime(2026, 1, 1),
        kind: MoneyInterestKind.simple,
        rateBps: 1200, // 12%
        ratePeriod: MoneyRatePeriod.yearly,
      );
      expect(interest, 120000);
    });
  });

  group('computeLoanScenario backfill', () {
    test('past start + two dated payments → correct pending', () {
      final MoneyLoan loan = MoneyLoan(
        id: 'MLN-1',
        customerId: 'C1',
        direction: MoneyLoanDirection.given,
        principalPaise: 1000000, // ₹10,000
        currencyCode: 'INR',
        interestKind: MoneyInterestKind.simple,
        rateBps: 200, // 2%/month
        ratePeriod: MoneyRatePeriod.monthly,
        interestStartedAt: DateTime(2026, 1, 1),
        status: MoneyLoanStatus.pending,
        createdAt: DateTime(2026, 6, 1),
        entries: <MoneyLoanEntry>[
          MoneyLoanEntry(
            id: 'E1',
            loanId: 'MLN-1',
            entryAt: DateTime(2026, 4, 1),
            amountPaise: 300000,
            kind: MoneyLoanEntryKind.payment,
          ),
          MoneyLoanEntry(
            id: 'E2',
            loanId: 'MLN-1',
            entryAt: DateTime(2026, 6, 1),
            amountPaise: 200000,
            kind: MoneyLoanEntryKind.payment,
          ),
        ],
      );

      final LoanScenario asOfJun1 = computeLoanScenario(
        loan: loan,
        now: DateTime(2026, 6, 1),
      );

      // Jan 1 → Apr 1 = 90 days = 3 months → ₹600 interest on 10k
      // Payment 3k: 600 interest + 2400 principal → principal 7600
      // Apr 1 → Jun 1 = 61 days → interest ≈ 7600 * 0.02 * (61/30)
      expect(asOfJun1.totalPaidPaise, 500000);
      expect(asOfJun1.interestAccruedPaise, greaterThan(60000));
      expect(asOfJun1.pendingPaise, greaterThan(0));
      expect(asOfJun1.remainingPrincipalPaise, lessThan(1000000));
      expect(
        asOfJun1.timeline.any(
          (LoanTimelineEvent e) => e.kind == LoanTimelineKind.payment,
        ),
        isTrue,
      );
      // Still pending — no auto-close
      expect(loan.status, MoneyLoanStatus.pending);
    });

    test('edit start date changes totals', () {
      final MoneyLoan base = MoneyLoan(
        id: 'MLN-2',
        customerId: 'C1',
        direction: MoneyLoanDirection.taken,
        principalPaise: 1000000,
        currencyCode: 'INR',
        interestKind: MoneyInterestKind.simple,
        rateBps: 100,
        ratePeriod: MoneyRatePeriod.monthly,
        interestStartedAt: DateTime(2026, 1, 1),
        status: MoneyLoanStatus.pending,
        createdAt: DateTime(2026, 3, 1),
      );
      final LoanScenario early = computeLoanScenario(
        loan: base,
        now: DateTime(2026, 3, 1),
      );
      final LoanScenario laterStart = computeLoanScenario(
        loan: base.copyWith(interestStartedAt: DateTime(2026, 2, 1)),
        now: DateTime(2026, 3, 1),
      );
      expect(laterStart.interestAccruedPaise, lessThan(early.interestAccruedPaise));
      expect(laterStart.pendingPaise, lessThan(early.pendingPaise));
    });

    test('adjustment clears remainder then close allowed', () async {
      final LocalRepository repo = await bootRepo();
      final customer = await ensureCustomer(repo);
      final String loanId = await repo.createMoneyLoan(
        customerId: customer.id,
        direction: MoneyLoanDirection.given,
        principalPaise: 100000, // ₹1,000
        interestStartedAt: DateTime(2026, 1, 1),
        interestKind: MoneyInterestKind.simple,
        rateBps: 0,
        ratePeriod: MoneyRatePeriod.monthly,
      );
      await repo.addMoneyLoanEntry(
        loanId: loanId,
        entryAt: DateTime(2026, 2, 1),
        amountPaise: 60000,
        kind: MoneyLoanEntryKind.payment,
      );
      MoneyLoan? loan = await repo.getMoneyLoan(loanId);
      LoanScenario scenario = computeLoanScenario(
        loan: loan!,
        now: DateTime(2026, 2, 1),
      );
      expect(scenario.pendingPaise, 40000);
      expect(loan.status, MoneyLoanStatus.pending);

      await repo.addMoneyLoanEntry(
        loanId: loanId,
        entryAt: DateTime(2026, 2, 1),
        amountPaise: 40000,
        kind: MoneyLoanEntryKind.adjustment,
      );
      loan = await repo.getMoneyLoan(loanId);
      scenario = computeLoanScenario(loan: loan!, now: DateTime(2026, 2, 1));
      expect(scenario.pendingPaise, 0);

      await repo.closeMoneyLoan(loanId, closedAt: DateTime(2026, 2, 1));
      loan = await repo.getMoneyLoan(loanId);
      expect(loan!.status, MoneyLoanStatus.closed);
    });

    test('keep pending after partial pay when remaining > 0', () async {
      final LocalRepository repo = await bootRepo();
      final customer = await ensureCustomer(repo);
      final String loanId = await repo.createMoneyLoan(
        customerId: customer.id,
        direction: MoneyLoanDirection.taken,
        principalPaise: 500000,
        interestStartedAt: DateTime.now(),
        rateBps: 0,
      );
      await repo.addMoneyLoanEntry(
        loanId: loanId,
        entryAt: DateTime.now(),
        amountPaise: 100000,
        kind: MoneyLoanEntryKind.payment,
      );
      final MoneyLoan loan = (await repo.getMoneyLoan(loanId))!;
      final LoanScenario scenario = computeLoanScenario(loan: loan);
      expect(scenario.pendingPaise, greaterThan(0));
      expect(loan.status, MoneyLoanStatus.pending);
    });

    test('given and taken loans per customer', () async {
      final LocalRepository repo = await bootRepo();
      final customer = await ensureCustomer(repo);
      await repo.createMoneyLoan(
        customerId: customer.id,
        direction: MoneyLoanDirection.given,
        principalPaise: 100000,
        interestStartedAt: DateTime.now(),
      );
      await repo.createMoneyLoan(
        customerId: customer.id,
        direction: MoneyLoanDirection.taken,
        principalPaise: 200000,
        interestStartedAt: DateTime.now(),
      );
      final List<MoneyLoan> loans =
          await repo.listMoneyLoans(customerId: customer.id);
      expect(loans, hasLength(2));
      expect(
        loans.map((MoneyLoan l) => l.direction).toSet(),
        <MoneyLoanDirection>{
          MoneyLoanDirection.given,
          MoneyLoanDirection.taken,
        },
      );
    });

    test('close with outstanding does not auto-close on payment', () async {
      final LocalRepository repo = await bootRepo();
      final customer = await ensureCustomer(repo);
      final String loanId = await repo.createMoneyLoan(
        customerId: customer.id,
        direction: MoneyLoanDirection.given,
        principalPaise: 100000,
        interestStartedAt: DateTime.now(),
        rateBps: 0,
      );
      await repo.addMoneyLoanEntry(
        loanId: loanId,
        entryAt: DateTime.now(),
        amountPaise: 100000,
        kind: MoneyLoanEntryKind.payment,
      );
      MoneyLoan loan = (await repo.getMoneyLoan(loanId))!;
      expect(computeLoanScenario(loan: loan).pendingPaise, 0);
      expect(loan.status, MoneyLoanStatus.pending);

      await repo.closeMoneyLoan(loanId);
      loan = (await repo.getMoneyLoan(loanId))!;
      expect(loan.status, MoneyLoanStatus.closed);
    });
  });

  group('schema', () {
    test('schemaVersion is 14 with money loan tables', () async {
      final LocalRepository repo = await bootRepo();
      expect(repo.database.schemaVersion, 14);
    });
  });
}
