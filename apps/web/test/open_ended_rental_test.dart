@Tags(['unit', 'pricing'])
library;

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/infrastructure/db/app_database.dart';
import 'package:asset_os/domain/models/entities.dart';
import 'package:asset_os/application/local_repository.dart';

import 'support/test_harness.dart';

void main() {
  group('open-ended rentals', () {
    test('createRental openEnded stores null dueAt and zero base', () async {
      final LocalRepository repository = await bootRepo();
      await repository.addInventory(
        name: 'Tractor',
        category: 'Farm',
        units: 2,
        billingMode: BillingMode.daily,
        rateAmount: 10000,
        dueDateOptional: true,
      );
      final InventoryItem tractor = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.name == 'Tractor');
      expect(tractor.dueDateOptional, isTrue);

      final Customer customer =
          await ensureCustomer(repository);
      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: tractor.id,
            instanceName: 'Unit A',
            shortCode: 'TRC-01',
          ),
        ],
        openEnded: true,
      );

      final Rental created = (await repository.listRentals()).first;
      expect(created.dueAt, isNull);
      expect(created.isOpenEnded, isTrue);
      expect(created.hasDueDate, isFalse);
      expect(created.durationUnits, 0);
      expect(created.baseAmount, 0);
      expect(created.lines.single.baseAmount, 0);
      expect(created.statusFor(DateTime.now()), AssetStatus.rented);
    });

    test('accrual grows and return finalizes base with late=0', () async {
      final LocalRepository repository = await bootRepo();
      final db = repository.database;

      await repository.addInventory(
        name: 'Pump',
        category: 'Farm',
        units: 1,
        billingMode: BillingMode.daily,
        rateAmount: 5000,
        lateFeePerDay: 1000,
        dueDateOptional: true,
      );
      final InventoryItem pump = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.name == 'Pump');
      final Customer customer =
          await ensureCustomer(repository);

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: pump.id,
            instanceName: 'Pump 1',
            shortCode: 'PMP-01',
          ),
        ],
        openEnded: true,
      );
      final Rental created = (await repository.listRentals()).first;
      expect(created.dueAt, isNull);

      final DateTime asOf = created.startedAt.add(const Duration(days: 3));
      final int accrued = created.lines.single.totalAmountAsOf(
        created.startedAt,
        created.dueAt,
        asOf,
      );
      expect(accrued, 15000);
      expect(created.lateAmountAsOf(asOf), 0);
      expect(created.statusFor(asOf), AssetStatus.rented);

      await (db.update(db.rentals)..where((t) => t.id.equals(created.id))).write(
        RentalsCompanion(
          startedAt: Value<DateTime>(
            DateTime.now().subtract(const Duration(days: 2)),
          ),
        ),
      );

      await repository.returnRental(created.id);
      final Rental returned = (await repository.listRentals())
          .firstWhere((Rental r) => r.id == created.id);
      expect(returned.isActive, isFalse);
      expect(returned.lateAmount, 0);
      expect(returned.baseAmount, greaterThan(0));
      expect(returned.totalAmount, returned.baseAmount);
      expect(returned.lines.single.lateAmount, 0);
    });

    test('mixed cart openEnded throws ArgumentError', () async {
      final LocalRepository repository = await bootRepo();
      await repository.addInventory(
        name: 'Optional Tool',
        category: 'Tools',
        units: 2,
        billingMode: BillingMode.weekly,
        rateAmount: 2000,
        dueDateOptional: true,
      );
      await repository.addInventory(
        name: 'Required Tool',
        category: 'Tools',
        units: 2,
        billingMode: BillingMode.weekly,
        rateAmount: 2000,
        dueDateOptional: false,
      );
      final List<InventoryItem> inventory = await repository.listInventory();
      final InventoryItem optional = inventory.firstWhere(
        (InventoryItem i) => i.name == 'Optional Tool',
      );
      final InventoryItem required = inventory.firstWhere(
        (InventoryItem i) => i.name == 'Required Tool',
      );
      final Customer customer =
          await ensureCustomer(repository);

      expect(
        () => repository.createRental(
          customer: customer,
          lines: <RentalLineInput>[
            RentalLineInput(
              itemId: optional.id,
              instanceName: 'Opt A',
              shortCode: 'OPT-A',
            ),
            RentalLineInput(
              itemId: required.id,
              instanceName: 'Req A',
              shortCode: 'REQ-A',
            ),
          ],
          openEnded: true,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('due-required item still gets dueAt when not openEnded', () async {
      final LocalRepository repository = await bootRepo();
      await repository.addInventory(
        name: 'Chair Set',
        category: 'Event',
        units: 5,
        billingMode: BillingMode.weekly,
        rateAmount: 3000,
        dueDateOptional: false,
      );
      final InventoryItem chair = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.name == 'Chair Set');
      final Customer customer =
          await ensureCustomer(repository);

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: chair.id,
            instanceName: 'Set A',
            shortCode: 'CHR-A',
          ),
        ],
        durationUnits: 1,
      );
      final Rental created = (await repository.listRentals()).first;
      expect(created.dueAt, isNotNull);
      expect(created.isOpenEnded, isFalse);
      expect(created.baseAmount, 3000);
    });

    test('statusFor never overdue without due', () {
      final Rental openEnded = Rental(
        id: 'REN-OE',
        customerId: 'CUS-1',
        lines: const <RentalLine>[
          RentalLine(
            id: 'RLI-1',
            itemId: 'INV-1',
            catalogName: 'Tractor',
            instanceName: 'A',
            shortCode: 'T-1',
            billingMode: BillingMode.daily,
            rateAmount: 1000,
          ),
        ],
        startedAt: DateTime(2026, 1, 1),
        dueAt: null,
        timeline: const <RentalEvent>[],
        qrCode: 'rental:oe',
      );
      final DateTime farFuture = DateTime(2026, 12, 31);
      expect(openEnded.statusFor(farFuture), AssetStatus.rented);
      expect(openEnded.lateAmountAsOf(farFuture), 0);
    });

    test('inventory dueDateOptional persists on add and update', () async {
      final LocalRepository repository = await bootRepo();
      await repository.addInventory(
        name: 'Harvester',
        category: 'Farm',
        units: 1,
        dueDateOptional: true,
      );
      InventoryItem item = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.name == 'Harvester');
      expect(item.dueDateOptional, isTrue);

      await repository.updateInventory(
        id: item.id,
        name: item.name,
        category: item.category,
        units: item.totalUnits,
        dueDateOptional: false,
      );
      item = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.id == item.id);
      expect(item.dueDateOptional, isFalse);
    });
  });
}
