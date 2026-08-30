@Tags(['unit', 'pricing', 'loans'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/application/local_repository.dart';
import 'package:asset_os/domain/pricing/rental_pricing.dart';
import 'package:asset_os/l10n/app_localizations_en.dart';

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

    test('quarterly three months is 1.0', () {
      expect(
        accrualFraction(
          from: DateTime(2026, 1, 1),
          to: DateTime(2026, 4, 1),
          ratePeriod: MoneyRatePeriod.quarterly,
        ),
        1.0,
      );
    });

    test('halfYearly six months is 1.0', () {
      expect(
        accrualFraction(
          from: DateTime(2026, 1, 1),
          to: DateTime(2026, 7, 1),
          ratePeriod: MoneyRatePeriod.halfYearly,
        ),
        1.0,
      );
    });
  });

  group('nextInterestPeriodEnd', () {
    test('quarterly is +3 months', () {
      expect(
        nextInterestPeriodEnd(
          DateTime(2026, 1, 1),
          MoneyRatePeriod.quarterly,
        ),
        DateTime(2026, 4, 1),
      );
    });

    test('halfYearly is +6 months', () {
      expect(
        nextInterestPeriodEnd(
          DateTime(2026, 1, 1),
          MoneyRatePeriod.halfYearly,
        ),
        DateTime(2026, 7, 1),
      );
    });
  });

  group('nextCapitalizationCycleEnd', () {
    test('halfYearly is +6 months', () {
      expect(
        nextCapitalizationCycleEnd(
          DateTime(2026, 1, 1),
          MoneyCapitalizationCycle.halfYearly,
        ),
        DateTime(2026, 7, 1),
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
      expect(asOfOct.reversePendingInterestPaise, -asOfOct.unpaidInterestPaise);
      expect(asOfOct.pendingInterestPaise, 0);
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
      expect(asOfOct.positiveInterestAccruedPaise, 510000);
      expect(asOfOct.reverseInterestAccruedPaise, 30000);
      expect(asOfOct.pendingInterestPaise, 480000);
      expect(asOfOct.reversePendingInterestPaise, 0);
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

    test('interest segment day span matches calendarDaysBetween', () {
      final MoneyLoan loan = _loan(
        id: 'MLN-days',
        principalPaise: 1000000,
        rateBps: 1200,
        ratePeriod: MoneyRatePeriod.yearly,
        startedAt: DateTime(2026, 1, 1),
        capitalizationPolicy: MoneyCapitalizationPolicy.never,
        createdAt: DateTime(2026, 2, 1),
      );

      final LoanScenario asOf = computeLoanScenario(
        loan: loan,
        now: DateTime(2026, 2, 1),
      );

      final LoanTimelineEvent segment = asOf.timeline.firstWhere(
        (LoanTimelineEvent e) => e.kind == LoanTimelineKind.interestSegment,
      );
      expect(segment.from, DateTime(2026, 1, 1));
      expect(segment.through, DateTime(2026, 2, 1));
      final int days = calendarDaysBetween(segment.from!, segment.through!);
      expect(days, 31);
      expect(segment.amountPaise, 10000);
      expect(segment.principalBasisPaise, 1000000);
      expect(segment.balanceAfterPaise, 1010000);

      final AppLocalizationsEn l10n = AppLocalizationsEn();
      expect(l10n.loanLedgerInterest, 'Interest');
      expect(l10n.loanLedgerReverseInterest, 'Reverse interest');
      expect(
        l10n.loanLedgerMetaOnPrincipal(
          '₹10000',
          '01/01/2026',
          '01/02/2026',
          days,
        ),
        'on ₹10000 · 01/01/2026–01/02/2026 · 31 days',
      );
    });

    test('balanceAfterPaise tracks outstanding after each event', () {
      final MoneyLoan loan = _loan(
        id: 'MLN-bal',
        principalPaise: 1000000,
        rateBps: 1200,
        ratePeriod: MoneyRatePeriod.yearly,
        startedAt: DateTime(2026, 1, 1),
        capitalizationPolicy: MoneyCapitalizationPolicy.never,
        createdAt: DateTime(2026, 3, 1),
        entries: <MoneyLoanEntry>[
          MoneyLoanEntry(
            id: 'E-pay',
            loanId: 'MLN-bal',
            entryAt: DateTime(2026, 2, 1),
            amountPaise: 300000,
            kind: MoneyLoanEntryKind.repayment,
          ),
        ],
      );

      final LoanScenario scenario = computeLoanScenario(
        loan: loan,
        now: DateTime(2026, 2, 1),
      );

      final LoanTimelineEvent principal = scenario.timeline.firstWhere(
        (LoanTimelineEvent e) => e.kind == LoanTimelineKind.disbursement,
      );
      expect(principal.amountPaise, 1000000);
      expect(principal.balanceAfterPaise, 1000000);

      final LoanTimelineEvent interest = scenario.timeline.firstWhere(
        (LoanTimelineEvent e) => e.kind == LoanTimelineKind.interestSegment,
      );
      expect(interest.amountPaise, 10000);
      expect(interest.balanceAfterPaise, 1010000);

      final LoanTimelineEvent payment = scenario.timeline.firstWhere(
        (LoanTimelineEvent e) => e.kind == LoanTimelineKind.payment,
      );
      expect(payment.amountPaise, 300000);
      expect(payment.balanceAfterPaise, 710000);
      expect(scenario.pendingPaise, 710000);

      final LoanTimelineEvent pending = scenario.timeline.lastWhere(
        (LoanTimelineEvent e) => e.kind == LoanTimelineKind.pendingAsOf,
      );
      expect(pending.amountPaise, 710000);
      expect(pending.balanceAfterPaise, 710000);
    });

    test('balanceAfterPaise follows overpay outstanding', () {
      final MoneyLoan loan = _loan(
        id: 'MLN-over',
        principalPaise: 1000000,
        rateBps: 0,
        ratePeriod: MoneyRatePeriod.yearly,
        startedAt: DateTime(2026, 1, 1),
        capitalizationPolicy: MoneyCapitalizationPolicy.never,
        createdAt: DateTime(2026, 2, 1),
        entries: <MoneyLoanEntry>[
          MoneyLoanEntry(
            id: 'E-over',
            loanId: 'MLN-over',
            entryAt: DateTime(2026, 1, 15),
            amountPaise: 1500000,
            kind: MoneyLoanEntryKind.repayment,
          ),
        ],
      );

      final LoanScenario scenario = computeLoanScenario(
        loan: loan,
        now: DateTime(2026, 2, 1),
      );
      expect(scenario.pendingPaise, -500000);

      final LoanTimelineEvent payment = scenario.timeline.firstWhere(
        (LoanTimelineEvent e) => e.kind == LoanTimelineKind.payment,
      );
      expect(payment.balanceAfterPaise, -500000);

      final LoanTimelineEvent pending = scenario.timeline.lastWhere(
        (LoanTimelineEvent e) => e.kind == LoanTimelineKind.pendingAsOf,
      );
      expect(pending.balanceAfterPaise, -500000);
      expect(pending.amountPaise, pending.balanceAfterPaise);
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
      expect(after.totalPrincipalPaise, 15000000);
      expect(after.principalPaise, 10000000);
      expect(after.unpaidInterestPaise, 1500000);
      expect(after.pendingPaise, 16500000);
    });

    test('totalPrincipalPaise is create plus disbursements; pending reflects repayments',
        () {
      final MoneyLoan loan = _loan(
        id: 'MLN-total-p',
        principalPaise: 1000000, // ₹10,000
        rateBps: 0,
        ratePeriod: MoneyRatePeriod.monthly,
        startedAt: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 3, 1),
        entries: <MoneyLoanEntry>[
          MoneyLoanEntry(
            id: 'E-disb',
            loanId: 'MLN-total-p',
            entryAt: DateTime(2026, 1, 15),
            amountPaise: 500000, // ₹5,000
            kind: MoneyLoanEntryKind.disbursement,
          ),
          MoneyLoanEntry(
            id: 'E-pay',
            loanId: 'MLN-total-p',
            entryAt: DateTime(2026, 2, 1),
            amountPaise: 200000, // ₹2,000
            kind: MoneyLoanEntryKind.repayment,
          ),
        ],
      );

      final LoanScenario scenario = computeLoanScenario(
        loan: loan,
        now: DateTime(2026, 3, 1),
      );
      expect(scenario.totalPrincipalPaise, 1500000);
      expect(scenario.principalPaise, 1000000);
      expect(scenario.remainingPrincipalPaise, 1300000);
      expect(scenario.totalPaidPaise, 200000);
      expect(scenario.pendingPaise, 1300000);
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

    test('repayment allows missing note', () async {
      final LocalRepository repo = await bootRepo();
      final customer = await ensureCustomer(repo);
      final String loanId = await repo.createMoneyLoan(
        customerId: customer.id,
        direction: MoneyLoanDirection.given,
        principalPaise: 100000,
        interestStartedAt: DateTime(2026, 1, 1),
        rateBps: 0,
      );
      final String entryId = await repo.addMoneyLoanEntry(
        loanId: loanId,
        entryAt: DateTime(2026, 2, 1),
        amountPaise: 10000,
        kind: MoneyLoanEntryKind.repayment,
      );
      expect(entryId, isNotEmpty);
      final MoneyLoan loan = (await repo.getMoneyLoan(loanId))!;
      expect(loan.entries.single.note, isNull);
    });

    test('repayment note surfaces on loan timeline', () async {
      final LocalRepository repo = await bootRepo();
      final customer = await ensureCustomer(repo);
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
        amountPaise: 50000,
        kind: MoneyLoanEntryKind.repayment,
        note: 'upi-99',
      );
      final MoneyLoan loan = (await repo.getMoneyLoan(loanId))!;
      final LoanScenario scenario = computeLoanScenario(
        loan: loan,
        now: DateTime(2026, 2, 1),
      );
      final List<LoanTimelineEvent> payments = scenario.timeline
          .where((LoanTimelineEvent e) => e.kind == LoanTimelineKind.payment)
          .toList();
      expect(payments, isNotEmpty);
      expect(payments.last.note, 'upi-99');
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
        note: 'PAY-001',
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
        note: 'PAY-002',
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
        note: 'PAY-002',
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
        note: 'DISB-01',
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
        note: 'PAY-003',
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

    test('update repayment amount date and note recalculates scenario', () async {
      final LocalRepository repo = await bootRepo();
      final customer = await ensureCustomer(repo);
      final String loanId = await repo.createMoneyLoan(
        customerId: customer.id,
        direction: MoneyLoanDirection.given,
        principalPaise: 100000,
        interestStartedAt: DateTime(2026, 1, 1),
        rateBps: 0,
      );
      final String entryId = await repo.addMoneyLoanEntry(
        loanId: loanId,
        entryAt: DateTime(2026, 2, 1),
        amountPaise: 30000,
        kind: MoneyLoanEntryKind.repayment,
        note: 'PAY-OLD',
      );
      await repo.updateMoneyLoanEntry(
        entryId: entryId,
        entryAt: DateTime(2026, 2, 15),
        amountPaise: 50000,
        note: 'pay-new',
      );
      final MoneyLoan loan = (await repo.getMoneyLoan(loanId))!;
      final LoanScenario scenario = computeLoanScenario(
        loan: loan,
        now: DateTime(2026, 2, 15),
      );
      expect(scenario.pendingPaise, 50000);
      final LoanTimelineEvent payment = scenario.timeline
          .lastWhere((LoanTimelineEvent e) => e.kind == LoanTimelineKind.payment);
      expect(payment.at, DateTime(2026, 2, 15));
      expect(payment.note, 'pay-new');
      expect(payment.amountPaise, 50000);
    });

    test('update disbursement changes principal summary', () async {
      final LocalRepository repo = await bootRepo();
      final customer = await ensureCustomer(repo);
      final String loanId = await repo.createMoneyLoan(
        customerId: customer.id,
        direction: MoneyLoanDirection.given,
        principalPaise: 100000,
        interestStartedAt: DateTime(2026, 1, 1),
        rateBps: 0,
      );
      final String entryId = await repo.addMoneyLoanPrincipal(
        loanId: loanId,
        entryAt: DateTime(2026, 1, 10),
        amountPaise: 20000,
        note: 'DISB-OLD',
      );
      await repo.updateMoneyLoanEntry(
        entryId: entryId,
        amountPaise: 50000,
        note: 'DISB-NEW',
      );
      final MoneyLoan loan = (await repo.getMoneyLoan(loanId))!;
      expect(
        computeLoanScenario(loan: loan, now: DateTime(2026, 1, 10))
            .remainingPrincipalPaise,
        150000,
      );
    });

    test('update repayment can clear note', () async {
      final LocalRepository repo = await bootRepo();
      final customer = await ensureCustomer(repo);
      final String loanId = await repo.createMoneyLoan(
        customerId: customer.id,
        direction: MoneyLoanDirection.given,
        principalPaise: 100000,
        interestStartedAt: DateTime(2026, 1, 1),
        rateBps: 0,
      );
      final String entryId = await repo.addMoneyLoanEntry(
        loanId: loanId,
        entryAt: DateTime(2026, 2, 1),
        amountPaise: 10000,
        kind: MoneyLoanEntryKind.repayment,
        note: 'PAY-001',
      );
      await repo.updateMoneyLoanEntry(
        entryId: entryId,
        clearNote: true,
      );
      final MoneyLoan loan = (await repo.getMoneyLoan(loanId))!;
      expect(loan.entries.single.note, isNull);
    });

    test('update repayment rejects note over 20 chars', () async {
      final LocalRepository repo = await bootRepo();
      final customer = await ensureCustomer(repo);
      final String loanId = await repo.createMoneyLoan(
        customerId: customer.id,
        direction: MoneyLoanDirection.given,
        principalPaise: 100000,
        interestStartedAt: DateTime(2026, 1, 1),
        rateBps: 0,
      );
      final String entryId = await repo.addMoneyLoanEntry(
        loanId: loanId,
        entryAt: DateTime(2026, 2, 1),
        amountPaise: 10000,
        kind: MoneyLoanEntryKind.repayment,
        note: 'PAY-001',
      );
      expect(
        () => repo.updateMoneyLoanEntry(
          entryId: entryId,
          note: 'ABCDEFGHIJABCDEFGHIJK',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('update entry on closed loan throws', () async {
      final LocalRepository repo = await bootRepo();
      final customer = await ensureCustomer(repo);
      final String loanId = await repo.createMoneyLoan(
        customerId: customer.id,
        direction: MoneyLoanDirection.given,
        principalPaise: 100000,
        interestStartedAt: DateTime(2026, 1, 1),
        rateBps: 0,
      );
      final String entryId = await repo.addMoneyLoanEntry(
        loanId: loanId,
        entryAt: DateTime(2026, 2, 1),
        amountPaise: 100000,
        kind: MoneyLoanEntryKind.repayment,
        note: 'PAY-FULL',
      );
      await repo.closeMoneyLoan(loanId, closedAt: DateTime(2026, 2, 1));
      expect(
        () => repo.updateMoneyLoanEntry(
          entryId: entryId,
          amountPaise: 50000,
        ),
        throwsA(isA<StateError>()),
      );
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
      expect(repo.database.schemaVersion, 24);
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

    test('createMoneyLoan persists halfYearly rate and cap cycle', () async {
      final LocalRepository repo = await bootRepo();
      final customer = await ensureCustomer(repo);
      final String loanId = await repo.createMoneyLoan(
        customerId: customer.id,
        direction: MoneyLoanDirection.given,
        principalPaise: 100000,
        interestStartedAt: DateTime(2026, 1, 1),
        ratePeriod: MoneyRatePeriod.halfYearly,
        capitalizationPolicy: MoneyCapitalizationPolicy.onScheduledCycle,
        capitalizationCycle: MoneyCapitalizationCycle.halfYearly,
      );
      final MoneyLoan loan = (await repo.getMoneyLoan(loanId))!;
      expect(loan.ratePeriod, MoneyRatePeriod.halfYearly);
      expect(loan.capitalizationCycle, MoneyCapitalizationCycle.halfYearly);
    });

    test('createMoneyLoan persists quarterly ratePeriod', () async {
      final LocalRepository repo = await bootRepo();
      final customer = await ensureCustomer(repo);
      final String loanId = await repo.createMoneyLoan(
        customerId: customer.id,
        direction: MoneyLoanDirection.given,
        principalPaise: 100000,
        interestStartedAt: DateTime(2026, 1, 1),
        ratePeriod: MoneyRatePeriod.quarterly,
      );
      final MoneyLoan loan = (await repo.getMoneyLoan(loanId))!;
      expect(loan.ratePeriod, MoneyRatePeriod.quarterly);
      expect(
        loan.capitalizationCycle,
        MoneyCapitalizationCycle.quarterly,
      );
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

    test('MoneyRatePeriod.parse reads quarterly and halfYearly', () {
      expect(MoneyRatePeriod.parse('quarterly'), MoneyRatePeriod.quarterly);
      expect(MoneyRatePeriod.parse('halfYearly'), MoneyRatePeriod.halfYearly);
      expect(MoneyRatePeriod.parse('unknown'), MoneyRatePeriod.monthly);
    });

    test('MoneyCapitalizationCycle.parse and fromRatePeriod cover halfYearly',
        () {
      expect(
        MoneyCapitalizationCycle.parse('halfYearly'),
        MoneyCapitalizationCycle.halfYearly,
      );
      expect(
        MoneyCapitalizationCycle.fromRatePeriod(MoneyRatePeriod.quarterly),
        MoneyCapitalizationCycle.quarterly,
      );
      expect(
        MoneyCapitalizationCycle.fromRatePeriod(MoneyRatePeriod.halfYearly),
        MoneyCapitalizationCycle.halfYearly,
      );
    });
  });
}
