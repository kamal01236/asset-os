import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/core/models/entities.dart';
import 'package:asset_os/core/models/unknown_customer.dart';
import 'package:asset_os/core/repositories/local_repository.dart';

import 'support/test_harness.dart';
import 'package:asset_os/core/search/search_scope.dart';
import 'package:asset_os/core/validation/text_rules.dart';

void main() {
  group('min-length text rules', () {
    test('meetsMinMeaningfulText gates empty and short values', () {
      expect(meetsMinMeaningfulText(null), isFalse);
      expect(meetsMinMeaningfulText(''), isFalse);
      expect(meetsMinMeaningfulText('ab'), isFalse);
      expect(meetsMinMeaningfulText('abc'), isTrue);
      expect(meetsMinMeaningfulText(null, allowEmpty: true), isTrue);
      expect(meetsMinMeaningfulText('  ', allowEmpty: true), isTrue);
      expect(meetsMinMeaningfulText('ab', allowEmpty: true), isFalse);
    });
  });

  group('scoped search + validation', () {
    test('search below min length returns empty', () async {
      final LocalRepository repository = await bootRepo();
      final SearchResults results = await repository.search('ab');
      expect(results.customers, isEmpty);
      expect(results.currentRentals, isEmpty);
      expect(results.previousRentals, isEmpty);
      expect(results.inventory, isEmpty);
    });

    test('customers scope matches name and ignores inventory-only hits', () async {
      final LocalRepository repository = await bootRepo();
      await ensureCustomer(repository);
      await repository.addInventory(name: 'DSLR', category: 'Camera', units: 1);
      final SearchResults byName = await repository.search(
        'pri',
        scope: SearchScope.customers,
      );
      expect(byName.customers.any((c) => c.name.contains('Priya')), isTrue);
      expect(byName.inventory, isEmpty);
      expect(byName.currentRentals, isEmpty);

      final SearchResults inventoryOnly = await repository.search(
        'dsl',
        scope: SearchScope.customers,
      );
      expect(inventoryOnly.customers, isEmpty);
      expect(inventoryOnly.inventory, isEmpty);
    });

    test('customers scope surfaces nickname matches on Unknown', () async {
      final LocalRepository repository = await bootRepo();
      final Customer unknown = await repository.ensureUnknownCustomer();
      await repository.addInventory(name: 'Body Cam', category: 'Camera', units: 2);
      final InventoryItem item = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.availableUnits > 0);

      await repository.createRental(
        customer: unknown,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: item.id,
            instanceName: 'Body unit',
            shortCode: 'NICK-01',
          ),
        ],
        nickname: 'Raju',
      );

      final SearchResults found = await repository.search(
        'raj',
        scope: SearchScope.customers,
      );
      expect(found.customers.any((c) => c.id == kUnknownCustomerId), isTrue);
      expect(found.inventory, isEmpty);
    });

    test('inventory scope ignores customers', () async {
      final LocalRepository repository = await bootRepo();
      await ensureCustomer(repository);
      await repository.addInventory(name: 'DSLR', category: 'Camera', units: 1);
      final SearchResults results = await repository.search(
        'pri',
        scope: SearchScope.inventory,
      );
      expect(results.customers, isEmpty);
      expect(results.currentRentals, isEmpty);
      expect(results.inventory, isEmpty);

      final SearchResults byItem = await repository.search(
        'dsl',
        scope: SearchScope.inventory,
      );
      expect(byItem.inventory, isNotEmpty);
      expect(byItem.customers, isEmpty);
    });

    test('addInventory rejects short name', () async {
      final LocalRepository repository = await bootRepo();
      expect(
        () => repository.addInventory(name: 'ab', category: 'Tools', units: 1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('upsertCustomerByPhone rejects short new name', () async {
      final LocalRepository repository = await bootRepo();
      expect(
        () => repository.upsertCustomerByPhone(
          phone: '9999988888',
          fallbackName: 'ab',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
