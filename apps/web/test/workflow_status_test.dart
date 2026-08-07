@Tags(['unit', 'orders'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/core/models/entities.dart';
import 'package:asset_os/core/repositories/local_repository.dart';
import 'package:asset_os/core/templates/industry_templates.dart';
import 'package:asset_os/core/templates/workflows.dart';
import 'package:asset_os/core/l10n/timeline_l10n.dart';

import 'support/test_harness.dart';

void main() {
  group('workflow presets', () {
    test('rental / boutique / job / salon pipelines', () {
      expect(kRentalWorkflow.statuses.map((s) => s.id).toList(), <String>[
        'booked',
        'issued',
        'returned',
      ]);
      expect(kBoutiqueWorkflow.terminal.id, 'delivered');
      expect(kJobWorkflow.statuses.first.id, 'received');
      expect(kSalonWorkflow.statuses.length, 3);
      expect(kSalonWorkflow.terminal.isTerminal, isTrue);
    });

    test('terminalWorkflowStatusForOrder by fulfillment mix', () {
      expect(
        terminalWorkflowStatusForOrder(
          workflow: kRentalWorkflow,
          hasRent: false,
          hasJob: false,
          hasSell: true,
        ),
        kSoldWorkflowStatusId,
      );
      expect(
        terminalWorkflowStatusForOrder(
          workflow: kRentalWorkflow,
          hasRent: true,
          hasJob: false,
          hasSell: false,
        ),
        'returned',
      );
      expect(
        terminalWorkflowStatusForOrder(
          workflow: kRentalWorkflow,
          hasRent: false,
          hasJob: true,
          hasSell: false,
        ),
        kDoneWorkflowStatusId,
      );
      expect(
        terminalWorkflowStatusForOrder(
          workflow: kJobWorkflow,
          hasRent: false,
          hasJob: true,
          hasSell: false,
        ),
        'done',
      );
      expect(
        terminalWorkflowStatusForOrder(
          workflow: kBoutiqueWorkflow,
          hasRent: false,
          hasJob: false,
          hasSell: true,
        ),
        kSoldWorkflowStatusId,
      );
      expect(
        terminalWorkflowStatusForOrder(
          workflow: kRentalWorkflow,
          hasRent: true,
          hasJob: true,
          hasSell: true,
        ),
        'returned',
      );
    });

    test('sold status localizes and effectiveWorkflowStatusId keeps it', () {
      expect(
        localizedWorkflowStatusLabel(const Locale('en'), kSoldWorkflowStatusId),
        'Sold',
      );
      expect(
        localizedWorkflowStatusLabel(const Locale('hi'), kSoldWorkflowStatusId),
        'बिक गया',
      );
      expect(
        effectiveWorkflowStatusId(
          stored: kSoldWorkflowStatusId,
          orderStatus: OrderStatus.completed,
          workflow: kRentalWorkflow,
        ),
        kSoldWorkflowStatusId,
      );
      expect(
        resolveWorkflowStatusDisplay(
          workflow: kRentalWorkflow,
          statusId: kSoldWorkflowStatusId,
        )?.labelEn,
        'Sold',
      );
    });

    test('library and camera use rental; boutique/parlour/salon/mechanic mapped', () {
      expect(industryTemplateById('library')!.workflowId, kRentalWorkflowId);
      expect(industryTemplateById('camera')!.workflowId, kRentalWorkflowId);
      expect(industryTemplateById('boutique')!.workflowId, kBoutiqueWorkflowId);
      expect(industryTemplateById('parlour')!.workflowId, kJobWorkflowId);
      expect(industryTemplateById('salon')!.workflowId, kSalonWorkflowId);
      expect(industryTemplateById('mechanic')!.workflowId, kJobWorkflowId);
      expect(industryTemplateById('marriage_decor')!.workflowId, kRentalWorkflowId);
      expect(industryTemplateById('temple')!.workflowId, kRentalWorkflowId);
      expect(industryTemplateById('mobile_repair')!.workflowId, kJobWorkflowId);
      expect(industryTemplateById('laptop_repair')!.workflowId, kJobWorkflowId);
      expect(industryTemplateById('tailor')!.workflowId, kJobWorkflowId);
    });

    test('deriveWorkflowStatusFromOrderStatus', () {
      expect(
        deriveWorkflowStatusFromOrderStatus(OrderStatus.open, kRentalWorkflow),
        'booked',
      );
      expect(
        deriveWorkflowStatusFromOrderStatus(
          OrderStatus.completed,
          kBoutiqueWorkflow,
        ),
        'delivered',
      );
      expect(
        deriveWorkflowStatusFromOrderStatus(
          OrderStatus.cancelled,
          kRentalWorkflow,
        ),
        isNull,
      );
    });
  });

  group('workflow repository', () {
    test('create starts at initial; advance syncs terminal to completed', () async {
      final LocalRepository repository = await bootRepo();
      await repository.setActiveWorkflowId(kBoutiqueWorkflowId);
      await repository.addInventory(
        name: 'Lehenga',
        category: 'Boutique',
        units: 2,
        billingMode: BillingMode.weekly,
        rateAmount: 200000,
        requiresUnitIdentity: true,
      );
      final InventoryItem item = (await repository.listInventory()).single;
      final Customer customer = await ensureCustomer(repository);

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: item.id,
            instanceName: 'Lehenga A',
            shortCode: 'LEH-1',
          ),
        ],
      );

      Rental order = (await repository.listRentals()).single;
      expect(order.workflowStatus, 'pending');
      expect(order.orderStatus, OrderStatus.open);

      await repository.advanceWorkflowStatus(order.id);
      order = (await repository.listRentals()).single;
      expect(order.workflowStatus, 'in_progress');

      await repository.advanceWorkflowStatus(
        order.id,
        toStatusId: 'delivered',
      );
      order = (await repository.listRentals()).single;
      expect(order.workflowStatus, 'delivered');
      expect(order.orderStatus, OrderStatus.completed);
      expect(
        order.timeline.any(
          (RentalEvent e) => e.title == TimelineTitleKey.statusChanged,
        ),
        isTrue,
      );
    });

    test('onboarding persists active workflow id', () async {
      final LocalRepository repository = await bootRepo();
      final IndustryTemplate? mechanic = industryTemplateById('mechanic');
      expect(mechanic, isNotNull);
      await repository.completeIndustryOnboarding(
        mechanic!,
        locale: const Locale('en'),
      );
      expect(repository.activeWorkflow().id, kJobWorkflowId);
    });

    test('completeJobLines advances job workflow toward terminal', () async {
      final LocalRepository repository = await bootRepo();
      await repository.setActiveWorkflowId(kJobWorkflowId);
      await repository.addInventory(
        name: 'Oil Change',
        category: 'Mechanic',
        units: 2,
        billingMode: BillingMode.fixed,
        rateAmount: 50000,
        requiresUnitIdentity: false,
        defaultItemKind: ResourceType.job,
      );
      final InventoryItem item = (await repository.listInventory()).single;
      final Customer customer = await ensureCustomer(repository);

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: item.id,
            instanceName: 'Oil Change',
            shortCode: 'OIL-1',
            fulfillment: LineFulfillment.job,
            manualSaleAmountPaise: 50000,
          ),
          RentalLineInput(
            itemId: item.id,
            instanceName: 'Oil Change 2',
            shortCode: 'OIL-2',
            fulfillment: LineFulfillment.job,
            manualSaleAmountPaise: 50000,
          ),
        ],
      );

      Rental order = (await repository.listRentals()).single;
      expect(order.workflowStatus, 'received');

      await repository.completeJobLines(
        order.id,
        <String>[order.lines.first.id],
      );
      order = (await repository.listRentals()).single;
      expect(order.orderStatus, OrderStatus.open);
      expect(order.workflowStatus, 'in_progress');

      await repository.completeJobLines(
        order.id,
        <String>[order.openJobLines.single.id],
      );
      order = (await repository.listRentals()).single;
      expect(order.orderStatus, OrderStatus.completed);
      expect(order.workflowStatus, 'done');
    });

    test('sale-only create stores sold not returned under rental workflow',
        () async {
      final LocalRepository repository = await bootRepo();
      await repository.setActiveWorkflowId(kRentalWorkflowId);
      await repository.addInventory(
        name: 'Tripod',
        category: 'Camera',
        units: 2,
        billingMode: BillingMode.daily,
        rateAmount: 10000,
        requiresUnitIdentity: false,
      );
      final InventoryItem item = (await repository.listInventory()).single;
      final Customer customer = await ensureCustomer(repository);

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: item.id,
            instanceName: 'Tripod',
            shortCode: 'TRI-1',
            fulfillment: LineFulfillment.sell,
            manualSaleAmountPaise: 25000,
          ),
        ],
      );

      final Rental order = (await repository.listRentals()).single;
      expect(order.orderStatus, OrderStatus.completed);
      expect(order.workflowStatus, kSoldWorkflowStatusId);
      expect(order.workflowStatus, isNot('returned'));
      expect(
        localizedWorkflowStatusLabel(
          const Locale('en'),
          order.workflowStatus,
        ),
        'Sold',
      );
    });

    test('rent return still closes at returned under rental workflow', () async {
      final LocalRepository repository = await bootRepo();
      await repository.setActiveWorkflowId(kRentalWorkflowId);
      await repository.addInventory(
        name: 'Book',
        category: 'Library',
        units: 1,
        billingMode: BillingMode.weekly,
        rateAmount: 3000,
      );
      final InventoryItem item = (await repository.listInventory()).single;
      final Customer customer = await ensureCustomer(repository);

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: item.id,
            instanceName: 'Book',
            shortCode: 'BK-1',
          ),
        ],
      );

      Rental order = (await repository.listRentals()).single;
      expect(order.workflowStatus, 'booked');
      expect(order.orderStatus, OrderStatus.open);

      await repository.returnRental(order.id);
      order = (await repository.listRentals()).single;
      expect(order.orderStatus, OrderStatus.completed);
      expect(order.workflowStatus, 'returned');
    });

    test('all-job under rental workflow closes at done not returned', () async {
      final LocalRepository repository = await bootRepo();
      await repository.setActiveWorkflowId(kRentalWorkflowId);
      await repository.addInventory(
        name: 'Repair',
        category: 'Service',
        units: 1,
        billingMode: BillingMode.fixed,
        rateAmount: 40000,
        requiresUnitIdentity: false,
        defaultItemKind: ResourceType.job,
      );
      final InventoryItem item = (await repository.listInventory()).single;
      final Customer customer = await ensureCustomer(repository);

      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: item.id,
            instanceName: 'Repair',
            shortCode: 'REP-1',
            fulfillment: LineFulfillment.job,
            manualSaleAmountPaise: 40000,
          ),
        ],
      );

      Rental order = (await repository.listRentals()).single;
      expect(order.workflowStatus, 'booked');
      expect(order.orderStatus, OrderStatus.open);

      await repository.completeJobLines(
        order.id,
        <String>[order.lines.single.id],
      );
      order = (await repository.listRentals()).single;
      expect(order.orderStatus, OrderStatus.completed);
      expect(order.workflowStatus, kDoneWorkflowStatusId);
      expect(order.workflowStatus, isNot('returned'));
      expect(
        localizedWorkflowStatusLabel(
          const Locale('en'),
          order.workflowStatus,
        ),
        'Done',
      );
    });

    test('cancel keeps OrderStatus.cancelled without forcing terminal', () async {
      final LocalRepository repository = await bootRepo();
      await repository.setActiveWorkflowId(kRentalWorkflowId);
      await repository.addInventory(
        name: 'Book',
        category: 'Library',
        units: 1,
        billingMode: BillingMode.weekly,
        rateAmount: 3000,
      );
      final InventoryItem item = (await repository.listInventory()).single;
      final Customer customer = await ensureCustomer(repository);
      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: item.id,
            instanceName: 'Book',
            shortCode: 'BK-1',
          ),
        ],
      );
      final Rental open = (await repository.listRentals()).single;
      await repository.cancelOrder(rentalId: open.id);
      final Rental cancelled = (await repository.listRentals()).single;
      expect(cancelled.orderStatus, OrderStatus.cancelled);
      expect(cancelled.workflowStatus, 'booked');
    });
  });
}
