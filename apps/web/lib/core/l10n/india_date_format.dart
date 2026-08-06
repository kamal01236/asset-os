import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// India display date: `dd/MM/yyyy` (numeric, not locale month names).
String formatIndiaDate(DateTime value) {
  return DateFormat('dd/MM/yyyy').format(value);
}

/// India display date + time: `dd/MM/yyyy HH:mm` (24h, zero-padded).
String formatIndiaDateTime(DateTime value) {
  return DateFormat('dd/MM/yyyy HH:mm').format(value);
}

/// Locale for [showDatePicker] so calendar chrome is day-first.
Locale indiaDatePickerLocale(BuildContext context) {
  final String language = Localizations.localeOf(context).languageCode;
  return language == 'hi'
      ? const Locale('hi', 'IN')
      : const Locale('en', 'IN');
}
