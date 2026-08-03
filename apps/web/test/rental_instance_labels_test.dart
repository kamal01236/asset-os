import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:asset_os/core/db/app_database.dart';
import 'package:asset_os/core/models/entities.dart';
import 'package:asset_os/core/repositories/local_repository.dart';

import 'support/test_harness.dart';

Future<InventoryItem> _seedDslr(LocalRepository repository) async {
  await repository.addInventory(
    name: 'DSLR',
    category: 'Camera',
    units: 3,
    rateAmount: 150000,
  );
  return (await repository.listInventory())
      .firstWhere((InventoryItem i) => i.name == 'DSLR');
}

Future<InventoryItem> _seedTripod(LocalRepository repository) async {
  await repository.addInventory(
    name: 'Tripod',
    category: 'Camera',
    units: 1,
    rateAmount: 20000,
  );
  return (await repository.listInventory())
      .firstWhere((InventoryItem i) => i.name == 'Tripod');
}

void main() {
  group('rental instance labels', () {
    test('createRental stores instance name and short code', () async {
      final LocalRepository repository = await bootRepo();
      final Customer customer = await ensureCustomer(repository);
      final InventoryItem novelType = await _seedDslr(repository);

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: novelType.id,
            instanceName: 'Harry Potter',
            shortCode: 'nov-042',
          ),
        ],
      );

      final Rental created = (await repository.listRentals()).first;
      expect(created.lines, hasLength(1));
      expect(created.lines.first.catalogName, novelType.name);
      expect(created.lines.first.instanceName, 'Harry Potter');
      expect(created.lines.first.shortCode, 'NOV-042');
      expect(
        created.lines.first.displayLabel,
        'DSLR · Harry Potter (NOV-042)',
      );
    });

    test('duplicate active short code is rejected', () async {
      final LocalRepository repository = await bootRepo();
      final Customer customer = await ensureCustomer(repository);
      final InventoryItem dslr = await _seedDslr(repository);
      final InventoryItem tripod = await _seedTripod(repository);

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: dslr.id,
            instanceName: 'Harry Potter',
            shortCode: 'NOV-042',
          ),
        ],
      );

      expect(
        () => repository.createRental(
          customer: customer,
          lines: <RentalLineInput>[
            RentalLineInput(
              itemId: tripod.id,
              instanceName: 'Another copy',
              shortCode: 'nov-042',
            ),
          ],
        ),
        throwsA(isA<DuplicateActiveShortCodeException>()),
      );
    });

    test('search finds rental by short code and instance name', () async {
      final LocalRepository repository = await bootRepo();
      final Customer customer = await ensureCustomer(repository);
      final InventoryItem dslr = await _seedDslr(repository);

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: dslr.id,
            instanceName: 'Harry Potter',
            shortCode: 'NOV-042',
          ),
        ],
      );

      final SearchResults byCode = await repository.search('nov-042');
      expect(byCode.currentRentals, isNotEmpty);
      expect(byCode.currentRentals.first.lines.first.shortCode, 'NOV-042');

      final SearchResults byName = await repository.search('harry');
      expect(byName.currentRentals, isNotEmpty);
      expect(byName.currentRentals.first.lines.first.instanceName, 'Harry Potter');
    });

    test('return frees short code for reuse', () async {
      final LocalRepository repository = await bootRepo();
      final Customer customer = await ensureCustomer(repository);
      final InventoryItem dslr = await _seedDslr(repository);

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: dslr.id,
            instanceName: 'Harry Potter',
            shortCode: 'NOV-042',
          ),
        ],
      );
      final String rentalId = (await repository.listRentals()).first.id;
      await repository.returnRental(rentalId);

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: dslr.id,
            instanceName: 'Chamber of Secrets',
            shortCode: 'NOV-042',
          ),
        ],
      );

      final List<Rental> active = (await repository.listRentals())
          .where((Rental r) => r.isActive)
          .toList();
      expect(active, hasLength(1));
      expect(
        active.any(
          (Rental r) =>
              r.lines.any((RentalLine l) => l.instanceName == 'Chamber of Secrets'),
        ),
        isTrue,
      );
    });

    test('schema v6 tables include line id primary key', () async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      expect(db.schemaVersion, 9);

      await db.into(db.customers).insert(
        CustomersCompanion.insert(
          id: 'CUS-X',
          name: 'Test',
          phone: '1111111111',
          qrCode: 'customer:x',
        ),
      );
      await db.into(db.inventoryItems).insert(
        InventoryItemsCompanion.insert(
          id: 'INV-X',
          name: 'Novel',
          category: 'Books',
          availableUnits: 5,
          totalUnits: 5,
          status: AssetStatus.available.name,
          qrCode: 'inventory:x',
        ),
      );
      await db.into(db.rentals).insert(
        RentalsCompanion.insert(
          id: 'REN-X',
          customerId: 'CUS-X',
          startedAt: DateTime(2026, 8, 1),
          dueAt: Value<DateTime?>(DateTime(2026, 8, 4)),
          qrCode: 'rental:x',
        ),
      );
      await db.into(db.rentalItems).insert(
        RentalItemsCompanion.insert(
          id: 'RLI-X-1',
          rentalId: 'REN-X',
          itemId: 'INV-X',
          instanceName: const Value<String>('Novel'),
          shortCode: const Value<String>('LEGACY-REN-X-INV-X'),
        ),
      );

      final RentalItemRow row = await (db.select(db.rentalItems)
            ..where((t) => t.rentalId.equals('REN-X')))
          .getSingle();
      expect(row.id, 'RLI-X-1');
      expect(row.instanceName, 'Novel');
      expect(row.shortCode, 'LEGACY-REN-X-INV-X');
      expect(row.returnedAt, isNull);
    });

    test('legacy snapshot without lines still imports', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        LocalRepository.snapshotKey: AppDataSnapshot(
          customers: const <Customer>[
            Customer(
              id: 'CUS-L1',
              name: 'Legacy User',
              phone: '5555555555',
              isTrusted: false,
              qrCode: 'customer:l1',
            ),
          ],
          inventory: const <InventoryItem>[
            InventoryItem(
              id: 'INV-L1',
              name: 'Novel',
              category: 'Books',
              availableUnits: 10,
              totalUnits: 10,
              status: AssetStatus.available,
              qrCode: 'inventory:l1',
            ),
          ],
          rentals: <Rental>[
            Rental.fromJson(<String, dynamic>{
              'id': 'REN-L1',
              'customerId': 'CUS-L1',
              'itemIds': <String>['INV-L1'],
              'startedAt': DateTime(2026, 7, 1).toIso8601String(),
              'dueAt': DateTime(2026, 7, 4).toIso8601String(),
              'returnedAt': null,
              'timeline': <Map<String, dynamic>>[],
              'qrCode': 'rental:l1',
              'nickname': null,
            }),
          ],
        ).encode(),
      });
      final SharedPreferences preferences = await SharedPreferences.getInstance();
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final LocalRepository repository = LocalRepository(db, preferences);
      await repository.initialize(seedDemo: false);

      final List<Rental> rentals = await repository.listRentals();
      expect(rentals, hasLength(1));
      expect(rentals.first.lines, hasLength(1));
      expect(rentals.first.lines.first.itemId, 'INV-L1');
      expect(rentals.first.lines.first.shortCode, isNotEmpty);
    });
  });
}
