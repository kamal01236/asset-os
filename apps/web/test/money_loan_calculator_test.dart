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

  group('proRataPeriodInterestPaise', () {
    test('yearly half-year on repaid slice is P * rate * 6/12', () {
      final int interest = proRataPeriodInterestPaise(
        principalPaise: 5000000, // ₹50,000
        rateBps: 1200, // 12%/year
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 7, 1),
        ratePeriod: MoneyRatePeriod.yearly,
      );
      expect(interest, 300000); // ₹3,000
    });

    test('monthly mid-period uses days / days-in-period', () {
      // Jan 1→Feb 1 = 31 days; pay on Jan 16 → 15/31
      final int interest = proRataPeriodInterestPaise(
        principalPaise: 5000000,
        rateBps: 200, // 2%/month
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 1, 16),
        ratePeriod: MoneyRatePeriod.monthly,
      );
      expect(interest, (5000000 * 0.02 * 15 / 31).round());
    });
  });

  group('computeLoanScenario period-end', () {
    test('₹1L yearly: mid-period ₹50k repay defers 6mo interest on slice', () {
      final MoneyLoan loan = MoneyLoan(
        id: 'MLN-1L',
        customerId: 'C1',
        direction: MoneyLoanDirection.given,
        principalPaise: 10000000, // ₹1,00,000
        currencyCode: 'INR',
        interestKind: MoneyInterestKind.simple,
        rateBps: 1200, // 12%/year
        ratePeriod: MoneyRatePeriod.yearly,
        interestStartedAt: DateTime(2026, 1, 1),
        status: MoneyLoanStatus.pending,
        createdAt: DateTime(2026, 7, 1),
        entries: <MoneyLoanEntry>[
          MoneyLoanEntry(
            id: 'E1',
            loanId: 'MLN-1L',
            entryAt: DateTime(2026, 7, 1),
            amountPaise: 5000000, // ₹50,000
            kind: MoneyLoanEntryKind.payment,
          ),
        ],
      );

      final LoanScenario midYear = computeLoanScenario(
        loan: loan,
        now: DateTime(2026, 7, 1),
      );
      // Slice interest: 50000 × 12% × 6/12 = ₹3,000 (deferred, not capitalized)
      expect(midYear.interestAccruedPaise, 300000);
      expect(midYear.remainingPrincipalPaise, 5000000);
      expect(midYear.unpaidInterestPaise, 300000);
      expect(midYear.pendingPaise, 5300000);
      expect(
        midYear.timeline.where(
          (LoanTimelineEvent e) => e.kind == LoanTimelineKind.interestSegment,
        ),
        isEmpty,
      );
      final LoanTimelineEvent deferred = midYear.timeline.firstWhere(
        (LoanTimelineEvent e) =>
            e.kind == LoanTimelineKind.deferredSliceInterest,
      );
      expect(deferred.amountPaise, 300000);
      expect(deferred.principalBasisPaise, 5000000);
      final LoanTimelineEvent payment = midYear.timeline.firstWhere(
        (LoanTimelineEvent e) => e.kind == LoanTimelineKind.payment,
      );
      expect(payment.toInterestPaise, 0);
      expect(payment.toPrincipalPaise, 5000000);
    });

    test('₹1L yearly: anniversary capitalizes deferred + remaining interest',
        () {
      final MoneyLoan loan = MoneyLoan(
        id: 'MLN-1L-ann',
        customerId: 'C1',
        direction: MoneyLoanDirection.given,
        principalPaise: 10000000,
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
            loanId: 'MLN-1L-ann',
            entryAt: DateTime(2026, 7, 1),
            amountPaise: 5000000,
            kind: MoneyLoanEntryKind.payment,
          ),
        ],
      );

      final LoanScenario after = computeLoanScenario(
        loan: loan,
        now: DateTime(2027, 1, 1),
      );
      // Deferred 3000 + remaining 50000×12% = 6000 → total interest ₹9,000
      // Capitalized → pending ₹50,000 + ₹9,000 = ₹59,000
      expect(after.interestAccruedPaise, 900000);
      expect(after.remainingPrincipalPaise, 5900000);
      expect(after.pendingPaise, 5900000);
      expect(after.unpaidInterestPaise, 0);

      final LoanTimelineEvent interest = after.timeline.firstWhere(
        (LoanTimelineEvent e) => e.kind == LoanTimelineKind.interestSegment,
      );
      expect(interest.at, DateTime(2027, 1, 1));
      expect(interest.principalBasisPaise, 5000000);
      expect(interest.amountPaise, 900000);
    });

    test('monthly: mid-period repay defers day-pro-rata slice; month-end caps',
        () {
      final MoneyLoan loan = MoneyLoan(
        id: 'MLN-mo-slice',
        customerId: 'C1',
        direction: MoneyLoanDirection.given,
        principalPaise: 10000000, // ₹1,00,000
        currencyCode: 'INR',
        interestKind: MoneyInterestKind.simple,
        rateBps: 200, // 2%/month
        ratePeriod: MoneyRatePeriod.monthly,
        interestStartedAt: DateTime(2026, 1, 1),
        status: MoneyLoanStatus.pending,
        createdAt: DateTime(2026, 1, 16),
        entries: <MoneyLoanEntry>[
          MoneyLoanEntry(
            id: 'E1',
            loanId: 'MLN-mo-slice',
            entryAt: DateTime(2026, 1, 16),
            amountPaise: 5000000, // ₹50,000
            kind: MoneyLoanEntryKind.payment,
          ),
        ],
      );

      final int sliceInterest = (5000000 * 0.02 * 15 / 31).round();

      final LoanScenario midMonth = computeLoanScenario(
        loan: loan,
        now: DateTime(2026, 1, 16),
      );
      expect(midMonth.interestAccruedPaise, sliceInterest);
      expect(midMonth.remainingPrincipalPaise, 5000000);
      expect(midMonth.unpaidInterestPaise, sliceInterest);
      expect(midMonth.pendingPaise, 5000000 + sliceInterest);

      final LoanScenario monthEnd = computeLoanScenario(
        loan: loan,
        now: DateTime(2026, 2, 1),
      );
      // Remaining full month: 50000 × 2% = ₹1,000; capitalize both
      const int remainingInterest = 100000;
      final int totalInterest = sliceInterest + remainingInterest;
      expect(monthEnd.interestAccruedPaise, totalInterest);
      expect(monthEnd.pendingPaise, 5000000 + totalInterest);
      expect(monthEnd.unpaidInterestPaise, 0);
      final LoanTimelineEvent posted = monthEnd.timeline.firstWhere(
        (LoanTimelineEvent e) => e.kind == LoanTimelineKind.interestSegment,
      );
      expect(posted.amountPaise, totalInterest);
      expect(posted.principalBasisPaise, 5000000);
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
