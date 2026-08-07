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
      // Jan 1→Feb 1 = 31 days; to Jan 16 → 15/31
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
  });

  group('computeLoanScenario timeline', () {
    test('₹1L yearly: overpay then reverse interest through asOf', () {
      // +1L 1 Jan, −30k 1 Apr, −80k 1 Jul → balance −10k after Jul.
      final MoneyLoan loan = MoneyLoan(
        id: 'MLN-overpay',
        customerId: 'C1',
        direction: MoneyLoanDirection.given,
        principalPaise: 10000000, // ₹1,00,000
        currencyCode: 'INR',
        interestKind: MoneyInterestKind.simple,
        rateBps: 1200, // 12%/year
        ratePeriod: MoneyRatePeriod.yearly,
        interestStartedAt: DateTime(2026, 1, 1),
        prepaymentAllocation: MoneyPrepaymentAllocation.principalOnly,
        status: MoneyLoanStatus.pending,
        createdAt: DateTime(2026, 10, 1),
        entries: <MoneyLoanEntry>[
          MoneyLoanEntry(
            id: 'E1',
            loanId: 'MLN-overpay',
            entryAt: DateTime(2026, 4, 1),
            amountPaise: 3000000, // ₹30,000
            kind: MoneyLoanEntryKind.repayment,
          ),
          MoneyLoanEntry(
            id: 'E2',
            loanId: 'MLN-overpay',
            entryAt: DateTime(2026, 7, 1),
            amountPaise: 8000000, // ₹80,000
            kind: MoneyLoanEntryKind.repayment,
          ),
        ],
      );

      final LoanScenario asOfOct = computeLoanScenario(
        loan: loan,
        now: DateTime(2026, 10, 1),
      );

      // Jan→Apr on 1L: 100000 × 12% × 3/12 = ₹3,000
      // Apr→Jul on 70k: 70000 × 12% × 3/12 = ₹2,100
      // Jul→Oct reverse on −10k: −10000 × 12% × 3/12 = −₹300
      expect(asOfOct.remainingPrincipalPaise, -1000000);
      expect(asOfOct.unpaidInterestPaise, 480000); // 3000+2100−300
      expect(asOfOct.interestAccruedPaise, 480000);
      expect(asOfOct.pendingPaise, -520000); // −10k + 4.8k
      expect(asOfOct.totalPaidPaise, 11000000);

      final List<LoanTimelineEvent> segments = asOfOct.timeline
          .where(
            (LoanTimelineEvent e) => e.kind == LoanTimelineKind.interestSegment,
          )
          .toList();
      expect(segments, hasLength(3));
      expect(segments[0].amountPaise, 300000);
      expect(segments[0].principalBasisPaise, 10000000);
      expect(segments[0].from, DateTime(2026, 1, 1));
      expect(segments[0].through, DateTime(2026, 4, 1));
      expect(segments[1].amountPaise, 210000);
      expect(segments[1].principalBasisPaise, 7000000);
      expect(segments[2].amountPaise, -30000);
      expect(segments[2].principalBasisPaise, -1000000);
      expect(segments[2].from, DateTime(2026, 7, 1));
      expect(segments[2].through, DateTime(2026, 10, 1));
    });

    test('entry dated before start participates', () {
      final MoneyLoan loan = MoneyLoan(
        id: 'MLN-pre',
        customerId: 'C1',
        direction: MoneyLoanDirection.given,
        principalPaise: 10000000,
        currencyCode: 'INR',
        interestKind: MoneyInterestKind.simple,
        rateBps: 1200,
        ratePeriod: MoneyRatePeriod.yearly,
        interestStartedAt: DateTime(2026, 4, 1),
        status: MoneyLoanStatus.pending,
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

      // Jan 1 repay before start → balance −20k; Jan→Apr reverse on −20k = −₹600
      // Apr 1 synthetic +1L → balance 80k; Apr→Jul on 80k = ₹2,400
      expect(mid.remainingPrincipalPaise, 8000000);
      expect(mid.unpaidInterestPaise, 180000); // −600 + 2400
      expect(mid.interestAccruedPaise, 180000);
      expect(mid.pendingPaise, 8180000);
      expect(mid.totalPaidPaise, 2000000);

      final LoanTimelineEvent firstPayment = mid.timeline.firstWhere(
        (LoanTimelineEvent e) => e.kind == LoanTimelineKind.payment,
      );
      expect(firstPayment.at, DateTime(2026, 1, 1));
      expect(
        mid.timeline.first.kind,
        LoanTimelineKind.payment,
      );
      final LoanTimelineEvent principal = mid.timeline.firstWhere(
        (LoanTimelineEvent e) =>
            e.kind == LoanTimelineKind.disbursement && e.entryId == null,
      );
      expect(principal.at, DateTime(2026, 4, 1));
      expect(principal.amountPaise, 10000000);
    });

    test('zero balance gap accrues 0', () {
      final MoneyLoan loan = MoneyLoan(
        id: 'MLN-zero',
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
      expect(
        mid.timeline.where(
          (LoanTimelineEvent e) => e.kind == LoanTimelineKind.interestSegment,
        ),
        isEmpty,
      );
    });

    test('simple keeps signed unpaid; compound capitalizes between events', () {
      MoneyLoan base({required MoneyInterestKind kind}) => MoneyLoan(
            id: 'MLN-$kind',
            customerId: 'C1',
            direction: MoneyLoanDirection.given,
            principalPaise: 10000000,
            currencyCode: 'INR',
            interestKind: kind,
            rateBps: 1200,
            ratePeriod: MoneyRatePeriod.yearly,
            interestStartedAt: DateTime(2026, 1, 1),
            prepaymentAllocation: MoneyPrepaymentAllocation.principalOnly,
            status: MoneyLoanStatus.pending,
            createdAt: DateTime(2026, 7, 1),
            entries: <MoneyLoanEntry>[
              MoneyLoanEntry(
                id: 'E1',
                loanId: 'MLN-$kind',
                entryAt: DateTime(2026, 4, 1),
                amountPaise: 3000000,
                kind: MoneyLoanEntryKind.repayment,
              ),
            ],
          );

      final LoanScenario simple = computeLoanScenario(
        loan: base(kind: MoneyInterestKind.simple),
        now: DateTime(2026, 7, 1),
      );
      // Jan→Apr on 1L = 3000 unpaid; Apr→Jul on 70k = 2100 unpaid
      expect(simple.remainingPrincipalPaise, 7000000);
      expect(simple.unpaidInterestPaise, 510000);
      expect(simple.pendingPaise, 7510000);

      final LoanScenario compound = computeLoanScenario(
        loan: base(kind: MoneyInterestKind.compound),
        now: DateTime(2026, 7, 1),
      );
      // Jan→Apr: capitalize +3000 → balance 103000; pay 30000 → 73000
      // Apr→Jul: capitalize +2190 → balance 75190; unpaid 0
      expect(compound.unpaidInterestPaise, 0);
      expect(compound.remainingPrincipalPaise, 7519000);
      expect(compound.pendingPaise, 7519000);
      expect(compound.interestAccruedPaise, 519000); // 3000 + 2190
    });

    test('₹1L yearly mid repay shows interest segments not anniversary rows',
        () {
      final MoneyLoan loan = MoneyLoan(
        id: 'MLN-1L',
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
        createdAt: DateTime(2026, 7, 1),
        entries: <MoneyLoanEntry>[
          MoneyLoanEntry(
            id: 'E1',
            loanId: 'MLN-1L',
            entryAt: DateTime(2026, 7, 1),
            amountPaise: 5000000,
            kind: MoneyLoanEntryKind.repayment,
          ),
        ],
      );

      final LoanScenario midYear = computeLoanScenario(
        loan: loan,
        now: DateTime(2026, 7, 1),
      );
      // Jan→Jul on 1L = ₹6,000 unpaid; then repay 50k principal-only → bal 50k
      expect(midYear.interestAccruedPaise, 600000);
      expect(midYear.remainingPrincipalPaise, 5000000);
      expect(midYear.unpaidInterestPaise, 600000);
      expect(midYear.pendingPaise, 5600000);

      final LoanTimelineEvent segment = midYear.timeline.firstWhere(
        (LoanTimelineEvent e) => e.kind == LoanTimelineKind.interestSegment,
      );
      expect(segment.amountPaise, 600000);
      expect(segment.principalBasisPaise, 10000000);
      final LoanTimelineEvent payment = midYear.timeline.firstWhere(
        (LoanTimelineEvent e) => e.kind == LoanTimelineKind.payment,
      );
      expect(payment.toInterestPaise, 0);
      expect(payment.toPrincipalPaise, 5000000);
    });

    test('interest-first clears unpaid then principal across events', () {
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
      // Jan→Jul: +6000 unpaid; E1 interest-first → 6k interest + 44k principal
      //   bal 56k, unpaid 0
      // Jul→Jan: +3360 unpaid; E2 → 3360 interest + 6640 principal
      //   bal 49360, unpaid 0
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
      expect(after.pendingPaise, 4936000);
    });

    test('principalOnly leaves unpaid interest intact', () {
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
      final LoanTimelineEvent e2 = after.timeline.firstWhere(
        (LoanTimelineEvent e) =>
            e.kind == LoanTimelineKind.payment && e.entryId == 'E2',
      );
      expect(e2.toInterestPaise, 0);
      expect(e2.toPrincipalPaise, 1000000);
      expect(after.remainingPrincipalPaise, 4000000);
      expect(after.unpaidInterestPaise, 900000);
      expect(after.pendingPaise, 4900000);
    });

    test('monthly compound capitalizes between month gaps', () {
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
      // One gap Jan1→Apr1: fraction 3.0 → interest = P×2%×3 = ₹600; capitalize.
      expect(threeMonths.interestAccruedPaise, 60000);
      expect(threeMonths.pendingPaise, 1060000);
      expect(threeMonths.unpaidInterestPaise, 0);
      expect(
        threeMonths.timeline
            .where(
              (LoanTimelineEvent e) =>
                  e.kind == LoanTimelineKind.interestSegment,
            )
            .length,
        1,
      );
    });

    test('monthly simple accrues across multi-month gap', () {
      final MoneyLoan loan = MoneyLoan(
        id: 'MLN-mo',
        customerId: 'C1',
        direction: MoneyLoanDirection.given,
        principalPaise: 1000000,
        currencyCode: 'INR',
        interestKind: MoneyInterestKind.simple,
        rateBps: 200,
        ratePeriod: MoneyRatePeriod.monthly,
        interestStartedAt: DateTime(2026, 1, 1),
        status: MoneyLoanStatus.pending,
        createdAt: DateTime(2026, 1, 1),
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
      expect(twoMonths.pendingPaise, 1040000);
    });

    test('disbursement increases balance and earns from that date', () {
      final MoneyLoan loan = MoneyLoan(
        id: 'MLN-add',
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
      // Jan→Jul on 1L = 6000; Jul→Jan on 1.5L = 9000; unpaid 15000; bal 1.5L
      expect(after.remainingPrincipalPaise, 15000000);
      expect(after.unpaidInterestPaise, 1500000);
      expect(after.pendingPaise, 16500000);
      expect(after.interestAccruedPaise, 1500000);
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

    test('createMoneyLoan with advance keeps original principal and settles',
        () async {
      final LocalRepository repo = await bootRepo();
      final customer = await ensureCustomer(repo);
      final DateTime today = DateTime.now();
      final DateTime todayOnly = DateTime(today.year, today.month, today.day);
      final DateTime start = todayOnly.subtract(const Duration(days: 60));
      final DateTime advanceAt = todayOnly.subtract(const Duration(days: 30));
      const int principalPaise = 10000000; // ₹1,00,000
      const int advancePaise = 5000000; // ₹50,000

      final String loanId = await repo.createMoneyLoan(
        customerId: customer.id,
        direction: MoneyLoanDirection.given,
        principalPaise: principalPaise,
        interestStartedAt: start,
        interestKind: MoneyInterestKind.simple,
        rateBps: 1200,
        ratePeriod: MoneyRatePeriod.yearly,
        advancePaymentPaise: advancePaise,
        advancePaymentAt: advanceAt,
        advancePaymentNote: 'Advance payment',
      );

      final MoneyLoan loan = (await repo.getMoneyLoan(loanId))!;
      expect(loan.principalPaise, principalPaise);
      expect(loan.entries, hasLength(1));
      expect(loan.entries.single.kind, MoneyLoanEntryKind.repayment);
      expect(loan.entries.single.amountPaise, advancePaise);
      expect(loan.entries.single.entryAt, advanceAt);
      expect(loan.entries.single.note, 'Advance payment');

      final LoanScenario scenario = computeLoanScenario(
        loan: loan,
        now: todayOnly,
      );
      expect(scenario.principalPaise, principalPaise);
      expect(scenario.remainingPrincipalPaise, lessThan(principalPaise));
      expect(scenario.totalPaidPaise, advancePaise);

      final MoneyLoan manual = MoneyLoan(
        id: 'MLN-manual-advance',
        customerId: customer.id,
        direction: MoneyLoanDirection.given,
        principalPaise: principalPaise,
        currencyCode: 'INR',
        interestKind: MoneyInterestKind.simple,
        rateBps: 1200,
        ratePeriod: MoneyRatePeriod.yearly,
        interestStartedAt: start,
        status: MoneyLoanStatus.pending,
        createdAt: todayOnly,
        entries: <MoneyLoanEntry>[
          MoneyLoanEntry(
            id: 'E-advance',
            loanId: 'MLN-manual-advance',
            entryAt: advanceAt,
            amountPaise: advancePaise,
            kind: MoneyLoanEntryKind.repayment,
            note: 'Advance payment',
          ),
        ],
      );
      final LoanScenario expected = computeLoanScenario(
        loan: manual,
        now: todayOnly,
      );
      expect(scenario.remainingPrincipalPaise, expected.remainingPrincipalPaise);
      expect(scenario.unpaidInterestPaise, expected.unpaidInterestPaise);
      expect(scenario.pendingPaise, expected.pendingPaise);
      expect(scenario.interestAccruedPaise, expected.interestAccruedPaise);

      expect(scenario.timeline.first.kind, LoanTimelineKind.disbursement);
      expect(
        scenario.timeline.first.at,
        DateTime(start.year, start.month, start.day),
      );
      final int paymentIdx = scenario.timeline.indexWhere(
        (LoanTimelineEvent e) => e.kind == LoanTimelineKind.payment,
      );
      expect(paymentIdx, greaterThan(0));
      expect(scenario.timeline[paymentIdx].at, advanceAt);
      expect(scenario.timeline[paymentIdx].amountPaise, advancePaise);
    });

    test('createMoneyLoan without advance leaves entries empty', () async {
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
      expect(loan.principalPaise, 100000);
    });

    test('createMoneyLoan rejects invalid advance amount or date', () async {
      final LocalRepository repo = await bootRepo();
      final customer = await ensureCustomer(repo);
      final DateTime today = DateTime.now();
      final DateTime todayOnly = DateTime(today.year, today.month, today.day);
      final DateTime start = todayOnly.subtract(const Duration(days: 10));

      await expectLater(
        repo.createMoneyLoan(
          customerId: customer.id,
          direction: MoneyLoanDirection.given,
          principalPaise: 100000,
          interestStartedAt: start,
          advancePaymentPaise: 50000,
        ),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        repo.createMoneyLoan(
          customerId: customer.id,
          direction: MoneyLoanDirection.given,
          principalPaise: 100000,
          interestStartedAt: start,
          advancePaymentPaise: 100001,
          advancePaymentAt: start,
        ),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        repo.createMoneyLoan(
          customerId: customer.id,
          direction: MoneyLoanDirection.given,
          principalPaise: 100000,
          interestStartedAt: start,
          advancePaymentPaise: 0,
          advancePaymentAt: start,
        ),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        repo.createMoneyLoan(
          customerId: customer.id,
          direction: MoneyLoanDirection.given,
          principalPaise: 100000,
          interestStartedAt: start,
          advancePaymentPaise: 50000,
          advancePaymentAt: start.subtract(const Duration(days: 1)),
        ),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        repo.createMoneyLoan(
          customerId: customer.id,
          direction: MoneyLoanDirection.given,
          principalPaise: 100000,
          interestStartedAt: start,
          advancePaymentPaise: 50000,
          advancePaymentAt: todayOnly.add(const Duration(days: 1)),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('schema', () {
    test('schemaVersion is 16 with money loan tables', () async {
      final LocalRepository repo = await bootRepo();
      expect(repo.database.schemaVersion, 16);
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
