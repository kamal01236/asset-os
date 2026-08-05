@Tags(['unit', 'returns'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/core/models/customer_activity.dart';
import 'package:asset_os/core/models/entities.dart';
import 'package:asset_os/core/repositories/local_repository.dart';
import 'package:asset_os/l10n/app_localizations.dart';

import 'support/test_harness.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });
  test('requiresUnitIdentity persists on add and update', () async {
    final LocalRepository repository = await bootRepo();
    await repository.addInventory(
      name: 'Novels',
      category: 'Library',
      units: 5,
      requiresUnitIdentity: true,
    );
    await repository.addInventory(
      name: 'Drill Kit Solo',
      category: 'Tools',
      units: 2,
      requiresUnitIdentity: false,
    );

    final List<InventoryItem> inventory = await repository.listInventory();
    final InventoryItem novels =
        inventory.firstWhere((InventoryItem i) => i.name == 'Novels');
    final InventoryItem drill =
        inventory.firstWhere((InventoryItem i) => i.name == 'Drill Kit Solo');
    expect(novels.requiresUnitIdentity, isTrue);
    expect(drill.requiresUnitIdentity, isFalse);
    expect(novels.id, isNot(equals(drill.id)));

    await repository.updateInventory(
      id: novels.id,
      name: novels.name,
      category: novels.category,
      units: novels.totalUnits,
      requiresUnitIdentity: false,
    );
    final InventoryItem updated = (await repository.listInventory())
        .firstWhere((InventoryItem i) => i.id == novels.id);
    expect(updated.requiresUnitIdentity, isFalse);
  });

  test('rapid addInventory yields unique ids', () async {
    final LocalRepository repository = await bootRepo();
    await repository.addInventory(
      name: 'Alpha Item',
      category: 'Tools',
      units: 1,
    );
    await repository.addInventory(
      name: 'Beta Item',
      category: 'Tools',
      units: 1,
    );
    final List<InventoryItem> inventory = await repository.listInventory();
    expect(inventory.map((InventoryItem i) => i.id).toSet(), hasLength(2));
  });

  test('parent item issues qty 3 with required labels', () async {
    final LocalRepository repository = await bootRepo();
    await repository.addInventory(
      name: 'Novels',
      category: 'Library',
      units: 5,
      rateAmount: 5000,
      requiresUnitIdentity: true,
    );
    final InventoryItem novels = (await repository.listInventory())
        .firstWhere((InventoryItem i) => i.name == 'Novels');
    final Customer customer = await ensureCustomer(
      repository,
      phone: '9111111111',
      name: 'Reader One',
    );

    final String rentalId = await repository.createRental(
      customer: customer,
      lines: <RentalLineInput>[
        RentalLineInput(
          itemId: novels.id,
          instanceName: 'Harry Potter',
          shortCode: 'NOV-1',
        ),
        RentalLineInput(
          itemId: novels.id,
          instanceName: 'Hobbit',
          shortCode: 'NOV-2',
        ),
        RentalLineInput(
          itemId: novels.id,
          instanceName: 'Dune',
          shortCode: 'NOV-3',
        ),
      ],
      durationUnits: 1,
    );

    final Rental rental = (await repository.listRentals())
        .firstWhere((Rental r) => r.id == rentalId);
    expect(rental.lines, hasLength(3));
    expect(
      rental.lines.map((RentalLine l) => l.instanceName).toSet(),
      <String>{'Harry Potter', 'Hobbit', 'Dune'},
    );
    final InventoryItem after = (await repository.listInventory())
        .firstWhere((InventoryItem i) => i.id == novels.id);
    expect(after.availableUnits, 2);
  });

  test('individual item auto-labels without blocking names', () async {
    final LocalRepository repository = await bootRepo();
    await repository.addInventory(
      name: 'Tripod Pro',
      category: 'Camera',
      units: 3,
      rateAmount: 20000,
      requiresUnitIdentity: false,
    );
    final InventoryItem item = (await repository.listInventory())
        .firstWhere((InventoryItem i) => i.name == 'Tripod Pro');
    expect(item.requiresUnitIdentity, isFalse);

    final Set<String> used = <String>{};
    final String code1 = LocalRepository.generateAutoShortCode(
      catalogName: item.name,
      index: 1,
      usedCodes: used,
    );
    used.add(code1);
    final String code2 = LocalRepository.generateAutoShortCode(
      catalogName: item.name,
      index: 2,
      usedCodes: used,
    );
    expect(code1, isNot(equals(code2)));

    final Customer customer = await ensureCustomer(
      repository,
      phone: '9222222222',
      name: 'Cam User',
    );
    final String rentalId = await repository.createRental(
      customer: customer,
      lines: <RentalLineInput>[
        RentalLineInput(
          itemId: item.id,
          instanceName: item.name,
          shortCode: code1,
        ),
        RentalLineInput(
          itemId: item.id,
          instanceName: item.name,
          shortCode: code2,
        ),
      ],
      durationUnits: 1,
    );
    final Rental rental = (await repository.listRentals())
        .firstWhere((Rental r) => r.id == rentalId);
    expect(rental.lines, hasLength(2));
    expect(
      rental.lines.every((RentalLine l) => l.instanceName == 'Tripod Pro'),
      isTrue,
    );
  });

  test('partial return updates order status summary counts', () async {
    final LocalRepository repository = await bootRepo();
    await repository.addInventory(
      name: 'Novels Pack',
      category: 'Library',
      units: 4,
      rateAmount: 5000,
      requiresUnitIdentity: true,
    );
    final InventoryItem novels = (await repository.listInventory())
        .firstWhere((InventoryItem i) => i.name == 'Novels Pack');
    final Customer customer = await ensureCustomer(
      repository,
      phone: '9333333333',
      name: 'Returner',
    );
    final String rentalId = await repository.createRental(
      customer: customer,
      lines: <RentalLineInput>[
        RentalLineInput(
          itemId: novels.id,
          instanceName: 'Book A',
          shortCode: 'BK-A',
        ),
        RentalLineInput(
          itemId: novels.id,
          instanceName: 'Book B',
          shortCode: 'BK-B',
        ),
        RentalLineInput(
          itemId: novels.id,
          instanceName: 'Book C',
          shortCode: 'BK-C',
        ),
      ],
      durationUnits: 1,
    );
    Rental rental = (await repository.listRentals())
        .firstWhere((Rental r) => r.id == rentalId);
    RentalOrderStatusSummary summary =
        RentalOrderStatusSummary.fromRental(rental);
    expect(summary.issued, 3);
    expect(summary.pending, 3);
    expect(summary.returned, 0);

    await repository.returnRentalLines(
      rentalId,
      <String>[rental.lines.first.id],
    );
    rental = (await repository.listRentals())
        .firstWhere((Rental r) => r.id == rentalId);
    summary = RentalOrderStatusSummary.fromRental(rental);
    expect(summary.issued, 3);
    expect(summary.pending, 2);
    expect(summary.returned, 1);
    expect(rental.isActive, isTrue);
  });

  test('customer activity timeline orders issue then returns by time', () {
    final DateTime t0 = DateTime(2026, 1, 1, 10);
    final DateTime t1 = DateTime(2026, 1, 2, 12);
    final DateTime t2 = DateTime(2026, 1, 3, 9);
    final Rental rental = Rental(
      id: 'REN-ACT',
      customerId: 'CUS-1',
      lines: <RentalLine>[
        RentalLine(
          id: 'RLI-1',
          itemId: 'INV-1',
          catalogName: 'Novels',
          instanceName: 'Book A',
          shortCode: 'A-1',
          returnedAt: t1,
        ),
        RentalLine(
          id: 'RLI-2',
          itemId: 'INV-1',
          catalogName: 'Novels',
          instanceName: 'Book B',
          shortCode: 'B-1',
          returnedAt: t2,
        ),
      ],
      startedAt: t0,
      dueAt: t0.add(const Duration(days: 7)),
      timeline: <RentalEvent>[
        RentalEvent(
          title: 'Rental opened',
          subtitle: '2 items',
          at: t0,
        ),
      ],
      qrCode: 'rental:act',
    );

    final List<CustomerActivityEntry> activity =
        buildCustomerActivity(<Rental>[rental], l10n);
    expect(activity, isNotEmpty);

    final List<CustomerActivityEntry> issueReturn = activity
        .where(
          (CustomerActivityEntry e) =>
              e.kind == CustomerActivityKind.issued ||
              e.kind == CustomerActivityKind.returned,
        )
        .toList();
    // Newest first.
    expect(issueReturn.first.kind, CustomerActivityKind.returned);
    expect(issueReturn.first.subtitle, contains('Book B'));
    expect(issueReturn[1].kind, CustomerActivityKind.returned);
    expect(issueReturn[1].subtitle, contains('Book A'));
    expect(issueReturn.last.kind, CustomerActivityKind.issued);
    expect(issueReturn.last.at, t0);

    // Ascending check for chronological story.
    final List<CustomerActivityEntry> chrono =
        List<CustomerActivityEntry>.from(issueReturn)
          ..sort(
            (CustomerActivityEntry a, CustomerActivityEntry b) =>
                a.at.compareTo(b.at),
          );
    expect(chrono.map((CustomerActivityEntry e) => e.kind).toList(), <CustomerActivityKind>[
      CustomerActivityKind.issued,
      CustomerActivityKind.returned,
      CustomerActivityKind.returned,
    ]);
  });
}
