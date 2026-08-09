@Tags(['unit', 'pricing', 'loans'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/application/local_repository.dart';

import 'support/test_harness.dart';

MoneyLoan _loan({
  required String id,
  required int principalPaise,
  required int rateBps,
  required MoneyRatePeriod ratePeriod,
  required DateTime startedAt,
  MoneyCapitalizationPolicy capitalizationPolicy =
      MoneyCapitalizationPolicy.never,
  MoneyCapitalizationCycle capitalizationCycle =
      MoneyCapitalizationCycle.monthly,
  MoneyPrepaymentAllocation prepaymentAllocation =
      MoneyPrepaymentAllocation.interestThenPrincipal,
  MoneyLoanStatus status = MoneyLoanStatus.pending,
  DateTime? closedAt,
  List<MoneyLoanEntry> entries = const <MoneyLoanEntry>[],
  DateTime? createdAt,
}) {
  return MoneyLoan(
    id: id,
    customerId: 'C1',
    direction: MoneyLoanDirection.given,
    principalPaise: principalPaise,
    currencyCode: 'INR',
    interestKind: capitalizationPolicy.legacyInterestKind,
    rateBps: rateBps,
    ratePeriod: ratePeriod,
    capitalizationPolicy: capitalizationPolicy,
    capitalizationCycle: capitalizationCycle,
    interestStartedAt: startedAt,
    prepaymentAllocation: prepaymentAllocation,
    status: status,
    closedAt: closedAt,
    createdAt: createdAt ?? startedAt,
    entries: entries,
  );
}

void main() {
  group('periodInterestPaise', () {
    test('simple monthly period is P * rate', () {
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
        rateBps: 1200,
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

  group('accrualFraction', () {
    test('yearly half-year is 6/12', () {
      expect(
        accrualFraction(
          from: DateTime(2026, 1, 1),
          to: DateTime(2026, 7, 1),
          ratePeriod: MoneyRatePeriod.yearly,
        ),
        0.5,
      );
    });

    test('yearly three months is 3/12', () {
      expect(
        accrualFraction(
          from: DateTime(2026, 1, 1),
          to: DateTime(2026, 4, 1),
          ratePeriod: MoneyRatePeriod.yearly,
        ),
        0.25,
      );
    });

    test('monthly mid-period uses days / days-in-period', () {
      expect(
        accrualFraction(
          from: DateTime(2026, 1, 1),
          to: DateTime(2026, 1, 16),
          ratePeriod: MoneyRatePeriod.monthly,
        ),
        closeTo(15 / 31, 1e-9),
      );
    });

    test('monthly two full months is 2.0', () {
      expect(
        accrualFraction(
          from: DateTime(2026, 1, 1),
          to: DateTime(2026, 3, 1),
          ratePeriod: MoneyRatePeriod.monthly,
        ),
        2.0,
      );
    });

    test('daily365 uses days / 365', () {
      expect(
        accrualFraction(
          from: DateTime(2026, 1, 1),
          to: DateTime(2026, 1, 16),
          ratePeriod: MoneyRatePeriod.yearly,
          interestAccrual: MoneyInterestAccrual.daily365,
        ),
        closeTo(15 / 365, 1e-9),
      );
    });
  });

  group('capitalization policies', () {
    test('never: principal fixed; unpaid grows; pending = P + I', () {
      final MoneyLoan loan = _loan(
        id: 'MLN-never',
        principalPaise: 10000000,
        rateBps: 1200,
        ratePeriod: MoneyRatePeriod.yearly,
        startedAt: DateTime(2026, 1, 1),
        capitalizationPolicy: MoneyCapitalizationPolicy.never,
        prepaymentAllocation: MoneyPrepaymentAllocation.principalOnly,
        entries: <MoneyLoanEntry>[
          MoneyLoanEntry(
            id: 'E1',
            loanId: 'MLN-never',
            entryAt: DateTime(2026, 4, 1),
            amountPaise: 3000000,
            kind: MoneyLoanEntryKind.repayment,
          ),
        ],
      );

      final LoanScenario mid = computeLoanScenario(
        loan: loan,
        now: DateTime(2026, 7, 1),
      );
      // Jan→Apr on 1L = 3000 unpaid; pay 30k principal → bal 70k
      // Apr→Jul on 70k = 2100 unpaid
      expect(mid.remainingPrincipalPaise, 7000000);
      expect(mid.unpaidInterestPaise, 510000);
      expect(mid.pendingPaise, 7510000);
      expect(
        mid.timeline.where(
          (LoanTimelineEvent e) =>
              e.kind == LoanTimelineKind.interestCapitalized,
        ),
        isEmpty,
      );
    });

    test('onPayment: capitalize then pay (100k + 5k − 30k = 75k)', () {
      final MoneyLoan loan = _loan(
        id: 'MLN-pay',
        principalPaise: 10000000,
        rateBps: 1200,
        ratePeriod: MoneyRatePeriod.yearly,
        startedAt: DateTime(2026, 1, 1),
        capitalizationPolicy: MoneyCapitalizationPolicy.onPayment,
        prepaymentAllocation: MoneyPrepaymentAllocation.interestThenPrincipal,
        entries: <MoneyLoanEntry>[
          MoneyLoanEntry(
            id: 'E1',
            loanId: 'MLN-pay',
            entryAt: DateTime(2026, 6, 1),
            amountPaise: 3000000,
            kind: MoneyLoanEntryKind.repayment,
          ),
        ],
      );

      final LoanScenario after = computeLoanScenario(
        loan: loan,
        now: DateTime(2026, 6, 1),
      );
      // Jan→Jun: 100k × 12% × 5/12 = ₹5,000 unpaid
      // Capitalize → bal 105k, unpaid 0; pay 30k → bal 75k
      expect(after.interestAccruedPaise, 500000);
      expect(after.unpaidInterestPaise, 0);
      expect(after.remainingPrincipalPaise, 7500000);
      expect(after.pendingPaise, 7500000);
      final LoanTimelineEvent cap = after.timeline.firstWhere(
        (LoanTimelineEvent e) =>
            e.kind == LoanTimelineKind.interestCapitalized,
      );
      expect(cap.amountPaise, 500000);
      final LoanTimelineEvent pay = after.timeline.firstWhere(
        (LoanTimelineEvent e) => e.kind == LoanTimelineKind.payment,
      );
      expect(pay.toInterestPaise, 0);
      expect(pay.toPrincipalPaise, 3000000);
    });

    test('onScheduledCycle: capitalize event on cycle boundary', () {
      final MoneyLoan loan = _loan(
        id: 'MLN-sched',
        principalPaise: 1000000,
        rateBps: 200,
        ratePeriod: MoneyRatePeriod.monthly,
        startedAt: DateTime(2026, 1, 1),
        capitalizationPolicy: MoneyCapitalizationPolicy.onScheduledCycle,
        capitalizationCycle: MoneyCapitalizationCycle.monthly,
      );

      final LoanScenario threeMonths = computeLoanScenario(
        loan: loan,
        now: DateTime(2026, 4, 1),
      );
      // Jan→Feb: +200, capitalize; Feb→Mar: +204, capitalize; Mar→Apr: +208.08
      // → capitalize on Apr 1 boundary too
      expect(
        threeMonths.timeline
            .where(
              (LoanTimelineEvent e) =>
                  e.kind == LoanTimelineKind.interestCapitalized,
            )
            .length,
        3,
      );
      expect(threeMonths.unpaidInterestPaise, 0);
      // 10000 * 1.02^3 = 10612.08 → 1061208 paise
      expect(threeMonths.remainingPrincipalPaise, 1061208);
      expect(threeMonths.pendingPaise, 1061208);
    });

    test('onBalanceDirectionChange: capitalize before overpay flips sign', () {
      final MoneyLoan loan = _loan(
        id: 'MLN-flip',
        principalPaise: 10000000,
        rateBps: 1200,
        ratePeriod: MoneyRatePeriod.yearly,
        startedAt: DateTime(2026, 1, 1),
        capitalizationPolicy:
            MoneyCapitalizationPolicy.onBalanceDirectionChange,
        prepaymentAllocation: MoneyPrepaymentAllocation.principalOnly,
        entries: <MoneyLoanEntry>[
          MoneyLoanEntry(
            id: 'E1',
            loanId: 'MLN-flip',
            entryAt: DateTime(2026, 4, 1),
            amountPaise: 3000000,
            kind: MoneyLoanEntryKind.repayment,
          ),
          MoneyLoanEntry(
            id: 'E2',
            loanId: 'MLN-flip',
            entryAt: DateTime(2026, 7, 1),
            amountPaise: 8000000,
            kind: MoneyLoanEntryKind.repayment,
          ),
        ],
      );

      final LoanScenario asOfOct = computeLoanScenario(
        loan: loan,
        now: DateTime(2026, 10, 1),
      );
      // Before E2: bal 70k + unpaid 5100 = 75100; E2 80k would flip → capitalize
      // Cap 5100 → bal 75100; pay 80k → bal -4900; Jul→Oct reverse on -4900
      final List<LoanTimelineEvent> caps = asOfOct.timeline
          .where(
            (LoanTimelineEvent e) =>
                e.kind == LoanTimelineKind.interestCapitalized,
          )
          .toList();
      expect(caps, isNotEmpty);
      expect(caps.last.at, DateTime(2026, 7, 1));
      expect(asOfOct.remainingPrincipalPaise, lessThan(0));
      expect(asOfOct.unpaidInterestPaise, lessThan(0));
    });

    test('onLoanClosure: capitalize at close', () {
      final MoneyLoan open = _loan(
        id: 'MLN-close',
        principalPaise: 10000000,
        rateBps: 1200,
        ratePeriod: MoneyRatePeriod.yearly,
        startedAt: DateTime(2026, 1, 1),
        capitalizationPolicy: MoneyCapitalizationPolicy.onLoanClosure,
      );
      final LoanScenario beforeClose = computeLoanScenario(
        loan: open,
        now: DateTime(2026, 7, 1),
      );
      expect(beforeClose.remainingPrincipalPaise, 10000000);
      expect(beforeClose.unpaidInterestPaise, 600000);
      expect(
        beforeClose.timeline.where(
          (LoanTimelineEvent e) =>
              e.kind == LoanTimelineKind.interestCapitalized,
        ),
        isEmpty,
      );

      final MoneyLoan closed = open.copyWith(
        status: MoneyLoanStatus.closed,
        closedAt: DateTime(2026, 7, 1),
      );
      final LoanScenario afterClose = computeLoanScenario(
        loan: closed,
        now: DateTime(2026, 10, 1),
      );
      expect(afterClose.asOf, DateTime(2026, 7, 1));
      expect(afterClose.unpaidInterestPaise, 0);
      expect(afterClose.remainingPrincipalPaise, 10600000);
      expect(
        afterClose.timeline.where(
          (LoanTimelineEvent e) =>
              e.kind == LoanTimelineKind.interestCapitalized,
        ),
        isNotEmpty,
      );
    });

    test('manual: only after capitalize entry', () {
      final MoneyLoan before = _loan(
        id: 'MLN-man',
        principalPaise: 10000000,
        rateBps: 1200,
        ratePeriod: MoneyRatePeriod.yearly,
        startedAt: DateTime(2026, 1, 1),
        capitalizationPolicy: MoneyCapitalizationPolicy.manual,
      );
      final LoanScenario mid = computeLoanScenario(
        loan: before,
        now: DateTime(2026, 7, 1),
      );
      expect(mid.remainingPrincipalPaise, 10000000);
      expect(mid.unpaidInterestPaise, 600000);
      expect(
        mid.timeline.where(
          (LoanTimelineEvent e) =>
              e.kind == LoanTimelineKind.interestCapitalized,
        ),
        isEmpty,
      );

      final MoneyLoan after = before.copyWith(
        entries: <MoneyLoanEntry>[
          MoneyLoanEntry(
            id: 'E-cap',
            loanId: 'MLN-man',
            entryAt: DateTime(2026, 7, 1),
            amountPaise: 600000,
            kind: MoneyLoanEntryKind.capitalization,
          ),
        ],
      );
      final LoanScenario capped = computeLoanScenario(
        loan: after,
        now: DateTime(2026, 7, 1),
      );
      expect(capped.unpaidInterestPaise, 0);
      expect(capped.remainingPrincipalPaise, 10600000);
      expect(
        capped.timeline.where(
          (LoanTimelineEvent e) =>
              e.kind == LoanTimelineKind.interestCapitalized,
        ),
        hasLength(1),
      );
    });

    test('legacy interestKind maps to policy', () {
      expect(
        MoneyCapitalizationPolicy.fromLegacyInterestKind(
          MoneyInterestKind.simple,
        ),
        MoneyCapitalizationPolicy.never,
      );
      expect(
        MoneyCapitalizationPolicy.fromLegacyInterestKind(
          MoneyInterestKind.compound,
        ),
        MoneyCapitalizationPolicy.onScheduledCycle,
      );
      expect(
        MoneyCapitalizationPolicy.never.legacyInterestKind,
        MoneyInterestKind.simple,
      );
      expect(
        MoneyCapitalizationPolicy.onScheduledCycle.legacyInterestKind,
        MoneyInterestKind.compound,
      );
    });
  });

  group('computeLoanScenario timeline', () {
    test('₹1L yearly never: overpay then reverse interest through asOf', () {
      final MoneyLoan loan = _loan(
        id: 'MLN-overpay',
        principalPaise: 10000000,
        rateBps: 1200,
        ratePeriod: MoneyRatePeriod.yearly,
        startedAt: DateTime(2026, 1, 1),
        capitalizationPolicy: MoneyCapitalizationPolicy.never,
        prepaymentAllocation: MoneyPrepaymentAllocation.principalOnly,
        createdAt: DateTime(2026, 10, 1),
        entries: <MoneyLoanEntry>[
          MoneyLoanEntry(
            id: 'E1',
            loanId: 'MLN-overpay',
            entryAt: DateTime(2026, 4, 1),
            amountPaise: 3000000,
            kind: MoneyLoanEntryKind.repayment,
          ),
          MoneyLoanEntry(
            id: 'E2',
            loanId: 'MLN-overpay',
            entryAt: DateTime(2026, 7, 1),
            amountPaise: 8000000,
            kind: MoneyLoanEntryKind.repayment,
          ),
        ],
      );

      final LoanScenario asOfOct = computeLoanScenario(
        loan: loan,
        now: DateTime(2026, 10, 1),
      );

      expect(asOfOct.remainingPrincipalPaise, -1000000);
      expect(asOfOct.unpaidInterestPaise, 480000);
      expect(asOfOct.interestAccruedPaise, 480000);
      expect(asOfOct.pendingPaise, -520000);
      expect(asOfOct.totalPaidPaise, 11000000);

      final List<LoanTimelineEvent> segments = asOfOct.timeline
          .where(
            (LoanTimelineEvent e) => e.kind == LoanTimelineKind.interestSegment,
          )
          .toList();
      expect(segments, hasLength(3));
      expect(segments[0].amountPaise, 300000);
      expect(segments[1].amountPaise, 210000);
      expect(segments[2].amountPaise, -30000);
    });

    test('entry dated before start participates', () {
      final MoneyLoan loan = _loan(
        id: 'MLN-pre',
        principalPaise: 10000000,
        rateBps: 1200,
        ratePeriod: MoneyRatePeriod.yearly,
        startedAt: DateTime(2026, 4, 1),
        createdAt: DateTime(2026, 7, 1),
        entries: <MoneyLoanEntry>[
          MoneyLoanEntry(
            id: 'E-pre',
            loanId: 'MLN-pre',
            entryAt: DateTime(2026, 1, 1),
            amountPaise: 2000000,
            kind: MoneyLoanEntryKind.repayment,
          ),
        ],
      );

      final LoanScenario mid = computeLoanScenario(
        loan: loan,
        now: DateTime(2026, 7, 1),
      );

      expect(mid.remainingPrincipalPaise, 8000000);
      expect(mid.unpaidInterestPaise, 180000);
      expect(mid.pendingPaise, 8180000);
      expect(mid.totalPaidPaise, 2000000);
    });

    test('zero balance gap accrues 0', () {
      final MoneyLoan loan = _loan(
        id: 'MLN-zero',
        principalPaise: 10000000,
        rateBps: 1200,
        ratePeriod: MoneyRatePeriod.yearly,
        startedAt: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 7, 1),
        entries: <MoneyLoanEntry>[
          MoneyLoanEntry(
            id: 'E1',
            loanId: 'MLN-zero',
            entryAt: DateTime(2026, 1, 1),
            amountPaise: 10000000,
            kind: MoneyLoanEntryKind.repayment,
          ),
        ],
      );

      final LoanScenario mid = computeLoanScenario(
        loan: loan,
        now: DateTime(2026, 7, 1),
      );
      expect(mid.remainingPrincipalPaise, 0);
      expect(mid.unpaidInterestPaise, 0);
      expect(mid.interestAccruedPaise, 0);
      expect(mid.pendingPaise, 0);
    });

    test('interest-first clears unpaid then principal across events', () {
      final MoneyLoan loan = _loan(
        id: 'MLN-int-first',
        principalPaise: 10000000,
        rateBps: 1200,
        ratePeriod: MoneyRatePeriod.yearly,
        startedAt: DateTime(2026, 1, 1),
        createdAt: DateTime(2027, 1, 15),
        entries: <MoneyLoanEntry>[
          MoneyLoanEntry(
            id: 'E1',
            loanId: 'MLN-int-first',
            entryAt: DateTime(2026, 7, 1),
            amountPaise: 5000000,
            kind: MoneyLoanEntryKind.repayment,
          ),
          MoneyLoanEntry(
            id: 'E2',
            loanId: 'MLN-int-first',
            entryAt: DateTime(2027, 1, 1),
            amountPaise: 1000000,
            kind: MoneyLoanEntryKind.repayment,
          ),
        ],
      );

      final LoanScenario after = computeLoanScenario(
        loan: loan,
        now: DateTime(2027, 1, 1),
      );
      final LoanTimelineEvent e1 = after.timeline.firstWhere(
        (LoanTimelineEvent e) =>
            e.kind == LoanTimelineKind.payment && e.entryId == 'E1',
      );
      expect(e1.toInterestPaise, 600000);
      expect(e1.toPrincipalPaise, 4400000);
      final LoanTimelineEvent e2 = after.timeline.firstWhere(
        (LoanTimelineEvent e) =>
            e.kind == LoanTimelineKind.payment && e.entryId == 'E2',
      );
      expect(e2.toInterestPaise, 336000);
      expect(e2.toPrincipalPaise, 664000);
      expect(after.remainingPrincipalPaise, 4936000);
      expect(after.unpaidInterestPaise, 0);
    });

    test('principalOnly leaves unpaid interest intact', () {
      final MoneyLoan loan = _loan(
        id: 'MLN-prin-only',
        principalPaise: 10000000,
        rateBps: 1200,
        ratePeriod: MoneyRatePeriod.yearly,
        startedAt: DateTime(2026, 1, 1),
        prepaymentAllocation: MoneyPrepaymentAllocation.principalOnly,
        createdAt: DateTime(2027, 1, 1),
        entries: <MoneyLoanEntry>[
          MoneyLoanEntry(
            id: 'E1',
            loanId: 'MLN-prin-only',
            entryAt: DateTime(2026, 7, 1),
            amountPaise: 5000000,
            kind: MoneyLoanEntryKind.repayment,
          ),
          MoneyLoanEntry(
            id: 'E2',
            loanId: 'MLN-prin-only',
            entryAt: DateTime(2027, 1, 1),
            amountPaise: 1000000,
            kind: MoneyLoanEntryKind.repayment,
          ),
        ],
      );

      final LoanScenario after = computeLoanScenario(
        loan: loan,
        now: DateTime(2027, 1, 1),
      );
      expect(after.remainingPrincipalPaise, 4000000);
      expect(after.unpaidInterestPaise, 900000);
      expect(after.pendingPaise, 4900000);
    });

    test('monthly never accrues across multi-month gap', () {
      final MoneyLoan loan = _loan(
        id: 'MLN-mo',
        principalPaise: 1000000,
        rateBps: 200,
        ratePeriod: MoneyRatePeriod.monthly,
        startedAt: DateTime(2026, 1, 1),
      );

      final LoanScenario midMonth = computeLoanScenario(
        loan: loan,
        now: DateTime(2026, 1, 16),
      );
      final int midInterest = (1000000 * 0.02 * 15 / 31).round();
      expect(midMonth.interestAccruedPaise, midInterest);
      expect(midMonth.unpaidInterestPaise, midInterest);
      expect(midMonth.pendingPaise, 1000000 + midInterest);

      final LoanScenario twoMonths = computeLoanScenario(
        loan: loan,
        now: DateTime(2026, 3, 1),
      );
      expect(twoMonths.interestAccruedPaise, 40000);
      expect(twoMonths.remainingPrincipalPaise, 1000000);
      expect(twoMonths.unpaidInterestPaise, 40000);
    });

    test('disbursement increases balance and earns from that date', () {
      final MoneyLoan loan = _loan(
        id: 'MLN-add',
        principalPaise: 10000000,
        rateBps: 1200,
        ratePeriod: MoneyRatePeriod.yearly,
        startedAt: DateTime(2026, 1, 1),
        createdAt: DateTime(2027, 1, 1),
        entries: <MoneyLoanEntry>[
          MoneyLoanEntry(
            id: 'E-add',
            loanId: 'MLN-add',
            entryAt: DateTime(2026, 7, 1),
            amountPaise: 5000000,
            kind: MoneyLoanEntryKind.disbursement,
          ),
        ],
      );

      final LoanScenario after = computeLoanScenario(
        loan: loan,
        now: DateTime(2027, 1, 1),
      );
      expect(after.remainingPrincipalPaise, 15000000);
      expect(after.unpaidInterestPaise, 1500000);
      expect(after.pendingPaise, 16500000);
    });

    test('edit start date changes totals', () {
      final MoneyLoan base = _loan(
        id: 'MLN-2',
        principalPaise: 1000000,
        rateBps: 100,
        ratePeriod: MoneyRatePeriod.monthly,
        startedAt: DateTime(2026, 1, 1),
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
    });

    test('legacy kind payment parses as repayment', () {
      expect(MoneyLoanEntryKind.parse('payment'), MoneyLoanEntryKind.repayment);
      expect(
        MoneyLoanEntryKind.parse('capitalization'),
        MoneyLoanEntryKind.capitalization,
      );
    });

    test('adjustment clears remainder then close allowed', () async {
      final LocalRepository repo = await bootRepo();
      final customer = await ensureCustomer(repo);
      final String loanId = await repo.createMoneyLoan(
        customerId: customer.id,
        direction: MoneyLoanDirection.given,
        principalPaise: 100000,
        interestStartedAt: DateTime(2026, 1, 1),
        capitalizationPolicy: MoneyCapitalizationPolicy.never,
        rateBps: 0,
        ratePeriod: MoneyRatePeriod.monthly,
      );
      await repo.addMoneyLoanEntry(
        loanId: loanId,
        entryAt: DateTime(2026, 2, 1),
        amountPaise: 60000,
        kind: MoneyLoanEntryKind.repayment,
      );
      MoneyLoan? loan = await repo.getMoneyLoan(loanId);
      LoanScenario scenario = computeLoanScenario(
        loan: loan!,
        now: DateTime(2026, 2, 1),
      );
      expect(scenario.pendingPaise, 40000);

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
        kind: MoneyLoanEntryKind.repayment,
      );
      final MoneyLoan loan = (await repo.getMoneyLoan(loanId))!;
      expect(computeLoanScenario(loan: loan).pendingPaise, greaterThan(0));
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
        kind: MoneyLoanEntryKind.repayment,
      );
      MoneyLoan loan = (await repo.getMoneyLoan(loanId))!;
      expect(computeLoanScenario(loan: loan).pendingPaise, 0);
      expect(loan.status, MoneyLoanStatus.pending);

      await repo.closeMoneyLoan(loanId);
      loan = (await repo.getMoneyLoan(loanId))!;
      expect(loan.status, MoneyLoanStatus.closed);
    });

    test('addMoneyLoanPrincipal increases principal; repayment decreases',
        () async {
      final LocalRepository repo = await bootRepo();
      final customer = await ensureCustomer(repo);
      final String loanId = await repo.createMoneyLoan(
        customerId: customer.id,
        direction: MoneyLoanDirection.given,
        principalPaise: 100000,
        interestStartedAt: DateTime(2026, 1, 1),
        rateBps: 0,
      );

      await repo.addMoneyLoanPrincipal(
        loanId: loanId,
        entryAt: DateTime(2026, 1, 10),
        amountPaise: 40000,
      );
      MoneyLoan loan = (await repo.getMoneyLoan(loanId))!;
      expect(
        computeLoanScenario(loan: loan, now: DateTime(2026, 1, 10))
            .remainingPrincipalPaise,
        140000,
      );

      await repo.addMoneyLoanEntry(
        loanId: loanId,
        entryAt: DateTime(2026, 1, 15),
        amountPaise: 25000,
        kind: MoneyLoanEntryKind.repayment,
      );
      loan = (await repo.getMoneyLoan(loanId))!;
      expect(
        computeLoanScenario(loan: loan, now: DateTime(2026, 1, 15))
            .remainingPrincipalPaise,
        115000,
      );
    });

    test('createMoneyLoan leaves entries empty', () async {
      final LocalRepository repo = await bootRepo();
      final customer = await ensureCustomer(repo);
      final String loanId = await repo.createMoneyLoan(
        customerId: customer.id,
        direction: MoneyLoanDirection.given,
        principalPaise: 100000,
        interestStartedAt: DateTime.now(),
      );
      final MoneyLoan loan = (await repo.getMoneyLoan(loanId))!;
      expect(loan.entries, isEmpty);
      expect(loan.capitalizationPolicy, MoneyCapitalizationPolicy.never);
    });

    test('manual capitalize via repository', () async {
      final LocalRepository repo = await bootRepo();
      final customer = await ensureCustomer(repo);
      final String loanId = await repo.createMoneyLoan(
        customerId: customer.id,
        direction: MoneyLoanDirection.given,
        principalPaise: 10000000,
        interestStartedAt: DateTime(2026, 1, 1),
        capitalizationPolicy: MoneyCapitalizationPolicy.manual,
        rateBps: 1200,
        ratePeriod: MoneyRatePeriod.yearly,
      );
      await repo.capitalizeMoneyLoanInterest(
        loanId,
        at: DateTime(2026, 7, 1),
      );
      final MoneyLoan loan = (await repo.getMoneyLoan(loanId))!;
      expect(
        loan.entries.single.kind,
        MoneyLoanEntryKind.capitalization,
      );
      final LoanScenario scenario = computeLoanScenario(
        loan: loan,
        now: DateTime(2026, 7, 1),
      );
      expect(scenario.unpaidInterestPaise, 0);
      expect(scenario.remainingPrincipalPaise, 10600000);
    });

    test('legacy interestKind compound maps to onScheduledCycle on create',
        () async {
      final LocalRepository repo = await bootRepo();
      final customer = await ensureCustomer(repo);
      final String loanId = await repo.createMoneyLoan(
        customerId: customer.id,
        direction: MoneyLoanDirection.given,
        principalPaise: 100000,
        interestStartedAt: DateTime(2026, 1, 1),
        interestKind: MoneyInterestKind.compound,
        ratePeriod: MoneyRatePeriod.yearly,
      );
      final MoneyLoan loan = (await repo.getMoneyLoan(loanId))!;
      expect(
        loan.capitalizationPolicy,
        MoneyCapitalizationPolicy.onScheduledCycle,
      );
      expect(loan.capitalizationCycle, MoneyCapitalizationCycle.yearly);
    });
  });

  group('schema', () {
    test('schemaVersion is 19 with interestAccrual column', () async {
      final LocalRepository repo = await bootRepo();
      expect(repo.database.schemaVersion, 22);
    });

    test('createMoneyLoan defaults prepaymentAllocation to interestThenPrincipal',
        () async {
      final LocalRepository repo = await bootRepo();
      final customer = await ensureCustomer(repo);
      final String loanId = await repo.createMoneyLoan(
        customerId: customer.id,
        direction: MoneyLoanDirection.given,
        principalPaise: 100000,
        interestStartedAt: DateTime(2026, 1, 1),
      );
      final MoneyLoan loan = (await repo.getMoneyLoan(loanId))!;
      expect(
        loan.prepaymentAllocation,
        MoneyPrepaymentAllocation.interestThenPrincipal,
      );
    });

    test('createMoneyLoan persists principalOnly allocation', () async {
      final LocalRepository repo = await bootRepo();
      final customer = await ensureCustomer(repo);
      final String loanId = await repo.createMoneyLoan(
        customerId: customer.id,
        direction: MoneyLoanDirection.given,
        principalPaise: 100000,
        interestStartedAt: DateTime(2026, 1, 1),
        prepaymentAllocation: MoneyPrepaymentAllocation.principalOnly,
      );
      final MoneyLoan loan = (await repo.getMoneyLoan(loanId))!;
      expect(
        loan.prepaymentAllocation,
        MoneyPrepaymentAllocation.principalOnly,
      );
    });

    test('updateMoneyLoan writes setup fields and keeps customerId', () async {
      final LocalRepository repo = await bootRepo();
      final customer = await ensureCustomer(repo);
      final String loanId = await repo.createMoneyLoan(
        customerId: customer.id,
        direction: MoneyLoanDirection.given,
        principalPaise: 100000,
        interestStartedAt: DateTime(2026, 1, 1),
        rateBps: 200,
        ratePeriod: MoneyRatePeriod.monthly,
        capitalizationPolicy: MoneyCapitalizationPolicy.never,
        note: 'initial',
      );

      await repo.updateMoneyLoan(
        loanId: loanId,
        direction: MoneyLoanDirection.taken,
        principalPaise: 250000,
        rateBps: 1500,
        ratePeriod: MoneyRatePeriod.yearly,
        interestAccrual: MoneyInterestAccrual.daily365,
        capitalizationPolicy: MoneyCapitalizationPolicy.onScheduledCycle,
        capitalizationCycle: MoneyCapitalizationCycle.quarterly,
        prepaymentAllocation: MoneyPrepaymentAllocation.principalOnly,
        interestStartedAt: DateTime(2026, 2, 1),
        interestEndedAt: DateTime(2026, 12, 1),
        note: 'updated note',
      );

      final MoneyLoan loan = (await repo.getMoneyLoan(loanId))!;
      expect(loan.customerId, customer.id);
      expect(loan.direction, MoneyLoanDirection.taken);
      expect(loan.principalPaise, 250000);
      expect(loan.rateBps, 1500);
      expect(loan.ratePeriod, MoneyRatePeriod.yearly);
      expect(loan.interestAccrual, MoneyInterestAccrual.daily365);
      expect(
        loan.capitalizationPolicy,
        MoneyCapitalizationPolicy.onScheduledCycle,
      );
      expect(loan.capitalizationCycle, MoneyCapitalizationCycle.quarterly);
      expect(
        loan.prepaymentAllocation,
        MoneyPrepaymentAllocation.principalOnly,
      );
      expect(loan.interestStartedAt, DateTime(2026, 2, 1));
      expect(loan.interestEndedAt, DateTime(2026, 12, 1));
      expect(loan.note, 'updated note');
    });

    test('updateMoneyLoan rejects closed loans', () async {
      final LocalRepository repo = await bootRepo();
      final customer = await ensureCustomer(repo);
      final String loanId = await repo.createMoneyLoan(
        customerId: customer.id,
        direction: MoneyLoanDirection.given,
        principalPaise: 100000,
        interestStartedAt: DateTime(2026, 1, 1),
        rateBps: 0,
      );
      await repo.closeMoneyLoan(loanId, closedAt: DateTime(2026, 1, 2));
      await expectLater(
        repo.updateMoneyLoan(loanId: loanId, principalPaise: 200000),
        throwsA(isA<StateError>()),
      );
    });

    test('createMoneyLoan persists interestAccrual daily365', () async {
      final LocalRepository repo = await bootRepo();
      final customer = await ensureCustomer(repo);
      final String loanId = await repo.createMoneyLoan(
        customerId: customer.id,
        direction: MoneyLoanDirection.given,
        principalPaise: 100000,
        interestStartedAt: DateTime(2026, 1, 1),
        ratePeriod: MoneyRatePeriod.monthly,
        interestAccrual: MoneyInterestAccrual.daily365,
      );
      final MoneyLoan loan = (await repo.getMoneyLoan(loanId))!;
      expect(loan.ratePeriod, MoneyRatePeriod.monthly);
      expect(loan.interestAccrual, MoneyInterestAccrual.daily365);
    });

    test('legacy rate_period daily reads as yearly + daily365', () async {
      final LocalRepository repo = await bootRepo();
      final customer = await ensureCustomer(repo);
      final String loanId = await repo.createMoneyLoan(
        customerId: customer.id,
        direction: MoneyLoanDirection.given,
        principalPaise: 100000,
        interestStartedAt: DateTime(2026, 1, 1),
        ratePeriod: MoneyRatePeriod.monthly,
      );
      await repo.database.customStatement(
        "UPDATE money_loans SET rate_period = 'daily', "
        "interest_accrual = 'calendar' WHERE id = '$loanId'",
      );
      final MoneyLoan loan = (await repo.getMoneyLoan(loanId))!;
      expect(loan.ratePeriod, MoneyRatePeriod.yearly);
      expect(loan.interestAccrual, MoneyInterestAccrual.daily365);
    });

    test('MoneyPrepaymentAllocation.parse defaults unknown to interestThenPrincipal',
        () {
      expect(
        MoneyPrepaymentAllocation.parse(null),
        MoneyPrepaymentAllocation.interestThenPrincipal,
      );
      expect(
        MoneyPrepaymentAllocation.parse('principalOnly'),
        MoneyPrepaymentAllocation.principalOnly,
      );
    });
  });
}
