@Tags(['unit', 'orders', 'deposit'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/domain/models/entities.dart';
import 'package:asset_os/domain/orders/commercial_policy.dart';
import 'package:asset_os/domain/orders/order_payment.dart';
import 'package:asset_os/infrastructure/l10n/timeline_l10n.dart';
import 'package:asset_os/application/local_repository.dart';

import 'support/test_harness.dart';

void main() {
  group('order payment allocation', () {
    test('sell-first then advance; shortfall is discount', () {
      final OrderPaymentAllocation full = allocateOrderPayment(
        sellOutstandingPaise: 10000,
        amountReceivedPaise: 15000,
        securityPaise: 5000,
      );
      expect(full.sellPaidDelta, 10000);
      expect(full.sellDiscountDelta, 0);
      expect(full.advanceDelta, 5000);

      final OrderPaymentAllocation short = allocateOrderPayment(
        sellOutstandingPaise: 10000,
        amountReceivedPaise: 7000,
        securityPaise: 5000,
      );
      expect(short.sellPaidDelta, 7000);
      expect(short.sellDiscountDelta, 3000);
      expect(short.advanceDelta, 0);

      final OrderPaymentAllocation excessAdvance = allocateOrderPayment(
        sellOutstandingPaise: 10000,
        amountReceivedPaise: 20000,
        securityPaise: 5000,
      );
      expect(excessAdvance.advanceDelta, 10000);

      final OrderPaymentAllocation capped = allocateOrderPayment(
        sellOutstandingPaise: 10000,
        amountReceivedPaise: 20000,
        securityPaise: 5000,
        treatExcessAsDiscount: true,
      );
      expect(capped.advanceDelta, 5000);
      expect(capped.sellDiscountDelta, 0);
    });

    test('suggested security sums catalog × rent lines', () {
      const InventoryItem cam = InventoryItem(
        id: 'INV-1',
        name: 'Cam',
        category: 'Camera',
        availableUnits: 2,
        totalUnits: 2,
        status: AssetStatus.available,
        qrCode: 'inventory:1',
        securityDepositPaise: 50000,
      );
      const InventoryItem sale = InventoryItem(
        id: 'INV-2',
        name: 'Cable',
        category: 'General',
        availableUnits: 5,
        totalUnits: 5,
        status: AssetStatus.available,
        qrCode: 'inventory:2',
        defaultItemKind: ResourceType.sale,
        securityDepositPaise: 99999,
      );
      final Rental rental = Rental(
        id: 'REN-1',
        customerId: 'CUS-1',
        lines: const <RentalLine>[
          RentalLine(
            id: 'RLI-1',
            itemId: 'INV-1',
            catalogName: 'Cam',
            instanceName: 'Cam A',
            shortCode: 'CAM-1',
          ),
          RentalLine(
            id: 'RLI-2',
            itemId: 'INV-1',
            catalogName: 'Cam',
            instanceName: 'Cam B',
            shortCode: 'CAM-2',
          ),
          RentalLine(
            id: 'RLI-3',
            itemId: 'INV-2',
            catalogName: 'Cable',
            instanceName: 'Cable',
            shortCode: 'CAB-1',
            fulfillment: LineFulfillment.sell,
            baseAmount: 1000,
          ),
        ],
        startedAt: DateTime(2026, 1, 1),
        timeline: const <RentalEvent>[],
        qrCode: 'rental:1',
      );
      expect(
        computeSuggestedSecurityPaise(rental, <String, InventoryItem>{
          cam.id: cam,
          sale.id: sale,
        }),
        100000,
      );
    });
  });

  group('recordOrderPayment', () {
    test('full sell + security on mixed order', () async {
      final LocalRepository repository = await bootRepo();

      await repository.addInventory(
        name: 'Novel',
        category: 'Books',
        units: 3,
        rateAmount: 10000,
        securityDepositPaise: 20000,
        requiresUnitIdentity: false,
      );
      await repository.addInventory(
        name: 'Bookmark',
        category: 'General',
        units: 5,
        rateAmount: 5000,
        defaultItemKind: ResourceType.sale,
        requiresUnitIdentity: false,
      );
      final List<InventoryItem> inventory = await repository.listInventory();
      final InventoryItem novel =
          inventory.firstWhere((InventoryItem i) => i.name == 'Novel');
      final InventoryItem bookmark =
          inventory.firstWhere((InventoryItem i) => i.name == 'Bookmark');
      expect(novel.securityDepositPaise, 20000);

      final Customer customer = await ensureCustomer(repository);
      final String rentalId = await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: novel.id,
            instanceName: 'Novel',
            shortCode: 'NOV-1',
            durationUnits: 1,
          ),
          RentalLineInput(
            itemId: bookmark.id,
            instanceName: 'Bookmark',
            shortCode: 'BM-1',
            fulfillment: LineFulfillment.sell,
            manualSaleAmountPaise: 5000,
          ),
        ],
      );

      final Rental before = (await repository.listRentals())
          .firstWhere((Rental r) => r.id == rentalId);
      expect(before.depositAmount, 0);
      expect(before.sellDuePaise, 5000);
      expect(before.hasUnpaidSell, isTrue);
      expect(
        repository.suggestedSecurityPaiseFor(
          before,
          <String, InventoryItem>{for (final InventoryItem i in inventory) i.id: i},
        ),
        20000,
      );

      final Rental paid = await repository.recordOrderPayment(
        rentalId: rentalId,
        amountReceivedPaise: 25000,
        securityPaise: 20000,
        referenceCode: 'UPI-123',
      );
      expect(paid.sellPaidPaise, 5000);
      expect(paid.sellDiscountPaise, 0);
      expect(paid.depositAmount, 20000);
      expect(paid.hasUnpaidSell, isFalse);

      final RentalEvent paymentEvent = paid.timeline.lastWhere(
        (RentalEvent e) => e.title == TimelineTitleKey.paymentReceived,
      );
      expect(paymentEvent.referenceCode, 'UPI-123');
    });

    test('partial sell pay records discount and clears unpaid', () async {
      final LocalRepository repository = await bootRepo();
      await repository.addInventory(
        name: 'Cable',
        category: 'General',
        units: 2,
        defaultItemKind: ResourceType.sale,
        requiresUnitIdentity: false,
      );
      final InventoryItem item = (await repository.listInventory()).single;
      final Customer customer = await ensureCustomer(repository);
      final String rentalId = await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: item.id,
            instanceName: 'Cable',
            shortCode: 'CAB-1',
            fulfillment: LineFulfillment.sell,
            manualSaleAmountPaise: 10000,
          ),
        ],
      );

      final Rental paid = await repository.recordOrderPayment(
        rentalId: rentalId,
        amountReceivedPaise: 7000,
        securityPaise: 0,
        referenceCode: 'CASH-1',
      );
      expect(paid.sellPaidPaise, 7000);
      expect(paid.sellDiscountPaise, 3000);
      expect(paid.hasUnpaidSell, isFalse);
      expect(paid.depositAmount, 0);
    });

    test('rent-only security sets deposit; sell due 0', () async {
      final LocalRepository repository = await bootRepo();
      await repository.addInventory(
        name: 'Lens',
        category: 'Camera',
        units: 2,
        rateAmount: 50000,
        securityDepositPaise: 100000,
        requiresUnitIdentity: false,
      );
      final InventoryItem item = (await repository.listInventory()).single;
      final Customer customer = await ensureCustomer(repository);
      final String rentalId = await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: item.id,
            instanceName: 'Lens',
            shortCode: 'LEN-1',
            durationUnits: 2,
          ),
        ],
      );

      final Rental before = (await repository.listRentals())
          .firstWhere((Rental r) => r.id == rentalId);
      expect(before.sellDuePaise, 0);
      expect(before.hasUnpaidSell, isFalse);

      final Rental paid = await repository.recordOrderPayment(
        rentalId: rentalId,
        amountReceivedPaise: 100000,
        securityPaise: 100000,
        referenceCode: 'ADV-001',
      );
      expect(paid.depositAmount, 100000);
      expect(paid.sellPaidPaise, 0);
      expect(paid.sellDiscountPaise, 0);
    });
  });

  group('createOrderWithSettlement', () {
    test('refuses issue when required security missing', () async {
      final LocalRepository repository = await bootRepo();
      await repository.addInventory(
        name: 'DSLR',
        category: 'Camera',
        units: 2,
        rateAmount: 150000,
        securityDepositPaise: 500000,
        requiresUnitIdentity: false,
      );
      final InventoryItem item = (await repository.listInventory()).single;
      final Customer customer = await ensureCustomer(repository);
      final AggregatedOrderCommercial commercial = resolveOrderCommercial(
        <CommercialLineInput>[
          CommercialLineInput.fromCatalog(
            item: item,
            fulfillment: LineFulfillment.rent,
            lineAmountPaise: 150000,
            unitRatePaise: 150000,
          ),
        ],
        templateByType: const <ResourceType, CommercialPolicy>{
          ResourceType.rental: CommercialPolicy(
            pay: CommercialRequirement.optional,
            security: CommercialRequirement.required,
          ),
        },
      );
      expect(
        () => repository.createOrderWithSettlement(
          customer: customer,
          lines: <RentalLineInput>[
            RentalLineInput(
              itemId: item.id,
              instanceName: 'Body A',
              shortCode: 'CAM-A1',
              durationUnits: 1,
            ),
          ],
          amountReceivedPaise: 0,
          securityPaise: 0,
          commercial: commercial,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(await repository.listRentals(), isEmpty);
    });

    test('records sell pay and security atomically', () async {
      final LocalRepository repository = await bootRepo();
      await repository.addInventory(
        name: 'Oil',
        category: 'Parlour',
        units: 5,
        rateAmount: 15000,
        defaultItemKind: ResourceType.sale,
        requiresUnitIdentity: false,
      );
      await repository.addInventory(
        name: 'Steamer',
        category: 'Parlour',
        units: 2,
        rateAmount: 20000,
        securityDepositPaise: 20000,
        requiresUnitIdentity: false,
      );
      final List<InventoryItem> inventory = await repository.listInventory();
      final InventoryItem oil =
          inventory.firstWhere((InventoryItem i) => i.name == 'Oil');
      final InventoryItem steamer =
          inventory.firstWhere((InventoryItem i) => i.name == 'Steamer');
      final Customer customer = await ensureCustomer(repository);
      final AggregatedOrderCommercial commercial = resolveOrderCommercial(
        <CommercialLineInput>[
          CommercialLineInput.fromCatalog(
            item: oil,
            fulfillment: LineFulfillment.sell,
            lineAmountPaise: 15000,
            unitRatePaise: 15000,
          ),
          CommercialLineInput.fromCatalog(
            item: steamer,
            fulfillment: LineFulfillment.rent,
            lineAmountPaise: 20000,
            unitRatePaise: 20000,
          ),
        ],
      );
      final String rentalId = await repository.createOrderWithSettlement(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: oil.id,
            instanceName: 'Oil',
            shortCode: 'OIL-1',
            fulfillment: LineFulfillment.sell,
            manualSaleAmountPaise: 15000,
          ),
          RentalLineInput(
            itemId: steamer.id,
            instanceName: 'Steamer',
            shortCode: 'STM-1',
            durationUnits: 1,
          ),
        ],
        amountReceivedPaise: 35000,
        securityPaise: 20000,
        commercial: commercial,
        referenceCode: 'SETTLE-1',
      );
      final Rental paid = (await repository.listRentals())
          .firstWhere((Rental r) => r.id == rentalId);
      expect(paid.sellPaidPaise, 15000);
      expect(paid.depositAmount, 20000);
      expect(paid.hasUnpaidSell, isFalse);
      final RentalEvent paymentEvent = paid.timeline.lastWhere(
        (RentalEvent e) => e.title == TimelineTitleKey.paymentReceived,
      );
      expect(paymentEvent.referenceCode, 'SETTLE-1');
    });

    test('settlement without note records payment', () async {
      final LocalRepository repository = await bootRepo();
      await repository.addInventory(
        name: 'Oil',
        category: 'Parlour',
        units: 5,
        rateAmount: 15000,
        defaultItemKind: ResourceType.sale,
        requiresUnitIdentity: false,
      );
      final InventoryItem oil = (await repository.listInventory()).single;
      final Customer customer = await ensureCustomer(repository);
      final String rentalId = await repository.createOrderWithSettlement(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: oil.id,
            instanceName: 'Oil',
            shortCode: 'OIL-2',
            fulfillment: LineFulfillment.sell,
            manualSaleAmountPaise: 15000,
          ),
        ],
        amountReceivedPaise: 15000,
        securityPaise: 0,
      );
      final Rental paid = (await repository.listRentals())
          .firstWhere((Rental r) => r.id == rentalId);
      expect(paid.sellPaidPaise, 15000);
      final RentalEvent paymentEvent = paid.timeline.lastWhere(
        (RentalEvent e) => e.title == TimelineTitleKey.paymentReceived,
      );
      expect(paymentEvent.referenceCode, isNull);
    });
  });
}
