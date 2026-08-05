import 'package:flutter/widgets.dart';

import '../models/entities.dart';
import '../templates/industry_templates.dart';

/// Sentinel value for the "Other" category option (custom text field).
const String kCategoryOther = '__other__';

/// First-class General (non-rental) category; always top of the dropdown.
const String kCategoryGeneral = 'General';

/// Unique English category labels from industry template seed items.
final List<String> kPresetInventoryCategories =
    presetInventoryCategories(const Locale('en'));

/// Unique category labels from templates for [locale] (Hindi when `hi`).
List<String> presetInventoryCategories(Locale locale) {
  final Set<String> categories = <String>{};
  for (final IndustryTemplate template in kIndustryTemplates) {
    for (final TemplateInventoryItem item in template.items) {
      final String category = item.localizedCategory(locale).trim();
      if (category.isNotEmpty) {
        categories.add(category);
      }
    }
  }
  final List<String> sorted = categories.toList()..sort();
  return List<String>.unmodifiable(sorted);
}

/// Dropdown options = General ∪ template presets ∪ inventory categories, then Other.
///
/// [kCategoryGeneral] is always first. [kCategoryOther] is always last. Other named
/// options are sorted case-insensitively with no duplicates.
/// Template presets follow [locale] so Hindi UI matches imported Hindi categories.
List<String> buildCategoryOptions(
  List<InventoryItem> inventory, {
  Locale locale = const Locale('en'),
}) {
  final Set<String> categories = <String>{
    ...presetInventoryCategories(locale),
  };
  for (final InventoryItem item in inventory) {
    final String category = item.category.trim();
    if (category.isNotEmpty) {
      categories.add(category);
    }
  }
  categories.remove(kCategoryGeneral);
  final List<String> named = categories.toList()
    ..sort((String a, String b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return <String>[
    kCategoryGeneral,
    ...named,
    kCategoryOther,
  ];
}

/// Resolves the category string to persist from dropdown + optional custom field.
String resolveSelectedCategory({
  required String? selected,
  required String customText,
}) {
  if (selected == null || selected == kCategoryOther) {
    return customText.trim();
  }
  return selected.trim();
}

/// Default catalog kind implied by the selected category option.
InventoryItemKind defaultKindForCategory(String? selectedCategory) {
  if (selectedCategory == kCategoryGeneral) {
    return InventoryItemKind.general;
  }
  return InventoryItemKind.rental;
}

/// Sort inventory for New Order picker: sell/job catalog first, then by name.
List<InventoryItem> sortInventoryForOrderPicker(List<InventoryItem> items) {
  final List<InventoryItem> sorted = List<InventoryItem>.of(items);
  sorted.sort((InventoryItem a, InventoryItem b) {
    int kindRank(InventoryItem item) {
      switch (item.defaultItemKind) {
        case InventoryItemKind.general:
          return 0;
        case InventoryItemKind.job:
          return 1;
        case InventoryItemKind.rental:
          return 2;
      }
    }

    final int kindCmp = kindRank(a).compareTo(kindRank(b));
    if (kindCmp != 0) {
      return kindCmp;
    }
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return sorted;
}
