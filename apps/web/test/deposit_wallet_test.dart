import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:asset_os/core/db/app_database.dart';
import 'package:asset_os/core/models/entities.dart';
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

  group('customer deposit wallet', () {
    test('topUpDeposit credits balance and ledger', () async {
      final LocalRepository repository = await _bootRepo();
      final Customer customer =
          (await repository.customerByPhone('6666666666'))!;

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
      final LocalRepository repository = await _bootRepo();
      final Customer customer =
          (await repository.customerByPhone('6666666666'))!;
      expect(
        () => repository.topUpDeposit(customer.id, 0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('refundDeposit debits and cannot exceed balance', () async {
      final LocalRepository repository = await _bootRepo();
      final Customer customer =
          (await repository.customerByPhone('6666666666'))!;
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

    test('returnRental applies min(balance, total) and leftover carries', () async {
      final LocalRepository repository = await _bootRepo();
      final Customer customer =
          (await repository.customerByPhone('6666666666'))!;
      await repository.topUpDeposit(customer.id, 8000);

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
      );
      final Rental created = (await repository.listRentals()).first;
      expect(created.totalAmount, 5000);

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
      expect(after.depositBalance, 3000);

      final Rental returned = (await repository.listRentals())
          .firstWhere((Rental r) => r.id == created.id);
      expect(returned.depositApplied, 5000);
      expect(returned.amountDueAfterDeposit, 0);

      final List<DepositLedgerEntry> ledger =
          await repository.listDepositLedger(customer.id);
      expect(
        ledger.any((DepositLedgerEntry e) => e.type == DepositLedgerType.apply),
        isTrue,
      );
      final DepositLedgerEntry apply = ledger.firstWhere(
        (DepositLedgerEntry e) => e.type == DepositLedgerType.apply,
      );
      expect(apply.amount, -5000);
      expect(apply.rentalId, created.id);
      expect(apply.balanceAfter, 3000);
    });

    test('returnRental leaves remaining due when deposit is short', () async {
      final LocalRepository repository = await _bootRepo();
      final Customer customer =
          (await repository.customerByPhone('7777777777'))!;
      await repository.topUpDeposit(customer.id, 2000);

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

    test('leftover deposit remains for next rental issue', () async {
      final LocalRepository repository = await _bootRepo();
      final Customer customer =
          (await repository.customerByPhone('9999999999'))!;
      await repository.topUpDeposit(customer.id, 15000);

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
      );
      final String firstId = (await repository.listRentals()).first.id;
      await repository.returnRental(firstId);

      final Customer mid =
          (await repository.listCustomers())
              .firstWhere((Customer c) => c.id == customer.id);
      expect(mid.depositBalance, 11000);

      await repository.createRental(
        customer: mid,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: item.id,
            instanceName: 'Kit B',
            shortCode: 'CF-02',
          ),
        ],
      );
      final Customer still =
          (await repository.listCustomers())
              .firstWhere((Customer c) => c.id == customer.id);
      expect(still.depositBalance, 11000);

      final Rental second = (await repository.listRentals())
          .firstWhere((Rental r) => r.isActive);
      final RentalReturnResult? result =
          await repository.returnRental(second.id);
      expect(result!.depositApplied, 4000);
      expect(result.depositBalanceAfter, 7000);
    });

    test('return with zero deposit still finalizes charges', () async {
      final LocalRepository repository = await _bootRepo();
      final Customer customer =
          (await repository.customerByPhone('6666666666'))!;
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
      expect(db.schemaVersion, 6);

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
