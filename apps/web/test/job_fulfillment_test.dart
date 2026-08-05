@Tags(['unit', 'orders'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/core/models/entities.dart';
import 'package:asset_os/core/repositories/local_repository.dart';

import 'support/test_harness.dart';

void main() {
  group('job fulfillment', () {
    test('job order stays open and drops stock without closing line', () async {
      final LocalRepository repository = await bootRepo();
      await repository.addInventory(
        name: 'Facial',
        category: 'Parlour',
        units: 3,
        billingMode: BillingMode.fixed,
        rateAmount: 80000,
        requiresUnitIdentity: false,
        defaultItemKind: InventoryItemKind.job,
      );
      final InventoryItem item = (await repository.listInventory()).single;
      expect(item.defaultItemKind, InventoryItemKind.job);
      expect(item.isJob, isTrue);
      final Customer customer = await ensureCustomer(repository);

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: item.id,
            instanceName: 'Facial',
            shortCode: 'FAC-1',
            fulfillment: LineFulfillment.job,
            manualSaleAmountPaise: 80000,
          ),
        ],
      );

      final InventoryItem after = (await repository.listInventory()).single;
      expect(after.availableUnits, 2);
      expect(after.totalUnits, 2);

      final Rental order = (await repository.listRentals()).single;
      expect(order.isActive, isTrue);
      expect(order.hasPendingJobs, isTrue);
      expect(order.orderStatus, OrderStatus.open);
      expect(order.returnedAt, isNull);
      expect(order.lines.single.fulfillment, LineFulfillment.job);
      expect(order.lines.single.isOpen, isTrue);
      expect(order.baseAmount, 80000);
      expect(order.openJobLines, hasLength(1));
      expect(order.openRentLines, isEmpty);
    });

    test('completeJobLines closes without stock restore', () async {
      final LocalRepository repository = await bootRepo();
      await repository.addInventory(
        name: 'Haircut',
        category: 'Parlour',
        units: 2,
        billingMode: BillingMode.fixed,
        rateAmount: 30000,
        requiresUnitIdentity: false,
        defaultItemKind: InventoryItemKind.job,
      );
      final InventoryItem item = (await repository.listInventory()).single;
      final Customer customer = await ensureCustomer(repository);

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: item.id,
            instanceName: 'Haircut',
            shortCode: 'CUT-1',
            fulfillment: LineFulfillment.job,
            manualSaleAmountPaise: 30000,
          ),
        ],
      );

      final Rental open = (await repository.listRentals()).single;
      final RentalReturnResult? result = await repository.completeJobLines(
        open.id,
        <String>[open.lines.single.id],
      );
      expect(result, isNotNull);
      expect(result!.rentalClosed, isTrue);

      final InventoryItem after = (await repository.listInventory()).single;
      expect(after.availableUnits, 1);
      expect(after.totalUnits, 1);

      final Rental completed = (await repository.listRentals()).single;
      expect(completed.orderStatus, OrderStatus.completed);
      expect(completed.hasPendingJobs, isFalse);
      expect(completed.lines.single.isOpen, isFalse);
      expect(completed.returnedAt, isNotNull);
    });

    test('pending-jobs helper matches open job orders only', () async {
      final LocalRepository repository = await bootRepo();
      await repository.addInventory(
        name: 'Manicure',
        category: 'Parlour',
        units: 4,
        billingMode: BillingMode.fixed,
        rateAmount: 40000,
        requiresUnitIdentity: false,
        defaultItemKind: InventoryItemKind.job,
      );
      await repository.addInventory(
        name: 'USB Cable',
        category: 'General',
        units: 2,
        requiresUnitIdentity: false,
        defaultItemKind: InventoryItemKind.general,
      );
      final List<InventoryItem> inventory = await repository.listInventory();
      final InventoryItem manicure =
          inventory.firstWhere((InventoryItem i) => i.name == 'Manicure');
      final InventoryItem cable =
          inventory.firstWhere((InventoryItem i) => i.name == 'USB Cable');
      final Customer customer = await ensureCustomer(repository);

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: manicure.id,
            instanceName: 'Manicure',
            shortCode: 'MAN-1',
            fulfillment: LineFulfillment.job,
            manualSaleAmountPaise: 40000,
          ),
        ],
      );
      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: cable.id,
            instanceName: 'USB Cable',
            shortCode: 'USB-1',
            fulfillment: LineFulfillment.sell,
            manualSaleAmountPaise: 1500,
          ),
        ],
      );

      final List<Rental> rentals = await repository.listRentals();
      final List<Rental> pending =
          rentals.where((Rental r) => r.hasPendingJobs).toList();
      expect(pending, hasLength(1));
      expect(pending.single.lines.single.fulfillment, LineFulfillment.job);

      await repository.completeJobLines(
        pending.single.id,
        pending.single.openJobLines.map((RentalLine l) => l.id).toList(),
      );
      final List<Rental> after = await repository.listRentals();
      expect(after.where((Rental r) => r.hasPendingJobs), isEmpty);
    });

    test('job rejects zero amount', () async {
      final LocalRepository repository = await bootRepo();
      await repository.addInventory(
        name: 'Bridal Package',
        category: 'Parlour',
        units: 1,
        requiresUnitIdentity: false,
        defaultItemKind: InventoryItemKind.job,
        rateAmount: 1500000,
      );
      final InventoryItem item = (await repository.listInventory()).single;
      final Customer customer = await ensureCustomer(repository);

      await expectLater(
        () => repository.createRental(
          customer: customer,
          lines: <RentalLineInput>[
            RentalLineInput(
              itemId: item.id,
              instanceName: 'Bridal Package',
              shortCode: 'BRI-1',
              fulfillment: LineFulfillment.job,
              manualSaleAmountPaise: 0,
            ),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
