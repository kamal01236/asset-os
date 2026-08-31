@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/domain/payments/payment_reference.dart';

void main() {
  group('normalizeMoneyNote', () {
    test('trims and preserves case', () {
      expect(normalizeMoneyNote('  upi-123_a  '), 'upi-123_a');
      expect(normalizeMoneyNote('Cash receipt'), 'Cash receipt');
    });

    test('empty becomes null', () {
      expect(normalizeMoneyNote(null), isNull);
      expect(normalizeMoneyNote(''), isNull);
      expect(normalizeMoneyNote('   '), isNull);
    });
  });

  group('validateMoneyNote', () {
    test('accepts empty and free text', () {
      expect(() => validateMoneyNote(null), returnsNormally);
      expect(() => validateMoneyNote(''), returnsNormally);
      expect(() => validateMoneyNote('   '), returnsNormally);
      expect(() => validateMoneyNote('ABC123'), returnsNormally);
      expect(() => validateMoneyNote('UPI 01'), returnsNormally);
      expect(() => validateMoneyNote('ref@pay'), returnsNormally);
    });

    test('accepts max 20 chars', () {
      expect(
        () => validateMoneyNote('ABCDEFGHIJABCDEFGHIJ'),
        returnsNormally,
      );
    });

    test('rejects over 20 chars', () {
      expect(
        () => validateMoneyNote('ABCDEFGHIJABCDEFGHIJK'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
