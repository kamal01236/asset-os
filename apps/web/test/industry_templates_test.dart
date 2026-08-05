@Tags(['unit', 'inventory'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/core/home/home_modules.dart';
import 'package:asset_os/core/models/entities.dart';
import 'package:asset_os/core/repositories/local_repository.dart';
import 'package:asset_os/core/templates/industry_templates.dart';

import 'support/test_harness.dart';

void main() {
  group('industryTemplateById', () {
    test('finds parlour, boutique, and gym packs', () {
      final IndustryTemplate? parlour = industryTemplateById('parlour');
      final IndustryTemplate? boutique = industryTemplateById('boutique');
      final IndustryTemplate? gym = industryTemplateById('gym');

      expect(parlour, isNotNull);
      expect(parlour!.name, 'Beauty Parlour');
      expect(parlour.defaultHomeModules, kLibraryHomeModules);

      expect(boutique, isNotNull);
      expect(boutique!.name, 'Boutique');
      expect(boutique.defaultHomeModules, kLibraryHomeModules);

      expect(gym, isNotNull);
      expect(gym!.name, 'Gym Membership');
      expect(gym.defaultHomeModules, kLibraryHomeModules);

      expect(
        kIndustryTemplates.map((IndustryTemplate t) => t.id),
        containsAll(<String>['parlour', 'boutique', 'gym']),
      );
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
            defaultItemKind: InventoryItemKind.general,
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

      expect(haircut.defaultItemKind, InventoryItemKind.general);
      expect(haircut.requiresUnitIdentity, isFalse);
      expect(haircut.dueDateOptional, isFalse);
      expect(haircut.billingMode, BillingMode.fixed);
      expect(haircut.rateAmount, 30000);

      expect(lehenga.defaultItemKind, InventoryItemKind.rental);
      expect(lehenga.requiresUnitIdentity, isTrue);

      expect(locker.requiresUnitIdentity, isFalse);
      expect(locker.dueDateOptional, isTrue);
      expect(locker.billingMode, BillingMode.monthly);
    });

    test('parlour pack seeds job services and rental kits', () async {
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

      expect(facial.defaultItemKind, InventoryItemKind.job);
      expect(facial.requiresUnitIdentity, isFalse);
      expect(steamer.defaultItemKind, InventoryItemKind.rental);
      expect(steamer.requiresUnitIdentity, isTrue);
    });
  });
}
