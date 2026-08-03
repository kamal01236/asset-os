import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/core/db/app_database.dart';
import 'package:asset_os/core/models/entities.dart';
import 'package:asset_os/core/repositories/local_repository.dart';

import 'support/test_harness.dart';

void main() {
  group('rental pricing persistence', () {
    test('createRental stores weekly Novel amounts and due +7d', () async {
      final LocalRepository repository = await bootRepo();
      await repository.addInventory(
        name: 'Novel',
        category: 'Library',
        units: 5,
        billingMode: BillingMode.weekly,
        rateAmount: 5000,
        lateFeePerDay: 500,
      );
      final InventoryItem novel = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.name == 'Novel');
      final Customer customer =
          await ensureCustomer(repository);

      final DateTime before = DateTime.now();
      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: novel.id,
            instanceName: 'Harry Potter',
            shortCode: 'NOV-050',
          ),
        ],
        durationUnits: 1,
      );
      final DateTime after = DateTime.now();

      final Rental created = (await repository.listRentals()).first;
      expect(created.billingMode, BillingMode.weekly);
      expect(created.rateAmount, 5000);
      expect(created.lateFeePerDay, 500);
      expect(created.baseAmount, 5000);
      expect(created.lateAmount, 0);
      expect(created.totalAmount, 5000);
      expect(created.durationUnits, 1);

      final DateTime minDue = before.add(const Duration(days: 7));
      final DateTime maxDue = after.add(const Duration(days: 7));
      expect(
        !created.dueAt!.isBefore(minDue.subtract(const Duration(seconds: 2))),
        isTrue,
      );
      expect(
        !created.dueAt!.isAfter(maxDue.add(const Duration(seconds: 2))),
        isTrue,
      );
    });

    test('returnRental finalizes late fee after due', () async {
      final LocalRepository repository = await bootRepo();
      final db = repository.database;

      final Customer customer =
          await ensureCustomer(repository);
      await repository.addInventory(
        name: 'Novel Late',
        category: 'Library',
        units: 2,
        billingMode: BillingMode.weekly,
        rateAmount: 5000,
        lateFeePerDay: 500,
      );
      final InventoryItem novel = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.name == 'Novel Late');

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: novel.id,
            instanceName: 'Copy A',
            shortCode: 'NOV-L1',
          ),
        ],
        durationUnits: 1,
      );
      final Rental created = (await repository.listRentals()).first;

      // Force due date into the past so return computes late fee.
      await (db.update(db.rentals)..where((t) => t.id.equals(created.id))).write(
        RentalsCompanion(
          dueAt: Value<DateTime?>(
            DateTime.now().subtract(const Duration(days: 3)),
          ),
        ),
      );

      await repository.returnRental(created.id);
      final Rental returned = (await repository.listRentals())
          .firstWhere((Rental r) => r.id == created.id);
      expect(returned.isActive, isFalse);
      expect(returned.lateAmount, 1500);
      expect(returned.totalAmount, 6500);
    });

    test('fixed mode charges once', () async {
      final LocalRepository repository = await bootRepo();
      await repository.addInventory(
        name: 'Chair',
        category: 'Event',
        units: 10,
        billingMode: BillingMode.fixed,
        rateAmount: 2000,
      );
      final InventoryItem chair = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.name == 'Chair');
      final Customer customer =
          await ensureCustomer(repository);

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: chair.id,
            instanceName: 'Folding A',
            shortCode: 'CHR-01',
          ),
        ],
        durationUnits: 14,
      );

      final Rental created = (await repository.listRentals()).first;
      expect(created.billingMode, BillingMode.fixed);
      expect(created.baseAmount, 2000);
      expect(created.totalAmount, 2000);
    });
  });
}
