@Tags(['unit', 'pricing'])
library;

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

    test('dynamic rate override freezes on line; catalog edit does not change open rental',
        () async {
      final LocalRepository repository = await bootRepo();
      await repository.addInventory(
        name: 'Dynamic Cam',
        category: 'Camera',
        units: 2,
        billingMode: BillingMode.daily,
        rateAmount: 100000,
        lateFeePerDay: 1000,
        allowsDynamicPricing: true,
        dueDateOptional: true,
      );
      final InventoryItem cam = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.name == 'Dynamic Cam');
      final Customer customer = await ensureCustomer(repository);

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: cam.id,
            instanceName: 'Body A',
            shortCode: 'CAM-DYN',
            openEnded: true,
            rateAmountOverride: 75000,
          ),
        ],
        openEnded: true,
      );

      Rental open = (await repository.listRentals()).first;
      expect(open.lines.single.rateAmount, 75000);
      expect(open.rateAmount, 75000);
      expect(open.baseAmount, 0);

      await repository.updateInventory(
        id: cam.id,
        name: cam.name,
        category: cam.category,
        units: cam.totalUnits,
        rateAmount: 200000,
      );

      open = (await repository.listRentals())
          .firstWhere((Rental r) => r.id == open.id);
      expect(open.lines.single.rateAmount, 75000);

      // Open-ended return accrues at frozen override, not catalog 200000.
      final AppDatabase db = repository.database;
      await (db.update(db.rentals)..where((t) => t.id.equals(open.id))).write(
        RentalsCompanion(
          startedAt: Value<DateTime>(
            DateTime.now().subtract(const Duration(days: 2)),
          ),
        ),
      );
      await repository.returnRental(open.id);
      final Rental returned = (await repository.listRentals())
          .firstWhere((Rental r) => r.id == open.id);
      expect(returned.lines.single.rateAmount, 75000);
      expect(returned.baseAmount, 150000);
    });

    test('rate override rejected when item disallows dynamic pricing', () async {
      final LocalRepository repository = await bootRepo();
      await repository.addInventory(
        name: 'Fixed Rate Book',
        category: 'Library',
        units: 1,
        billingMode: BillingMode.weekly,
        rateAmount: 5000,
        allowsDynamicPricing: false,
      );
      final InventoryItem book = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.name == 'Fixed Rate Book');
      final Customer customer = await ensureCustomer(repository);

      expect(
        () => repository.createRental(
          customer: customer,
          lines: <RentalLineInput>[
            RentalLineInput(
              itemId: book.id,
              instanceName: 'Copy 1',
              shortCode: 'BK-FIX',
              rateAmountOverride: 3000,
            ),
          ],
          durationUnits: 1,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('fixed-due rental baseAmount unchanged after catalog rate edit', () async {
      final LocalRepository repository = await bootRepo();
      await repository.addInventory(
        name: 'Tripod',
        category: 'Camera',
        units: 3,
        billingMode: BillingMode.weekly,
        rateAmount: 4000,
        allowsDynamicPricing: true,
      );
      final InventoryItem item = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.name == 'Tripod');
      final Customer customer = await ensureCustomer(repository);

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: item.id,
            instanceName: 'Tripod A',
            shortCode: 'TRI-01',
            rateAmountOverride: 3500,
          ),
        ],
        durationUnits: 1,
      );
      final Rental created = (await repository.listRentals()).first;
      expect(created.baseAmount, 3500);
      expect(created.lines.single.rateAmount, 3500);

      await repository.updateInventory(
        id: item.id,
        name: item.name,
        category: item.category,
        units: item.totalUnits,
        rateAmount: 9000,
      );
      final Rental after = (await repository.listRentals())
          .firstWhere((Rental r) => r.id == created.id);
      expect(after.baseAmount, 3500);
      expect(after.lines.single.rateAmount, 3500);
    });
  });
}
