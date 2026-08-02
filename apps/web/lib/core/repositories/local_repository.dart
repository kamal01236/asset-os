import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/app_database.dart';
import '../models/entities.dart';

class SearchResults {
  const SearchResults({
    required this.customers,
    required this.currentRentals,
    required this.previousRentals,
    required this.inventory,
  });

  final List<Customer> customers;
  final List<Rental> currentRentals;
  final List<Rental> previousRentals;
  final List<InventoryItem> inventory;
}

sealed class QrDestination {
  const QrDestination();
}

class QrCustomer extends QrDestination {
  const QrCustomer(this.customerId);
  final String customerId;
}

class QrRental extends QrDestination {
  const QrRental(this.rentalId);
  final String rentalId;
}

class QrInventory extends QrDestination {
  const QrInventory(this.itemId);
  final String itemId;
}

/// Drift-backed facade preserving the UI call surface from the prefs era.
class LocalRepository {
  LocalRepository(this._db, this._preferences);

  static const String snapshotKey = 'asset_os_snapshot_v1';
  static const String _migrationMetaKey = 'prefs_snapshot_migrated_v1';

  final AppDatabase _db;
  final SharedPreferences _preferences;

  AppDatabase get database => _db;

  /// Open DB, migrate SharedPreferences snapshot once, or seed demo data.
  Future<void> initialize() async {
    final bool alreadyMigrated = await _isMigrationComplete();
    final List<CustomerRow> existingCustomers = await _db.select(_db.customers).get();

    if (existingCustomers.isNotEmpty) {
      if (!alreadyMigrated) {
        await _markMigrationComplete();
      }
      return;
    }

    final String? source = _preferences.getString(snapshotKey);
    if (source != null && source.isNotEmpty) {
      final AppDataSnapshot snapshot = AppDataSnapshot.decode(source);
      await _insertSnapshot(snapshot);
      await _markMigrationComplete();
      await _preferences.remove(snapshotKey);
      return;
    }

    await _insertSnapshot(buildDemoSnapshot());
    await _markMigrationComplete();
  }

  Stream<List<Customer>> watchCustomers() {
    final query = _db.select(_db.customers)
      ..orderBy([(t) => OrderingTerm(expression: t.name)]);
    return query.watch().map((rows) => rows.map(_mapCustomer).toList());
  }

  Stream<List<InventoryItem>> watchInventory() {
    final query = _db.select(_db.inventoryItems)
      ..orderBy([(t) => OrderingTerm(expression: t.name)]);
    return query.watch().map((rows) => rows.map(_mapInventory).toList());
  }

  Stream<List<Rental>> watchRentals() {
    return _db.select(_db.rentals).watch().asyncMap((rows) async {
      final List<Rental> rentals = <Rental>[];
      for (final row in rows) {
        rentals.add(await _mapRental(row));
      }
      rentals.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return rentals;
    });
  }

  Future<List<Customer>> listCustomers() => watchCustomers().first;
  Future<List<InventoryItem>> listInventory() => watchInventory().first;
  Future<List<Rental>> listRentals() => watchRentals().first;

  Future<void> createRental({
    required Customer customer,
    required List<InventoryItem> selectedItems,
  }) async {
    final DateTime now = DateTime.now();
    final String rentalId = 'REN-${now.millisecondsSinceEpoch}';
    final String qrCode = 'rental:${now.millisecondsSinceEpoch}';

    await _db.transaction(() async {
      await _db.into(_db.rentals).insert(
        RentalsCompanion.insert(
          id: rentalId,
          customerId: customer.id,
          startedAt: now,
          dueAt: now.add(const Duration(days: 3)),
          qrCode: qrCode,
        ),
      );

      for (final InventoryItem item in selectedItems) {
        await _db.into(_db.rentalItems).insert(
          RentalItemsCompanion.insert(rentalId: rentalId, itemId: item.id),
        );

        final InventoryItemRow? row = await (_db.select(_db.inventoryItems)
              ..where((t) => t.id.equals(item.id)))
            .getSingleOrNull();
        if (row == null) {
          continue;
        }
        final int nextAvailable = (row.availableUnits - 1).clamp(0, row.totalUnits);
        await (_db.update(_db.inventoryItems)..where((t) => t.id.equals(item.id))).write(
          InventoryItemsCompanion(
            availableUnits: Value<int>(nextAvailable),
            status: Value<String>(
              nextAvailable == 0 ? AssetStatus.rented.name : AssetStatus.available.name,
            ),
          ),
        );
      }

      await _db.into(_db.rentalEvents).insert(
        RentalEventsCompanion.insert(
          rentalId: rentalId,
          title: 'Rental opened',
          subtitle: 'Created from phone-first quick flow.',
          at: now,
        ),
      );
    });
  }

