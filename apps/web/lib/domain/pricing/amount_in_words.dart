import 'rental_pricing.dart';

/// Largest allowed whole-rupee amount (1 lakh crore).
const int kMaxAmountRupees = 1000000000000;

/// Sentinel returned when the absolute amount exceeds [kMaxAmountRupees].
/// UI maps this to the localized overflow string.
const String kAmountInWordsOverflow = '__amount_overflow__';

/// Convert a signed paise amount to Indian-scale words for [languageCode]
/// (`en` or `hi`; other codes fall back to English).
///
/// Empty-equivalent: callers should use [amountInWordsFromRupeesField] for
/// blank fields. Zero → “Zero rupees” / “शून्य रुपये”.
String amountInWordsFromPaise(int paise, {required String languageCode}) {
  final bool hi = languageCode.toLowerCase().startsWith('hi');
  final bool negative = paise < 0;
  final int absPaise = paise.abs();
  final int rupees = absPaise ~/ 100;
  final int paisePart = absPaise % 100;

  if (rupees > kMaxAmountRupees) {
    return kAmountInWordsOverflow;
  }

  final String rupeeWords = _integerToIndianWords(rupees, hindi: hi);
  final String currency = hi
      ? (rupees == 1 ? 'रुपया' : 'रुपये')
      : (rupees == 1 ? 'rupee' : 'rupees');

  String body;
  if (paisePart == 0) {
    body = hi ? '$rupeeWords $currency' : '$rupeeWords $currency';
  } else {
    final String paiseWords = _integerToIndianWords(paisePart, hindi: hi);
    if (hi) {
      body = '$rupeeWords $currency और $paiseWords पैसे';
    } else {
      body = '$rupeeWords $currency and $paiseWords paise';
    }
  }

  if (negative) {
    return hi ? 'ऋण $body' : 'Minus $body';
  }
  // Title-case English first letter for readability under fields.
  if (!hi && body.isNotEmpty) {
    return '${body[0].toUpperCase()}${body.substring(1)}';
  }
  return body;
}

/// Parse a rupees edit field and return amount-in-words.
///
/// Empty / whitespace → `''` (no helper noise). Over cap →
/// [kAmountInWordsOverflow].
String amountInWordsFromRupeesField(
  String raw, {
  required String languageCode,
}) {
  final String trimmed = raw.trim();
  if (trimmed.isEmpty || trimmed == '-' || trimmed == '.' || trimmed == '-.') {
    return '';
  }
  final int paise = parseRupeesToPaise(trimmed);
  // Detect overflow before int truncation from huge doubles: compare rupees.
  final String normalized = trimmed.replaceAll(',', '');
  final double? value = double.tryParse(normalized);
  if (value != null && value.abs() > kMaxAmountRupees) {
    return kAmountInWordsOverflow;
  }
  return amountInWordsFromPaise(paise, languageCode: languageCode);
}

String _integerToIndianWords(int n, {required bool hindi}) {
  assert(n >= 0);
  if (n == 0) {
    return hindi ? 'शून्य' : 'zero';
  }

  final List<String> parts = <String>[];

  final int crore = n ~/ 10000000;
  n %= 10000000;
  if (crore > 0) {
    // Recursive so coefficients above 999 work (e.g. ten thousand crore).
    parts.add(
      '${_integerToIndianWords(crore, hindi: hindi)} ${hindi ? 'करोड़' : 'crore'}',
    );
  }

  final int lakh = n ~/ 100000;
  n %= 100000;
  if (lakh > 0) {
    parts.add(
      '${_belowThousand(lakh, hindi: hindi)} ${hindi ? 'लाख' : 'lakh'}',
    );
  }

  final int thousand = n ~/ 1000;
  n %= 1000;
  if (thousand > 0) {
    parts.add(
      '${_belowThousand(thousand, hindi: hindi)} ${hindi ? 'हजार' : 'thousand'}',
    );
  }

  if (n > 0) {
    parts.add(_belowThousand(n, hindi: hindi));
  }

  return parts.join(' ');
}

