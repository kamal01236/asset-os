import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:asset_os/core/db/app_database.dart';
import 'package:asset_os/core/models/entities.dart';
import 'package:asset_os/core/models/unknown_customer.dart';
import 'package:asset_os/core/repositories/local_repository.dart';

Future<LocalRepository> _bootRepo() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  final AppDatabase db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final LocalRepository repository = LocalRepository(db, preferences);
  await repository.initialize();
  return repository;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('Unknown customer', () {
    test('initialize ensures CUS-UNKNOWN sentinel', () async {
      final LocalRepository repository = await _bootRepo();
      final List<Customer> customers = await repository.listCustomers();
      final Customer unknown =
          customers.firstWhere((c) => c.id == kUnknownCustomerId);
      expect(unknown.phone, kUnknownCustomerPhone);
      expect(unknown.name, kUnknownCustomerName);
      expect(customers.any((c) => c.id == kLegacySelfCustomerId), isFalse);
    });

    test('createRental to Unknown without nickname succeeds', () async {
      final LocalRepository repository = await _bootRepo();
      final Customer unknown = await repository.ensureUnknownCustomer();
      final List<InventoryItem> inventory = await repository.listInventory();
      final InventoryItem item =
          inventory.firstWhere((i) => i.availableUnits > 0);

      await repository.createRental(
        customer: unknown,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: item.id,
            instanceName: item.name,
            shortCode: 'UNK-TEST',
          ),
        ],
      );

      final List<Rental> rentals = await repository.listRentals();
      expect(
        rentals.any(
          (r) => r.customerId == kUnknownCustomerId && r.isActive,
        ),
        isTrue,
      );
    });

    test('optional nickname on Unknown does not rename customer', () async {
      final LocalRepository repository = await _bootRepo();
      final Customer unknown = await repository.ensureUnknownCustomer();
      final List<InventoryItem> inventory = await repository.listInventory();
      final InventoryItem item =
          inventory.firstWhere((i) => i.availableUnits > 0);

      await repository.createRental(
        customer: unknown,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: item.id,
            instanceName: item.name,
            shortCode: 'UNK-RAJU',
          ),
        ],
        nickname: 'Raju',
      );

      final List<Rental> rentals = await repository.listRentals();
      final Rental created = rentals.firstWhere(
        (r) => r.customerId == kUnknownCustomerId && r.isActive,
      );
      expect(created.nickname, 'Raju');

      final Customer after = (await repository.listCustomers())
          .firstWhere((c) => c.id == kUnknownCustomerId);
      expect(after.name, kUnknownCustomerName);

      final SearchResults found = await repository.search('Raju');
      expect(found.currentRentals.any((r) => r.id == created.id), isTrue);
    });

    test('no-phone path does not create a named Customer row', () async {
      final LocalRepository repository = await _bootRepo();
      final int before = (await repository.listCustomers()).length;
      final Customer unknown = await repository.ensureUnknownCustomer();
      final InventoryItem item = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.availableUnits > 0);

      await repository.createRental(
        customer: unknown,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: item.id,
            instanceName: item.name,
            shortCode: 'UNK-NICK',
          ),
        ],
        nickname: 'WalkInGuest',
      );

      final List<Customer> after = await repository.listCustomers();
      expect(after.length, before);
      expect(after.any((c) => c.name == 'WalkInGuest'), isFalse);
    });

    test('upsert rejects empty and reserved phone', () async {
      final LocalRepository repository = await _bootRepo();
      expect(
        () => repository.upsertCustomerByPhone(
          phone: '',
          fallbackName: 'Someone',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => repository.upsertCustomerByPhone(
          phone: kUnknownCustomerPhone,
          fallbackName: 'Someone',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('upsert enforces unique phone and keeps original name', () async {
      final LocalRepository repository = await _bootRepo();
      final Customer first = await repository.upsertCustomerByPhone(
        phone: '8888811111',
        fallbackName: 'Original Name',
      );
      final Customer second = await repository.upsertCustomerByPhone(
        phone: '8888811111',
        fallbackName: 'Different Name',
      );
      expect(second.id, first.id);
      expect(second.name, 'Original Name');
    });

    test('migrates legacy CUS-SELF rentals to Unknown', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await db.into(db.customers).insert(
            CustomersCompanion.insert(
              id: kLegacySelfCustomerId,
              name: 'SELF Known',
              phone: kUnknownCustomerPhone,
              isTrusted: const Value(true),
              qrCode: 'customer:self',
            ),
          );
      await db.into(db.inventoryItems).insert(
            InventoryItemsCompanion.insert(
              id: 'INV-LEGACY',
              name: 'Legacy Cam',
              category: 'Camera',
              availableUnits: 1,
              totalUnits: 1,
              status: 'available',
              qrCode: 'inventory:legacy',
            ),
          );
      final DateTime now = DateTime.now();
      await db.into(db.rentals).insert(
            RentalsCompanion.insert(
              id: 'REN-LEGACY',
              customerId: kLegacySelfCustomerId,
              startedAt: now,
              dueAt: Value<DateTime?>(now.add(const Duration(days: 1))),
              qrCode: 'rental:legacy',
              nickname: const Value<String?>('OldNick'),
            ),
          );

      final LocalRepository repository = LocalRepository(db, preferences);
      await repository.initialize();

      final List<Customer> customers = await repository.listCustomers();
      expect(customers.any((c) => c.id == kLegacySelfCustomerId), isFalse);
      expect(customers.any((c) => c.id == kUnknownCustomerId), isTrue);

      final List<Rental> rentals = await repository.listRentals();
      final Rental rental =
          rentals.firstWhere((Rental r) => r.id == 'REN-LEGACY');
      expect(rental.customerId, kUnknownCustomerId);
      expect(rental.nickname, 'OldNick');
    });

    test('searchCustomersByNameOrPhone excludes Unknown', () async {
      final LocalRepository repository = await _bootRepo();
      final List<Customer> hits =
          await repository.searchCustomersByNameOrPhone('unk');
      expect(hits.any((c) => c.id == kUnknownCustomerId), isFalse);

      final List<Customer> byPriya =
          await repository.searchCustomersByNameOrPhone('pri');
      expect(byPriya.any((c) => c.name.contains('Priya')), isTrue);
    });
  });
}
