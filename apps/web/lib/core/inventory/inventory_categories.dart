import '../models/entities.dart';
import '../templates/industry_templates.dart';

/// Sentinel value for the "Other" category option (custom text field).
const String kCategoryOther = '__other__';

/// First-class General (non-rental) category; always top of the dropdown.
const String kCategoryGeneral = 'General';

/// Unique category labels from industry template seed items.
final List<String> kPresetInventoryCategories = _collectPresetCategories();

List<String> _collectPresetCategories() {
  final Set<String> categories = <String>{};
  for (final IndustryTemplate template in kIndustryTemplates) {
    for (final TemplateInventoryItem item in template.items) {
      final String category = item.category.trim();
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
List<String> buildCategoryOptions(List<InventoryItem> inventory) {
  final Set<String> categories = <String>{...kPresetInventoryCategories};
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

/// Sort inventory for New Order picker: general items first, then by name.
List<InventoryItem> sortInventoryForOrderPicker(List<InventoryItem> items) {
  final List<InventoryItem> sorted = List<InventoryItem>.of(items);
  sorted.sort((InventoryItem a, InventoryItem b) {
    final int kindCmp = (a.isGeneral ? 0 : 1).compareTo(b.isGeneral ? 0 : 1);
    if (kindCmp != 0) {
      return kindCmp;
    }
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return sorted;
}
