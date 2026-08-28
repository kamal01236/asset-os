/// Operator-entered payment reference (orders + loan repayment/disbursement).
const int kPaymentReferenceMaxLength = 15;

final RegExp _paymentReferencePattern = RegExp(r'^[A-Z0-9_-]+$');

/// Trims and uppercases [raw] for persistence.
String normalizePaymentReference(String raw) => raw.trim().toUpperCase();

/// Throws [ArgumentError] when [raw] is empty, too long, or has invalid chars.
void validatePaymentReference(String raw) {
  final String normalized = normalizePaymentReference(raw);
  if (normalized.isEmpty) {
    throw ArgumentError('Payment reference is required');
  }
  if (normalized.length > kPaymentReferenceMaxLength) {
    throw ArgumentError(
      'Payment reference must be at most $kPaymentReferenceMaxLength characters',
    );
  }
  if (!_paymentReferencePattern.hasMatch(normalized)) {
    throw ArgumentError(
      'Payment reference may only contain letters, digits, hyphen, and underscore',
    );
  }
}

/// Validates then returns the normalized reference.
String requirePaymentReference(String raw) {
  validatePaymentReference(raw);
  return normalizePaymentReference(raw);
}
