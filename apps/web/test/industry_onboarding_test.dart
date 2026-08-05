@Tags(['unit', 'inventory'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:asset_os/core/home/home_modules.dart';
import 'package:asset_os/core/models/entities.dart';
import 'package:asset_os/core/models/unknown_customer.dart';
import 'package:asset_os/core/repositories/local_repository.dart';
import 'package:asset_os/core/templates/industry_templates.dart';

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
  });
}
