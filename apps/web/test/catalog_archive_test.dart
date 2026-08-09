@Tags(['unit', 'inventory', 'orders'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/domain/models/entities.dart';
import 'package:asset_os/application/local_repository.dart';
import 'package:asset_os/domain/templates/industry_templates.dart';

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

  group('applyTemplateInventorySelection', () {
    test('uncheck deactivates seeded item; re-check reactivates same row',
        () async {
      final LocalRepository repo = await bootRepo();
      final IndustryTemplate marriage = industryTemplateById('marriage_decor')!;
      final TemplateInventoryItem seedItem = marriage.items.first;

      await repo.importTemplateInventory(<TemplateInventoryItem>[seedItem]);
      final InventoryItem seeded = (await repo.listInventory()).single;
      expect(seeded.catalogActive, isTrue);

      final TemplateApplyResult drop = await repo.applyTemplateInventorySelection(
        checked: const <TemplateInventoryItem>[],
        unchecked: <TemplateInventoryItem>[seedItem],
      );
      expect(drop.deactivated, 1);
      expect(drop.added, 0);
      expect(drop.reactivated, 0);
      expect(await repo.listInventory(), isEmpty);

      final List<InventoryItem> inactive =
          await repo.listInventory(includeInactive: true);
      expect(inactive, hasLength(1));
      expect(inactive.single.id, seeded.id);
      expect(inactive.single.catalogActive, isFalse);

      final TemplateApplyResult restore =
          await repo.applyTemplateInventorySelection(
        checked: <TemplateInventoryItem>[seedItem],
        unchecked: const <TemplateInventoryItem>[],
      );
      expect(restore.reactivated, 1);
      expect(restore.added, 0);
      expect(restore.deactivated, 0);

      final List<InventoryItem> active = await repo.listInventory();
      expect(active, hasLength(1));
      expect(active.single.id, seeded.id);
      expect(active.single.catalogActive, isTrue);

      final List<InventoryItem> all =
          await repo.listInventory(includeInactive: true);
      expect(all, hasLength(1));
    });

    test('order history keeps catalog name after deactivate', () async {
      final LocalRepository repo = await bootRepo();
      final IndustryTemplate marriage = industryTemplateById('marriage_decor')!;
      final TemplateInventoryItem seedItem = marriage.items.first;

      await repo.importTemplateInventory(<TemplateInventoryItem>[seedItem]);
      final InventoryItem seeded = (await repo.listInventory()).single;
      final Customer customer = await ensureCustomer(repo);

      final String rentalId = await repo.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: seeded.id,
            instanceName: '${seeded.name} A',
            shortCode: 'TMP-1',
          ),
        ],
      );

      await repo.applyTemplateInventorySelection(
        checked: const <TemplateInventoryItem>[],
        unchecked: <TemplateInventoryItem>[seedItem],
      );
      expect(await repo.listInventory(), isEmpty);

      final Rental rental =
          (await repo.listRentals()).firstWhere((Rental r) => r.id == rentalId);
      expect(rental.lines, isNotEmpty);
      expect(rental.lines.first.catalogName, seeded.name);
      expect(rental.lines.first.itemId, seeded.id);
    });

    test('checked missing imports; unchecked missing is no-op', () async {
      final LocalRepository repo = await bootRepo();
      final IndustryTemplate marriage = industryTemplateById('marriage_decor')!;
      final TemplateInventoryItem first = marriage.items[0];
      final TemplateInventoryItem second = marriage.items[1];

      final TemplateApplyResult result =
          await repo.applyTemplateInventorySelection(
        checked: <TemplateInventoryItem>[first],
        unchecked: <TemplateInventoryItem>[second],
      );
      expect(result.added, 1);
      expect(result.deactivated, 0);
      expect(result.reactivated, 0);

      final List<InventoryItem> active = await repo.listInventory();
      expect(active, hasLength(1));
      expect(active.single.name, first.name);
    });
  });
}
