@Tags(['unit', 'orders', 'deposit'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/domain/models/customer_balance.dart';
import 'package:asset_os/domain/models/entities.dart';
import 'package:asset_os/application/local_repository.dart';

import 'support/test_harness.dart';

void main() {
  group('order bills and order deposit', () {
    test('create with deposit sets order.depositAmount; wallet unchanged',
        () async {
      final LocalRepository repository = await bootRepo();
      final Customer customer = await ensureCustomer(repository);
      expect(customer.depositBalance, 0);

      await repository.addInventory(
        name: 'Bill Novel',
        category: 'Library',
        units: 1,
        billingMode: BillingMode.fixed,
        rateAmount: 5000,
      );
      final InventoryItem item = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.name == 'Bill Novel');

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: item.id,
            instanceName: 'Copy 1',
            shortCode: 'BN-01',
          ),
        ],
        depositTopUpPaise: 8000,
      );

      final Rental created = (await repository.listRentals()).first;
      expect(created.depositAmount, 8000);
      expect(created.orderStatus, OrderStatus.open);
      expect(created.isActive, isTrue);

      final Customer after = (await repository.listCustomers())
          .firstWhere((Customer c) => c.id == customer.id);
      expect(after.depositBalance, 0);
    });

    test('return applies order deposit and completes when rent lines closed',
        () async {
      final LocalRepository repository = await bootRepo();
      final Customer customer = await ensureCustomer(repository);

      await repository.addInventory(
        name: 'Return Kit',
        category: 'Tools',
        units: 1,
        billingMode: BillingMode.fixed,
        rateAmount: 5000,
      );
      final InventoryItem item = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.name == 'Return Kit');

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: item.id,
            instanceName: 'Kit',
            shortCode: 'RK-01',
          ),
        ],
        depositTopUpPaise: 8000,
      );
      final Rental created = (await repository.listRentals()).first;

      final RentalReturnResult? result =
          await repository.returnRental(created.id);
      expect(result, isNotNull);
      expect(result!.depositApplied, 5000);
      expect(result.amountDue, 0);
      expect(result.depositBalanceAfter, 3000);
      expect(result.rentalClosed, isTrue);

      final Rental closed = (await repository.listRentals())
          .firstWhere((Rental r) => r.id == created.id);
      expect(closed.orderStatus, OrderStatus.completed);
      expect(closed.isActive, isFalse);
      expect(closed.depositAmount, 8000);
      expect(closed.depositApplied, 5000);

      final RentalReturnResult? blocked =
          await repository.returnRental(closed.id);
      expect(blocked, isNull);
    });

    test('cancel settles from order deposit and marks cancelled', () async {
      final LocalRepository repository = await bootRepo();
      final Customer customer = await ensureCustomer(repository);

      await repository.addInventory(
        name: 'Cancel Bill',
        category: 'Tools',
        units: 2,
        billingMode: BillingMode.fixed,
        rateAmount: 2000,
      );
      final InventoryItem item = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.name == 'Cancel Bill');

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: item.id,
            instanceName: 'One',
            shortCode: 'CB-1',
          ),
          RentalLineInput(
            itemId: item.id,
            instanceName: 'Two',
            shortCode: 'CB-2',
          ),
        ],
        depositTopUpPaise: 10000,
      );
      final Rental rental = (await repository.listRentals()).first;

      final OrderCancelResult? result = await repository.cancelOrder(
        rentalId: rental.id,
        amountKeptPaise: 3000,
        amountReturnedPaise: 2000,
        note: 'Customer cancelled',
      );
      expect(result, isNotNull);
      expect(result!.amountKeptPaise, 3000);
      expect(result.amountReturnedPaise, 2000);
      expect(result.depositBalanceAfter, 5000);

      final Rental closed = (await repository.listRentals())
          .firstWhere((Rental r) => r.id == rental.id);
      expect(closed.orderStatus, OrderStatus.cancelled);
      expect(closed.isActive, isFalse);
      expect(closed.totalAmount, 0);

      final InventoryItem stock = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.id == item.id);
      expect(stock.availableUnits, 2);

      final Customer after = (await repository.listCustomers())
          .firstWhere((Customer c) => c.id == customer.id);
      expect(after.depositBalance, 0);
    });

    test('sell-only order is completed at create', () async {
      final LocalRepository repository = await bootRepo();
      final Customer customer = await ensureCustomer(repository);
      await repository.addInventory(
        name: 'Sold Tripod',
        category: 'Camera',
        units: 2,
        billingMode: BillingMode.daily,
        rateAmount: 10000,
        requiresUnitIdentity: false,
      );
      final InventoryItem tripod = (await repository.listInventory()).single;

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: tripod.id,
            instanceName: 'Tripod',
            shortCode: 'ST-1',
            fulfillment: LineFulfillment.sell,
            manualSaleAmountPaise: 25000,
          ),
        ],
        depositTopUpPaise: 1000,
      );

      final Rental order = (await repository.listRentals()).single;
      expect(order.orderStatus, OrderStatus.completed);
      expect(order.isActive, isFalse);
      expect(order.depositAmount, 1000);
      expect(order.returnedAt, isNotNull);
    });

    test('customer net signed across open completed cancelled', () async {
      final LocalRepository repository = await bootRepo();
      final Customer customer = await ensureCustomer(repository);

      await repository.addInventory(
        name: 'Net A',
        category: 'Tools',
        units: 3,
        billingMode: BillingMode.fixed,
        rateAmount: 4000,
      );
      final InventoryItem item = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.name == 'Net A');

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: item.id,
            instanceName: 'Open',
            shortCode: 'NA-1',
          ),
        ],
        depositTopUpPaise: 10000,
      );
      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: item.id,
            instanceName: 'Done',
            shortCode: 'NA-2',
          ),
        ],
        depositTopUpPaise: 1000,
      );
      final List<Rental> rentals = await repository.listRentals();
      final Rental toComplete =
          rentals.firstWhere((Rental r) => r.lines.first.shortCode == 'NA-2');
      await repository.returnRental(toComplete.id);

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: item.id,
            instanceName: 'Cancel',
            shortCode: 'NA-3',
          ),
        ],
        depositTopUpPaise: 5000,
      );
      final Rental toCancel = (await repository.listRentals())
          .firstWhere((Rental r) => r.lines.first.shortCode == 'NA-3');
      await repository.cancelOrder(rentalId: toCancel.id);

      final List<Rental> all = await repository.listRentals();
      final CustomerBalanceAsOf balance =
          customerBalanceAsOf(customer, all, DateTime.now());
      // open: 4000 - 10000 = -6000; completed: 4000 - 1000 = 3000; cancelled: 0
      expect(balance.netPaise, -3000);
      expect(balance.creditPaise, 3000);
      expect(balance.advancePaise, 11000);
      expect(balance.pendingPaise, 8000);
    });
  });
}
