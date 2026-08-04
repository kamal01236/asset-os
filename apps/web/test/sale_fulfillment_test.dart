import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/core/inventory/inventory_categories.dart';
import 'package:asset_os/core/models/entities.dart';
import 'package:asset_os/core/repositories/local_repository.dart';

import 'support/test_harness.dart';

void main() {
  group('sale fulfillment', () {
    test('General category persists defaultItemKind=general', () async {
      final LocalRepository repository = await bootRepo();
      await repository.addInventory(
        name: 'USB Cable',
        category: kCategoryGeneral,
        units: 3,
        requiresUnitIdentity: false,
        defaultItemKind: InventoryItemKind.general,
      );
      final InventoryItem item = (await repository.listInventory()).single;
      expect(item.category, kCategoryGeneral);
      expect(item.defaultItemKind, InventoryItemKind.general);
      expect(item.isGeneral, isTrue);
      expect(repository.database.schemaVersion, 10);
    });

    test('rental item sold with manual amount drops total and closes line',
        () async {
      final LocalRepository repository = await bootRepo();
      await repository.addInventory(
        name: 'Tripod',
        category: 'Camera',
        units: 2,
        billingMode: BillingMode.daily,
        rateAmount: 10000,
        requiresUnitIdentity: false,
      );
      final InventoryItem tripod = (await repository.listInventory()).single;
      final Customer customer = await ensureCustomer(repository);

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: tripod.id,
            instanceName: 'Tripod',
            shortCode: 'TRI-1',
            fulfillment: LineFulfillment.sell,
            manualSaleAmountPaise: 25000,
          ),
        ],
      );

      final InventoryItem after = (await repository.listInventory()).single;
      expect(after.availableUnits, 1);
      expect(after.totalUnits, 1);

      final Rental order = (await repository.listRentals()).single;
      expect(order.isActive, isFalse);
      expect(order.orderStatus, OrderStatus.completed);
      expect(order.returnedAt, isNotNull);
      expect(order.baseAmount, 25000);
      expect(order.lines.single.fulfillment, LineFulfillment.sell);
      expect(order.lines.single.isOpen, isFalse);
      expect(order.lines.single.baseAmount, 25000);
      expect(order.lines.single.lateAmount, 0);
    });

    test('general item rented opens with duration and keeps total', () async {
      final LocalRepository repository = await bootRepo();
      await repository.addInventory(
        name: 'Extension Cord',
        category: kCategoryGeneral,
        units: 4,
        billingMode: BillingMode.daily,
        rateAmount: 5000,
        requiresUnitIdentity: false,
        defaultItemKind: InventoryItemKind.general,
      );
      final InventoryItem cord = (await repository.listInventory()).single;
      final Customer customer = await ensureCustomer(repository);

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: cord.id,
            instanceName: 'Extension Cord',
            shortCode: 'CRD-1',
            fulfillment: LineFulfillment.rent,
            durationUnits: 2,
          ),
        ],
        durationUnits: 2,
      );

      final InventoryItem after = (await repository.listInventory()).single;
      expect(after.availableUnits, 3);
      expect(after.totalUnits, 4);

      final Rental order = (await repository.listRentals()).single;
      expect(order.isActive, isTrue);
      expect(order.lines.single.fulfillment, LineFulfillment.rent);
      expect(order.lines.single.isOpen, isTrue);
      expect(order.baseAmount, 10000);
    });

    test('mixed order keeps rent open and closes sell with stock drop',
        () async {
      final LocalRepository repository = await bootRepo();
      await repository.addInventory(
        name: 'Novel',
        category: 'Library',
        units: 3,
        billingMode: BillingMode.weekly,
        rateAmount: 5000,
        requiresUnitIdentity: true,
      );
      await repository.addInventory(
        name: 'Bookmark',
        category: kCategoryGeneral,
        units: 5,
        requiresUnitIdentity: false,
        defaultItemKind: InventoryItemKind.general,
      );
      final List<InventoryItem> inventory = await repository.listInventory();
      final InventoryItem novel =
          inventory.firstWhere((InventoryItem i) => i.name == 'Novel');
      final InventoryItem bookmark =
          inventory.firstWhere((InventoryItem i) => i.name == 'Bookmark');
      final Customer customer = await ensureCustomer(repository);

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: novel.id,
            instanceName: 'Harry Potter',
            shortCode: 'NOV-100',
            fulfillment: LineFulfillment.rent,
            durationUnits: 1,
          ),
          RentalLineInput(
            itemId: bookmark.id,
            instanceName: 'Bookmark',
            shortCode: 'BMK-1',
            fulfillment: LineFulfillment.sell,
            manualSaleAmountPaise: 1500,
          ),
        ],
      );

      final List<InventoryItem> after = await repository.listInventory();
      final InventoryItem novelAfter =
          after.firstWhere((InventoryItem i) => i.name == 'Novel');
      final InventoryItem bookmarkAfter =
          after.firstWhere((InventoryItem i) => i.name == 'Bookmark');
      expect(novelAfter.availableUnits, 2);
      expect(novelAfter.totalUnits, 3);
      expect(bookmarkAfter.availableUnits, 4);
      expect(bookmarkAfter.totalUnits, 4);

      final Rental order = (await repository.listRentals()).single;
      expect(order.isActive, isTrue);
      expect(order.lines.length, 2);
      final RentalLine rentLine = order.lines
          .firstWhere((RentalLine l) => l.fulfillment == LineFulfillment.rent);
      final RentalLine sellLine = order.lines
          .firstWhere((RentalLine l) => l.fulfillment == LineFulfillment.sell);
      expect(rentLine.isOpen, isTrue);
      expect(sellLine.isOpen, isFalse);
      expect(sellLine.baseAmount, 1500);
      expect(order.baseAmount, 5000 + 1500);
    });

    test('sell rejects zero amount', () async {
      final LocalRepository repository = await bootRepo();
      await repository.addInventory(
        name: 'Lens Cap',
        category: kCategoryGeneral,
        units: 1,
        requiresUnitIdentity: false,
        defaultItemKind: InventoryItemKind.general,
      );
      final InventoryItem item = (await repository.listInventory()).single;
      final Customer customer = await ensureCustomer(repository);

      await expectLater(
        () => repository.createRental(
          customer: customer,
          lines: <RentalLineInput>[
            RentalLineInput(
              itemId: item.id,
              instanceName: 'Lens Cap',
              shortCode: 'CAP-1',
              fulfillment: LineFulfillment.sell,
              manualSaleAmountPaise: 0,
            ),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