String _belowThousand(int n, {required bool hindi}) {
  assert(n >= 0 && n < 1000);
  if (n == 0) {
    return '';
  }
  if (n < 100) {
    return _belowHundred(n, hindi: hindi);
  }
  final int hundreds = n ~/ 100;
  final int rest = n % 100;
  final String hundredWord = hindi
      ? '${_belowHundred(hundreds, hindi: true)} सौ'
      : '${_belowHundred(hundreds, hindi: false)} hundred';
  if (rest == 0) {
    return hundredWord;
  }
  return '$hundredWord ${_belowHundred(rest, hindi: hindi)}';
}

String _belowHundred(int n, {required bool hindi}) {
  assert(n >= 0 && n < 100);
  if (hindi) {
    return _hindiBelowHundred[n];
  }
  if (n < 20) {
    return _englishOnes[n];
  }
  final int tens = n ~/ 10;
  final int ones = n % 10;
  if (ones == 0) {
    return _englishTens[tens];
  }
  return '${_englishTens[tens]} ${_englishOnes[ones]}';
}

const List<String> _englishOnes = <String>[
  'zero',
  'one',
  'two',
  'three',
  'four',
  'five',
  'six',
  'seven',
  'eight',
  'nine',
  'ten',
  'eleven',
  'twelve',
  'thirteen',
  'fourteen',
  'fifteen',
  'sixteen',
  'seventeen',
  'eighteen',
  'nineteen',
];

const List<String> _englishTens = <String>[
  '',
  '',
  'twenty',
  'thirty',
  'forty',
  'fifty',
  'sixty',
  'seventy',
  'eighty',
  'ninety',
];

/// Full 0–99 Hindi forms (irregular teens).
const List<String> _hindiBelowHundred = <String>[
  'शून्य',
  'एक',
  'दो',
  'तीन',
  'चार',
  'पाँच',
  'छह',
  'सात',
  'आठ',
  'नौ',
  'दस',
  'ग्यारह',
  'बारह',
  'तेरह',
  'चौदह',
  'पंद्रह',
  'सोलह',
  'सत्रह',
  'अठारह',
  'उन्नीस',
  'बीस',
  'इक्कीस',
  'बाईस',
  'तेईस',
  'चौबीस',
  'पच्चीस',
  'छब्बीस',
  'सत्ताईस',
  'अट्ठाईस',
  'उनतीस',
  'तीस',
  'इकतीस',
  'बत्तीस',
  'तैंतीस',
  'चौंतीस',
  'पैंतीस',
  'छत्तीस',
  'सैंतीस',
  'अड़तीस',
  'उनतालीस',
  'चालीस',
  'इकतालीस',
  'बयालीस',
  'तैंतालीस',
  'चवालीस',
  'पैंतालीस',
  'छियालीस',
  'सैंतालीस',
  'अड़तालीस',
  'उनचास',
  'पचास',
  'इक्यावन',
  'बावन',
  'तिरपन',
  'चौवन',
  'पचपन',
  'छप्पन',
  'सत्तावन',
  'अट्ठावन',
  'उनसठ',
  'साठ',
  'इकसठ',
  'बासठ',
  'तिरसठ',
  'चौंसठ',
  'पैंसठ',
  'छियासठ',
  'सड़सठ',
  'अड़सठ',
  'उनहत्तर',
  'सत्तर',
  'इकहत्तर',
  'बहत्तर',
  'तिहत्तर',
  'चौहत्तर',
  'पचहत्तर',
  'छिहत्तर',
  'सतहत्तर',
  'अठहत्तर',
  'उनासी',
  'अस्सी',
  'इक्यासी',
  'बयासी',
  'तिरासी',
  'चौरासी',
  'पचासी',
  'छियासी',
  'सत्तासी',
  'अठासी',
  'नवासी',
  'नब्बे',
  'इक्यानवे',
  'बानवे',
  'तिरानवे',
  'चौरानवे',
  'पंचानवे',
  'छियानवे',
  'सत्तानवे',
  'अट्ठानवे',
  'निन्यानवे',
];
