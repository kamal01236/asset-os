@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/domain/payments/payment_reference.dart';

void main() {
  group('normalizePaymentReference', () {
    test('trims and uppercases', () {
      expect(normalizePaymentReference('  upi-123_a  '), 'UPI-123_A');
    });
  });

  group('validatePaymentReference', () {
    test('accepts valid refs', () {
      expect(() => validatePaymentReference('ABC123'), returnsNormally);
      expect(() => validatePaymentReference('UPI-01_X'), returnsNormally);
    });

    test('rejects empty', () {
      expect(
        () => validatePaymentReference('   '),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects over 15 chars', () {
      expect(
        () => validatePaymentReference('ABCDEFGHIJKLMNOP'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects invalid charset', () {
      expect(
        () => validatePaymentReference('UPI 123'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => validatePaymentReference('ref@pay'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('requirePaymentReference', () {
    test('returns normalized value', () {
      expect(requirePaymentReference('txn-9'), 'TXN-9');
    });
  });
}
