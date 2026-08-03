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

  group('partial return and replace', () {
    test('four lines return one-by-one; stock restores; last closes', () async {
      final LocalRepository repository = await _bootRepo();
      final Customer customer =
          (await repository.customerByPhone('6666666666'))!;

      await repository.addInventory(
        name: 'Partial Novel',
        category: 'Library',
        units: 4,
        billingMode: BillingMode.weekly,
        rateAmount: 1000,
      );
      final InventoryItem novel = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.name == 'Partial Novel');

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: novel.id,
            instanceName: 'Copy 1',
            shortCode: 'PN-01',
          ),
          RentalLineInput(
            itemId: novel.id,
            instanceName: 'Copy 2',
            shortCode: 'PN-02',
          ),
          RentalLineInput(
            itemId: novel.id,
            instanceName: 'Copy 3',
            shortCode: 'PN-03',
          ),
          RentalLineInput(
            itemId: novel.id,
            instanceName: 'Copy 4',
            shortCode: 'PN-04',
          ),
        ],
      );

      final Rental created = (await repository.listRentals()).first;
      expect(created.lines, hasLength(4));
      expect(created.openLines, hasLength(4));
      expect(created.baseAmount, 4000);

      InventoryItem stock = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.id == novel.id);
      expect(stock.availableUnits, 0);

      final String firstId = created.openLines.first.id;
      final RentalReturnResult? first = await repository.returnRentalLines(
        created.id,
        <String>[firstId],
      );
      expect(first, isNotNull);
      expect(first!.rentalClosed, isFalse);
      expect(first.returnedLineIds, <String>[firstId]);
      expect(first.totalAmount, 1000);

      Rental mid = (await repository.listRentals())
          .firstWhere((Rental r) => r.id == created.id);
      expect(mid.isActive, isTrue);
      expect(mid.openLines, hasLength(3));
      expect(mid.returnedLines, hasLength(1));

      stock = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.id == novel.id);
      expect(stock.availableUnits, 1);

      // Short code freed after return.
      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: novel.id,
            instanceName: 'Reuse code',
            shortCode: 'PN-01',
          ),
        ],
      );

      mid = (await repository.listRentals())
          .firstWhere((Rental r) => r.id == created.id);
      final List<String> rest =
          mid.openLines.map((RentalLine l) => l.id).toList();
      final RentalReturnResult? restResult =
          await repository.returnRentalLines(created.id, rest);
      expect(restResult!.rentalClosed, isTrue);

      final Rental closed = (await repository.listRentals())
          .firstWhere((Rental r) => r.id == created.id);
      expect(closed.isActive, isFalse);
      expect(closed.openLines, isEmpty);
      expect(closed.returnedLines, hasLength(4));
    });

    test('deposit applies per line across partial returns', () async {
      final LocalRepository repository = await _bootRepo();
      final Customer customer =
          (await repository.customerByPhone('6666666666'))!;
      await repository.topUpDeposit(customer.id, 1500);

      await repository.addInventory(
        name: 'Deposit Partial',
        category: 'Library',
        units: 2,
        billingMode: BillingMode.fixed,
        rateAmount: 1000,
      );
      final InventoryItem item = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.name == 'Deposit Partial');

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: item.id,
            instanceName: 'Unit A',
            shortCode: 'DP-A',
          ),
          RentalLineInput(
            itemId: item.id,
            instanceName: 'Unit B',
            shortCode: 'DP-B',
          ),
        ],
      );
      final Rental rental = (await repository.listRentals()).first;
      final String lineA = rental.openLines.first.id;
      final String lineB = rental.openLines.last.id;

      final RentalReturnResult? first =
          await repository.returnRentalLines(rental.id, <String>[lineA]);
      expect(first!.depositApplied, 1000);
      expect(first.depositBalanceAfter, 500);

      final RentalReturnResult? second =
          await repository.returnRentalLines(rental.id, <String>[lineB]);
      expect(second!.depositApplied, 500);
      expect(second.amountDue, 500);
      expect(second.depositBalanceAfter, 0);
      expect(second.rentalClosed, isTrue);

      final List<DepositLedgerEntry> applyEntries =
          (await repository.listDepositLedger(customer.id))
              .where((DepositLedgerEntry e) => e.type == DepositLedgerType.apply)
              .toList();
      expect(applyEntries, hasLength(2));
    });

    test('replace returns line and opens new rental with link', () async {
      final LocalRepository repository = await _bootRepo();
      final Customer customer =
          (await repository.customerByPhone('7777777777'))!;
      await repository.topUpDeposit(customer.id, 5000);

      await repository.addInventory(
        name: 'Replace Kit',
        category: 'Tools',
        units: 3,
        billingMode: BillingMode.fixed,
        rateAmount: 2000,
      );
      final InventoryItem item = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.name == 'Replace Kit');

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: item.id,
            instanceName: 'Old unit',
            shortCode: 'RP-OLD',
          ),
          RentalLineInput(
            itemId: item.id,
            instanceName: 'Keep unit',
            shortCode: 'RP-KEEP',
          ),
        ],
      );
      final Rental original = (await repository.listRentals()).first;
      final String replaceId = original.openLines
          .firstWhere((RentalLine l) => l.shortCode == 'RP-OLD')
          .id;

      final RentalReplaceResult? result = await repository.replaceRentalLine(
        rentalId: original.id,
        lineId: replaceId,
        newLine: RentalLineInput(
          itemId: item.id,
          instanceName: 'New unit',
          shortCode: 'RP-NEW',
        ),
      );
      expect(result, isNotNull);
      expect(result!.returnResult.rentalClosed, isFalse);
      expect(result.returnResult.depositApplied, 2000);
      expect(result.returnResult.depositBalanceAfter, 3000);

      final Rental stillOpen = (await repository.listRentals())
          .firstWhere((Rental r) => r.id == original.id);
      expect(stillOpen.isActive, isTrue);
      expect(stillOpen.openLines, hasLength(1));
      expect(stillOpen.openLines.first.shortCode, 'RP-KEEP');

      final Rental replacement = (await repository.listRentals())
          .firstWhere((Rental r) => r.id == result.newRentalId);
      expect(replacement.customerId, customer.id);
      expect(replacement.replacedFromRentalId, original.id);
      expect(replacement.lines, hasLength(1));
      expect(replacement.lines.first.shortCode, 'RP-NEW');
      expect(replacement.lines.first.instanceName, 'New unit');
    });

    test('returnRental returns all open lines', () async {
      final LocalRepository repository = await _bootRepo();
      final Customer customer =
          (await repository.customerByPhone('9999999999'))!;

      await repository.addInventory(
        name: 'Full Return Pack',
        category: 'Tools',
        units: 2,
        billingMode: BillingMode.fixed,
        rateAmount: 3000,
      );
      final InventoryItem item = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.name == 'Full Return Pack');

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: item.id,
            instanceName: 'One',
            shortCode: 'FR-1',
          ),
          RentalLineInput(
            itemId: item.id,
            instanceName: 'Two',
            shortCode: 'FR-2',
          ),
        ],
      );
      final Rental rental = (await repository.listRentals()).first;
      final RentalReturnResult? result =
          await repository.returnRental(rental.id);
      expect(result!.rentalClosed, isTrue);
      expect(result.totalAmount, 6000);
      expect(result.returnedLineIds, hasLength(2));

      final Rental closed = (await repository.listRentals())
          .firstWhere((Rental r) => r.id == rental.id);
      expect(closed.isActive, isFalse);
    });

    test('search by returned short code does not match active rental', () async {
      final LocalRepository repository = await _bootRepo();
      final Customer customer =
          (await repository.customerByPhone('6666666666'))!;

      await repository.addInventory(
        name: 'Search Novel',
        category: 'Library',
        units: 2,
        billingMode: BillingMode.weekly,
        rateAmount: 1000,
      );
      final InventoryItem novel = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.name == 'Search Novel');

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: novel.id,
            instanceName: 'Alpha',
            shortCode: 'SR-ALPHA',
          ),
          RentalLineInput(
            itemId: novel.id,
            instanceName: 'Beta',
            shortCode: 'SR-BETA',
          ),
        ],
      );
      final Rental rental = (await repository.listRentals()).first;
      final String alphaId = rental.openLines
          .firstWhere((RentalLine l) => l.shortCode == 'SR-ALPHA')
          .id;
      await repository.returnRentalLines(rental.id, <String>[alphaId]);

      final SearchResults byReturned = await repository.search('SR-ALPHA');
      expect(byReturned.currentRentals, isEmpty);

      final SearchResults byOpen = await repository.search('SR-BETA');
      expect(byOpen.currentRentals, isNotEmpty);
      expect(byOpen.currentRentals.first.id, rental.id);
    });
  });
}
