@Tags(['unit', 'inventory', 'orders'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/core/models/entities.dart';
import 'package:asset_os/core/repositories/local_repository.dart';
import 'package:asset_os/core/templates/industry_templates.dart';

import 'support/test_harness.dart';

void main() {
  group('catalog soft-archive', () {
    test('archive hides from default listInventory and restore brings back',
        () async {
      final LocalRepository repo = await bootRepo();
      await repo.addInventory(
        name: 'Canon 80D',
        category: 'Camera',
        units: 2,
      );
      final InventoryItem item = (await repo.listInventory()).single;
      expect(item.catalogActive, isTrue);

      await repo.setInventoryCatalogActive(item.id, active: false);

      expect(await repo.listInventory(), isEmpty);
      final List<InventoryItem> all =
          await repo.listInventory(includeInactive: true);
      expect(all, hasLength(1));
      expect(all.single.catalogActive, isFalse);

      await repo.setInventoryCatalogActive(item.id, active: true);
      expect((await repo.listInventory()).single.id, item.id);
      expect((await repo.listInventory()).single.catalogActive, isTrue);
    });

    test('hard delete succeeds when unused', () async {
      final LocalRepository repo = await bootRepo();
      await repo.addInventory(
        name: 'Spare tripod',
        category: 'Camera',
        units: 1,
      );
      final InventoryItem item = (await repo.listInventory()).single;

      await repo.deleteInventoryIfUnused(item.id);
      expect(await repo.listInventory(includeInactive: true), isEmpty);
    });

    test('hard delete fails with open or closed order history', () async {
      final LocalRepository repo = await bootRepo();
      await repo.addInventory(
        name: 'Lens',
        category: 'Camera',
        units: 2,
        requiresUnitIdentity: false,
      );
      final InventoryItem item = (await repo.listInventory()).single;
      final Customer customer = await ensureCustomer(repo);

      final String rentalId = await repo.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: item.id,
            instanceName: 'Lens A',
            shortCode: 'LENS-1',
          ),
        ],
      );

      await expectLater(
        repo.deleteInventoryIfUnused(item.id),
        throwsA(isA<InventoryInUseException>()),
      );

      // Soft-archive still allowed while rented.
      await repo.setInventoryCatalogActive(item.id, active: false);
      expect(await repo.listInventory(), isEmpty);
      expect(
        (await repo.listInventory(includeInactive: true)).single.catalogActive,
        isFalse,
      );

      await repo.returnRental(rentalId);

      await expectLater(
        repo.deleteInventoryIfUnused(item.id),
        throwsA(isA<InventoryInUseException>()),
      );
    });

    test('template-seeded item can be archived', () async {
      final LocalRepository repo = await bootRepo();
      final IndustryTemplate marriage = industryTemplateById('marriage_decor')!;
      await repo.importTemplateInventory(marriage.items.take(1).toList());

      final InventoryItem seeded = (await repo.listInventory()).single;
      await repo.setInventoryCatalogActive(seeded.id, active: false);

      expect(await repo.listInventory(), isEmpty);
      expect(
        (await repo.listInventory(includeInactive: true)).single.name,
        seeded.name,
      );

      // Re-import skips archived name (dedup includes inactive).
      final TemplateImportResult again =
          await repo.importTemplateInventory(marriage.items.take(1).toList());
      expect(again.added, 0);
      expect(again.skipped, 1);
    });
  });
}
