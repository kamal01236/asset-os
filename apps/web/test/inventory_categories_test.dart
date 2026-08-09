@Tags(['unit', 'inventory'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/domain/inventory/inventory_categories.dart';
import 'package:asset_os/domain/models/entities.dart';

InventoryItem _item({
  required String id,
  required String category,
  ResourceType defaultItemKind = ResourceType.rental,
  String? name,
}) {
  return InventoryItem(
    id: id,
    name: name ?? 'Item $id',
    category: category,
    availableUnits: 1,
    totalUnits: 1,
    status: AssetStatus.available,
    qrCode: 'QR-$id',
    defaultItemKind: defaultItemKind,
  );
}

void main() {
  group('buildCategoryOptions', () {
    test('includes all template presets', () {
      final List<String> options = buildCategoryOptions(const <InventoryItem>[]);
      expect(
        options,
        containsAll(<String>[
          'Boutique',
          'Camera',
          'Event',
          'Farm',
          'Gym',
          'Library',
          'Office',
          'Parlour',
          'Tools',
        ]),
      );
      expect(kPresetInventoryCategories, isNotEmpty);
      for (final String preset in kPresetInventoryCategories) {
        expect(options, contains(preset));
      }
    });

    test('places General first and Other last', () {
      final List<String> options = buildCategoryOptions(<InventoryItem>[
        _item(id: '1', category: 'Sports'),
      ]);
      expect(options.first, kCategoryGeneral);
      expect(options.last, kCategoryOther);
      expect(options.where((String value) => value == kCategoryGeneral).length, 1);
      expect(options.where((String value) => value == kCategoryOther).length, 1);
    });

    test('merges distinct inventory categories and sorts named options', () {
      final List<String> options = buildCategoryOptions(<InventoryItem>[
        _item(id: '1', category: 'Sports'),
        _item(id: '2', category: 'sports'),
        _item(id: '3', category: 'Library'),
        _item(id: '4', category: '  Custom Gear  '),
        _item(id: '5', category: ''),
        _item(id: '6', category: '   '),
        _item(id: '7', category: kCategoryGeneral),
      ]);

      expect(options, contains('Sports'));
      expect(options, contains('sports'));
      expect(options, contains('Custom Gear'));
      expect(options.where((String c) => c == 'Library').length, 1);
      expect(options.first, kCategoryGeneral);

      final List<String> named = options
          .where(
            (String value) =>
                value != kCategoryOther && value != kCategoryGeneral,
          )
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
      expect(
        resolveSelectedCategory(
          selected: kCategoryGeneral,
          customText: 'ignored',
        ),
        kCategoryGeneral,
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

  group('defaultKindForCategory', () {
    test('General maps to sale kind', () {
      expect(
        defaultKindForCategory(kCategoryGeneral),
        ResourceType.sale,
      );
      expect(defaultKindForCategory('Camera'), ResourceType.rental);
    });
  });

  group('sortInventoryForOrderPicker', () {
    test('puts sale items first then sorts by name', () {
      final List<InventoryItem> sorted = sortInventoryForOrderPicker(<InventoryItem>[
        _item(id: '1', category: 'Camera', name: 'Zoom'),
        _item(
          id: '2',
          category: kCategoryGeneral,
          name: 'Cable',
          defaultItemKind: ResourceType.sale,
        ),
        _item(id: '3', category: 'Tools', name: 'Adapter'),
        _item(
          id: '4',
          category: kCategoryGeneral,
          name: 'Battery',
          defaultItemKind: ResourceType.sale,
        ),
      ]);
      expect(
        sorted.map((InventoryItem i) => i.name).toList(),
        <String>['Battery', 'Cable', 'Adapter', 'Zoom'],
      );
    });
  });
}
