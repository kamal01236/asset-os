import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Digits-only phone suitable for `wa.me`.
///
/// Strips non-digits. If the result is exactly 10 digits, prefixes
/// [countryCode] (default `91`).
String normalizeWhatsAppPhone(
  String raw, {
  String countryCode = '91',
}) {
  final String digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) {
    return '';
  }
  final String cc = countryCode.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 10 && cc.isNotEmpty) {
    return '$cc$digits';
  }
  return digits;
}

/// Builds `https://wa.me/<digits>?text=<urlencoded>`.
Uri buildWhatsAppShareUri({
  required String phoneDigits,
  required String message,
  String countryCode = '91',
}) {
  final String e164 = normalizeWhatsAppPhone(
    phoneDigits,
    countryCode: countryCode,
  );
  return Uri.https('wa.me', '/$e164', <String, String>{'text': message});
}

/// Result of attempting to open WhatsApp (or clipboard fallback).
enum WhatsAppShareOutcome {
  launched,
  copiedToClipboard,
  missingPhone,
}

/// Opens WhatsApp to [phoneDigits] with [message]; on failure copies to clipboard.
Future<WhatsAppShareOutcome> shareReportToSelf({
  required String phoneDigits,
  required String message,
  String countryCode = '91',
  Future<bool> Function(Uri uri, {LaunchMode mode})? launch,
  Future<void> Function(ClipboardData data)? setClipboard,
}) async {
  final String e164 = normalizeWhatsAppPhone(
    phoneDigits,
    countryCode: countryCode,
  );
  if (e164.isEmpty || e164.length < 10) {
    return WhatsAppShareOutcome.missingPhone;
  }

  final Uri uri = buildWhatsAppShareUri(
    phoneDigits: e164,
    message: message,
    countryCode: countryCode,
  );

  final Future<bool> Function(Uri uri, {LaunchMode mode}) launcher =
      launch ??
      (Uri u, {LaunchMode mode = LaunchMode.platformDefault}) =>
          launchUrl(u, mode: mode);
  final Future<void> Function(ClipboardData data) clipboard =
      setClipboard ?? Clipboard.setData;

  try {
    final bool ok = await launcher(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (ok) {
      return WhatsAppShareOutcome.launched;
    }
  } catch (_) {
    // Fall through to clipboard.
  }

  await clipboard(ClipboardData(text: message));
  return WhatsAppShareOutcome.copiedToClipboard;
}
