import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:asset_os/core/db/app_database.dart';
import 'package:asset_os/core/models/entities.dart';
import 'package:asset_os/core/models/self_customer.dart';
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

  group('SELF Known + nickname', () {
    test('initialize ensures CUS-SELF sentinel', () async {
      final LocalRepository repository = await _bootRepo();
      final List<Customer> customers = await repository.listCustomers();
      final Customer self = customers.firstWhere((c) => c.id == kSelfCustomerId);
      expect(self.phone, kSelfCustomerPhone);
      expect(self.name, kSelfCustomerName);
    });

    test('createRental to SELF without nickname fails', () async {
      final LocalRepository repository = await _bootRepo();
      final Customer self = await repository.ensureSelfCustomer();
      final List<InventoryItem> inventory = await repository.listInventory();
      final InventoryItem item = inventory.firstWhere((i) => i.availableUnits > 0);

      expect(
        () => repository.createRental(
          customer: self,
          selectedItems: <InventoryItem>[item],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createRental to SELF with nickname persists without renaming customer', () async {
      final LocalRepository repository = await _bootRepo();
      final Customer self = await repository.ensureSelfCustomer();
      final List<InventoryItem> inventory = await repository.listInventory();
      final InventoryItem item = inventory.firstWhere((i) => i.availableUnits > 0);

      await repository.createRental(
        customer: self,
        selectedItems: <InventoryItem>[item],
        nickname: 'Raju',
      );

      final List<Rental> rentals = await repository.listRentals();
      final Rental created = rentals.firstWhere(
        (r) => r.customerId == kSelfCustomerId && r.isActive,
      );
      expect(created.nickname, 'Raju');

      final Customer after = (await repository.listCustomers())
          .firstWhere((c) => c.id == kSelfCustomerId);
      expect(after.name, kSelfCustomerName);

      final SearchResults found = await repository.search('Raju');
      expect(found.currentRentals.any((r) => r.id == created.id), isTrue);
    });

    test('upsert by sentinel phone returns SELF and ignores fallback name', () async {
      final LocalRepository repository = await _bootRepo();
      final Customer upserted = await repository.upsertCustomerByPhone(
        phone: kSelfCustomerPhone,
        fallbackName: 'ShouldNotApply',
      );
      expect(upserted.id, kSelfCustomerId);
      expect(upserted.name, kSelfCustomerName);
    });
  });
}
