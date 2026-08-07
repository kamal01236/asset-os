import 'package:flutter/services.dart';

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
