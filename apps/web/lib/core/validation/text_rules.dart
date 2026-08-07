/// Minimum length for free-text identity/note fields (names, nicknames, notes).
const int kMinMeaningfulTextLength = 1;

/// Returns true when [value] meets the meaningful-text rule.
///
/// Empty/whitespace-only values are allowed only when [allowEmpty] is true
/// (e.g. optional notes). Non-empty values must be at least
/// [kMinMeaningfulTextLength] characters after trim.
bool meetsMinMeaningfulText(String? value, {bool allowEmpty = false}) {
  final String trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return allowEmpty;
  }
  return trimmed.length >= kMinMeaningfulTextLength;
}
