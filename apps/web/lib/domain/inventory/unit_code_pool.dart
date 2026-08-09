/// Normalize a unit-code prefix for storage and pool generation.
String normalizeUnitCodePrefix(String? raw) {
  final String trimmed = (raw ?? '').trim().toUpperCase();
  if (trimmed.isEmpty) {
    return '';
  }
  return trimmed.replaceAll(RegExp(r'[^A-Z0-9\-_]'), '');
}

/// Virtual short codes `PREFIX-001…PREFIX-N` (zero-pad from digit width of [total]).
List<String> generateUnitPool({
  required String prefix,
  required int total,
}) {
  final String normalized = normalizeUnitCodePrefix(prefix);
  if (normalized.isEmpty || total < 1) {
    return const <String>[];
  }
  final int width = '$total'.length;
  return List<String>.generate(total, (int i) {
    final String n = (i + 1).toString().padLeft(width, '0');
    return '$normalized-$n';
  });
}

/// Occupancy row for a single unit code in a catalog pool.
class UnitOccupancyRow {
  const UnitOccupancyRow({
    required this.code,
    required this.occupied,
    this.customerName,
    this.customerId,
    this.rentalId,
    this.instanceName,
  });

  final String code;
  final bool occupied;
  final String? customerName;
  final String? customerId;
  final String? rentalId;
  final String? instanceName;
}
