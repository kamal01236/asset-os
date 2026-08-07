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
            kind: MoneyLoanEntryKind.repayment,
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

    test('₹1L yearly Simple: anniversary posts unpaid interest; principal stays',
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
            kind: MoneyLoanEntryKind.repayment,
          ),
        ],
      );

      final LoanScenario after = computeLoanScenario(
        loan: loan,
        now: DateTime(2027, 1, 1),
      );
      // Deferred 3000 + remaining 50000×12% = 6000 → unpaid ₹9,000
      // Principal stays ₹50,000 (not capitalized to ₹59,000)
      expect(after.interestAccruedPaise, 900000);
      expect(after.remainingPrincipalPaise, 5000000);
      expect(after.unpaidInterestPaise, 900000);
      expect(after.pendingPaise, 5900000);

      final List<LoanTimelineEvent> endRows = after.timeline
          .where(
            (LoanTimelineEvent e) =>
                e.at == DateTime(2027, 1, 1) &&
                (e.kind == LoanTimelineKind.periodEndSliceInterest ||
                    e.kind == LoanTimelineKind.remainingPeriodInterest ||
                    e.kind == LoanTimelineKind.principalRemains),
          )
          .toList();
      expect(endRows, hasLength(3));
      expect(endRows[0].kind, LoanTimelineKind.periodEndSliceInterest);
      expect(endRows[0].amountPaise, 300000);
      expect(endRows[0].principalBasisPaise, 5000000);
      expect(endRows[0].from, DateTime(2026, 1, 1));
      expect(endRows[0].through, DateTime(2026, 7, 1));
      expect(endRows[1].kind, LoanTimelineKind.remainingPeriodInterest);
      expect(endRows[1].amountPaise, 600000);
      expect(endRows[1].principalBasisPaise, 5000000);
      expect(endRows[2].kind, LoanTimelineKind.principalRemains);
      expect(endRows[2].amountPaise, 5000000);
      expect(
        after.timeline.where(
          (LoanTimelineEvent e) =>
              e.kind == LoanTimelineKind.principalAfterCapitalize,
        ),
        isEmpty,
      );
      expect(
        after.timeline.where(
          (LoanTimelineEvent e) => e.kind == LoanTimelineKind.interestSegment,
        ),
        isEmpty,
      );
    });

    test('₹1L yearly Compound: anniversary capitalizes into principal', () {
      final MoneyLoan loan = MoneyLoan(
        id: 'MLN-1L-ann-cmp',
        customerId: 'C1',
        direction: MoneyLoanDirection.given,
        principalPaise: 10000000,
        currencyCode: 'INR',
        interestKind: MoneyInterestKind.compound,
        rateBps: 1200,
        ratePeriod: MoneyRatePeriod.yearly,
        interestStartedAt: DateTime(2026, 1, 1),
        status: MoneyLoanStatus.pending,
        createdAt: DateTime(2027, 1, 1),
        entries: <MoneyLoanEntry>[
          MoneyLoanEntry(
            id: 'E1',
            loanId: 'MLN-1L-ann-cmp',
            entryAt: DateTime(2026, 7, 1),
            amountPaise: 5000000,
            kind: MoneyLoanEntryKind.repayment,
          ),
        ],
      );

      final LoanScenario after = computeLoanScenario(
        loan: loan,
        now: DateTime(2027, 1, 1),
      );
      expect(after.interestAccruedPaise, 900000);
      expect(after.remainingPrincipalPaise, 5900000);
      expect(after.pendingPaise, 5900000);
      expect(after.unpaidInterestPaise, 0);
      expect(
        after.timeline.where(
          (LoanTimelineEvent e) =>
              e.kind == LoanTimelineKind.principalAfterCapitalize,
        ),
        hasLength(1),
      );
    });

    test('₹1L yearly: two mid-period payments → interest-first then slices', () {
      final MoneyLoan loan = MoneyLoan(
        id: 'MLN-1L-two',
        customerId: 'C1',
        direction: MoneyLoanDirection.given,
        principalPaise: 10000000, // ₹1,00,000
        currencyCode: 'INR',
        interestKind: MoneyInterestKind.simple,
        rateBps: 1200, // 12%/year
        ratePeriod: MoneyRatePeriod.yearly,
        interestStartedAt: DateTime(2026, 1, 1),
        status: MoneyLoanStatus.pending,
        createdAt: DateTime(2027, 1, 1),
        entries: <MoneyLoanEntry>[
          MoneyLoanEntry(
            id: 'E1',
            loanId: 'MLN-1L-two',
            entryAt: DateTime(2026, 4, 1),
            amountPaise: 3000000, // ₹30,000 at 3 months
            kind: MoneyLoanEntryKind.repayment,
          ),
          MoneyLoanEntry(
            id: 'E2',
            loanId: 'MLN-1L-two',
            entryAt: DateTime(2026, 7, 1),
            amountPaise: 2000000, // ₹20,000 at 6 months
            kind: MoneyLoanEntryKind.repayment,
          ),
        ],
      );

      final LoanScenario after = computeLoanScenario(
        loan: loan,
        now: DateTime(2027, 1, 1),
      );
      // E1: ₹30k → principal; deferred slice ₹900
      // E2: interest-first clears ₹900 deferred, then ₹19,100 principal
      //     new slice: 19100×12%×6/12 = ₹1,146
      // Remaining core 50900×12% = ₹6,108
      // Simple: principal ₹50,900; unpaid ₹7,254
      expect(after.interestAccruedPaise, 815400);
      expect(after.remainingPrincipalPaise, 5090000);
      expect(after.unpaidInterestPaise, 725400);
      expect(after.pendingPaise, 5815400);

      final LoanTimelineEvent e2Pay = after.timeline.firstWhere(
        (LoanTimelineEvent e) =>
            e.kind == LoanTimelineKind.payment && e.entryId == 'E2',
      );
      expect(e2Pay.toInterestPaise, 90000);
      expect(e2Pay.toPrincipalPaise, 1910000);

      final List<LoanTimelineEvent> endRows = after.timeline
          .where(
            (LoanTimelineEvent e) =>
                e.at == DateTime(2027, 1, 1) &&
                e.kind != LoanTimelineKind.pendingAsOf,
          )
          .toList();
      expect(endRows, hasLength(3));
      expect(endRows[0].kind, LoanTimelineKind.periodEndSliceInterest);
      expect(endRows[0].amountPaise, 114600);
      expect(endRows[0].principalBasisPaise, 1910000);
      expect(endRows[0].entryId, 'E2');
      expect(endRows[1].kind, LoanTimelineKind.remainingPeriodInterest);
      expect(endRows[1].amountPaise, 610800);
      expect(endRows[1].principalBasisPaise, 5090000);
      expect(endRows[2].kind, LoanTimelineKind.principalRemains);
      expect(endRows[2].amountPaise, 5090000);

      expect(
        after.timeline
            .where(
              (LoanTimelineEvent e) =>
                  e.kind == LoanTimelineKind.deferredSliceInterest,
            )
            .length,
        2,
      );
    });

    test('₹1L yearly: mid-period add principal defers remainder interest', () {
      final MoneyLoan loan = MoneyLoan(
        id: 'MLN-1L-add',
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
            id: 'E-add',
            loanId: 'MLN-1L-add',
            entryAt: DateTime(2026, 7, 1),
            amountPaise: 5000000, // ₹50,000 top-up
            kind: MoneyLoanEntryKind.disbursement,
          ),
        ],
      );

      final LoanScenario midYear = computeLoanScenario(
        loan: loan,
        now: DateTime(2026, 7, 1),
      );
      // Remainder on add: 50000 × 12% × 6/12 = ₹3,000
      expect(midYear.interestAccruedPaise, 300000);
      expect(midYear.remainingPrincipalPaise, 15000000);
      expect(midYear.unpaidInterestPaise, 300000);
      expect(midYear.pendingPaise, 15300000);
      final LoanTimelineEvent deferredAdd = midYear.timeline.firstWhere(
        (LoanTimelineEvent e) =>
            e.kind == LoanTimelineKind.deferredAddSliceInterest,
      );
      expect(deferredAdd.amountPaise, 300000);
      expect(deferredAdd.principalBasisPaise, 5000000);
      expect(deferredAdd.from, DateTime(2026, 7, 1));
      expect(deferredAdd.through, DateTime(2027, 1, 1));

      final LoanScenario after = computeLoanScenario(
        loan: loan,
        now: DateTime(2027, 1, 1),
      );
      // Add slice 3000 + full-period on 100k = 12000 → unpaid ₹15,000
      // Simple: principal stays ₹1,50,000
      expect(after.interestAccruedPaise, 1500000);
      expect(after.remainingPrincipalPaise, 15000000);
      expect(after.unpaidInterestPaise, 1500000);
      expect(after.pendingPaise, 16500000);

      final List<LoanTimelineEvent> endRows = after.timeline
          .where(
            (LoanTimelineEvent e) =>
                e.at == DateTime(2027, 1, 1) &&
                e.kind != LoanTimelineKind.pendingAsOf,
          )
          .toList();
      expect(endRows, hasLength(3));
      expect(endRows[0].kind, LoanTimelineKind.periodEndAddSliceInterest);
      expect(endRows[0].amountPaise, 300000);
      expect(endRows[0].principalBasisPaise, 5000000);
      expect(endRows[1].kind, LoanTimelineKind.remainingPeriodInterest);
      expect(endRows[1].amountPaise, 1200000);
      expect(endRows[1].principalBasisPaise, 10000000);
      expect(endRows[2].kind, LoanTimelineKind.principalRemains);
      expect(endRows[2].amountPaise, 15000000);
    });

    test('₹1L yearly: repay + mid-period top-up → both slices + full-period core',
        () {
      final MoneyLoan loan = MoneyLoan(
        id: 'MLN-1L-both',
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
            id: 'E-repay',
            loanId: 'MLN-1L-both',
            entryAt: DateTime(2026, 7, 1),
            amountPaise: 5000000,
            kind: MoneyLoanEntryKind.repayment,
          ),
          MoneyLoanEntry(
            id: 'E-add',
            loanId: 'MLN-1L-both',
            entryAt: DateTime(2026, 10, 1),
            amountPaise: 3000000,
            kind: MoneyLoanEntryKind.disbursement,
          ),
        ],
      );

      final LoanScenario after = computeLoanScenario(
        loan: loan,
        now: DateTime(2027, 1, 1),
      );
      // Repay slice: 50000×12%×6/12 = ₹3,000
      // Add slice: 30000×12%×3/12 = ₹900
      // Full-period core: (100000-50000)×12% = ₹6,000
      // Simple: principal ₹80,000; unpaid ₹9,900
      expect(after.interestAccruedPaise, 990000);
      expect(after.remainingPrincipalPaise, 8000000);
      expect(after.unpaidInterestPaise, 990000);
      expect(after.pendingPaise, 8990000);

      final List<LoanTimelineEvent> endRows = after.timeline
          .where(
            (LoanTimelineEvent e) =>
                e.at == DateTime(2027, 1, 1) &&
                e.kind != LoanTimelineKind.pendingAsOf,
          )
          .toList();
      expect(endRows, hasLength(4));
      expect(endRows[0].kind, LoanTimelineKind.periodEndSliceInterest);
      expect(endRows[0].amountPaise, 300000);
      expect(endRows[1].kind, LoanTimelineKind.periodEndAddSliceInterest);
      expect(endRows[1].amountPaise, 90000);
      expect(endRows[1].principalBasisPaise, 3000000);
      expect(endRows[2].kind, LoanTimelineKind.remainingPeriodInterest);
      expect(endRows[2].amountPaise, 600000);
      expect(endRows[2].principalBasisPaise, 5000000);
      expect(endRows[3].kind, LoanTimelineKind.principalRemains);
      expect(endRows[3].amountPaise, 8000000);
    });

    test('legacy kind payment parses as repayment', () {
      expect(MoneyLoanEntryKind.parse('payment'), MoneyLoanEntryKind.repayment);
      expect(
        MoneyLoanEntryKind.parse('repayment'),
        MoneyLoanEntryKind.repayment,
      );
      expect(
        MoneyLoanEntryKind.parse('disbursement'),
        MoneyLoanEntryKind.disbursement,
      );
    });

    test('monthly: mid-period repay defers day-pro-rata slice; month-end due',
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
            kind: MoneyLoanEntryKind.repayment,
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
      // Remaining full month: 50000 × 2% = ₹1,000; Simple posts unpaid
      const int remainingInterest = 100000;
      final int totalInterest = sliceInterest + remainingInterest;
      expect(monthEnd.interestAccruedPaise, totalInterest);
      expect(monthEnd.remainingPrincipalPaise, 5000000);
      expect(monthEnd.unpaidInterestPaise, totalInterest);
      expect(monthEnd.pendingPaise, 5000000 + totalInterest);
      final LoanTimelineEvent sliceRow = monthEnd.timeline.firstWhere(
        (LoanTimelineEvent e) =>
            e.kind == LoanTimelineKind.periodEndSliceInterest,
      );
      expect(sliceRow.amountPaise, sliceInterest);
      expect(sliceRow.principalBasisPaise, 5000000);
      final LoanTimelineEvent remainingRow = monthEnd.timeline.firstWhere(
        (LoanTimelineEvent e) =>
            e.kind == LoanTimelineKind.remainingPeriodInterest,
      );
      expect(remainingRow.amountPaise, remainingInterest);
      expect(remainingRow.principalBasisPaise, 5000000);
      final LoanTimelineEvent principalNow = monthEnd.timeline.firstWhere(
        (LoanTimelineEvent e) => e.kind == LoanTimelineKind.principalRemains,
      );
      expect(principalNow.amountPaise, 5000000);
    });

    test('monthly Simple interest only after each full month; no compound', () {
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
      expect(oneMonth.remainingPrincipalPaise, 1000000);
      expect(oneMonth.unpaidInterestPaise, 20000);
      expect(oneMonth.pendingPaise, 1020000);

      final LoanScenario twoMonths = computeLoanScenario(
        loan: loan,
        now: DateTime(2026, 3, 1),
      );
      // Jan→Feb: +200 on 10k unpaid; Feb→Mar: +200 on same 10k principal
      expect(twoMonths.interestAccruedPaise, 40000);
      expect(twoMonths.remainingPrincipalPaise, 1000000);
      expect(twoMonths.unpaidInterestPaise, 40000);
      expect(twoMonths.pendingPaise, 1040000);
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
                  e.kind == LoanTimelineKind.remainingPeriodInterest,
            )
            .length,
        3,
      );
      expect(
        threeMonths.timeline
            .where(
              (LoanTimelineEvent e) =>
                  e.kind == LoanTimelineKind.principalAfterCapitalize,
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
            kind: MoneyLoanEntryKind.repayment,
          ),
          MoneyLoanEntry(
            id: 'E2',
            loanId: 'MLN-1',
            entryAt: DateTime(2026, 6, 1),
            amountPaise: 200000,
            kind: MoneyLoanEntryKind.repayment,
          ),
        ],
      );

      final LoanScenario asOfJun1 = computeLoanScenario(
        loan: loan,
        now: DateTime(2026, 6, 1),
      );

      // Jan→Feb→Mar→Apr: 3 months Simple on 10k → unpaid 60000, then pay 3k
      // Apr 1 is a boundary: interest posts first, then payment (interest-first).
      // Walk:
      //  Feb 1: unpaid +20000 → 20000; principal 1000000
      //  Mar 1: unpaid +20000 → 40000
      //  Apr 1: unpaid +20000 → 60000, then pay 300000 → interest 60000, principal 240000
      //         → unpaid 0, principal 760000
      //  May 1: unpaid +15200 → 15200; principal 760000
      //  Jun 1: unpaid +15200 → 30400, then pay 200000 → interest 30400, principal 169600
      //         → unpaid 0, principal 590400
      expect(asOfJun1.totalPaidPaise, 500000);
      expect(asOfJun1.interestAccruedPaise, 90400);
      expect(asOfJun1.pendingPaise, 590400);
      expect(asOfJun1.remainingPrincipalPaise, 590400);
      expect(asOfJun1.unpaidInterestPaise, 0);
      final LoanTimelineEvent aprPay = asOfJun1.timeline.firstWhere(
        (LoanTimelineEvent e) =>
            e.kind == LoanTimelineKind.payment && e.at == DateTime(2026, 4, 1),
      );
      expect(aprPay.toInterestPaise, 60000);
      expect(aprPay.toPrincipalPaise, 240000);
      expect(
        asOfJun1.timeline.any(
          (LoanTimelineEvent e) => e.kind == LoanTimelineKind.payment,
        ),
        isTrue,
      );
      expect(loan.status, MoneyLoanStatus.pending);
    });

    test('Simple repayment clears unpaid interest before principal', () {
      final MoneyLoan loan = MoneyLoan(
        id: 'MLN-int-first',
        customerId: 'C1',
        direction: MoneyLoanDirection.given,
        principalPaise: 10000000,
        currencyCode: 'INR',
        interestKind: MoneyInterestKind.simple,
        rateBps: 1200,
        ratePeriod: MoneyRatePeriod.yearly,
        interestStartedAt: DateTime(2026, 1, 1),
        status: MoneyLoanStatus.pending,
        createdAt: DateTime(2027, 2, 1),
        entries: <MoneyLoanEntry>[
          MoneyLoanEntry(
            id: 'E-repay-mid',
            loanId: 'MLN-int-first',
            entryAt: DateTime(2026, 7, 1),
            amountPaise: 5000000,
            kind: MoneyLoanEntryKind.repayment,
          ),
          MoneyLoanEntry(
            id: 'E-repay-after',
            loanId: 'MLN-int-first',
            entryAt: DateTime(2027, 1, 15),
            amountPaise: 1000000, // ₹10,000 after anniversary unpaid ₹9,000
            kind: MoneyLoanEntryKind.repayment,
          ),
        ],
      );

      final LoanScenario after = computeLoanScenario(
        loan: loan,
        now: DateTime(2027, 1, 15),
      );
      // After year-end: principal 50k, unpaid 9k. Pay 10k → 9k interest, 1k principal.
      // Mid-period slice on the ₹1k principal portion accrues a small deferred amount.
      final LoanTimelineEvent pay = after.timeline.firstWhere(
        (LoanTimelineEvent e) =>
            e.kind == LoanTimelineKind.payment && e.entryId == 'E-repay-after',
      );
      expect(pay.toInterestPaise, 900000);
      expect(pay.toPrincipalPaise, 100000);
      expect(after.remainingPrincipalPaise, 4900000);
      expect(after.unpaidInterestPaise, lessThan(900000));
      expect(after.unpaidInterestPaise, greaterThan(0));
      expect(after.pendingPaise, 4900000 + after.unpaidInterestPaise);
    });

    test('principalOnly repayment leaves unpaid interest intact', () {
      final MoneyLoan loan = MoneyLoan(
        id: 'MLN-prin-only',
        customerId: 'C1',
        direction: MoneyLoanDirection.given,
        principalPaise: 10000000,
        currencyCode: 'INR',
        interestKind: MoneyInterestKind.simple,
        rateBps: 1200,
        ratePeriod: MoneyRatePeriod.yearly,
        interestStartedAt: DateTime(2026, 1, 1),
        prepaymentAllocation: MoneyPrepaymentAllocation.principalOnly,
        status: MoneyLoanStatus.pending,
        createdAt: DateTime(2027, 2, 1),
        entries: <MoneyLoanEntry>[
          MoneyLoanEntry(
            id: 'E-repay-mid',
            loanId: 'MLN-prin-only',
            entryAt: DateTime(2026, 7, 1),
            amountPaise: 5000000,
            kind: MoneyLoanEntryKind.repayment,
          ),
          MoneyLoanEntry(
            id: 'E-repay-after',
            loanId: 'MLN-prin-only',
            entryAt: DateTime(2027, 1, 15),
            amountPaise: 1000000, // ₹10,000 after anniversary unpaid ₹9,000
            kind: MoneyLoanEntryKind.repayment,
          ),
        ],
      );

      final LoanScenario after = computeLoanScenario(
        loan: loan,
        now: DateTime(2027, 1, 15),
      );
      // Same numbers as interest-first, but entire ₹10k reduces principal.
      // Unpaid ₹9k stays; slice interest on ₹10k principal cut is deferred.
      final LoanTimelineEvent pay = after.timeline.firstWhere(
        (LoanTimelineEvent e) =>
            e.kind == LoanTimelineKind.payment && e.entryId == 'E-repay-after',
      );
      expect(pay.toInterestPaise, 0);
      expect(pay.toPrincipalPaise, 1000000);
      expect(after.remainingPrincipalPaise, 4000000);
      expect(after.unpaidInterestPaise, greaterThanOrEqualTo(900000));
      expect(after.pendingPaise, 4000000 + after.unpaidInterestPaise);
    });

    test('interestThenPrincipal applies on Compound deferred interest', () {
      final MoneyLoan loan = MoneyLoan(
        id: 'MLN-cmp-int-first',
        customerId: 'C1',
        direction: MoneyLoanDirection.given,
        principalPaise: 10000000,
        currencyCode: 'INR',
        interestKind: MoneyInterestKind.compound,
        rateBps: 1200,
        ratePeriod: MoneyRatePeriod.yearly,
        interestStartedAt: DateTime(2026, 1, 1),
        prepaymentAllocation: MoneyPrepaymentAllocation.interestThenPrincipal,
        status: MoneyLoanStatus.pending,
        createdAt: DateTime(2026, 8, 1),
        entries: <MoneyLoanEntry>[
          MoneyLoanEntry(
            id: 'E1',
            loanId: 'MLN-cmp-int-first',
            entryAt: DateTime(2026, 4, 1),
            amountPaise: 3000000,
            kind: MoneyLoanEntryKind.repayment,
          ),
          MoneyLoanEntry(
            id: 'E2',
            loanId: 'MLN-cmp-int-first',
            entryAt: DateTime(2026, 7, 1),
            amountPaise: 2000000,
            kind: MoneyLoanEntryKind.repayment,
          ),
        ],
      );

      final LoanScenario mid = computeLoanScenario(
        loan: loan,
        now: DateTime(2026, 7, 1),
      );
      // E1 deferred slice: 30000×12%×3/12 = ₹900
      // E2 interest-first clears ₹900, then ₹19,100 principal
      final LoanTimelineEvent e2Pay = mid.timeline.firstWhere(
        (LoanTimelineEvent e) =>
            e.kind == LoanTimelineKind.payment && e.entryId == 'E2',
      );
      expect(e2Pay.toInterestPaise, 90000);
      expect(e2Pay.toPrincipalPaise, 1910000);
      expect(mid.remainingPrincipalPaise, 5090000);
    });

    test('principalOnly on Compound skips deferred interest', () {
      final MoneyLoan loan = MoneyLoan(
        id: 'MLN-cmp-prin-only',
        customerId: 'C1',
        direction: MoneyLoanDirection.given,
        principalPaise: 10000000,
        currencyCode: 'INR',
        interestKind: MoneyInterestKind.compound,
        rateBps: 1200,
        ratePeriod: MoneyRatePeriod.yearly,
        interestStartedAt: DateTime(2026, 1, 1),
        prepaymentAllocation: MoneyPrepaymentAllocation.principalOnly,
        status: MoneyLoanStatus.pending,
        createdAt: DateTime(2026, 8, 1),
        entries: <MoneyLoanEntry>[
          MoneyLoanEntry(
            id: 'E1',
            loanId: 'MLN-cmp-prin-only',
            entryAt: DateTime(2026, 4, 1),
            amountPaise: 3000000,
            kind: MoneyLoanEntryKind.repayment,
          ),
          MoneyLoanEntry(
            id: 'E2',
            loanId: 'MLN-cmp-prin-only',
            entryAt: DateTime(2026, 7, 1),
            amountPaise: 2000000,
            kind: MoneyLoanEntryKind.repayment,
          ),
        ],
      );

      final LoanScenario mid = computeLoanScenario(
        loan: loan,
        now: DateTime(2026, 7, 1),
      );
      final LoanTimelineEvent e2Pay = mid.timeline.firstWhere(
        (LoanTimelineEvent e) =>
            e.kind == LoanTimelineKind.payment && e.entryId == 'E2',
      );
      expect(e2Pay.toInterestPaise, 0);
      expect(e2Pay.toPrincipalPaise, 2000000);
      expect(mid.remainingPrincipalPaise, 5000000);
      expect(mid.unpaidInterestPaise, greaterThan(0));
    });

    test('Simple disbursement still increases principal', () {
      final MoneyLoan loan = MoneyLoan(
        id: 'MLN-add-simple',
        customerId: 'C1',
        direction: MoneyLoanDirection.given,
        principalPaise: 10000000,
        currencyCode: 'INR',
        interestKind: MoneyInterestKind.simple,
        rateBps: 1200,
        ratePeriod: MoneyRatePeriod.yearly,
        interestStartedAt: DateTime(2026, 1, 1),
        status: MoneyLoanStatus.pending,
        createdAt: DateTime(2026, 7, 1),
        entries: <MoneyLoanEntry>[
          MoneyLoanEntry(
            id: 'E-add',
            loanId: 'MLN-add-simple',
            entryAt: DateTime(2026, 7, 1),
            amountPaise: 2500000,
            kind: MoneyLoanEntryKind.disbursement,
          ),
        ],
      );

      final LoanScenario mid = computeLoanScenario(
        loan: loan,
        now: DateTime(2026, 7, 1),
      );
      expect(mid.remainingPrincipalPaise, 12500000);
      expect(mid.unpaidInterestPaise, greaterThan(0));
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
        (LoanTimelineEvent e) =>
            e.kind == LoanTimelineKind.remainingPeriodInterest,
      ).length, 2);
      expect(laterStart.timeline.where(
        (LoanTimelineEvent e) =>
            e.kind == LoanTimelineKind.remainingPeriodInterest,
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
        kind: MoneyLoanEntryKind.repayment,
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
        kind: MoneyLoanEntryKind.repayment,
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
      expect(loan.entries.single.kind, MoneyLoanEntryKind.disbursement);
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
        kind: MoneyLoanEntryKind.repayment,
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
    test('schemaVersion is 15 with money loan tables', () async {
      final LocalRepository repo = await bootRepo();
      expect(repo.database.schemaVersion, 15);
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

    test('MoneyPrepaymentAllocation.parse defaults unknown to interestThenPrincipal',
        () {
      expect(
        MoneyPrepaymentAllocation.parse(null),
        MoneyPrepaymentAllocation.interestThenPrincipal,
      );
      expect(
        MoneyPrepaymentAllocation.parse(''),
        MoneyPrepaymentAllocation.interestThenPrincipal,
      );
      expect(
        MoneyPrepaymentAllocation.parse('principalOnly'),
        MoneyPrepaymentAllocation.principalOnly,
      );
    });
  });
}
