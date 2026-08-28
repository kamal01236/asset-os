@Tags(['unit', 'orders'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/domain/models/entities.dart';
import 'package:asset_os/domain/orders/commercial_policy.dart';
import 'package:asset_os/domain/templates/industry_templates.dart';
import 'package:asset_os/domain/subscriptions/subscription_coverage.dart';
import 'package:asset_os/domain/subscriptions/subscription_models.dart';
import 'package:asset_os/application/local_repository.dart';

import 'support/test_harness.dart';

void main() {
  test('schemaVersion is 24 with customer_subscriptions', () async {
    final LocalRepository repo = await bootRepo();
    expect(repo.database.schemaVersion, 24);
  });

  test('seedDemo initialize completes', () async {
    final LocalRepository repo = await bootRepo(seedDemo: true);
    expect(await repo.listCustomers(), isNotEmpty);
    expect(await repo.listInventory(), isNotEmpty);
  });

  test('grant on membership sell; same-tier renew extends end', () async {
    final LocalRepository repo = await bootRepo();
    final Customer customer = await ensureCustomer(repo);
    final String planId = await repo.addInventory(
      name: 'Monthly Basic',
      category: 'Gym',
      units: 20,
      billingMode: BillingMode.monthly,
      rateAmount: 150000,
      defaultItemKind: ResourceType.membership,
      requiresUnitIdentity: false,
      metadata: <String, Object?>{
        kSubscriptionTierMetadataKey: 'basic',
        kSubscriptionPeriodUnitMetadataKey: 'month',
        kSubscriptionPeriodCountMetadataKey: 1,
      },
    );

    final String firstId = await repo.createRental(
      customer: customer,
      lines: <RentalLineInput>[
        RentalLineInput(
          itemId: planId,
          instanceName: 'Monthly Basic',
          shortCode: 'MEM-1',
          fulfillment: LineFulfillment.sell,
          manualSaleAmountPaise: 150000,
        ),
      ],
    );
    final List<CustomerSubscription> afterFirst =
        await repo.listCustomerSubscriptions(customer.id);
    expect(afterFirst, hasLength(1));
    expect(afterFirst.single.tier, SubscriptionTier.basic);
    expect(afterFirst.single.sourceRentalId, firstId);
    final DateTime firstEnd = afterFirst.single.validUntil;

    await repo.createRental(
      customer: customer,
      lines: <RentalLineInput>[
        RentalLineInput(
          itemId: planId,
          instanceName: 'Monthly Basic',
          shortCode: 'MEM-2',
          fulfillment: LineFulfillment.sell,
          manualSaleAmountPaise: 150000,
        ),
      ],
    );
    final List<CustomerSubscription> afterRenew =
        await repo.listCustomerSubscriptions(customer.id);
    expect(afterRenew, hasLength(1));
    expect(afterRenew.single.validUntil.isAfter(firstEnd), isTrue);
    expect(
      await repo.customerEffectiveSubscriptionRank(customer.id),
      SubscriptionTier.basic.rank,
    );
  });

  test('higher-tier purchase adds a new row and jumps effective rank', () async {
    final LocalRepository repo = await bootRepo();
    final Customer customer = await ensureCustomer(repo);
    final String basicId = await repo.addInventory(
      name: 'Basic Plan',
      category: 'Gym',
      units: 10,
      defaultItemKind: ResourceType.membership,
      requiresUnitIdentity: false,
      metadata: <String, Object?>{
        kSubscriptionTierMetadataKey: 'basic',
        kSubscriptionPeriodUnitMetadataKey: 'month',
        kSubscriptionPeriodCountMetadataKey: 1,
      },
    );
    final String proId = await repo.addInventory(
      name: 'Pro Plan',
      category: 'Gym',
      units: 10,
      defaultItemKind: ResourceType.membership,
      requiresUnitIdentity: false,
      metadata: <String, Object?>{
        kSubscriptionTierMetadataKey: 'pro',
        kSubscriptionPeriodUnitMetadataKey: 'year',
        kSubscriptionPeriodCountMetadataKey: 1,
      },
    );
    await repo.createRental(
      customer: customer,
      lines: <RentalLineInput>[
        RentalLineInput(
          itemId: basicId,
          instanceName: 'Basic Plan',
          shortCode: 'B-1',
          fulfillment: LineFulfillment.sell,
          manualSaleAmountPaise: 10000,
        ),
      ],
    );
    await repo.createRental(
      customer: customer,
      lines: <RentalLineInput>[
        RentalLineInput(
          itemId: proId,
          instanceName: 'Pro Plan',
          shortCode: 'P-1',
          fulfillment: LineFulfillment.sell,
          manualSaleAmountPaise: 1200000,
        ),
      ],
    );
    final List<CustomerSubscription> rows =
        await repo.listCustomerSubscriptions(customer.id);
    expect(rows, hasLength(2));
    expect(
      await repo.customerEffectiveSubscriptionRank(customer.id),
      SubscriptionTier.pro.rank,
    );
  });

  test('backfill creates ledger rows from historical membership sells', () async {
    final LocalRepository repo = await bootRepo();
    final Customer customer = await ensureCustomer(repo);
    final String planId = await repo.addInventory(
      name: 'Legacy Membership',
      category: 'Library',
      units: 10,
      billingMode: BillingMode.monthly,
      rateAmount: 10000,
      defaultItemKind: ResourceType.membership,
      requiresUnitIdentity: false,
      metadata: <String, Object?>{
        kEntitlementDaysMetadataKey: 30,
      },
    );
    await repo.createRental(
      customer: customer,
      lines: <RentalLineInput>[
        RentalLineInput(
          itemId: planId,
          instanceName: 'Legacy Membership',
          shortCode: 'LEG-1',
          fulfillment: LineFulfillment.sell,
          manualSaleAmountPaise: 10000,
        ),
      ],
    );
    // Grant already ran; wipe ledger + meta flag and backfill again.
    await repo.database.delete(repo.database.customerSubscriptions).go();
    await (repo.database.delete(repo.database.appMeta)
          ..where(
            (t) => t.key.equals('customer_subscriptions_backfill_v23'),
          ))
        .go();
    await repo.ensureCustomerSubscriptionsBackfill();
    final List<CustomerSubscription> rows =
        await repo.listCustomerSubscriptions(customer.id);
    expect(rows, isNotEmpty);
    expect(rows.first.tier, SubscriptionTier.basic);
    expect(
      rows.first.validUntil.isAfter(rows.first.startsAt),
      isTrue,
    );
  });

  test('createOrderWithSettlement upsell SKU then issues gated line', () async {
    final LocalRepository repo = await bootRepo();
    final Customer customer = await ensureCustomer(repo);
    final String bookId = await repo.addInventory(
      name: 'Novel',
      category: 'Library',
      units: 5,
      billingMode: BillingMode.weekly,
      rateAmount: 0,
      defaultItemKind: ResourceType.loan,
      requiresUnitIdentity: false,
      metadata: <String, Object?>{
        kCommercialMetadataKey: kLibraryLoanCommercial.toJson(),
        kMinSubscriptionTierMetadataKey: 'basic',
      },
    );
    final String memberId = await repo.addInventory(
      name: 'Library membership',
      category: 'Library',
      units: 20,
      billingMode: BillingMode.monthly,
      rateAmount: 10000,
      defaultItemKind: ResourceType.membership,
      requiresUnitIdentity: false,
      metadata: <String, Object?>{
        kSubscriptionTierMetadataKey: 'basic',
        kSubscriptionPeriodUnitMetadataKey: 'month',
        kSubscriptionPeriodCountMetadataKey: 1,
      },
    );

    final List<CommercialLineInput> inputs = <CommercialLineInput>[
      CommercialLineInput.fromCatalog(
        item: (await repo.listInventory()).firstWhere(
          (InventoryItem i) => i.id == bookId,
        ),
        fulfillment: LineFulfillment.rent,
        lineAmountPaise: 0,
      ),
      CommercialLineInput.fromCatalog(
        item: (await repo.listInventory()).firstWhere(
          (InventoryItem i) => i.id == memberId,
        ),
        fulfillment: LineFulfillment.sell,
        lineAmountPaise: 10000,
      ),
    ];
    final AggregatedOrderCommercial commercial = resolveOrderCommercial(
      inputs,
      templateByType: const <ResourceType, CommercialPolicy>{
        ResourceType.loan: kLibraryLoanCommercial,
      },
    );
    expect(commercial.cartMinTier, SubscriptionTier.basic);

    final String rentalId = await repo.createOrderWithSettlement(
      customer: customer,
      lines: <RentalLineInput>[
        RentalLineInput(
          itemId: bookId,
          instanceName: 'Novel',
          shortCode: 'NOV-1',
          fulfillment: LineFulfillment.rent,
          durationUnits: 1,
        ),
        RentalLineInput(
          itemId: memberId,
          instanceName: 'Library membership',
          shortCode: 'LIB-1',
          fulfillment: LineFulfillment.sell,
          manualSaleAmountPaise: 10000,
        ),
      ],
      amountReceivedPaise: 10000,
      securityPaise: 0,
      subscriptionSatisfied: true,
      commercial: commercial,
      referenceCode: 'MEM-001',
    );
    expect(rentalId, isNotEmpty);
    expect(
      await repo.customerEffectiveSubscriptionRank(customer.id),
      SubscriptionTier.basic.rank,
    );
  });

  test('unknown customer does not receive a ledger row', () async {
    final LocalRepository repo = await bootRepo();
    final Customer unknown = await repo.ensureUnknownCustomer();
    final String planId = await repo.addInventory(
      name: 'Walk-in Pass',
      category: 'Gym',
      units: 10,
      defaultItemKind: ResourceType.membership,
      requiresUnitIdentity: false,
      metadata: <String, Object?>{
        kSubscriptionTierMetadataKey: 'basic',
        kSubscriptionPeriodUnitMetadataKey: 'day',
        kSubscriptionPeriodCountMetadataKey: 1,
      },
    );
    await repo.createRental(
      customer: unknown,
      lines: <RentalLineInput>[
        RentalLineInput(
          itemId: planId,
          instanceName: 'Walk-in Pass',
          shortCode: 'W-1',
          fulfillment: LineFulfillment.sell,
          manualSaleAmountPaise: 30000,
        ),
      ],
    );
    expect(await repo.listCustomerSubscriptions(unknown.id), isEmpty);
    expect(await repo.customerEffectiveSubscriptionRank(unknown.id), 0);
  });

  test('watchCustomerSubscriptions emits current rows', () async {
    final LocalRepository repo = await bootRepo();
    final List<CustomerSubscription> first = await repo
        .watchCustomerSubscriptions()
        .first
        .timeout(const Duration(seconds: 5));
    expect(first, isEmpty);
  });
}
