@Tags(['unit', 'deposit'])
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/core/db/app_database.dart';
import 'package:asset_os/core/models/entities.dart';
import 'package:asset_os/core/repositories/local_repository.dart';

import 'support/test_harness.dart';

void main() {
  group('customer deposit wallet', () {
    test('topUpDeposit credits balance and ledger', () async {
      final LocalRepository repository = await bootRepo();
      final Customer customer =
          await ensureCustomer(repository);

      final Customer topped = await repository.topUpDeposit(
        customer.id,
        10000,
        note: 'Cash at counter',
      );
      expect(topped.depositBalance, 10000);

      final Customer refreshed =
          (await repository.listCustomers())
              .firstWhere((Customer c) => c.id == customer.id);
      expect(refreshed.depositBalance, 10000);

      final List<DepositLedgerEntry> ledger =
          await repository.listDepositLedger(customer.id);
      expect(ledger, hasLength(1));
      expect(ledger.first.type, DepositLedgerType.topUp);
      expect(ledger.first.amount, 10000);
      expect(ledger.first.balanceAfter, 10000);
      expect(ledger.first.note, 'Cash at counter');
    });

    test('topUpDeposit rejects non-positive amounts', () async {
      final LocalRepository repository = await bootRepo();
      final Customer customer =
          await ensureCustomer(repository);
      expect(
        () => repository.topUpDeposit(customer.id, 0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('refundDeposit debits and cannot exceed balance', () async {
      final LocalRepository repository = await bootRepo();
      final Customer customer =
          await ensureCustomer(repository);
      await repository.topUpDeposit(customer.id, 5000);

      final Customer refunded =
          await repository.refundDeposit(customer.id, 2000);
      expect(refunded.depositBalance, 3000);

      expect(
        () => repository.refundDeposit(customer.id, 4000),
        throwsA(isA<ArgumentError>()),
      );

      final List<DepositLedgerEntry> ledger =
          await repository.listDepositLedger(customer.id);
      final DepositLedgerEntry refund = ledger.firstWhere(
        (DepositLedgerEntry e) => e.type == DepositLedgerType.refund,
      );
      expect(refund.amount, -2000);
      expect(refund.balanceAfter, 3000);
    });

    test('returnRental applies min(orderDeposit, total) and leftover remains',
        () async {
      final LocalRepository repository = await bootRepo();
      final Customer customer =
          await ensureCustomer(repository);

      await repository.addInventory(
        name: 'Deposit Novel',
        category: 'Library',
        units: 2,
        billingMode: BillingMode.weekly,
        rateAmount: 5000,
      );
      final InventoryItem novel = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.name == 'Deposit Novel');

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: novel.id,
            instanceName: 'Copy Dep',
            shortCode: 'DEP-01',
          ),
        ],
        durationUnits: 1,
        depositTopUpPaise: 8000,
      );
      final Rental created = (await repository.listRentals()).first;
      expect(created.totalAmount, 5000);
      expect(created.depositAmount, 8000);

      final RentalReturnResult? result =
          await repository.returnRental(created.id);
      expect(result, isNotNull);
      expect(result!.depositApplied, 5000);
      expect(result.totalAmount, 5000);
      expect(result.amountDue, 0);
      expect(result.depositBalanceAfter, 3000);

      final Customer after =
          (await repository.listCustomers())
              .firstWhere((Customer c) => c.id == customer.id);
      expect(after.depositBalance, 0);

      final Rental returned = (await repository.listRentals())
          .firstWhere((Rental r) => r.id == created.id);
      expect(returned.depositApplied, 5000);
      expect(returned.amountDueAfterDeposit, 0);
      expect(returned.orderStatus, OrderStatus.completed);
    });

    test('returnRental leaves remaining due when order deposit is short',
        () async {
      final LocalRepository repository = await bootRepo();
      final Customer customer =
          await ensureCustomer(repository, phone: '7777777777', name: 'Amit Sharma');

      await repository.addInventory(
        name: 'Short Deposit Item',
        category: 'Tools',
        units: 1,
        billingMode: BillingMode.fixed,
        rateAmount: 10000,
      );
      final InventoryItem item = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.name == 'Short Deposit Item');

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: item.id,
            instanceName: 'Unit 1',
            shortCode: 'SHT-01',
          ),
        ],
        depositTopUpPaise: 2000,
      );

      final Rental created = (await repository.listRentals()).first;
      final RentalReturnResult? result =
          await repository.returnRental(created.id);
      expect(result, isNotNull);
      expect(result!.depositApplied, 2000);
      expect(result.amountDue, 8000);
      expect(result.depositBalanceAfter, 0);

      final Customer after =
          (await repository.listCustomers())
              .firstWhere((Customer c) => c.id == customer.id);
      expect(after.depositBalance, 0);
    });

    test('order deposit does not carry across separate orders', () async {
      final LocalRepository repository = await bootRepo();
      final Customer customer =
          await ensureCustomer(repository, phone: '9999999999', name: 'Ravi Das');

      await repository.addInventory(
        name: 'Carry Forward Kit',
        category: 'Tools',
        units: 3,
        billingMode: BillingMode.fixed,
        rateAmount: 4000,
      );
      final InventoryItem item = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.name == 'Carry Forward Kit');

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: item.id,
            instanceName: 'Kit A',
            shortCode: 'CF-01',
          ),
        ],
        depositTopUpPaise: 15000,
      );
      final String firstId = (await repository.listRentals()).first.id;
      final RentalReturnResult? firstResult =
          await repository.returnRental(firstId);
      expect(firstResult!.depositApplied, 4000);
      expect(firstResult.depositBalanceAfter, 11000);

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: item.id,
            instanceName: 'Kit B',
            shortCode: 'CF-02',
          ),
        ],
        depositTopUpPaise: 0,
      );
      final Rental second = (await repository.listRentals())
          .firstWhere((Rental r) => r.isActive);
      expect(second.depositAmount, 0);
      final RentalReturnResult? result =
          await repository.returnRental(second.id);
      expect(result!.depositApplied, 0);
      expect(result.depositBalanceAfter, 0);
    });

    test('return with zero deposit still finalizes charges', () async {
      final LocalRepository repository = await bootRepo();
      final Customer customer =
          await ensureCustomer(repository);
      expect(customer.depositBalance, 0);

      await repository.addInventory(
        name: 'No Deposit Item',
        category: 'Camera',
        units: 1,
        billingMode: BillingMode.fixed,
        rateAmount: 2500,
      );
      final InventoryItem item = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.name == 'No Deposit Item');

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: item.id,
            instanceName: 'Body',
            shortCode: 'ND-01',
          ),
        ],
      );
      final Rental created = (await repository.listRentals()).first;
      final RentalReturnResult? result =
          await repository.returnRental(created.id);
      expect(result!.depositApplied, 0);
      expect(result.amountDue, 2500);
      expect(result.depositBalanceAfter, 0);

      final List<DepositLedgerEntry> ledger =
          await repository.listDepositLedger(customer.id);
      expect(
        ledger.where((DepositLedgerEntry e) => e.type == DepositLedgerType.apply),
        isEmpty,
      );
    });

    test('schema v6 includes deposit columns and ledger table', () async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      expect(db.schemaVersion, 22);

      await db.into(db.customers).insert(
        CustomersCompanion.insert(
          id: 'CUS-DEP',
          name: 'Deposit Tester',
          phone: '1212121212',
          qrCode: 'customer:dep',
        ),
      );
      final CustomerRow row = await (db.select(db.customers)
            ..where((t) => t.id.equals('CUS-DEP')))
          .getSingle();
      expect(row.depositBalance, 0);

      await db.into(db.depositLedger).insert(
        DepositLedgerCompanion.insert(
          id: 'DEP-1',
          customerId: 'CUS-DEP',
          type: DepositLedgerType.topUp.storageValue,
          amount: 100,
          balanceAfter: 100,
          at: DateTime.now(),
        ),
      );
      expect(await db.select(db.depositLedger).get(), hasLength(1));
    });
  });
}
