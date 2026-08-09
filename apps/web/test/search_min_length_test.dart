@Tags(['unit', 'search'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/domain/models/entities.dart';
import 'package:asset_os/domain/models/unknown_customer.dart';
import 'package:asset_os/application/local_repository.dart';

import 'support/test_harness.dart';
import 'package:asset_os/domain/search/search_scope.dart';
import 'package:asset_os/domain/validation/text_rules.dart';

void main() {
  group('min-length text rules', () {
    test('meetsMinMeaningfulText gates empty and accepts single char', () {
      expect(meetsMinMeaningfulText(null), isFalse);
      expect(meetsMinMeaningfulText(''), isFalse);
      expect(meetsMinMeaningfulText('  '), isFalse);
      expect(meetsMinMeaningfulText('a'), isTrue);
      expect(meetsMinMeaningfulText('ab'), isTrue);
      expect(meetsMinMeaningfulText(null, allowEmpty: true), isTrue);
      expect(meetsMinMeaningfulText('  ', allowEmpty: true), isTrue);
      expect(meetsMinMeaningfulText('a', allowEmpty: true), isTrue);
    });
  });

  group('scoped search + validation', () {
    test('search below min length returns empty', () async {
      final LocalRepository repository = await bootRepo();
      final SearchResults results = await repository.search('');
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

    test('addInventory rejects empty name', () async {
      final LocalRepository repository = await bootRepo();
      expect(
        () => repository.addInventory(name: '  ', category: 'Tools', units: 1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('addInventory accepts single-character name', () async {
      final LocalRepository repository = await bootRepo();
      await repository.addInventory(name: 'ab', category: 'Tools', units: 1);
      final List<InventoryItem> items = await repository.listInventory();
      expect(items.any((InventoryItem i) => i.name == 'ab'), isTrue);
    });

    test('upsertCustomerByPhone rejects empty new name', () async {
      final LocalRepository repository = await bootRepo();
      expect(
        () => repository.upsertCustomerByPhone(
          phone: '9999988888',
          fallbackName: '  ',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('upsertCustomerByPhone accepts short new name', () async {
      final LocalRepository repository = await bootRepo();
      final Customer customer = await repository.upsertCustomerByPhone(
        phone: '9999988888',
        fallbackName: 'ab',
      );
      expect(customer.name, 'ab');
    });
  });
}
