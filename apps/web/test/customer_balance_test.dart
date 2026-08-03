import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/core/models/customer_balance.dart';
import 'package:asset_os/core/models/entities.dart';

Customer _customer({int depositBalance = 0, String id = 'C-1'}) {
  return Customer(
    id: id,
    name: 'Test',
    phone: '9999999999',
    isTrusted: false,
    qrCode: 'QR-$id',
    depositBalance: depositBalance,
  );
}

RentalLine _line({
  required String id,
  required int rateAmount,
  BillingMode billingMode = BillingMode.daily,
  int baseAmount = 0,
  int lateFeePerDay = 0,
  DateTime? returnedAt,
}) {
  return RentalLine(
    id: id,
    itemId: 'INV-1',
    catalogName: 'Tool',
    instanceName: 'Unit',
    shortCode: 'TL-01',
    rateAmount: rateAmount,
    billingMode: billingMode,
    baseAmount: baseAmount,
    lateFeePerDay: lateFeePerDay,
    returnedAt: returnedAt,
  );
}

Rental _rental({
  required String id,
  required String customerId,
  required DateTime startedAt,
  DateTime? dueAt,
  DateTime? returnedAt,
  required List<RentalLine> lines,
  int baseAmount = 0,
  int lateAmount = 0,
  int totalAmount = 0,
}) {
  return Rental(
    id: id,
    customerId: customerId,
    lines: lines,
    startedAt: startedAt,
    dueAt: dueAt,
    returnedAt: returnedAt,
    timeline: const <RentalEvent>[],
    qrCode: 'QR-$id',
    billingMode: BillingMode.daily,
    rateAmount: lines.isEmpty ? 0 : lines.first.rateAmount,
    lateFeePerDay: lines.isEmpty ? 0 : lines.first.lateFeePerDay,
    baseAmount: baseAmount,
    lateAmount: lateAmount,
    totalAmount: totalAmount,
  );
}

