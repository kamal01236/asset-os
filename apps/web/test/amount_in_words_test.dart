@Tags(['unit', 'pricing'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/domain/pricing/amount_in_words.dart';

void main() {
  group('amountInWordsFromPaise EN', () {
    test('zero', () {
      expect(
        amountInWordsFromPaise(0, languageCode: 'en'),
        'Zero rupees',
      );
    });

    test('one rupee', () {
      expect(
        amountInWordsFromPaise(100, languageCode: 'en'),
        'One rupee',
      );
    });

    test('twenty one', () {
      expect(
        amountInWordsFromPaise(2100, languageCode: 'en'),
        'Twenty one rupees',
      );
    });

    test('one hundred', () {
      expect(
        amountInWordsFromPaise(10000, languageCode: 'en'),
        'One hundred rupees',
      );
    });

    test('one thousand', () {
      expect(
        amountInWordsFromPaise(100000, languageCode: 'en'),
        'One thousand rupees',
      );
    });

    test('one lakh', () {
      expect(
        amountInWordsFromPaise(10000000, languageCode: 'en'),
        'One lakh rupees',
      );
    });

    test('one crore', () {
      expect(
        amountInWordsFromPaise(1000000000, languageCode: 'en'),
        'One crore rupees',
      );
    });

    test('ten thousand crore', () {
      expect(
        amountInWordsFromPaise(10000000000000, languageCode: 'en'),
        'Ten thousand crore rupees',
      );
    });

    test('one lakh crore (max)', () {
      expect(
        amountInWordsFromPaise(kMaxAmountRupees * 100, languageCode: 'en'),
        'One lakh crore rupees',
      );
    });

    test('paise', () {
      expect(
        amountInWordsFromPaise(2150, languageCode: 'en'),
        'Twenty one rupees and fifty paise',
      );
    });

    test('negative', () {
      expect(
        amountInWordsFromPaise(-50000, languageCode: 'en'),
        'Minus five hundred rupees',
      );
    });

    test('over cap', () {
      expect(
        amountInWordsFromPaise((kMaxAmountRupees + 1) * 100, languageCode: 'en'),
        kAmountInWordsOverflow,
      );
    });
  });

  group('amountInWordsFromPaise HI', () {
    test('zero', () {
      expect(
        amountInWordsFromPaise(0, languageCode: 'hi'),
        'शून्य रुपये',
      );
    });

    test('twenty one', () {
      expect(
        amountInWordsFromPaise(2100, languageCode: 'hi'),
        'इक्कीस रुपये',
      );
    });

    test('one lakh', () {
      expect(
        amountInWordsFromPaise(10000000, languageCode: 'hi'),
        'एक लाख रुपये',
      );
    });

    test('one crore with paise', () {
      expect(
        amountInWordsFromPaise(1000000025, languageCode: 'hi'),
        'एक करोड़ रुपये और पच्चीस पैसे',
      );
    });

    test('ten thousand crore', () {
      expect(
        amountInWordsFromPaise(10000000000000, languageCode: 'hi'),
        'दस हजार करोड़ रुपये',
      );
    });

    test('one lakh crore (max)', () {
      expect(
        amountInWordsFromPaise(kMaxAmountRupees * 100, languageCode: 'hi'),
        'एक लाख करोड़ रुपये',
      );
    });

    test('negative', () {
      expect(
        amountInWordsFromPaise(-100, languageCode: 'hi'),
        'ऋण एक रुपया',
      );
    });
  });

  group('amountInWordsFromRupeesField', () {
    test('empty → empty', () {
      expect(
        amountInWordsFromRupeesField('', languageCode: 'en'),
        '',
      );
      expect(
        amountInWordsFromRupeesField('   ', languageCode: 'en'),
        '',
      );
    });

    test('parses decimals', () {
      expect(
        amountInWordsFromRupeesField('21.5', languageCode: 'en'),
        'Twenty one rupees and fifty paise',
      );
    });

    test('overflow from field', () {
      expect(
        amountInWordsFromRupeesField('${kMaxAmountRupees + 1}', languageCode: 'en'),
        kAmountInWordsOverflow,
      );
    });
  });
}
