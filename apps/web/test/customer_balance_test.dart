@Tags(['unit', 'customers'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/domain/models/customer_balance.dart';
import 'package:asset_os/domain/models/entities.dart';

Customer _customer({String id = 'C-1'}) {
  return Customer(
    id: id,
    name: 'Test',
    phone: '9999999999',
    isTrusted: false,
    qrCode: 'QR-$id',
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
  int depositAmount = 0,
  OrderStatus orderStatus = OrderStatus.open,
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
    depositAmount: depositAmount,
    orderStatus: orderStatus,
  );
}

void main() {
  group('customerBalanceAsOf', () {
    final DateTime start = DateTime(2026, 8, 1, 10);
    final DateTime asOf = DateTime(2026, 8, 4, 10);

    test('no rentals: zero advance/pending/net', () {
      final Customer customer = _customer();
      final CustomerBalanceAsOf balance =
          customerBalanceAsOf(customer, const <Rental>[], asOf);
      expect(balance.advancePaise, 0);
      expect(balance.pendingPaise, 0);
      expect(balance.netPaise, 0);
      expect(balance.duePaise, 0);
      expect(balance.creditPaise, 0);
      expect(balance.openItemsCount, 0);
      expect(balance.hasActivity, isFalse);
    });

    test('open rental: pending accrues; deposit reduces net', () {
      final Customer customer = _customer();
      final Rental rental = _rental(
        id: 'R-OE',
        customerId: customer.id,
        startedAt: start,
        dueAt: null,
        depositAmount: 4000,
        lines: <RentalLine>[
          _line(id: 'L-OE', rateAmount: 5000, billingMode: BillingMode.daily),
        ],
      );
      // 3 days * 5000 = 15000 pending; net = 15000 - 4000 = 11000
      final CustomerBalanceAsOf balance =
          customerBalanceAsOf(customer, <Rental>[rental], asOf);
      expect(balance.advancePaise, 4000);
      expect(balance.pendingPaise, 15000);
      expect(balance.netPaise, 11000);
      expect(balance.duePaise, 11000);
      expect(balance.creditPaise, 0);
      expect(balance.openItemsCount, 1);
    });

    test('deposit larger than charges → credit (negative net)', () {
      final Customer customer = _customer();
      final Rental rental = _rental(
        id: 'R-OE',
        customerId: customer.id,
        startedAt: start,
        dueAt: null,
        depositAmount: 20000,
        lines: <RentalLine>[
          _line(id: 'L-OE', rateAmount: 5000, billingMode: BillingMode.daily),
        ],
      );
      final CustomerBalanceAsOf balance =
          customerBalanceAsOf(customer, <Rental>[rental], asOf);
      expect(balance.pendingPaise, 15000);
      expect(balance.netPaise, -5000);
      expect(balance.duePaise, 0);
      expect(balance.creditPaise, 5000);
    });

    test('completed uses finalized totalAmount', () {
      final Customer customer = _customer();
      final Rental rental = _rental(
        id: 'R-DONE',
        customerId: customer.id,
        startedAt: start,
        dueAt: asOf,
        returnedAt: asOf,
        depositAmount: 3000,
        totalAmount: 10000,
        orderStatus: OrderStatus.completed,
        lines: <RentalLine>[
          _line(
            id: 'L-1',
            rateAmount: 5000,
            baseAmount: 10000,
            returnedAt: asOf,
          ),
        ],
      );
      final CustomerBalanceAsOf balance =
          customerBalanceAsOf(customer, <Rental>[rental], asOf);
      expect(balance.pendingPaise, 10000);
      expect(balance.advancePaise, 3000);
      expect(balance.netPaise, 7000);
      expect(balance.openItemsCount, 0);
    });

    test('cancelled orders contribute zero', () {
      final Customer customer = _customer();
      final Rental cancelled = _rental(
        id: 'R-X',
        customerId: customer.id,
        startedAt: start,
        depositAmount: 9000,
        totalAmount: 0,
        orderStatus: OrderStatus.cancelled,
        returnedAt: asOf,
        lines: <RentalLine>[
          _line(id: 'L-X', rateAmount: 5000, returnedAt: asOf),
        ],
      );
      final Rental open = _rental(
        id: 'R-OE',
        customerId: customer.id,
        startedAt: start,
        dueAt: null,
        depositAmount: 1000,
        lines: <RentalLine>[
          _line(id: 'L-OE', rateAmount: 5000, billingMode: BillingMode.daily),
        ],
      );
      final CustomerBalanceAsOf balance = customerBalanceAsOf(
        customer,
        <Rental>[cancelled, open],
        asOf,
      );
      expect(balance.advancePaise, 1000);
      expect(balance.pendingPaise, 15000);
      expect(balance.netPaise, 14000);
    });

    test('sums signed net across open and completed', () {
      final Customer customer = _customer();
      final Rental open = _rental(
        id: 'R-1',
        customerId: customer.id,
        startedAt: start,
        dueAt: null,
        depositAmount: 20000,
        lines: <RentalLine>[
          _line(id: 'L-1', rateAmount: 5000, billingMode: BillingMode.daily),
        ],
      );
      final Rental done = _rental(
        id: 'R-2',
        customerId: customer.id,
        startedAt: start,
        returnedAt: asOf,
        depositAmount: 1000,
        totalAmount: 8000,
        orderStatus: OrderStatus.completed,
        lines: <RentalLine>[
          _line(id: 'L-2', rateAmount: 2000, baseAmount: 8000, returnedAt: asOf),
        ],
      );
      final CustomerBalanceAsOf balance = customerBalanceAsOf(
        customer,
        <Rental>[open, done],
        asOf,
      );
      // open: 15000 - 20000 = -5000; completed: 8000 - 1000 = 7000; net = 2000
      expect(balance.advancePaise, 21000);
      expect(balance.pendingPaise, 23000);
      expect(balance.netPaise, 2000);
      expect(balance.openItemsCount, 1);
    });

    test('ignores other customers', () {
      final Customer customer = _customer();
      final Rental other = _rental(
        id: 'R-C',
        customerId: 'C-OTHER',
        startedAt: start,
        dueAt: null,
        depositAmount: 99999,
        lines: <RentalLine>[
          _line(id: 'L-C', rateAmount: 5000, billingMode: BillingMode.daily),
        ],
      );
      final CustomerBalanceAsOf balance =
          customerBalanceAsOf(customer, <Rental>[other], asOf);
      expect(balance.hasActivity, isFalse);
      expect(balance.netPaise, 0);
    });
  });
}
