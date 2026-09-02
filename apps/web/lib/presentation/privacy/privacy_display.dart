import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/privacy/privacy_settings.dart';
import '../../application/providers/app_providers.dart';
import '../../domain/pricing/rental_pricing.dart';

/// Central masking for list/detail surfaces. Do not use in settlement / payment flows.
String displayMoney(
  BuildContext context,
  WidgetRef ref,
  int paise, {
  String currencyCode = 'INR',
}) {
  final PrivacySettings settings = ref.watch(privacySettingsProvider);
  if (settings.hidePrices) {
    return kMaskedMoneyDisplay;
  }
  return formatMoney(paise, currencyCode: currencyCode);
}

String displayPhone(BuildContext context, WidgetRef ref, String phone) {
  final PrivacySettings settings = ref.watch(privacySettingsProvider);
  if (settings.hidePhoneNumbers) {
    return maskPhone(phone);
  }
  return phone;
}

/// Masked money placeholder shown when hide-prices is on.
const String kMaskedMoneyDisplay = '••••';

/// Partial phone mask: `98•••••321` style.
String maskPhone(String phone) {
  final String digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length <= 4) {
    return kMaskedMoneyDisplay;
  }
  if (digits.length <= 6) {
    return '${digits.substring(0, 2)}••••';
  }
  return '${digits.substring(0, 2)}•••••${digits.substring(digits.length - 3)}';
}
