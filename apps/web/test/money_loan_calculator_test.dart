@Tags(['unit', 'pricing', 'loans'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/core/repositories/local_repository.dart';

import 'support/test_harness.dart';

void main() {
  group('periodInterestPaise', () {
    test('simple monthly period is P * rate', () {
      // 2% monthly on ₹10,000 → ₹200
      final int interest = periodInterestPaise(
        principalPaise: 1000000,
        kind: MoneyInterestKind.simple,
        rateBps: 200,
      );
      expect(interest, 20000);
    });

    test('yearly simple period is P * rate', () {
      final int interest = periodInterestPaise(
        principalPaise: 1000000,
        kind: MoneyInterestKind.simple,
        rateBps: 1200, // 12%
      );
      expect(interest, 120000);
    });

    test('one-period simple and compound match', () {
      final int simple = periodInterestPaise(
        principalPaise: 1000000,
        kind: MoneyInterestKind.simple,
        rateBps: 200,
      );
      final int compound = periodInterestPaise(
        principalPaise: 1000000,
        kind: MoneyInterestKind.compound,
        rateBps: 200,
      );
      expect(compound, simple);
    });
  });

  group('computeLoanScenario period-end', () {
    test('mid-year payment reduces principal only; no interest until anniversary',
        () {
      final MoneyLoan loan = MoneyLoan(
        id: 'MLN-mid',
        customerId: 'C1',
        direction: MoneyLoanDirection.given,
        principalPaise: 1000000, // ₹10,000
        currencyCode: 'INR',
        interestKind: MoneyInterestKind.simple,
        rateBps: 1200, // 12%/year
        ratePeriod: MoneyRatePeriod.yearly,
        interestStartedAt: DateTime(2026, 1, 1),
        status: MoneyLoanStatus.pending,
        createdAt: DateTime(2026, 4, 1),
        entries: <MoneyLoanEntry>[
          MoneyLoanEntry(
            id: 'E1',
            loanId: 'MLN-mid',
            entryAt: DateTime(2026, 4, 1),
            amountPaise: 300000, // ₹3,000
            kind: MoneyLoanEntryKind.payment,
          ),
        ],
      );

      final LoanScenario midYear = computeLoanScenario(
        loan: loan,
        now: DateTime(2026, 6, 1),
      );
      expect(midYear.interestAccruedPaise, 0);
      expect(midYear.remainingPrincipalPaise, 700000);
      expect(midYear.pendingPaise, 700000);
      expect(midYear.unpaidInterestPaise, 0);
      expect(
        midYear.timeline.where(
          (LoanTimelineEvent e) => e.kind == LoanTimelineKind.interestSegment,
        ),
        isEmpty,
      );
      final LoanTimelineEvent payment = midYear.timeline.firstWhere(
        (LoanTimelineEvent e) => e.kind == LoanTimelineKind.payment,
      );
      expect(payment.toInterestPaise, 0);
      expect(payment.toPrincipalPaise, 300000);
    });

    test('after anniversary interest posts on reduced principal and capitalizes',
        () {
      final MoneyLoan loan = MoneyLoan(
        id: 'MLN-ann',
        customerId: 'C1',
        direction: MoneyLoanDirection.given,
        principalPaise: 1000000,
        currencyCode: 'INR',
        interestKind: MoneyInterestKind.simple,
        rateBps: 1200,
        ratePeriod: MoneyRatePeriod.yearly,
        interestStartedAt: DateTime(2026, 1, 1),
        status: MoneyLoanStatus.pending,
        createdAt: DateTime(2027, 1, 1),
        entries: <MoneyLoanEntry>[
          MoneyLoanEntry(
            id: 'E1',
            loanId: 'MLN-ann',
            entryAt: DateTime(2026, 4, 1),
            amountPaise: 300000,
            kind: MoneyLoanEntryKind.payment,
          ),
        ],
      );

      final LoanScenario after = computeLoanScenario(
        loan: loan,
        now: DateTime(2027, 1, 1),
      );
      // Interest on ₹7,000 × 12% = ₹840; capitalized → pending ₹7,840
      expect(after.interestAccruedPaise, 84000);
      expect(after.remainingPrincipalPaise, 784000);
      expect(after.pendingPaise, 784000);
      expect(after.unpaidInterestPaise, 0);

      final LoanTimelineEvent interest = after.timeline.firstWhere(
        (LoanTimelineEvent e) => e.kind == LoanTimelineKind.interestSegment,
      );
      expect(interest.at, DateTime(2027, 1, 1));
      expect(interest.principalBasisPaise, 700000);
      expect(interest.amountPaise, 84000);
    });

    test('monthly interest only after each full month', () {
      final MoneyLoan loan = MoneyLoan(
        id: 'MLN-mo',
        customerId: 'C1',
        direction: MoneyLoanDirection.given,
        principalPaise: 1000000,
        currencyCode: 'INR',
        interestKind: MoneyInterestKind.simple,
        rateBps: 200, // 2%/month
        ratePeriod: MoneyRatePeriod.monthly,
        interestStartedAt: DateTime(2026, 1, 1),
        status: MoneyLoanStatus.pending,
        createdAt: DateTime(2026, 1, 1),
      );

      final LoanScenario midMonth = computeLoanScenario(
        loan: loan,
        now: DateTime(2026, 1, 15),
      );
      expect(midMonth.interestAccruedPaise, 0);
      expect(midMonth.pendingPaise, 1000000);

      final LoanScenario oneMonth = computeLoanScenario(
        loan: loan,
        now: DateTime(2026, 2, 1),
      );
      expect(oneMonth.interestAccruedPaise, 20000);
      expect(oneMonth.pendingPaise, 1020000);

      final LoanScenario twoMonths = computeLoanScenario(
        loan: loan,
        now: DateTime(2026, 3, 1),
      );
      // Jan→Feb: 200 on 10k → 10200; Feb→Mar: 204 on 10200 → 10404
      expect(twoMonths.interestAccruedPaise, 40400);
      expect(twoMonths.pendingPaise, 1040400);
    });

    test('compound multi-period grows via capitalization', () {
      final MoneyLoan loan = MoneyLoan(
        id: 'MLN-cmp',
        customerId: 'C1',
        direction: MoneyLoanDirection.given,
        principalPaise: 1000000,
        currencyCode: 'INR',
        interestKind: MoneyInterestKind.compound,
        rateBps: 200,
        ratePeriod: MoneyRatePeriod.monthly,
        interestStartedAt: DateTime(2026, 1, 1),
        status: MoneyLoanStatus.pending,
        createdAt: DateTime(2026, 1, 1),
      );

      final LoanScenario threeMonths = computeLoanScenario(
        loan: loan,
        now: DateTime(2026, 4, 1),
      );
      // 10000 * 1.02^3 = 10612.08 → 1061208 paise (rounded per period)
      // Period fold: 1000000→1020000→1040400→1061208
      expect(threeMonths.interestAccruedPaise, 61208);
      expect(threeMonths.pendingPaise, 1061208);
      expect(
        threeMonths.timeline
            .where(
              (LoanTimelineEvent e) =>
                  e.kind == LoanTimelineKind.interestSegment,
            )
            .length,
        3,
      );
    });

    test('past start + two dated payments → period-end pending', () {
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

      // Jan→Feb→Mar→Apr: 3 months on 10k → capitalize to 1061208, then pay 3k
      // Apr 1 is a boundary: interest posts first, then payment.
      // Walk:
      //  Feb 1: +20000 → 1020000
      //  Mar 1: +20400 → 1040400
      //  Apr 1: +20808 → 1061208, then pay 300000 → 761208
      //  May 1: +15224 → 776432
      //  Jun 1: +15529 → 791961, then pay 200000 → 591961
      expect(asOfJun1.totalPaidPaise, 500000);
      expect(asOfJun1.interestAccruedPaise, 91961);
      expect(asOfJun1.pendingPaise, 591961);
      expect(asOfJun1.remainingPrincipalPaise, 591961);
      expect(
        asOfJun1.timeline.any(
          (LoanTimelineEvent e) => e.kind == LoanTimelineKind.payment,
        ),
        isTrue,
      );
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
      // Early: Jan→Feb→Mar = 2 periods; later: Feb→Mar = 1 period
      expect(laterStart.interestAccruedPaise, lessThan(early.interestAccruedPaise));
      expect(laterStart.pendingPaise, lessThan(early.pendingPaise));
      expect(early.timeline.where(
        (LoanTimelineEvent e) => e.kind == LoanTimelineKind.interestSegment,
      ).length, 2);
      expect(laterStart.timeline.where(
        (LoanTimelineEvent e) => e.kind == LoanTimelineKind.interestSegment,
      ).length, 1);
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

    test('addMoneyLoanEntry nudges watchMoneyLoans with new entry', () async {
      final LocalRepository repo = await bootRepo();
      final customer = await ensureCustomer(repo);
      final String loanId = await repo.createMoneyLoan(
        customerId: customer.id,
        direction: MoneyLoanDirection.given,
        principalPaise: 100000,
        interestStartedAt: DateTime(2026, 1, 1),
        rateBps: 0,
      );

      final List<List<MoneyLoan>> emissions = <List<MoneyLoan>>[];
      final sub = repo.watchMoneyLoans().listen(emissions.add);
      addTearDown(sub.cancel);

      // Wait for initial emission (loan with zero entries).
      await Future<void>.delayed(Duration.zero);
      await pumpEventQueue();
      expect(emissions, isNotEmpty);
      final MoneyLoan before = emissions.last.firstWhere(
        (MoneyLoan l) => l.id == loanId,
      );
      expect(before.entries, isEmpty);

      await repo.addMoneyLoanEntry(
        loanId: loanId,
        entryAt: DateTime(2026, 1, 15),
        amountPaise: 25000,
        kind: MoneyLoanEntryKind.payment,
      );
      await pumpEventQueue();

      final MoneyLoan after = emissions.last.firstWhere(
        (MoneyLoan l) => l.id == loanId,
      );
      expect(after.entries, hasLength(1));
      expect(after.entries.single.amountPaise, 25000);
      expect(
        computeLoanScenario(loan: after, now: DateTime(2026, 1, 15)).pendingPaise,
        75000,
      );
    });
  });

  group('schema', () {
    test('schemaVersion is 14 with money loan tables', () async {
      final LocalRepository repo = await bootRepo();
      expect(repo.database.schemaVersion, 14);
    });
  });
}
