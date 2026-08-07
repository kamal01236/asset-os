@Tags(['unit', 'returns'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/core/l10n/timeline_l10n.dart';
import 'package:asset_os/core/models/entities.dart';
import 'package:asset_os/core/repositories/local_repository.dart';

import 'support/test_harness.dart';

void main() {
  group('partial return', () {
    test('four lines return one-by-one; stock restores; last closes', () async {
      final LocalRepository repository = await bootRepo();
      final Customer customer =
          await ensureCustomer(repository);

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
      final LocalRepository repository = await bootRepo();
      final Customer customer =
          await ensureCustomer(repository);

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
        depositTopUpPaise: 1500,
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
    });

    test('returnRental returns all open lines', () async {
      final LocalRepository repository = await bootRepo();
      final Customer customer =
          await ensureCustomer(repository, phone: '9999999999', name: 'Ravi Das');

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
      final LocalRepository repository = await bootRepo();
      final Customer customer =
          await ensureCustomer(repository);

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

    test('chargedTotal below computed stores discount and note on event', () async {
      final LocalRepository repository = await bootRepo();
      final Customer customer =
          await ensureCustomer(repository);

      await repository.addInventory(
        name: 'Discount Kit',
        category: 'Tools',
        units: 2,
        billingMode: BillingMode.fixed,
        rateAmount: 5000,
      );
      final InventoryItem item = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.name == 'Discount Kit');

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: item.id,
            instanceName: 'Unit A',
            shortCode: 'DK-A',
          ),
          RentalLineInput(
            itemId: item.id,
            instanceName: 'Unit B',
            shortCode: 'DK-B',
          ),
        ],
        depositTopUpPaise: 10000,
      );
      final Rental rental = (await repository.listRentals()).first;
      final List<String> lineIds =
          rental.openLines.map((RentalLine l) => l.id).toList();

      final RentalReturnResult? result = await repository.returnRentalLines(
        rental.id,
        lineIds,
        chargedTotalPaise: 6000,
        note: 'Staff goodwill',
      );
      expect(result, isNotNull);
      expect(result!.totalAmount, 6000);
      expect(result.depositApplied, 6000);
      expect(result.depositBalanceAfter, 4000);
      expect(result.rentalClosed, isTrue);

      final Rental closed = (await repository.listRentals())
          .firstWhere((Rental r) => r.id == rental.id);
      expect(closed.totalAmount, 6000);
      expect(closed.baseAmount + closed.lateAmount, 6000);

      final RentalEvent returnEvent = closed.timeline.lastWhere(
        (RentalEvent e) => e.title == TimelineTitleKey.returned,
      );
      expect(returnEvent.subtitle, startsWith(TimelineSubtitleKey.allLinesReturned));
      expect(returnEvent.subtitle, contains('d:'));
      expect(returnEvent.subtitle, contains('Staff goodwill'));
    });

    test('returnRentalQuantities multi-step by itemId; last closes', () async {
      final LocalRepository repository = await bootRepo();
      final Customer customer = await ensureCustomer(repository);

      await repository.addInventory(
        name: 'Scaffold',
        category: 'Construction',
        units: 10,
        billingMode: BillingMode.fixed,
        rateAmount: 1000,
        requiresUnitIdentity: false,
      );
      final InventoryItem scaffold = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.name == 'Scaffold');

      await repository.createRental(
        customer: customer,
        lines: List<RentalLineInput>.generate(
          10,
          (int i) => RentalLineInput(
            itemId: scaffold.id,
            instanceName: 'Unit ${i + 1}',
            shortCode: 'SC-${i + 1}',
          ),
        ),
      );
      final Rental created = (await repository.listRentals()).first;
      expect(created.openRentLines, hasLength(10));

      final RentalReturnResult? first = await repository.returnRentalQuantities(
        created.id,
        <String, int>{scaffold.id: 3},
      );
      expect(first, isNotNull);
      expect(first!.rentalClosed, isFalse);
      expect(first.returnedLineIds, hasLength(3));

      Rental mid = (await repository.listRentals())
          .firstWhere((Rental r) => r.id == created.id);
      expect(mid.openRentLines, hasLength(7));
      expect(mid.returnedLines, hasLength(3));
      expect(
        mid.returnedLines.every(
          (RentalLine l) =>
              l.returnDisposition == ReturnDisposition.returned,
        ),
        isTrue,
      );

      InventoryItem stock = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.id == scaffold.id);
      expect(stock.availableUnits, 3);

      final RentalEvent partialEvent = mid.timeline.firstWhere(
        (RentalEvent e) => e.title == TimelineTitleKey.partialReturn,
      );
      expect(
        partialEvent.subtitle,
        startsWith(TimelineSubtitleKey.partialReturnQty),
      );
      expect(partialEvent.subtitle, contains('Scaffold × 3'));

      final RentalReturnResult? second = await repository.returnRentalQuantities(
        created.id,
        <String, int>{scaffold.id: 4},
      );
      expect(second!.rentalClosed, isFalse);
      expect(second.returnedLineIds, hasLength(4));

      mid = (await repository.listRentals())
          .firstWhere((Rental r) => r.id == created.id);
      expect(mid.openRentLines, hasLength(3));
      expect(
        mid.timeline
            .where((RentalEvent e) => e.title == TimelineTitleKey.partialReturn)
            .length,
        2,
      );

      final RentalReturnResult? last = await repository.returnRentalQuantities(
        created.id,
        <String, int>{scaffold.id: 3},
      );
      expect(last!.rentalClosed, isTrue);

      final Rental closed = (await repository.listRentals())
          .firstWhere((Rental r) => r.id == created.id);
      expect(closed.isActive, isFalse);
      expect(closed.openRentLines, isEmpty);
      stock = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.id == scaffold.id);
      expect(stock.availableUnits, 10);
    });

    test('mark lost short-closes without stock restore', () async {
      final LocalRepository repository = await bootRepo();
      final Customer customer = await ensureCustomer(repository);

      await repository.addInventory(
        name: 'Pipe',
        category: 'Construction',
        units: 5,
        billingMode: BillingMode.fixed,
        rateAmount: 2000,
        requiresUnitIdentity: false,
      );
      final InventoryItem pipe = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.name == 'Pipe');

      await repository.createRental(
        customer: customer,
        lines: List<RentalLineInput>.generate(
          5,
          (int i) => RentalLineInput(
            itemId: pipe.id,
            instanceName: 'Pipe ${i + 1}',
            shortCode: 'PP-${i + 1}',
          ),
        ),
      );
      final Rental rental = (await repository.listRentals()).first;

      await repository.returnRentalQuantities(
        rental.id,
        <String, int>{pipe.id: 3},
      );
      InventoryItem stock = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.id == pipe.id);
      expect(stock.availableUnits, 3);

      final RentalReturnResult? lost = await repository.markRentalQuantitiesLost(
        rental.id,
        <String, int>{pipe.id: 2},
      );
      expect(lost, isNotNull);
      expect(lost!.rentalClosed, isTrue);
      expect(lost.lostLineIds, hasLength(2));
      expect(lost.returnedLineIds, isEmpty);

      stock = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.id == pipe.id);
      expect(stock.availableUnits, 3);

      final Rental closed = (await repository.listRentals())
          .firstWhere((Rental r) => r.id == rental.id);
      expect(closed.isActive, isFalse);
      expect(
        closed.lines.where((RentalLine l) => l.isLost),
        hasLength(2),
      );
      expect(
        closed.timeline.any(
          (RentalEvent e) => e.title == TimelineTitleKey.unitsLost,
        ),
        isTrue,
      );
      final RentalEvent lostEvent = closed.timeline.firstWhere(
        (RentalEvent e) => e.title == TimelineTitleKey.unitsLost,
      );
      expect(
        lostEvent.subtitle,
        startsWith(TimelineSubtitleKey.unitsLostQty),
      );
      expect(lostEvent.subtitle, contains('Pipe × 2'));
    });

    test('identity-required items still return by explicit line ids', () async {
      final LocalRepository repository = await bootRepo();
      final Customer customer = await ensureCustomer(repository);

      await repository.addInventory(
        name: 'Camera',
        category: 'AV',
        units: 3,
        billingMode: BillingMode.fixed,
        rateAmount: 5000,
        requiresUnitIdentity: true,
      );
      final InventoryItem camera = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.name == 'Camera');

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: camera.id,
            instanceName: 'Body A',
            shortCode: 'CAM-A',
          ),
          RentalLineInput(
            itemId: camera.id,
            instanceName: 'Body B',
            shortCode: 'CAM-B',
          ),
          RentalLineInput(
            itemId: camera.id,
            instanceName: 'Body C',
            shortCode: 'CAM-C',
          ),
        ],
      );
      final Rental rental = (await repository.listRentals()).first;
      final String lineB = rental.openRentLines
          .firstWhere((RentalLine l) => l.shortCode == 'CAM-B')
          .id;

      final RentalReturnResult? first = await repository.returnRentalLines(
        rental.id,
        <String>[lineB],
      );
      expect(first!.returnedLineIds, <String>[lineB]);
      expect(first.rentalClosed, isFalse);

      Rental mid = (await repository.listRentals())
          .firstWhere((Rental r) => r.id == rental.id);
      expect(
        mid.openRentLines.map((RentalLine l) => l.shortCode).toList()..sort(),
        <String>['CAM-A', 'CAM-C'],
      );

      final RentalReturnResult? rest = await repository.returnRentalLines(
        rental.id,
        mid.openRentLines.map((RentalLine l) => l.id).toList(),
      );
      expect(rest!.rentalClosed, isTrue);
    });
  });

  group('cancel order', () {
    test('restores stock and settles kept/returned deposit', () async {
      final LocalRepository repository = await bootRepo();
      final Customer customer =
          await ensureCustomer(repository);

      await repository.addInventory(
        name: 'Cancel Kit',
        category: 'Tools',
        units: 2,
        billingMode: BillingMode.fixed,
        rateAmount: 2000,
      );
      final InventoryItem item = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.name == 'Cancel Kit');

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: item.id,
            instanceName: 'One',
            shortCode: 'CK-1',
          ),
          RentalLineInput(
            itemId: item.id,
            instanceName: 'Two',
            shortCode: 'CK-2',
          ),
        ],
        depositTopUpPaise: 10000,
      );
      final Rental rental = (await repository.listRentals()).first;
      expect(
        (await repository.listInventory())
            .firstWhere((InventoryItem i) => i.id == item.id)
            .availableUnits,
        0,
      );

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
      expect(closed.isActive, isFalse);
      expect(closed.orderStatus, OrderStatus.cancelled);
      expect(closed.totalAmount, 0);
      expect(closed.openLines, isEmpty);
      expect(
        closed.timeline.any(
          (RentalEvent e) => e.title == TimelineTitleKey.orderCancelled,
        ),
        isTrue,
      );

      final InventoryItem stock = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.id == item.id);
      expect(stock.availableUnits, 2);

      final Customer after =
          (await repository.listCustomers())
              .firstWhere((Customer c) => c.id == customer.id);
      expect(after.depositBalance, 0);
    });

    test('blocked after partial return', () async {
      final LocalRepository repository = await bootRepo();
      final Customer customer =
          await ensureCustomer(repository, phone: '8888888888', name: 'Neha Shah');

      await repository.addInventory(
        name: 'Block Cancel',
        category: 'Tools',
        units: 2,
        billingMode: BillingMode.fixed,
        rateAmount: 1000,
      );
      final InventoryItem item = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.name == 'Block Cancel');

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: item.id,
            instanceName: 'Unit A',
            shortCode: 'BC-A',
          ),
          RentalLineInput(
            itemId: item.id,
            instanceName: 'Unit B',
            shortCode: 'BC-B',
          ),
        ],
      );
      final Rental rental = (await repository.listRentals()).first;
      await repository.returnRentalLines(
        rental.id,
        <String>[rental.openLines.first.id],
      );

      expect(
        () => repository.cancelOrder(rentalId: rental.id),
        throwsA(isA<StateError>()),
      );
    });
  });
}
