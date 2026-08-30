/// Optional free-text note on transactional money (orders + loan cash entries).
const int kMoneyNoteMaxLength = 20;

/// Alias kept for call sites still using the old name.
const int kPaymentReferenceMaxLength = kMoneyNoteMaxLength;

/// Trims [raw]; empty / whitespace-only → `null`. Stored as entered (no uppercase).
String? normalizeMoneyNote(String? raw) {
  final String trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

/// Empty OK; non-empty length must be ≤ [kMoneyNoteMaxLength]. No charset rule.
void validateMoneyNote(String? raw) {
  final String? normalized = normalizeMoneyNote(raw);
  if (normalized == null) {
    return;
  }
  if (normalized.length > kMoneyNoteMaxLength) {
    throw ArgumentError(
      'Note must be at most $kMoneyNoteMaxLength characters',
    );
  }
}

/// Validates then returns the normalized note (`null` when empty).
String? optionalMoneyNote(String? raw) {
  validateMoneyNote(raw);
  return normalizeMoneyNote(raw);
}

/// Trims [raw] for persistence (legacy name; no longer uppercases).
String normalizePaymentReference(String raw) =>
    normalizeMoneyNote(raw) ?? '';

/// Validates optional money note (legacy name; empty is allowed).
void validatePaymentReference(String? raw) => validateMoneyNote(raw);

/// Validates and returns normalized note, or `null` when empty (legacy name).
String? requirePaymentReference(String? raw) => optionalMoneyNote(raw);
