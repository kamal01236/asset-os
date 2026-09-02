import 'dart:math';

import 'verification_models.dart';

final Random _otpRandom = Random();

/// Generates a 6-digit numeric offline OTP (no network).
String generateOfflineOtp() {
  return (_otpRandom.nextInt(900000) + 100000).toString();
}

/// Returns true when [input] matches the stored operator PIN.
bool validatePin(String input, String? storedPin) {
  if (storedPin == null || storedPin.isEmpty) {
    return false;
  }
  return input.trim() == storedPin.trim();
}

/// All [requiredItems] must be checked true for pass.
bool validateChecklist(
  Map<String, bool> results,
  List<String> requiredItems,
) {
  if (requiredItems.isEmpty) {
    return true;
  }
  for (final String item in requiredItems) {
    if (results[item] != true) {
      return false;
    }
  }
  return true;
}

/// Builds an immutable verification result for persistence.
VerificationRecord buildVerificationRecord({
  required VerificationMethod method,
  String? code,
  Map<String, bool>? checklistResults,
  DateTime? verifiedAt,
  List<String> mediaIds = const <String>[],
}) {
  return VerificationRecord(
    method: method,
    code: code,
    checklistResults: checklistResults,
    verifiedAt: verifiedAt ?? DateTime.now(),
    mediaIds: mediaIds,
  );
}
