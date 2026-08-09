@Tags(['unit', 'pricing'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/domain/models/entities.dart';
import 'package:asset_os/application/local_repository.dart';

import 'support/test_harness.dart';

void main() {
  group('createRental per-line duration', () {
    test('distinct line amounts and earliest parent dueAt', () async {
      final LocalRepository repository = await bootRepo();
      await repository.addInventory(
        name: 'Daily Cam',
        category: 'Camera',
        units: 3,
        billingMode: BillingMode.daily,
        rateAmount: 10000,
        requiresUnitIdentity: false,
      );
      await repository.addInventory(
        name: 'Weekly Lens',
        category: 'Camera',
        units: 3,
        billingMode: BillingMode.weekly,
        rateAmount: 5000,
        requiresUnitIdentity: false,
      );
      final List<InventoryItem> inventory = await repository.listInventory();
      final InventoryItem daily = inventory.firstWhere(
        (InventoryItem i) => i.name == 'Daily Cam',
      );
      final InventoryItem weekly = inventory.firstWhere(
        (InventoryItem i) => i.name == 'Weekly Lens',
      );
      final Customer customer =
          await ensureCustomer(repository);

      final DateTime before = DateTime.now();
      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: daily.id,
            instanceName: 'Daily Cam',
            shortCode: 'DAY-1',
            durationUnits: 2,
          ),
          RentalLineInput(
            itemId: weekly.id,
            instanceName: 'Weekly Lens',
            shortCode: 'WK-1',
            durationUnits: 1,
          ),
        ],
      );
      final DateTime after = DateTime.now();

      final Rental created = (await repository.listRentals()).first;
      expect(created.lines, hasLength(2));
      expect(created.lines[0].baseAmount, 20000); // 2 days * 10000
      expect(created.lines[1].baseAmount, 5000); // 1 week * 5000
      expect(created.baseAmount, 25000);
      expect(created.totalAmount, 25000);

      // Earliest due is daily +2d (before weekly +7d).
      final DateTime minDue = before.add(const Duration(days: 2));
      final DateTime maxDue = after.add(const Duration(days: 2));
      expect(
        !created.dueAt!.isBefore(minDue.subtract(const Duration(seconds: 2))),
        isTrue,
      );
      expect(
        !created.dueAt!.isAfter(maxDue.add(const Duration(seconds: 2))),
        isTrue,
      );
    });

    test('depositTopUpPaise sets order deposit; wallet unchanged', () async {
      final LocalRepository repository = await bootRepo();
      final Customer customer =
          await ensureCustomer(repository);
      expect(customer.depositBalance, 0);
      await repository.addInventory(
        name: 'Tripod',
        category: 'Camera',
        units: 1,
        rateAmount: 20000,
      );
      final InventoryItem tripod = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.name == 'Tripod');

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: tripod.id,
            instanceName: 'Tripod unit',
            shortCode: 'TRP-99',
            durationUnits: 1,
          ),
        ],
        depositTopUpPaise: 2500,
      );

      final Customer updated =
          (await repository.listCustomers())
              .firstWhere((Customer c) => c.id == customer.id);
      expect(updated.depositBalance, 0);
      final Rental created = (await repository.listRentals()).first;
      expect(created.depositAmount, 2500);
    });
  });
}
