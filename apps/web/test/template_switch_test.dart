@Tags(['unit', 'loans', 'inventory'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:asset_os/core/home/home_modules.dart';
import 'package:asset_os/core/models/entities.dart';
import 'package:asset_os/core/repositories/local_repository.dart';
import 'package:asset_os/core/templates/industry_templates.dart';
import 'package:asset_os/core/transactions/transaction_list_item.dart';

import 'support/test_harness.dart';

void main() {
  group('activateIndustryTemplate switch', () {
    test('keeps loans listable when leaving Money Lending; New Loan gated',
        () async {
      final LocalRepository repo = await bootRepo(seedDemo: false);
      final IndustryTemplate lending = industryTemplateById('money_lending')!;
      final IndustryTemplate camera = industryTemplateById('camera')!;

      await repo.completeIndustryOnboarding(lending);
      expect(repo.enabledResourceTypes(), <ResourceType>[ResourceType.financial]);
      expect(canCreateLoanTransaction(repo.enabledResourceTypes()), isTrue);

      final Customer customer = await ensureCustomer(repo);
      await repo.createMoneyLoan(
        customerId: customer.id,
        direction: MoneyLoanDirection.given,
        principalPaise: 100000,
        interestStartedAt: DateTime(2026, 1, 1),
        rateBps: 0,
      );
      final List<MoneyLoan> before = await repo.listMoneyLoans();
      expect(before, hasLength(1));

      await repo.activateIndustryTemplate(camera);

      expect(await repo.selectedIndustryTemplateId(), 'camera');
      expect(
        repo.enabledResourceTypes(),
        <ResourceType>[ResourceType.rental],
      );
      expect(canCreateLoanTransaction(repo.enabledResourceTypes()), isFalse);

      final List<MoneyLoan> afterSwitch = await repo.listMoneyLoans();
      expect(afterSwitch, hasLength(1));
      expect(afterSwitch.first.id, before.first.id);
      expect(
        showLoansTransactionFilter(
          repo.enabledResourceTypes(),
          afterSwitch,
        ),
        isTrue,
      );

      await repo.activateIndustryTemplate(lending);

      expect(await repo.selectedIndustryTemplateId(), 'money_lending');
      expect(
        repo.enabledResourceTypes(),
        <ResourceType>[ResourceType.financial],
      );
      expect(canCreateLoanTransaction(repo.enabledResourceTypes()), isTrue);
      expect(await repo.listMoneyLoans(), hasLength(1));
    });

    test('does not wipe inventory when switching packs', () async {
      final LocalRepository repo = await bootRepo(seedDemo: false);
      final IndustryTemplate library = industryTemplateById('library')!;
      final IndustryTemplate lending = industryTemplateById('money_lending')!;

      await repo.completeIndustryOnboarding(library);
      final int inventoryCount = (await repo.listInventory()).length;
      expect(inventoryCount, greaterThan(0));

      await repo.activateIndustryTemplate(lending);

      expect(await repo.selectedIndustryTemplateId(), 'money_lending');
      expect((await repo.listInventory()).length, inventoryCount);
      expect(
        repo.enabledResourceTypes(),
        <ResourceType>[ResourceType.financial],
      );
      expect(canCreateLoanTransaction(repo.enabledResourceTypes()), isTrue);
    });

    test('money_lending empty pack enables financial without inventory seed',
        () async {
      final LocalRepository repo = await bootRepo(seedDemo: false);
      final IndustryTemplate lending = industryTemplateById('money_lending')!;

      await repo.activateIndustryTemplate(lending);

      expect(await repo.selectedIndustryTemplateId(), 'money_lending');
      expect(await repo.listInventory(), isEmpty);
      expect(
        repo.enabledResourceTypes(),
        <ResourceType>[ResourceType.financial],
      );
      expect(canCreateLoanTransaction(repo.enabledResourceTypes()), isTrue);

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(kHomeModulesPrefsKey),
        encodeHomeModules(kMoneyLendingHomeModules),
      );
    });
  });
}
