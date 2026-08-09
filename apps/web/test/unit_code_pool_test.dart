@Tags(['unit', 'inventory', 'orders', 'returns', 'reports'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/domain/models/entities.dart';
import 'package:asset_os/application/reports/report_builder.dart';
import 'package:asset_os/domain/reports/report_models.dart';
import 'package:asset_os/domain/reports/report_widgets.dart';
import 'package:asset_os/application/local_repository.dart';
import 'package:asset_os/domain/templates/industry_templates.dart';
import 'package:asset_os/l10n/app_localizations.dart';

import 'support/test_harness.dart';

void main() {
  group('generateUnitPool', () {
    test('zero-pads from digit width of total', () {
      final List<String> seats40 = generateUnitPool(prefix: 'SEAT', total: 40);
      expect(seats40.length, 40);
      expect(seats40.first, 'SEAT-01');
      expect(seats40.last, 'SEAT-40');
      expect(generateUnitPool(prefix: 'seat', total: 5).first, 'SEAT-1');
      expect(generateUnitPool(prefix: 'CAM', total: 100).last, 'CAM-100');
      expect(generateUnitPool(prefix: '', total: 10), isEmpty);
      expect(generateUnitPool(prefix: 'X', total: 0), isEmpty);
    });
  });

  group('unit code pool + occupancy', () {
    test('available codes shrink on assign and free on return', () async {
      final LocalRepository repo = await bootRepo();
      await repo.addInventory(
        name: 'Reading seat',
        category: 'Library',
        units: 3,
        requiresUnitIdentity: true,
        unitCodePrefix: 'SEAT',
        billingMode: BillingMode.monthly,
        rateAmount: 50000,
      );
      final InventoryItem seat = (await repo.listInventory()).first;
      expect(seat.unitCodePrefix, 'SEAT');
      expect(seat.hasUnitCodePool, isTrue);

      List<String> available = await repo.listAvailableUnitCodes(seat.id);
      expect(available, <String>['SEAT-1', 'SEAT-2', 'SEAT-3']);

      final Customer customer = await ensureCustomer(repo);
      final String rentalId = await repo.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: seat.id,
            instanceName: 'Student A',
            shortCode: 'SEAT-2',
          ),
        ],
      );

      available = await repo.listAvailableUnitCodes(seat.id);
      expect(available, <String>['SEAT-1', 'SEAT-3']);

      await expectLater(
        repo.createRental(
          customer: customer,
          lines: <RentalLineInput>[
            RentalLineInput(
              itemId: seat.id,
              instanceName: 'Student B',
              shortCode: 'SEAT-2',
            ),
          ],
        ),
        throwsA(isA<DuplicateActiveShortCodeException>()),
      );

      await repo.returnRental(rentalId);
      available = await repo.listAvailableUnitCodes(seat.id);
      expect(available, <String>['SEAT-1', 'SEAT-2', 'SEAT-3']);
    });

    test('occupancy rows and report include occupied + available', () async {
      final LocalRepository repo = await bootRepo();
      await repo.addInventory(
        name: 'Reading seat',
        category: 'Library',
        units: 2,
        requiresUnitIdentity: true,
        unitCodePrefix: 'SEAT',
        billingMode: BillingMode.monthly,
        rateAmount: 50000,
      );
      final InventoryItem seat = (await repo.listInventory()).first;
      final Customer customer = await ensureCustomer(repo);
      await repo.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: seat.id,
            instanceName: 'Priya',
            shortCode: 'SEAT-1',
          ),
        ],
      );

      final List<UnitOccupancyRow> rows = await repo.listUnitOccupancy(seat.id);
      expect(rows.length, 2);
      expect(rows.first.code, 'SEAT-1');
      expect(rows.first.occupied, isTrue);
      expect(rows.first.customerName, 'Priya Patel');
      expect(rows.last.code, 'SEAT-2');
      expect(rows.last.occupied, isFalse);

      final AppLocalizations l10n =
          await AppLocalizations.delegate.load(const Locale('en'));
      final DateTime now = DateTime(2026, 8, 7, 12);
      final String text = const ReportBuilder().build(
        l10n: l10n,
        type: ReportType.unitOccupancy,
        range: ReportDateRange.resolve(period: ReportPeriod.daily, now: now),
        customers: await repo.listCustomers(),
        inventory: await repo.listInventory(),
        rentals: await repo.listRentals(),
        now: now,
      );
      expect(text, contains('Unit occupancy'));
      expect(text, contains('SEAT-1'));
      expect(text, contains('Occupied'));
      expect(text, contains('Priya Patel'));
      expect(text, contains('SEAT-2'));
      expect(text, contains('Available'));
    });
  });

  group('extend + auto-vacate', () {
    test('extend moves due and keeps short codes', () async {
      final LocalRepository repo = await bootRepo();
      await repo.addInventory(
        name: 'Reading seat',
        category: 'Library',
        units: 2,
        requiresUnitIdentity: true,
        unitCodePrefix: 'SEAT',
        billingMode: BillingMode.monthly,
        rateAmount: 50000,
      );
      final InventoryItem seat = (await repo.listInventory()).first;
      final Customer customer = await ensureCustomer(repo);
      final String rentalId = await repo.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: seat.id,
            instanceName: 'Student',
            shortCode: 'SEAT-1',
            durationUnits: 1,
          ),
        ],
      );
      final Rental before =
          (await repo.listRentals()).firstWhere((Rental r) => r.id == rentalId);
      expect(before.lines.first.shortCode, 'SEAT-1');
      final DateTime currentDue = before.dueAt!;
      final DateTime newDue = DateTime(
        currentDue.year,
        currentDue.month,
        currentDue.day,
      ).add(const Duration(days: 14));

      final bool ok = await repo.extendRentalDue(rentalId, newDue);
      expect(ok, isTrue);
      final Rental after =
          (await repo.listRentals()).firstWhere((Rental r) => r.id == rentalId);
      expect(after.lines.first.shortCode, 'SEAT-1');
      expect(after.dueAt!.year, newDue.year);
      expect(after.dueAt!.month, newDue.month);
      expect(after.dueAt!.day, newDue.day);
      expect(
        after.timeline.any((RentalEvent e) => e.title.contains('due_extended')),
        isTrue,
      );
    });

    test('auto-vacate frees overdue open codes idempotently', () async {
      final LocalRepository repo = await bootRepo();
      await repo.addInventory(
        name: 'Reading seat',
        category: 'Library',
        units: 2,
        requiresUnitIdentity: true,
        unitCodePrefix: 'SEAT',
        billingMode: BillingMode.monthly,
        rateAmount: 50000,
      );
      final InventoryItem seat = (await repo.listInventory()).first;
      final Customer customer = await ensureCustomer(repo);
      final String rentalId = await repo.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: seat.id,
            instanceName: 'Student',
            shortCode: 'SEAT-1',
            durationUnits: 1,
          ),
        ],
      );
      final Rental open =
          (await repo.listRentals()).firstWhere((Rental r) => r.id == rentalId);
      // Force due into the past via extend is not allowed; use DB through extend
      // rejection path — instead re-create with custom timing by updating via
      // return isn't right. Use extend after manually setting? Simpler: call
      // autoVacate with asOf far in the future so current due is "before today".
      final DateTime farFuture = open.dueAt!.add(const Duration(days: 40));
      expect(await repo.listAvailableUnitCodes(seat.id), <String>['SEAT-2']);

      final int vacated =
          await repo.autoVacateOverdueRentals(asOf: farFuture);
      expect(vacated, 1);
      final Rental closed =
          (await repo.listRentals()).firstWhere((Rental r) => r.id == rentalId);
      expect(closed.isActive, isFalse);
      expect(
        closed.timeline.any((RentalEvent e) => e.title.contains('auto_vacated')),
        isTrue,
      );
      expect(
        await repo.listAvailableUnitCodes(seat.id),
        <String>['SEAT-1', 'SEAT-2'],
      );

      final int again = await repo.autoVacateOverdueRentals(asOf: farFuture);
      expect(again, 0);
    });
  });

  group('library template sitting', () {
    test('seeds Reading seat with SEAT prefix and occupancy widget', () async {
      final IndustryTemplate library = industryTemplateById('library')!;
      expect(library.description.toLowerCase(), contains('seat'));
      expect(library.defaultReportWidgets, contains(ReportWidgetId.unitOccupancy));

      final TemplateInventoryItem seat = library.items.firstWhere(
        (TemplateInventoryItem i) => i.name == 'Reading seat',
      );
      expect(seat.requiresUnitIdentity, isTrue);
      expect(seat.unitCodePrefix, 'SEAT');
      expect(seat.defaultUnits, 40);
      expect(seat.billingMode, BillingMode.monthly);

      final LocalRepository repo = await bootRepo();
      final TemplateImportResult imported =
          await repo.importTemplateInventory(library.items);
      expect(imported.added, library.items.length);
      final InventoryItem stored = (await repo.listInventory())
          .firstWhere((InventoryItem i) => i.name == 'Reading seat');
      expect(stored.unitCodePrefix, 'SEAT');
      expect(stored.totalUnits, 40);
      expect(
        await repo.listAvailableUnitCodes(stored.id),
        hasLength(40),
      );
      expect(
        (await repo.listAvailableUnitCodes(stored.id)).first,
        'SEAT-01',
      );
    });
  });
}