  Future<void> returnRental(String rentalId) async {
    final DateTime now = DateTime.now();
    await _db.transaction(() async {
      final RentalRow? rental = await (_db.select(_db.rentals)
            ..where((t) => t.id.equals(rentalId)))
          .getSingleOrNull();
      if (rental == null || rental.returnedAt != null) {
        return;
      }

      await (_db.update(_db.rentals)..where((t) => t.id.equals(rentalId))).write(
        RentalsCompanion(returnedAt: Value<DateTime?>(now)),
      );

      await _db.into(_db.rentalEvents).insert(
        RentalEventsCompanion.insert(
          rentalId: rentalId,
          title: 'Returned',
          subtitle: 'Marked as returned by staff.',
          at: now,
        ),
      );

      final List<RentalItemRow> links = await (_db.select(_db.rentalItems)
            ..where((t) => t.rentalId.equals(rentalId)))
          .get();
      for (final RentalItemRow link in links) {
        final InventoryItemRow? item = await (_db.select(_db.inventoryItems)
              ..where((t) => t.id.equals(link.itemId)))
            .getSingleOrNull();
        if (item == null) {
          continue;
        }
        final int nextAvailable = (item.availableUnits + 1).clamp(0, item.totalUnits);
        await (_db.update(_db.inventoryItems)..where((t) => t.id.equals(item.id))).write(
          InventoryItemsCompanion(
            availableUnits: Value<int>(nextAvailable),
            status: Value<String>(AssetStatus.available.name),
          ),
        );
      }
    });
  }

  Future<void> addInventory({
    required String name,
    required String category,
    required int units,
    String? notes,
  }) async {
    final DateTime now = DateTime.now();
    await _db.into(_db.inventoryItems).insert(
      InventoryItemsCompanion.insert(
        id: 'INV-${now.millisecondsSinceEpoch}',
        name: name,
        category: category,
        availableUnits: units,
        totalUnits: units,
        status: AssetStatus.available.name,
        qrCode: 'inventory:${now.millisecondsSinceEpoch}',
        notes: Value<String?>(notes?.isEmpty == true ? null : notes),
      ),
    );
  }

  Future<Customer> upsertCustomerByPhone({
    required String phone,
    String? fallbackName,
  }) async {
    final Customer? existing = await customerByPhone(phone);
    if (existing != null) {
      return existing;
    }
    final DateTime now = DateTime.now();
    final int count = (await _db.select(_db.customers).get()).length;
    final Customer customer = Customer(
      id: 'CUS-${now.millisecondsSinceEpoch}',
      name: fallbackName?.trim().isNotEmpty == true
          ? fallbackName!.trim()
          : 'Customer ${count + 1}',
      phone: phone.trim(),
      isTrusted: false,
      qrCode: 'customer:${now.millisecondsSinceEpoch}',
    );
    await _db.into(_db.customers).insert(_customerCompanion(customer));
    return customer;
  }

  Future<Customer?> customerByPhone(String phone) async {
    final String normalized = phone.trim();
    if (normalized.isEmpty) {
      return null;
    }
    final CustomerRow? row = await (_db.select(_db.customers)
          ..where((t) => t.phone.equals(normalized)))
        .getSingleOrNull();
    return row == null ? null : _mapCustomer(row);
  }

  Future<SearchResults> search(String query) async {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return const SearchResults(
        customers: <Customer>[],
        currentRentals: <Rental>[],
        previousRentals: <Rental>[],
        inventory: <InventoryItem>[],
      );
    }

    final List<Customer> customers = (await listCustomers()).where((customer) {
      return customer.name.toLowerCase().contains(q) ||
          customer.phone.toLowerCase().contains(q) ||
          customer.id.toLowerCase().contains(q);
    }).toList();

    final List<Rental> rentals = await listRentals();
    final List<Rental> currentRentals = rentals.where((rental) {
      return rental.isActive &&
          (rental.id.toLowerCase().contains(q) || rental.qrCode.toLowerCase().contains(q));
    }).toList();
    final List<Rental> previousRentals = rentals.where((rental) {
      return !rental.isActive &&
          (rental.id.toLowerCase().contains(q) || rental.qrCode.toLowerCase().contains(q));
    }).toList();

