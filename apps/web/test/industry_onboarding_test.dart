@Tags(['unit', 'inventory'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:asset_os/domain/home/home_modules.dart';
import 'package:asset_os/domain/models/entities.dart';
import 'package:asset_os/domain/models/unknown_customer.dart';
import 'package:asset_os/application/local_repository.dart';
import 'package:asset_os/domain/templates/industry_templates.dart';

import 'support/test_harness.dart';

void main() {
  group('first-load industry onboarding', () {
    test('empty boot does not insert Priya/DSLR demo', () async {
      final LocalRepository repo = await bootRepo(seedDemo: false);

      final List<Customer> customers = await repo.listCustomers();
      final List<InventoryItem> inventory = await repo.listInventory();

      expect(customers.map((Customer c) => c.id), <String>[kUnknownCustomerId]);
      expect(inventory, isEmpty);
      expect(await repo.needsIndustryOnboarding(), isTrue);
      expect(await repo.selectedIndustryTemplateId(), isNull);

      expect(
        customers.any((Customer c) => c.name.contains('Priya')),
        isFalse,
      );
      expect(
        inventory.any((InventoryItem i) => i.name == 'DSLR'),
        isFalse,
      );
    });

    test('completeIndustryOnboarding with library seeds pack and meta', () async {
      final LocalRepository repo = await bootRepo(seedDemo: false);
      final IndustryTemplate library = industryTemplateById('library')!;

      await repo.completeIndustryOnboarding(library);

      expect(await repo.needsIndustryOnboarding(), isFalse);
      expect(await repo.selectedIndustryTemplateId(), 'library');

      final List<InventoryItem> inventory = await repo.listInventory();
      final Set<String> names =
          inventory.map((InventoryItem i) => i.name).toSet();
      expect(names, containsAll(<String>['Novel', 'Book', 'Journal', 'Magazine', 'Calculator']));
      expect(names.contains('DSLR'), isFalse);
      expect(inventory.length, library.items.length);

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(kHomeModulesPrefsKey),
        encodeHomeModules(kLibraryHomeModules),
      );
      expect(prefs.getBool(kHomeModulesCustomizedKey), isFalse);
      expect(
        prefs.getString(kEnabledResourceTypesPrefsKey),
        encodeEnabledResourceTypes(library.enabledResourceTypes),
      );
      expect(
        repo.enabledResourceTypes(),
        <ResourceType>[
          ResourceType.rental,
          ResourceType.loan,
          ResourceType.membership,
        ],
      );
    });

    test('completeIndustryOnboarding persists camera rental-only types', () async {
      final LocalRepository repo = await bootRepo(seedDemo: false);
      final IndustryTemplate camera = industryTemplateById('camera')!;

      await repo.completeIndustryOnboarding(camera);

      expect(
        repo.enabledResourceTypes(),
        <ResourceType>[ResourceType.rental],
      );
      expect(
        fulfillmentOptionsForEnabledTypes(repo.enabledResourceTypes()),
        <LineFulfillment>[LineFulfillment.rent],
      );
    });

    test('unionEnabledResourceTypes does not shrink existing set', () async {
      final LocalRepository repo = await bootRepo(seedDemo: false);
      await repo.setEnabledResourceTypes(const <ResourceType>[
        ResourceType.rental,
        ResourceType.sale,
      ]);

      final List<ResourceType> merged = await repo.unionEnabledResourceTypes(
        const <ResourceType>[ResourceType.job, ResourceType.rental],
      );

      expect(
        merged,
        <ResourceType>[
          ResourceType.rental,
          ResourceType.sale,
          ResourceType.job,
        ],
      );
    });

    test('second launch skips onboarding after template chosen', () async {
      final LocalRepository repo = await bootRepo(seedDemo: false);
      await repo.completeIndustryOnboarding(industryTemplateById('library')!);

      expect(await repo.needsIndustryOnboarding(), isFalse);
      expect(await repo.selectedIndustryTemplateId(), 'library');
    });

    test('existing inventory skips onboarding without template meta', () async {
      final LocalRepository repo = await bootRepo(seedDemo: true);

      expect(await repo.selectedIndustryTemplateId(), isNull);
      expect(await repo.needsIndustryOnboarding(), isFalse);
      expect(
        (await repo.listInventory()).any((InventoryItem i) => i.name == 'DSLR'),
        isTrue,
      );
    });

    test('seedDemo enables fallback types so Sell/Job are not hidden', () async {
      final LocalRepository repo = await bootRepo(seedDemo: true);

      expect(
        repo.enabledResourceTypes(),
        containsAll(<ResourceType>[
          ResourceType.rental,
          ResourceType.sale,
          ResourceType.job,
        ]),
      );
      expect(
        fulfillmentOptionsForEnabledTypes(repo.enabledResourceTypes()),
        containsAll(<LineFulfillment>[
          LineFulfillment.rent,
          LineFulfillment.sell,
          LineFulfillment.job,
        ]),
      );
    });

    test('ensureEnabledResourceTypes expands rental-only inventory', () async {
      final LocalRepository repo = await bootRepo(seedDemo: false);
      await repo.addInventory(
        name: 'Camera Body',
        category: 'Camera',
        units: 1,
        requiresUnitIdentity: false,
        defaultItemKind: ResourceType.rental,
      );

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(kEnabledResourceTypesPrefsKey);

      final List<ResourceType> resolved =
          await repo.ensureEnabledResourceTypes();
      expect(
        resolved,
        containsAll(<ResourceType>[
          ResourceType.rental,
          ResourceType.sale,
          ResourceType.job,
        ]),
      );
    });
  });
}