void main() {
  group('customerBalanceAsOf', () {
    final DateTime start = DateTime(2026, 8, 1, 10);
    final DateTime asOf = DateTime(2026, 8, 4, 10);

    test('no rentals: advance from deposit, pending and due zero', () {
      final Customer customer = _customer(depositBalance: 5000);
      final CustomerBalanceAsOf balance =
          customerBalanceAsOf(customer, const <Rental>[], asOf);
      expect(balance.advancePaise, 5000);
      expect(balance.pendingPaise, 0);
      expect(balance.duePaise, 0);
      expect(balance.openItemsCount, 0);
      expect(balance.hasActivity, isTrue);
    });

    test('no activity when deposit and rentals are empty', () {
      final Customer customer = _customer();
      final CustomerBalanceAsOf balance =
          customerBalanceAsOf(customer, const <Rental>[], asOf);
      expect(balance.hasActivity, isFalse);
      expect(balance.duePaise, 0);
    });

    test('dated active rental includes base plus late accrual', () {
      final Customer customer = _customer();
      final DateTime due = DateTime(2026, 8, 2, 10);
      final Rental rental = _rental(
        id: 'R-1',
        customerId: customer.id,
        startedAt: start,
        dueAt: due,
        lines: <RentalLine>[
          _line(
            id: 'L-1',
            rateAmount: 10000,
            baseAmount: 10000,
            lateFeePerDay: 1000,
          ),
        ],
        baseAmount: 10000,
      );
      // asOf is 2 calendar days after due → late = 2 * 1000
      final CustomerBalanceAsOf balance =
          customerBalanceAsOf(customer, <Rental>[rental], asOf);
      expect(balance.pendingPaise, 12000);
      expect(balance.duePaise, 12000);
      expect(balance.openItemsCount, 1);
    });

    test('open-ended accrual grows with elapsed days', () {
      final Customer customer = _customer();
      final Rental rental = _rental(
        id: 'R-OE',
        customerId: customer.id,
        startedAt: start,
        dueAt: null,
        lines: <RentalLine>[
          _line(id: 'L-OE', rateAmount: 5000, billingMode: BillingMode.daily),
        ],
      );
      // start Aug 1 → asOf Aug 4 = 3 days → 15000
      final CustomerBalanceAsOf balance =
          customerBalanceAsOf(customer, <Rental>[rental], asOf);
      expect(balance.pendingPaise, 15000);
      expect(balance.duePaise, 15000);
      expect(balance.openItemsCount, 1);
    });

    test('deposit larger than pending → due is 0', () {
      final Customer customer = _customer(depositBalance: 20000);
      final Rental rental = _rental(
        id: 'R-OE',
        customerId: customer.id,
        startedAt: start,
        dueAt: null,
        lines: <RentalLine>[
          _line(id: 'L-OE', rateAmount: 5000, billingMode: BillingMode.daily),
        ],
      );
      final CustomerBalanceAsOf balance =
          customerBalanceAsOf(customer, <Rental>[rental], asOf);
      expect(balance.advancePaise, 20000);
      expect(balance.pendingPaise, 15000);
      expect(balance.duePaise, 0);
    });

    test('deposit smaller than pending → due is the gap', () {
      final Customer customer = _customer(depositBalance: 4000);
      final Rental rental = _rental(
        id: 'R-OE',
        customerId: customer.id,
        startedAt: start,
        dueAt: null,
        lines: <RentalLine>[
          _line(id: 'L-OE', rateAmount: 5000, billingMode: BillingMode.daily),
        ],
      );
      final CustomerBalanceAsOf balance =
          customerBalanceAsOf(customer, <Rental>[rental], asOf);
      expect(balance.pendingPaise, 15000);
      expect(balance.duePaise, 11000);
    });

    test('ignores returned rentals and other customers', () {
      final Customer customer = _customer(depositBalance: 1000);
      final Rental active = _rental(
        id: 'R-A',
        customerId: customer.id,
        startedAt: start,
        dueAt: null,
        lines: <RentalLine>[
          _line(id: 'L-A', rateAmount: 5000, billingMode: BillingMode.daily),
        ],
      );
      final Rental returned = _rental(
        id: 'R-B',
        customerId: customer.id,
        startedAt: start,
        dueAt: asOf,
        returnedAt: asOf,
        lines: <RentalLine>[
          _line(
            id: 'L-B',
            rateAmount: 5000,
            baseAmount: 99999,
            returnedAt: asOf,
          ),
        ],
        totalAmount: 99999,
      );
      final Rental other = _rental(
        id: 'R-C',
        customerId: 'C-OTHER',
        startedAt: start,
        dueAt: null,
        lines: <RentalLine>[
          _line(id: 'L-C', rateAmount: 5000, billingMode: BillingMode.daily),
        ],
      );
      final CustomerBalanceAsOf balance = customerBalanceAsOf(
        customer,
        <Rental>[active, returned, other],
        asOf,
      );
      expect(balance.pendingPaise, 15000);
      expect(balance.openItemsCount, 1);
      expect(balance.duePaise, 14000);
    });

    test('sums multiple active rentals and open lines', () {
      final Customer customer = _customer();
      final Rental first = _rental(
        id: 'R-1',
        customerId: customer.id,
        startedAt: start,
        dueAt: null,
        lines: <RentalLine>[
          _line(id: 'L-1a', rateAmount: 5000, billingMode: BillingMode.daily),
          _line(id: 'L-1b', rateAmount: 5000, billingMode: BillingMode.daily),
        ],
      );
      final Rental second = _rental(
        id: 'R-2',
        customerId: customer.id,
        startedAt: start,
        dueAt: null,
        lines: <RentalLine>[
          _line(id: 'L-2', rateAmount: 2000, billingMode: BillingMode.daily),
        ],
      );
      final CustomerBalanceAsOf balance = customerBalanceAsOf(
        customer,
        <Rental>[first, second],
        asOf,
      );
      // (5000+5000+2000) * 3 days
      expect(balance.pendingPaise, 36000);
      expect(balance.openItemsCount, 3);
    });
  });
}