    final List<InventoryItem> inventory = (await listInventory()).where((item) {
      return item.name.toLowerCase().contains(q) ||
          item.category.toLowerCase().contains(q) ||
          item.id.toLowerCase().contains(q);
    }).toList();

    return SearchResults(
      customers: customers,
      currentRentals: currentRentals,
      previousRentals: previousRentals,
      inventory: inventory,
    );
  }

  Future<QrDestination?> resolveQr(String code) async {
    final String input = code.trim();
    if (input.isEmpty) {
      return null;
    }

    final CustomerRow? customer = await (_db.select(_db.customers)
          ..where((t) => t.qrCode.equals(input)))
        .getSingleOrNull();
    if (customer != null) {
      return QrCustomer(customer.id);
    }

    final RentalRow? rental = await (_db.select(_db.rentals)
          ..where((t) => t.qrCode.equals(input)))
        .getSingleOrNull();
    if (rental != null) {
      return QrRental(rental.id);
    }

    final InventoryItemRow? item = await (_db.select(_db.inventoryItems)
          ..where((t) => t.qrCode.equals(input)))
        .getSingleOrNull();
    if (item != null) {
      return QrInventory(item.id);
    }
    return null;
  }

  Future<bool> _isMigrationComplete() async {
    final AppMetaRow? row = await (_db.select(_db.appMeta)
          ..where((t) => t.key.equals(_migrationMetaKey)))
        .getSingleOrNull();
    return row?.value == '1';
  }

  Future<void> _markMigrationComplete() async {
    await _db.into(_db.appMeta).insertOnConflictUpdate(
      AppMetaCompanion.insert(key: _migrationMetaKey, value: '1'),
    );
  }

  Future<void> _insertSnapshot(AppDataSnapshot snapshot) async {
    await _db.transaction(() async {
      for (final Customer customer in snapshot.customers) {
        await _db.into(_db.customers).insertOnConflictUpdate(_customerCompanion(customer));
      }
      for (final InventoryItem item in snapshot.inventory) {
        await _db.into(_db.inventoryItems).insertOnConflictUpdate(_inventoryCompanion(item));
      }
      for (final Rental rental in snapshot.rentals) {
        await _db.into(_db.rentals).insertOnConflictUpdate(
          RentalsCompanion.insert(
            id: rental.id,
            customerId: rental.customerId,
            startedAt: rental.startedAt,
            dueAt: rental.dueAt,
            returnedAt: Value<DateTime?>(rental.returnedAt),
            qrCode: rental.qrCode,
          ),
        );
        for (final String itemId in rental.itemIds) {
          await _db.into(_db.rentalItems).insertOnConflictUpdate(
            RentalItemsCompanion.insert(rentalId: rental.id, itemId: itemId),
          );
        }
        for (final RentalEvent event in rental.timeline) {
          await _db.into(_db.rentalEvents).insert(
            RentalEventsCompanion.insert(
              rentalId: rental.id,
              title: event.title,
              subtitle: event.subtitle,
              at: event.at,
            ),
          );
        }
      }
    });
  }

  CustomersCompanion _customerCompanion(Customer customer) {
    return CustomersCompanion.insert(
      id: customer.id,
      name: customer.name,
      phone: customer.phone,
      isTrusted: Value<bool>(customer.isTrusted),
      qrCode: customer.qrCode,
    );
  }

  InventoryItemsCompanion _inventoryCompanion(InventoryItem item) {
    return InventoryItemsCompanion.insert(
      id: item.id,
      name: item.name,
      category: item.category,
      availableUnits: item.availableUnits,
      totalUnits: item.totalUnits,
      status: item.status.name,
      qrCode: item.qrCode,
      notes: Value<String?>(item.notes),
    );
  }

  Customer _mapCustomer(CustomerRow row) {
    return Customer(
      id: row.id,
      name: row.name,
      phone: row.phone,
      isTrusted: row.isTrusted,
      qrCode: row.qrCode,
    );
  }

  InventoryItem _mapInventory(InventoryItemRow row) {
    return InventoryItem(
      id: row.id,
      name: row.name,
      category: row.category,
      availableUnits: row.availableUnits,
      totalUnits: row.totalUnits,
      status: AssetStatus.values.byName(row.status),
      qrCode: row.qrCode,
      notes: row.notes,
    );
  }

  Future<Rental> _mapRental(RentalRow row) async {
    final List<RentalItemRow> links = await (_db.select(_db.rentalItems)
          ..where((t) => t.rentalId.equals(row.id)))
        .get();
    final eventQuery = _db.select(_db.rentalEvents)..where((t) => t.rentalId.equals(row.id));
    final List<RentalEventRow> events = await eventQuery.get();
    events.sort((a, b) => b.at.compareTo(a.at));

    return Rental(
      id: row.id,
      customerId: row.customerId,
      itemIds: links.map((link) => link.itemId).toList(),
      startedAt: row.startedAt,
      dueAt: row.dueAt,
      returnedAt: row.returnedAt,
      qrCode: row.qrCode,
      timeline: events
          .map(
            (event) => RentalEvent(
              title: event.title,
              subtitle: event.subtitle,
              at: event.at,
            ),
          )
          .toList(),
    );
  }
}

