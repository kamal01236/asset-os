import 'package:flutter/material.dart';

import '../../domain/inventory/inventory_categories.dart';

/// Category dropdown with General on top and Other revealing a custom text field.
class CategoryPickerField extends StatelessWidget {
  const CategoryPickerField({
    required this.options,
    required this.selectedValue,
    required this.customController,
    required this.onSelected,
    required this.categoryLabel,
    required this.otherLabel,
    required this.customLabel,
    this.generalLabel,
    this.customHint,
    this.fieldKeyPrefix = 'category',
    super.key,
  });

  final List<String> options;
  final String? selectedValue;
  final TextEditingController customController;
  final ValueChanged<String?> onSelected;
  final String categoryLabel;
  final String otherLabel;
  final String customLabel;
  /// Localized label for [kCategoryGeneral]; falls back to the stored value.
  final String? generalLabel;
  final String? customHint;
  final String fieldKeyPrefix;

  bool get _isOther => selectedValue == kCategoryOther;

  String _displayLabel(String value) {
    if (value == kCategoryOther) {
      return otherLabel;
    }
    if (value == kCategoryGeneral && generalLabel != null) {
      return generalLabel!;
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final String? value =
        selectedValue != null && options.contains(selectedValue)
            ? selectedValue
            : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DropdownButtonFormField<String>(
          key: ValueKey<String>('$fieldKeyPrefix-$value'),
          initialValue: value,
          decoration: InputDecoration(labelText: categoryLabel),
          items: options
              .map(
                (String option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(_displayLabel(option)),
                ),
              )
              .toList(),
          onChanged: onSelected,
        ),
        if (_isOther) ...<Widget>[
          const SizedBox(height: 8),
          TextField(
            controller: customController,
            decoration: InputDecoration(
              labelText: customLabel,
              hintText: customHint,
            ),
          ),
        ],
      ],
    );
  }
}
