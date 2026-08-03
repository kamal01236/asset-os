import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/core/inventory/inventory_categories.dart';
import 'package:asset_os/core/models/entities.dart';

InventoryItem _item({
  required String id,
  required String category,
}) {
  return InventoryItem(
    id: id,
    name: 'Item $id',
    category: category,
    availableUnits: 1,
    totalUnits: 1,
    status: AssetStatus.available,
    qrCode: 'QR-$id',
  );
}

void main() {
  group('buildCategoryOptions', () {
    test('includes all template presets', () {
      final List<String> options = buildCategoryOptions(const <InventoryItem>[]);
      expect(
        options,
        containsAll(<String>[
          'Camera',
          'Event',
          'Farm',
          'Library',
          'Office',
          'Tools',
        ]),
      );
      expect(kPresetInventoryCategories, isNotEmpty);
      for (final String preset in kPresetInventoryCategories) {
        expect(options, contains(preset));
      }
    });

    test('merges distinct inventory categories and sorts named options', () {
      final List<String> options = buildCategoryOptions(<InventoryItem>[
        _item(id: '1', category: 'Sports'),
        _item(id: '2', category: 'sports'),
        _item(id: '3', category: 'Library'),
        _item(id: '4', category: '  Custom Gear  '),
        _item(id: '5', category: ''),
        _item(id: '6', category: '   '),
      ]);

      expect(options, contains('Sports'));
      expect(options, contains('sports'));
      expect(options, contains('Custom Gear'));
      expect(options.where((String c) => c == 'Library').length, 1);

      final List<String> named = options
          .where((String value) => value != kCategoryOther)
          .toList();
      final List<String> sorted = List<String>.of(named)
        ..sort((String a, String b) => a.toLowerCase().compareTo(b.toLowerCase()));
      expect(named, sorted);
    });

    test('places Other sentinel last and only once', () {
      final List<String> options = buildCategoryOptions(<InventoryItem>[
        _item(id: '1', category: 'Sports'),
      ]);
      expect(options.last, kCategoryOther);
      expect(options.where((String value) => value == kCategoryOther).length, 1);
      expect(options.contains(kCategoryOther), isTrue);
    });

    test('does not duplicate presets already present in inventory', () {
      final List<String> options = buildCategoryOptions(<InventoryItem>[
        _item(id: '1', category: 'Camera'),
        _item(id: '2', category: 'Camera'),
      ]);
      expect(options.where((String value) => value == 'Camera').length, 1);
    });
  });

  group('resolveSelectedCategory', () {
    test('uses selected label for named options', () {
      expect(
        resolveSelectedCategory(selected: 'Library', customText: 'ignored'),
        'Library',
      );
    });

    test('uses custom text for Other or null selection', () {
      expect(
        resolveSelectedCategory(
          selected: kCategoryOther,
          customText: '  Custom Gear  ',
        ),
        'Custom Gear',
      );
      expect(
        resolveSelectedCategory(selected: null, customText: 'Fallback'),
        'Fallback',
      );
    });
  });
}
