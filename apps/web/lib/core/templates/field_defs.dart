import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../models/entities.dart';

bool _isHindi(Locale locale) => locale.languageCode == 'hi';

/// Value kinds for dynamic catalog fields (JSON on [InventoryItem.metadata]).
enum FieldValueType {
  text,
  number,
  money,
  bool,
  date,
}

/// Built-in field definition (id + type + resource scope + en/hi labels).
class FieldDef {
  const FieldDef({
    required this.id,
    required this.type,
    required this.labelEn,
    this.labelHi = '',
    this.resourceTypes,
  });

  final String id;
  final FieldValueType type;
  final String labelEn;
  final String labelHi;

  /// Null means all resource types (`*`).
  final List<ResourceType>? resourceTypes;

  bool appliesTo(ResourceType type) {
    final List<ResourceType>? allowed = resourceTypes;
    if (allowed == null || allowed.isEmpty) {
      return true;
    }
    return allowed.contains(type);
  }

  String localizedLabel(Locale locale) =>
      _isHindi(locale) && labelHi.isNotEmpty ? labelHi : labelEn;
}

/// Prefs key for comma-separated extra field ids from the active template.
const String kExtraFieldIdsPrefsKey = 'asset_os_extra_field_ids';

const String kFieldEstimatedDuration = 'estimated_duration';
const String kFieldMaxVisits = 'max_visits';
const String kFieldBarcode = 'barcode';

/// Starter defs for values that are not already first-class columns.
const List<FieldDef> kFieldDefs = <FieldDef>[
  FieldDef(
    id: kFieldEstimatedDuration,
    type: FieldValueType.number,
    labelEn: 'Estimated duration (min)',
    labelHi: 'अनुमानित अवधि (मिनट)',
    resourceTypes: <ResourceType>[
      ResourceType.service,
      ResourceType.job,
    ],
  ),
  FieldDef(
    id: kFieldMaxVisits,
    type: FieldValueType.number,
    labelEn: 'Max visits',
    labelHi: 'अधिकतम विज़िट',
    resourceTypes: <ResourceType>[
      ResourceType.membership,
      ResourceType.subscription,
    ],
  ),
  FieldDef(
    id: kFieldBarcode,
    type: FieldValueType.text,
    labelEn: 'Barcode',
    labelHi: 'बारकोड',
    resourceTypes: <ResourceType>[
      ResourceType.rental,
      ResourceType.sale,
      ResourceType.loan,
    ],
  ),
];

FieldDef? fieldDefById(String? id) {
  if (id == null || id.isEmpty) {
    return null;
  }
  for (final FieldDef def in kFieldDefs) {
    if (def.id == id) {
      return def;
    }
  }
  return null;
}

List<String> parseExtraFieldIds(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return const <String>[];
  }
  final List<String> out = <String>[];
  final Set<String> seen = <String>{};
  for (final String part in raw.split(',')) {
    final String id = part.trim();
    if (id.isEmpty || fieldDefById(id) == null) {
      continue;
    }
    if (seen.add(id)) {
      out.add(id);
    }
  }
  return out;
}

String encodeExtraFieldIds(Iterable<String> ids) {
  final List<String> ordered = <String>[];
  final Set<String> seen = <String>{};
  for (final String id in ids) {
    if (fieldDefById(id) == null) {
      continue;
    }
    if (seen.add(id)) {
      ordered.add(id);
    }
  }
  return ordered.join(',');
}

/// Fields shown on add/edit for [type].
///
/// When [templateFieldIds] is non-empty, only those ids (that apply) are used;
/// otherwise every registry def that applies to [type].
List<FieldDef> resolveExtraFields({
  required ResourceType type,
  List<String>? templateFieldIds,
}) {
  final List<String>? preferred = templateFieldIds;
  if (preferred != null && preferred.isNotEmpty) {
    final List<FieldDef> selected = <FieldDef>[];
    for (final String id in preferred) {
      final FieldDef? def = fieldDefById(id);
      if (def != null && def.appliesTo(type)) {
        selected.add(def);
      }
    }
    return selected;
  }
  return kFieldDefs.where((FieldDef f) => f.appliesTo(type)).toList();
}

/// Encode metadata map for Drift text column; empty → null.
String? encodeMetadata(Map<String, Object?> values) {
  if (values.isEmpty) {
    return null;
  }
  final Map<String, Object?> cleaned = <String, Object?>{};
  for (final MapEntry<String, Object?> entry in values.entries) {
    final Object? value = entry.value;
    if (value == null) {
      continue;
    }
    if (value is String && value.trim().isEmpty) {
      continue;
    }
    cleaned[entry.key] = value;
  }
  if (cleaned.isEmpty) {
    return null;
  }
  return jsonEncode(cleaned);
}

/// Decode metadata JSON; invalid / empty → empty map.
Map<String, Object?> decodeMetadata(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return <String, Object?>{};
  }
  try {
    final Object? decoded = jsonDecode(raw);
    if (decoded is Map) {
      return Map<String, Object?>.from(decoded);
    }
  } catch (_) {
    // Ignore corrupt JSON; treat as empty.
  }
  return <String, Object?>{};
}

/// Format a metadata value for read-only detail rows.
String formatMetadataValue(FieldDef def, Object? value) {
  if (value == null) {
    return '';
  }
  switch (def.type) {
    case FieldValueType.bool:
      return value == true || value == 1 || value == 'true' ? 'Yes' : 'No';
    case FieldValueType.money:
      final int paise = value is int
          ? value
          : value is num
              ? value.round()
              : int.tryParse('$value') ?? 0;
      final String rupees = (paise / 100).toStringAsFixed(
        paise % 100 == 0 ? 0 : 2,
      );
      return '₹$rupees';
    case FieldValueType.number:
    case FieldValueType.text:
    case FieldValueType.date:
      return '$value';
  }
}