/// Demo seed used when DB is empty and no SharedPreferences snapshot exists.
AppDataSnapshot buildDemoSnapshot({DateTime? now}) {
  final DateTime clock = now ?? DateTime.now();
  final List<Customer> seedCustomers = <Customer>[
    const Customer(
      id: 'CUS-1001',
      name: 'Priya Patel',
      phone: '9876500001',
      isTrusted: true,
      qrCode: 'customer:1001',
    ),
    const Customer(
      id: 'CUS-1002',
      name: 'Amit Sharma',
      phone: '9876500002',
      isTrusted: false,
      qrCode: 'customer:1002',
    ),
    const Customer(
      id: 'CUS-1003',
      name: 'Ravi Das',
      phone: '9876500003',
      isTrusted: true,
      qrCode: 'customer:1003',
    ),
  ];

  final List<InventoryItem> seedInventory = <InventoryItem>[
    const InventoryItem(
      id: 'INV-2001',
      name: 'Canon DSLR Camera',
      category: 'Camera',
      availableUnits: 2,
      totalUnits: 3,
      status: AssetStatus.available,
      qrCode: 'inventory:2001',
    ),
    const InventoryItem(
      id: 'INV-2002',
      name: 'Bosch Drill Kit',
      category: 'Tools',
      availableUnits: 0,
      totalUnits: 2,
      status: AssetStatus.rented,
      qrCode: 'inventory:2002',
    ),
    const InventoryItem(
      id: 'INV-2003',
      name: 'Audio Mixer X12',
      category: 'Audio',
      availableUnits: 1,
      totalUnits: 1,
      status: AssetStatus.available,
      qrCode: 'inventory:2003',
    ),
  ];

  final List<Rental> seedRentals = <Rental>[
    Rental(
      id: 'REN-3001',
      customerId: seedCustomers[0].id,
      itemIds: <String>['INV-2002'],
      startedAt: clock.subtract(const Duration(days: 2)),
      dueAt: clock,
      timeline: <RentalEvent>[
        RentalEvent(
          title: 'Due today',
          subtitle: 'Auto reminder generated.',
          at: clock.subtract(const Duration(hours: 2)),
        ),
        RentalEvent(
          title: 'Rental opened',
          subtitle: '1 item checked out by staff.',
          at: clock.subtract(const Duration(days: 2)),
        ),
      ],
      qrCode: 'rental:3001',
    ),
    Rental(
      id: 'REN-3002',
      customerId: seedCustomers[1].id,
      itemIds: <String>['INV-2001'],
      startedAt: clock.subtract(const Duration(days: 5)),
      dueAt: clock.subtract(const Duration(days: 1)),
      timeline: <RentalEvent>[
        RentalEvent(
          title: 'Returned',
          subtitle: 'Closed at counter.',
          at: clock.subtract(const Duration(days: 1)),
        ),
        RentalEvent(
          title: 'Rental opened',
          subtitle: 'Manual walk-in checkout.',
          at: clock.subtract(const Duration(days: 5)),
        ),
      ],
      qrCode: 'rental:3002',
      returnedAt: clock.subtract(const Duration(days: 1)),
    ),
  ];

  return AppDataSnapshot(
    customers: seedCustomers,
    inventory: seedInventory,
    rentals: seedRentals,
  );
}
