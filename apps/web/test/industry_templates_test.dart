@Tags(['unit', 'inventory'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/core/home/home_modules.dart';
import 'package:asset_os/core/models/entities.dart';
import 'package:asset_os/core/reports/report_widgets.dart';
import 'package:asset_os/core/repositories/local_repository.dart';
import 'package:asset_os/core/templates/industry_templates.dart';

import 'support/test_harness.dart';

void main() {
  group('resourceTypesFromItems', () {
    test('unions distinct kinds in first-seen order', () {
      expect(
        resourceTypesFromItems(const <ResourceType>[
          ResourceType.service,
          ResourceType.rental,
          ResourceType.service,
          ResourceType.job,
        ]),
        <ResourceType>[
          ResourceType.service,
          ResourceType.rental,
          ResourceType.job,
        ],
      );
    });

    test('defaults from template items when override omitted', () {
      const IndustryTemplate pack = IndustryTemplate(
        id: 'test',
        name: 'Test',
        description: 'Test',
        items: <TemplateInventoryItem>[
          TemplateInventoryItem(
            name: 'A',
            category: 'X',
            defaultUnits: 1,
            defaultItemKind: ResourceType.membership,
          ),
          TemplateInventoryItem(
            name: 'B',
            category: 'X',
            defaultUnits: 1,
            defaultItemKind: ResourceType.sale,
          ),
        ],
      );
      expect(
        pack.enabledResourceTypes,
        <ResourceType>[ResourceType.membership, ResourceType.sale],
      );
    });
  });

  group('fulfillmentOptionsForEnabledTypes', () {
    test('rental-only hides Sell and Job', () {
      expect(
        fulfillmentOptionsForEnabledTypes(const <ResourceType>[
          ResourceType.rental,
        ]),
        <LineFulfillment>[LineFulfillment.rent],
      );
    });

    test('sale enables Sell; job/service enable Job', () {
      expect(
        fulfillmentOptionsForEnabledTypes(const <ResourceType>[
          ResourceType.rental,
          ResourceType.sale,
        ]),
        <LineFulfillment>[LineFulfillment.rent, LineFulfillment.sell],
      );
      expect(
        fulfillmentOptionsForEnabledTypes(const <ResourceType>[
          ResourceType.service,
        ]),
        <LineFulfillment>[LineFulfillment.job],
      );
    });

    test('membership and subscription enable Sell; loan enables Rent', () {
      expect(
        fulfillmentOptionsForEnabledTypes(const <ResourceType>[
          ResourceType.membership,
        ]),
        <LineFulfillment>[LineFulfillment.sell],
      );
      expect(
        fulfillmentOptionsForEnabledTypes(const <ResourceType>[
          ResourceType.subscription,
        ]),
        <LineFulfillment>[LineFulfillment.sell],
      );
      expect(
        fulfillmentOptionsForEnabledTypes(const <ResourceType>[
          ResourceType.loan,
        ]),
        <LineFulfillment>[LineFulfillment.rent],
      );
    });

    test('keeps current Sell visible even when sale not enabled', () {
      expect(
        fulfillmentOptionsForEnabledTypes(
          const <ResourceType>[ResourceType.rental],
          current: LineFulfillment.sell,
        ),
        <LineFulfillment>[LineFulfillment.rent, LineFulfillment.sell],
      );
    });
  });

  group('resolveEnabledResourceTypes', () {
    test('rental-only inventory unions fallback so Sell/Job stay available', () {
      expect(
        resolveEnabledResourceTypes(
          prefsRaw: null,
          inventoryKinds: const <ResourceType>[ResourceType.rental],
        ),
        <ResourceType>[
          ResourceType.rental,
          ResourceType.sale,
          ResourceType.job,
        ],
      );
    });

    test('explicit prefs win even when rental-only', () {
      expect(
        resolveEnabledResourceTypes(
          prefsRaw: 'rental',
          inventoryKinds: const <ResourceType>[ResourceType.rental],
        ),
        <ResourceType>[ResourceType.rental],
      );
    });

    test('sale inventory does not need fallback expansion', () {
      expect(
        resolveEnabledResourceTypes(
          prefsRaw: null,
          inventoryKinds: const <ResourceType>[
            ResourceType.rental,
            ResourceType.sale,
          ],
        ),
        <ResourceType>[ResourceType.rental, ResourceType.sale],
      );
    });
  });

  group('industryTemplateById', () {
    test('finds parlour, boutique, and gym packs with presets', () {
      final IndustryTemplate? parlour = industryTemplateById('parlour');
      final IndustryTemplate? boutique = industryTemplateById('boutique');
      final IndustryTemplate? gym = industryTemplateById('gym');

      expect(parlour, isNotNull);
      expect(parlour!.name, 'Beauty Parlour');
      expect(parlour.defaultHomeModules, kJobHomeModules);
      expect(
        parlour.enabledResourceTypes,
        <ResourceType>[
          ResourceType.service,
          ResourceType.job,
          ResourceType.rental,
        ],
      );

      expect(boutique, isNotNull);
      expect(boutique!.name, 'Boutique');
      expect(boutique.defaultHomeModules, kJobHomeModules);
      expect(
        boutique.enabledResourceTypes,
        containsAll(<ResourceType>[
          ResourceType.rental,
          ResourceType.sale,
          ResourceType.job,
        ]),
      );

      expect(gym, isNotNull);
      expect(gym!.name, 'Gym Membership');
      expect(gym.defaultHomeModules, kMembershipHomeModules);
      expect(
        gym.enabledResourceTypes,
        containsAll(<ResourceType>[
          ResourceType.membership,
          ResourceType.sale,
          ResourceType.rental,
        ]),
      );

      expect(
        kIndustryTemplates.map((IndustryTemplate t) => t.id),
        containsAll(<String>['parlour', 'boutique', 'gym']),
      );
    });

    test('pure rental packs use rental home modules', () {
      for (final String id in <String>[
        'camera',
        'farm',
        'event',
        'construction',
        'office',
      ]) {
        final IndustryTemplate pack = industryTemplateById(id)!;
        expect(pack.defaultHomeModules, kRentalHomeModules, reason: id);
        expect(
          pack.enabledResourceTypes,
          <ResourceType>[ResourceType.rental],
          reason: id,
        );
      }
    });

    test('library enables rental and loan with library home modules', () {
      final IndustryTemplate library = industryTemplateById('library')!;
      expect(library.defaultHomeModules, kLibraryHomeModules);
      expect(
        library.enabledResourceTypes,
        <ResourceType>[ResourceType.rental, ResourceType.loan],
      );
    });

    test('money_lending enables financial with loan home/report presets', () {
      final IndustryTemplate pack = industryTemplateById('money_lending')!;
      expect(pack.name, 'Money Lending');
      expect(pack.defaultHomeModules, kMoneyLendingHomeModules);
      expect(pack.defaultReportWidgets, kMoneyLendingReportWidgets);
      expect(
        pack.enabledResourceTypes,
        <ResourceType>[ResourceType.financial],
      );
      expect(pack.items, isEmpty);
    });

    test('returns null for unknown id', () {
      expect(industryTemplateById('unknown-pack'), isNull);
    });
  });

  group('importTemplateInventory fields', () {
    test('applies defaultItemKind and requiresUnitIdentity', () async {
      final LocalRepository repo = await bootRepo();

      final TemplateImportResult result = await repo.importTemplateInventory(
        const <TemplateInventoryItem>[
          TemplateInventoryItem(
            name: 'Haircut',
            category: 'Parlour',
            defaultUnits: 1,
            billingMode: BillingMode.fixed,
            rateAmount: 30000,
            defaultItemKind: ResourceType.sale,
            requiresUnitIdentity: false,
          ),
          TemplateInventoryItem(
            name: 'Lehenga',
            category: 'Boutique',
            defaultUnits: 2,
            billingMode: BillingMode.weekly,
            rateAmount: 200000,
            requiresUnitIdentity: true,
          ),
          TemplateInventoryItem(
            name: 'Locker',
            category: 'Gym',
            defaultUnits: 10,
            billingMode: BillingMode.monthly,
            rateAmount: 30000,
            requiresUnitIdentity: false,
            dueDateOptional: true,
          ),
        ],
      );

      expect(result.added, 3);
      expect(result.skipped, 0);

      final List<InventoryItem> inventory = await repo.listInventory();
      final InventoryItem haircut =
          inventory.firstWhere((InventoryItem i) => i.name == 'Haircut');
      final InventoryItem lehenga =
          inventory.firstWhere((InventoryItem i) => i.name == 'Lehenga');
      final InventoryItem locker =
          inventory.firstWhere((InventoryItem i) => i.name == 'Locker');

      expect(haircut.defaultItemKind, ResourceType.sale);
      expect(haircut.requiresUnitIdentity, isFalse);
      expect(haircut.dueDateOptional, isFalse);
      expect(haircut.billingMode, BillingMode.fixed);
      expect(haircut.rateAmount, 30000);

      expect(lehenga.defaultItemKind, ResourceType.rental);
      expect(lehenga.requiresUnitIdentity, isTrue);

      expect(locker.requiresUnitIdentity, isFalse);
      expect(locker.dueDateOptional, isTrue);
      expect(locker.billingMode, BillingMode.monthly);
    });

    test('parlour pack seeds service treatments and rental kits', () async {
      final LocalRepository repo = await bootRepo();
      final IndustryTemplate parlour = industryTemplateById('parlour')!;

      final TemplateImportResult result =
          await repo.importTemplateInventory(parlour.items);
      expect(result.added, parlour.items.length);

      final List<InventoryItem> inventory = await repo.listInventory();
      final InventoryItem facial =
          inventory.firstWhere((InventoryItem i) => i.name == 'Facial');
      final InventoryItem steamer =
          inventory.firstWhere((InventoryItem i) => i.name == 'Steamer Kit');

      expect(facial.defaultItemKind, ResourceType.service);
      expect(facial.requiresUnitIdentity, isFalse);
      expect(steamer.defaultItemKind, ResourceType.rental);
      expect(steamer.requiresUnitIdentity, isFalse);
    });

    test('gym pack seeds membership and sale day pass', () async {
      final LocalRepository repo = await bootRepo();
      final IndustryTemplate gym = industryTemplateById('gym')!;

      await repo.importTemplateInventory(gym.items);
      final List<InventoryItem> inventory = await repo.listInventory();
      final InventoryItem monthly = inventory
          .firstWhere((InventoryItem i) => i.name == 'Monthly Membership');
      final InventoryItem dayPass =
          inventory.firstWhere((InventoryItem i) => i.name == 'Day Pass');

      expect(monthly.defaultItemKind, ResourceType.membership);
      expect(dayPass.defaultItemKind, ResourceType.sale);
    });
  });
}
