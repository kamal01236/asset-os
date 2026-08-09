import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n_ext.dart';
import '../pricing/rental_pricing.dart';
import '../templates/field_defs.dart';

/// Controllers + values for dynamic [FieldDef] inputs on add/edit resource.
class DynamicFieldEditors {
  DynamicFieldEditors();

  final Map<String, TextEditingController> _text = <String, TextEditingController>{};
  final Map<String, bool> _bools = <String, bool>{};

  void syncFields(List<FieldDef> fields, Map<String, Object?> values) {
    final Set<String> keep = fields.map((FieldDef f) => f.id).toSet();
    for (final String id in _text.keys.toList()) {
      if (!keep.contains(id)) {
        _text.remove(id)?.dispose();
      }
    }
    _bools.removeWhere((String id, _) => !keep.contains(id));

    for (final FieldDef field in fields) {
      final Object? raw = values[field.id];
      switch (field.type) {
        case FieldValueType.bool:
          _bools[field.id] = raw == true || raw == 1 || raw == 'true';
        case FieldValueType.money:
          final int paise = raw is int
              ? raw
              : raw is num
                  ? raw.round()
                  : int.tryParse('$raw') ?? 0;
          _controller(field.id).text = paiseToRupeesField(paise);
        case FieldValueType.number:
        case FieldValueType.text:
        case FieldValueType.date:
          _controller(field.id).text = raw == null ? '' : '$raw';
      }
    }
  }

  TextEditingController _controller(String id) {
    return _text.putIfAbsent(id, TextEditingController.new);
  }

  bool boolValue(String id) => _bools[id] ?? false;

  void setBool(String id, bool value) => _bools[id] = value;

  Map<String, Object?> collect(List<FieldDef> fields) {
    final Map<String, Object?> out = <String, Object?>{};
    for (final FieldDef field in fields) {
      switch (field.type) {
        case FieldValueType.bool:
          out[field.id] = boolValue(field.id);
        case FieldValueType.money:
          out[field.id] = parseRupeesToPaise(_controller(field.id).text);
        case FieldValueType.number:
          final String raw = _controller(field.id).text.trim();
          if (raw.isEmpty) {
            continue;
          }
          final num? parsed = num.tryParse(raw);
          if (parsed != null) {
            out[field.id] = parsed is int ? parsed : parsed.round();
          }
        case FieldValueType.text:
        case FieldValueType.date:
          final String raw = _controller(field.id).text.trim();
          if (raw.isNotEmpty) {
            out[field.id] = raw;
          }
      }
    }
    return out;
  }

  void dispose() {
    for (final TextEditingController c in _text.values) {
      c.dispose();
    }
    _text.clear();
    _bools.clear();
  }
}

/// Form rows for [fields] bound to [editors].
List<Widget> buildDynamicFieldInputs({
  required BuildContext context,
  required List<FieldDef> fields,
  required DynamicFieldEditors editors,
  required VoidCallback onChanged,
}) {
  if (fields.isEmpty) {
    return const <Widget>[];
  }
  final Locale locale = Localizations.localeOf(context);
  final AppLocalizations l10n = context.l10n;
  final List<Widget> children = <Widget>[
    const SizedBox(height: 8),
    Text(
      l10n.extraFieldsSectionTitle,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    ),
    const SizedBox(height: 8),
  ];
  for (final FieldDef field in fields) {
    children.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _fieldInput(
          field: field,
          locale: locale,
          editors: editors,
          onChanged: onChanged,
        ),
      ),
    );
  }
  return children;
}

Widget _fieldInput({
  required FieldDef field,
  required Locale locale,
  required DynamicFieldEditors editors,
  required VoidCallback onChanged,
}) {
  final String label = field.localizedLabel(locale);
  switch (field.type) {
    case FieldValueType.bool:
      return SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: editors.boolValue(field.id),
        title: Text(label),
        onChanged: (bool value) {
          editors.setBool(field.id, value);
          onChanged();
        },
      );
    case FieldValueType.money:
      return TextField(
        controller: editors._controller(field.id),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
        ],
      );
    case FieldValueType.number:
      return TextField(
        controller: editors._controller(field.id),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
        ],
      );
    case FieldValueType.date:
      return TextField(
        controller: editors._controller(field.id),
        decoration: InputDecoration(
          labelText: label,
          hintText: 'YYYY-MM-DD',
        ),
      );
    case FieldValueType.text:
      return TextField(
        controller: editors._controller(field.id),
        decoration: InputDecoration(labelText: label),
      );
  }
}
