@Tags(['unit', 'orders', 'pricing'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/domain/models/entities.dart';
import 'package:asset_os/domain/orders/commercial_policy.dart';

void main() {
  group('resolveLinePolicy', () {
    test('rental with rate and no deposit: pay optional, security off', () {
      final CommercialPolicy policy = resolveLinePolicy(
        type: ResourceType.rental,
        ratePaise: 150000,
        securityDepositPaise: 0,
      );
      expect(policy.pay, CommercialRequirement.optional);
      expect(policy.advance, CommercialRequirement.optional);
      expect(policy.security, CommercialRequirement.off);
      expect(policy.subscription, CommercialRequirement.off);
    });

    test('rental deposit optional unless template marks required', () {
      final CommercialPolicy optional = resolveLinePolicy(
        type: ResourceType.rental,
        ratePaise: 150000,
        securityDepositPaise: 500000,
      );
      expect(optional.security, CommercialRequirement.optional);

      final CommercialPolicy required = resolveLinePolicy(
        type: ResourceType.rental,
        templateTypeDefault: const CommercialPolicy(
          pay: CommercialRequirement.optional,
          advance: CommercialRequirement.optional,
          security: CommercialRequirement.required,
        ),
        ratePaise: 150000,
        securityDepositPaise: 500000,
      );
      expect(required.security, CommercialRequirement.required);
    });

    test('rental security required is off when catalog deposit is 0', () {
      final CommercialPolicy policy = resolveLinePolicy(
        type: ResourceType.rental,
        templateTypeDefault: const CommercialPolicy(
          pay: CommercialRequirement.optional,
          advance: CommercialRequirement.optional,
          security: CommercialRequirement.required,
        ),
        ratePaise: 150000,
        securityDepositPaise: 0,
      );
      expect(policy.security, CommercialRequirement.off);
    });

    test('loan rate 0 turns pay off; deposit optional', () {
      final CommercialPolicy zero = resolveLinePolicy(
        type: ResourceType.loan,
        templateTypeDefault: const CommercialPolicy(
          pay: CommercialRequirement.off,
          security: CommercialRequirement.optional,
          subscription: CommercialRequirement.optional,
        ),
        ratePaise: 0,
        securityDepositPaise: 0,
      );
      expect(zero.pay, CommercialRequirement.off);
      expect(zero.security, CommercialRequirement.off);
      expect(zero.subscription, CommercialRequirement.optional);

      final CommercialPolicy withDeposit = resolveLinePolicy(
        type: ResourceType.loan,
        ratePaise: 0,
        securityDepositPaise: 10000,
      );
      expect(withDeposit.pay, CommercialRequirement.off);
      expect(withDeposit.security, CommercialRequirement.optional);
    });

    test('sale pay required when amount > 0 else off', () {
      expect(
        resolveLinePolicy(type: ResourceType.sale, ratePaise: 15000).pay,
        CommercialRequirement.required,
      );
      expect(
        resolveLinePolicy(type: ResourceType.sale, ratePaise: 0).pay,
        CommercialRequirement.off,
      );
    });

    test('service pay optional; membership pay required', () {
      expect(
        resolveLinePolicy(type: ResourceType.service, ratePaise: 30000).pay,
        CommercialRequirement.optional,
      );
      expect(
        resolveLinePolicy(type: ResourceType.membership, ratePaise: 150000).pay,
        CommercialRequirement.required,
      );
      expect(
        resolveLinePolicy(
          type: ResourceType.membership,
          ratePaise: 150000,
        ).subscription,
        CommercialRequirement.off,
      );
    });

    test('item metadata commercial overlay wins for security', () {
      final CommercialPolicy policy = resolveLinePolicy(
        type: ResourceType.rental,
        itemDelta: const CommercialPolicyDelta(
          security: CommercialRequirement.required,
        ),
        ratePaise: 200000,
        securityDepositPaise: 200000,
      );
      expect(policy.security, CommercialRequirement.required);
    });

    test('custom follows rental defaults', () {
      final CommercialPolicy policy = resolveLinePolicy(
        type: ResourceType.custom,
        ratePaise: 10000,
        securityDepositPaise: 5000,
      );
      expect(policy.pay, CommercialRequirement.optional);
      expect(policy.security, CommercialRequirement.optional);
    });
  });

  group('aggregateOrderCommercial', () {
    test('mixed parlour: pay required from sale, optional security from rental',
        () {
      final AggregatedOrderCommercial agg = resolveOrderCommercial(
        const <CommercialLineInput>[
          CommercialLineInput(
            type: ResourceType.service,
            fulfillment: LineFulfillment.job,
            unitRatePaise: 30000,
            lineAmountPaise: 30000,
          ),
          CommercialLineInput(
            type: ResourceType.sale,
            fulfillment: LineFulfillment.sell,
            unitRatePaise: 15000,
            lineAmountPaise: 15000,
          ),
          CommercialLineInput(
            type: ResourceType.rental,
            fulfillment: LineFulfillment.rent,
            unitRatePaise: 20000,
            lineAmountPaise: 20000,
            securityDepositPaise: 20000,
          ),
        ],
      );
      expect(agg.pay, CommercialRequirement.required);
      expect(agg.minPayNowPaise, 15000);
      expect(agg.security, CommercialRequirement.optional);
      expect(agg.suggestedSecurityPaise, 20000);
      expect(agg.showPay, isTrue);
      expect(agg.showSecurity, isTrue);
      expect(agg.requireSecurity, isFalse);
      expect(agg.shouldShowCommercialStep, isTrue);
    });

    test('library loan-only with no deposit skips commercial step', () {
      final AggregatedOrderCommercial agg = resolveOrderCommercial(
        const <CommercialLineInput>[
          CommercialLineInput(
            type: ResourceType.loan,
            fulfillment: LineFulfillment.rent,
            unitRatePaise: 0,
            lineAmountPaise: 0,
          ),
        ],
        templateByType: const <ResourceType, CommercialPolicy>{
          ResourceType.loan: CommercialPolicy(
            pay: CommercialRequirement.off,
            security: CommercialRequirement.optional,
            subscription: CommercialRequirement.optional,
          ),
        },
      );
      expect(agg.pay, CommercialRequirement.off);
      expect(agg.security, CommercialRequirement.off);
      expect(agg.subscription, CommercialRequirement.optional);
      expect(agg.shouldShowCommercialStep, isFalse);
    });

    test('camera rental with required security blocks until deposit', () {
      final AggregatedOrderCommercial agg = resolveOrderCommercial(
        const <CommercialLineInput>[
          CommercialLineInput(
            type: ResourceType.rental,
            fulfillment: LineFulfillment.rent,
            unitRatePaise: 150000,
            lineAmountPaise: 150000,
            securityDepositPaise: 500000,
          ),
        ],
        templateByType: const <ResourceType, CommercialPolicy>{
          ResourceType.rental: CommercialPolicy(
            pay: CommercialRequirement.optional,
            advance: CommercialRequirement.optional,
            security: CommercialRequirement.required,
          ),
        },
      );
      expect(agg.requireSecurity, isTrue);
      expect(agg.suggestedSecurityPaise, 500000);
      expect(agg.shouldShowCommercialStep, isTrue);
      expect(agg.minPayNowPaise, 0);
    });

    test('gym membership + locker unions pay required and optional security',
        () {
      final AggregatedOrderCommercial agg = resolveOrderCommercial(
        const <CommercialLineInput>[
          CommercialLineInput(
            type: ResourceType.membership,
            fulfillment: LineFulfillment.sell,
            unitRatePaise: 150000,
            lineAmountPaise: 150000,
          ),
          CommercialLineInput(
            type: ResourceType.rental,
            fulfillment: LineFulfillment.rent,
            unitRatePaise: 30000,
            lineAmountPaise: 30000,
            securityDepositPaise: 50000,
          ),
        ],
      );
      expect(agg.pay, CommercialRequirement.required);
      expect(agg.minPayNowPaise, 150000);
      expect(agg.security, CommercialRequirement.optional);
      expect(agg.suggestedSecurityPaise, 50000);
    });

    test('priced rental alone does not force commercial step', () {
      final AggregatedOrderCommercial agg = resolveOrderCommercial(
        const <CommercialLineInput>[
          CommercialLineInput(
            type: ResourceType.rental,
            fulfillment: LineFulfillment.rent,
            unitRatePaise: 20000,
            lineAmountPaise: 20000,
          ),
        ],
      );
      expect(agg.pay, CommercialRequirement.optional);
      expect(agg.shouldShowCommercialStep, isFalse);
    });
  });

  group('assertCommercialSatisfied', () {
    test('throws when required security missing', () {
      final AggregatedOrderCommercial agg = resolveOrderCommercial(
        const <CommercialLineInput>[
          CommercialLineInput(
            type: ResourceType.rental,
            fulfillment: LineFulfillment.rent,
            unitRatePaise: 150000,
            lineAmountPaise: 150000,
            securityDepositPaise: 500000,
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
        () => assertCommercialSatisfied(
          aggregated: agg,
          amountReceivedPaise: 0,
          securityPaise: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
      assertCommercialSatisfied(
        aggregated: agg,
        amountReceivedPaise: 500000,
        securityPaise: 500000,
      );
    });

    test('throws when required pay below min', () {
      final AggregatedOrderCommercial agg = resolveOrderCommercial(
        const <CommercialLineInput>[
          CommercialLineInput(
            type: ResourceType.sale,
            fulfillment: LineFulfillment.sell,
            unitRatePaise: 15000,
            lineAmountPaise: 15000,
          ),
        ],
      );
      expect(
        () => assertCommercialSatisfied(
          aggregated: agg,
          amountReceivedPaise: 1000,
          securityPaise: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
      assertCommercialSatisfied(
        aggregated: agg,
        amountReceivedPaise: 15000,
        securityPaise: 0,
      );
    });

    test('requireAnyOf security or subscription', () {
      final AggregatedOrderCommercial agg = resolveOrderCommercial(
        const <CommercialLineInput>[
          CommercialLineInput(
            type: ResourceType.loan,
            fulfillment: LineFulfillment.rent,
            unitRatePaise: 0,
            lineAmountPaise: 0,
          ),
        ],
        templateByType: const <ResourceType, CommercialPolicy>{
          ResourceType.loan: CommercialPolicy(
            pay: CommercialRequirement.off,
            subscription: CommercialRequirement.optional,
            requireAnyOf: <CommercialStep>[
              CommercialStep.security,
              CommercialStep.subscription,
            ],
          ),
        },
      );
      expect(agg.shouldShowCommercialStep, isTrue);
      expect(
        () => assertCommercialSatisfied(
          aggregated: agg,
          amountReceivedPaise: 0,
          securityPaise: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
      assertCommercialSatisfied(
        aggregated: agg,
        amountReceivedPaise: 0,
        securityPaise: 1000,
      );
      assertCommercialSatisfied(
        aggregated: agg,
        amountReceivedPaise: 0,
        securityPaise: 0,
        subscriptionSatisfied: true,
      );
    });
  });

  group('customerHasActiveEntitlement', () {
    test('membership sell within billing period counts', () {
      final DateTime start = DateTime(2026, 1, 1);
      const InventoryItem plan = InventoryItem(
        id: 'INV-M',
        name: 'Monthly Membership',
        category: 'Gym',
        availableUnits: 10,
        totalUnits: 10,
        status: AssetStatus.available,
        qrCode: 'inventory:m',
        billingMode: BillingMode.monthly,
        rateAmount: 150000,
        defaultItemKind: ResourceType.membership,
        requiresUnitIdentity: false,
      );
      final Rental closed = Rental(
        id: 'REN-M',
        customerId: 'CUS-1',
        lines: <RentalLine>[
          RentalLine(
            id: 'RLI-M',
            itemId: 'INV-M',
            catalogName: 'Monthly Membership',
            instanceName: 'Monthly Membership',
            shortCode: 'MEM-1',
            fulfillment: LineFulfillment.sell,
            baseAmount: 150000,
            billingMode: BillingMode.monthly,
            rateAmount: 150000,
            returnedAt: start,
          ),
        ],
        startedAt: start,
        timeline: const <RentalEvent>[],
        qrCode: 'rental:m',
        orderStatus: OrderStatus.completed,
      );
      expect(
        customerHasActiveEntitlement(
          customerOrders: <Rental>[closed],
          inventoryById: <String, InventoryItem>{plan.id: plan},
          now: DateTime(2026, 1, 15),
        ),
        isTrue,
      );
      expect(
        customerHasActiveEntitlement(
          customerOrders: <Rental>[closed],
          inventoryById: <String, InventoryItem>{plan.id: plan},
          now: DateTime(2026, 3, 1),
        ),
        isFalse,
      );
    });

    test('metadata.validUntil overrides billing mode', () {
      final DateTime start = DateTime(2026, 1, 1);
      const InventoryItem plan = InventoryItem(
        id: 'INV-Q',
        name: 'Quarterly',
        category: 'Gym',
        availableUnits: 5,
        totalUnits: 5,
        status: AssetStatus.available,
        qrCode: 'inventory:q',
        billingMode: BillingMode.fixed,
        rateAmount: 400000,
        defaultItemKind: ResourceType.membership,
        requiresUnitIdentity: false,
        metadata: <String, Object?>{
          kEntitlementValidUntilMetadataKey: '2026-04-01T00:00:00.000',
        },
      );
      final Rental closed = Rental(
        id: 'REN-Q',
        customerId: 'CUS-1',
        lines: <RentalLine>[
          RentalLine(
            id: 'RLI-Q',
            itemId: 'INV-Q',
            catalogName: 'Quarterly',
            instanceName: 'Quarterly',
            shortCode: 'Q-1',
            fulfillment: LineFulfillment.sell,
            baseAmount: 400000,
            returnedAt: start,
          ),
        ],
        startedAt: start,
        timeline: const <RentalEvent>[],
        qrCode: 'rental:q',
        orderStatus: OrderStatus.completed,
      );
      expect(
        customerHasActiveEntitlement(
          customerOrders: <Rental>[closed],
          inventoryById: <String, InventoryItem>{plan.id: plan},
          now: DateTime(2026, 3, 15),
        ),
        isTrue,
      );
      expect(
        customerHasActiveEntitlement(
          customerOrders: <Rental>[closed],
          inventoryById: <String, InventoryItem>{plan.id: plan},
          now: DateTime(2026, 4, 2),
        ),
        isFalse,
      );
    });
  });

  group('metadata parse', () {
    test('reads commercial map from inventory metadata', () {
      final CommercialPolicyDelta? delta = commercialDeltaFromMetadata(
        <String, Object?>{
          kCommercialMetadataKey: <String, Object?>{
            'security': 'required',
            'requireAnyOf': <String>['security', 'subscription'],
          },
        },
      );
      expect(delta, isNotNull);
      expect(delta!.security, CommercialRequirement.required);
      expect(
        delta.requireAnyOf,
        <CommercialStep>[
          CommercialStep.security,
          CommercialStep.subscription,
        ],
      );
    });
  });
}
