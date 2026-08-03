import '../models/entities.dart';
import '../templates/industry_templates.dart';

/// Sentinel value for the "Other" category option (custom text field).
const String kCategoryOther = '__other__';

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

/// Dropdown options = template presets ∪ distinct inventory categories, then Other.
///
/// [kCategoryOther] is always last. Named options are sorted case-insensitively
/// with no duplicates.
List<String> buildCategoryOptions(List<InventoryItem> inventory) {
  final Set<String> categories = <String>{...kPresetInventoryCategories};
  for (final InventoryItem item in inventory) {
    final String category = item.category.trim();
    if (category.isNotEmpty) {
      categories.add(category);
    }
  }
  final List<String> options = categories.toList()
    ..sort((String a, String b) => a.toLowerCase().compareTo(b.toLowerCase()));
  options.add(kCategoryOther);
  return options;
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
