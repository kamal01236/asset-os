import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/core/pricing/rental_pricing.dart';

void main() {
  group('computeDueAt', () {
    final DateTime start = DateTime(2026, 8, 3, 10, 30);

    test('daily adds duration days', () {
      expect(
        computeDueAt(start: start, mode: BillingMode.daily, durationUnits: 3),
        DateTime(2026, 8, 6, 10, 30),
      );
    });

    test('weekly adds 7 * units days', () {
      expect(
        computeDueAt(start: start, mode: BillingMode.weekly, durationUnits: 1),
        DateTime(2026, 8, 10, 10, 30),
      );
      expect(
        computeDueAt(start: start, mode: BillingMode.weekly, durationUnits: 2),
        DateTime(2026, 8, 17, 10, 30),
      );
    });

    test('monthly adds calendar months', () {
      expect(
        computeDueAt(start: start, mode: BillingMode.monthly, durationUnits: 1),
        DateTime(2026, 9, 3, 10, 30),
      );
    });

    test('fixed uses duration as due-in days', () {
      expect(
        computeDueAt(start: start, mode: BillingMode.fixed, durationUnits: 5),
        DateTime(2026, 8, 8, 10, 30),
      );
    });

    test('custom uses customEnd', () {
      final DateTime end = DateTime(2026, 8, 20);
      expect(
        computeDueAt(
          start: start,
          mode: BillingMode.custom,
          durationUnits: 1,
          customEnd: end,
        ),
        end,
      );
    });
  });

  group('computeBaseAmount', () {
    final DateTime start = DateTime(2026, 8, 3);

    test('weekly 1 week at ₹50 = 5000 paise', () {
      final DateTime due = computeDueAt(
        start: start,
        mode: BillingMode.weekly,
        durationUnits: 1,
      );
      expect(
        computeBaseAmount(
          mode: BillingMode.weekly,
          rateAmount: 5000,
          start: start,
          due: due,
        ),
        5000,
      );
    });

    test('weekly spanning into second week charges 2 periods', () {
      final DateTime due = start.add(const Duration(days: 8));
      expect(
        computeBaseAmount(
          mode: BillingMode.weekly,
          rateAmount: 5000,
          start: start,
          due: due,
        ),
        10000,
      );
    });

    test('fixed charges once regardless of due span', () {
      final DateTime due = start.add(const Duration(days: 30));
      expect(
        computeBaseAmount(
          mode: BillingMode.fixed,
          rateAmount: 10000,
          start: start,
          due: due,
        ),
        10000,
      );
    });

    test('daily multiplies by days', () {
      final DateTime due = start.add(const Duration(days: 3));
      expect(
        computeBaseAmount(
          mode: BillingMode.daily,
          rateAmount: 150000,
          start: start,
          due: due,
        ),
        450000,
      );
    });

    test('custom bills as daily', () {
      final DateTime due = start.add(const Duration(days: 4));
      expect(
        computeBaseAmount(
          mode: BillingMode.custom,
          rateAmount: 1000,
          start: start,
          due: due,
        ),
        4000,
      );
    });
  });

  group('computeLateAmount', () {
    final DateTime due = DateTime(2026, 8, 10);

    test('zero before or on due date', () {
      expect(
        computeLateAmount(
          due: due,
          asOf: DateTime(2026, 8, 10),
          lateFeePerDay: 500,
        ),
        0,
      );
      expect(
        computeLateAmount(
          due: due,
          asOf: DateTime(2026, 8, 9),
          lateFeePerDay: 500,
        ),
        0,
      );
    });

    test('multiplies overdue whole days', () {
      expect(
        computeLateAmount(
          due: due,
          asOf: DateTime(2026, 8, 13),
          lateFeePerDay: 500,
        ),
        1500,
      );
    });

    test('zero when late fee disabled', () {
      expect(
        computeLateAmount(
          due: due,
          asOf: DateTime(2026, 8, 20),
          lateFeePerDay: 0,
        ),
        0,
      );
    });
  });

  group('formatMoney / parseRupeesToPaise', () {
    test('formats INR without trailing zeros', () {
      expect(formatMoney(5000), '₹50');
      expect(formatMoney(5050), '₹50.50');
      expect(formatMoney(0), '₹0');
    });

    test('parses rupees field to paise', () {
      expect(parseRupeesToPaise('50'), 5000);
      expect(parseRupeesToPaise('50.5'), 5050);
      expect(parseRupeesToPaise(''), 0);
    });
  });
}
