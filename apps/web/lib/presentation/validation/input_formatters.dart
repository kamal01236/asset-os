import 'package:flutter/services.dart';

import '../../domain/pricing/amount_in_words.dart';

/// Digits only — phone numbers and whole-rupee (non-negative) amounts.
final TextInputFormatter kDigitsOnlyInputFormatter =
    FilteringTextInputFormatter.digitsOnly;

/// Whole-rupee amounts that may be negative (e.g. loan adjustments).
final TextInputFormatter kSignedDigitsInputFormatter =
    TextInputFormatter.withFunction((
  TextEditingValue oldValue,
  TextEditingValue newValue,
) {
  final String text = newValue.text;
  if (text.isEmpty || RegExp(r'^-?\d*$').hasMatch(text)) {
    return newValue;
  }
  return oldValue;
});

/// Blocks edits whose absolute rupee value would exceed [maxRupees].
///
/// Allows intermediate strings (`''`, `'-'`, `'.'`) so typing stays fluid.
TextInputFormatter maxRupeesInputFormatter({
  int maxRupees = kMaxAmountRupees,
  bool allowDecimal = false,
  bool allowSigned = false,
}) {
  final String pattern = allowSigned
      ? (allowDecimal ? r'^-?\d*\.?\d{0,2}$' : r'^-?\d*$')
      : (allowDecimal ? r'^\d*\.?\d{0,2}$' : r'^\d*$');
  final RegExp allowed = RegExp(pattern);

  return TextInputFormatter.withFunction((
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String text = newValue.text;
    if (text.isEmpty || text == '-' || text == '.' || text == '-.') {
      return newValue;
    }
    if (!allowed.hasMatch(text)) {
      return oldValue;
    }
    final double? value = double.tryParse(text.replaceAll(',', ''));
    if (value == null) {
      return oldValue;
    }
    if (value.abs() > maxRupees) {
      return oldValue;
    }
    return newValue;
  });
}
