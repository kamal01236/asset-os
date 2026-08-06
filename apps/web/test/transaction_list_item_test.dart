@Tags(['unit', 'loans'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/core/loans/loan_models.dart';
import 'package:asset_os/core/models/entities.dart';
import 'package:asset_os/core/transactions/transaction_list_item.dart';

Rental _order({
  required String id,
  required DateTime startedAt,
  String customerId = 'CUS-1',
}) {
  return Rental(
    id: id,
    customerId: customerId,
    startedAt: startedAt,
    dueAt: startedAt.add(const Duration(days: 1)),
    rateAmount: 10000,
    depositAmount: 0,
    lateFeePerDay: 0,
    qrCode: 'rental:$id',
    lines: const <RentalLine>[],
    timeline: const <RentalEvent>[],
  );
}

MoneyLoan _loan({
  required String id,
  required DateTime createdAt,
  String customerId = 'CUS-1',
}) {
  return MoneyLoan(
    id: id,
    customerId: customerId,
    direction: MoneyLoanDirection.given,
    principalPaise: 500000,
    currencyCode: 'INR',
    interestKind: MoneyInterestKind.simple,
    rateBps: 1000,
    ratePeriod: MoneyRatePeriod.monthly,
    interestStartedAt: createdAt,
    status: MoneyLoanStatus.pending,
    createdAt: createdAt,
  );
}

void main() {
  test('mergeTransactionListItems sorts by activity newest first', () {
    final DateTime older = DateTime(2026, 1, 1);
    final DateTime newer = DateTime(2026, 2, 1);
    final List<TransactionListItem> items = mergeTransactionListItems(
      rentals: <Rental>[
        _order(id: 'REN-OLD', startedAt: older),
      ],
      loans: <MoneyLoan>[
        _loan(id: 'MLN-NEW', createdAt: newer),
      ],
    );
    expect(items, hasLength(2));
    expect(items.first.id, 'MLN-NEW');
    expect(items.last.id, 'REN-OLD');
    expect(items.first.kind, TransactionKind.loan);
    expect(items.last.kind, TransactionKind.order);
  });

  test('create gates: pure financial is loan-only; rental can create order', () {
    expect(
      canCreateOrderTransaction(const <ResourceType>[ResourceType.financial]),
      isFalse,
    );
    expect(
      canCreateLoanTransaction(const <ResourceType>[ResourceType.financial]),
      isTrue,
    );
    expect(
      canCreateOrderTransaction(const <ResourceType>[ResourceType.rental]),
      isTrue,
    );
    expect(
      canCreateLoanTransaction(const <ResourceType>[ResourceType.rental]),
      isFalse,
    );
  });

  test('filter chips respect enabled types and existing rows', () {
    expect(
      showOrdersTransactionFilter(
        const <ResourceType>[ResourceType.financial],
        const <Rental>[],
      ),
      isFalse,
    );
    expect(
      showOrdersTransactionFilter(
        const <ResourceType>[ResourceType.financial],
        <Rental>[_order(id: 'REN-1', startedAt: DateTime(2026, 1, 1))],
      ),
      isTrue,
    );
    expect(
      showLoansTransactionFilter(
        const <ResourceType>[ResourceType.rental],
        const <MoneyLoan>[],
      ),
      isFalse,
    );
    expect(
      showLoansTransactionFilter(
        const <ResourceType>[ResourceType.rental],
        <MoneyLoan>[_loan(id: 'MLN-1', createdAt: DateTime(2026, 1, 1))],
      ),
      isTrue,
    );
  });
}
