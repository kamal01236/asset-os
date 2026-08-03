import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/app_database.dart';
import '../models/entities.dart';
import '../models/self_customer.dart';
import '../pricing/rental_pricing.dart';
import '../templates/industry_templates.dart';

class TemplateImportResult {
  const TemplateImportResult({
    required this.added,
    required this.skipped,
  });

  final int added;
  final int skipped;
}

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
      await ensureSelfCustomer();
      return;
    }

    final String? source = _preferences.getString(snapshotKey);
    if (source != null && source.isNotEmpty) {
      final AppDataSnapshot snapshot = AppDataSnapshot.decode(source);
      await _insertSnapshot(snapshot);
      await _markMigrationComplete();
      await _preferences.remove(snapshotKey);
      await ensureSelfCustomer();
      return;
    }

    await _insertSnapshot(buildDemoSnapshot());
    await _markMigrationComplete();
    await ensureSelfCustomer();
  }

  /// Inserts the fixed SELF Known sentinel if missing; never renames it.
  Future<Customer> ensureSelfCustomer() async {
    final CustomerRow? byId = await (_db.select(_db.customers)
          ..where((t) => t.id.equals(kSelfCustomerId)))
        .getSingleOrNull();
    if (byId != null) {
      return _mapCustomer(byId);
    }

    final CustomerRow? byPhone = await (_db.select(_db.customers)
          ..where((t) => t.phone.equals(kSelfCustomerPhone)))
        .getSingleOrNull();
    if (byPhone != null) {
      return _mapCustomer(byPhone);
    }

    final Customer self = buildSelfCustomer();
    await _db.into(_db.customers).insert(_customerCompanion(self));
    return self;
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

  /// Normalize short codes for storage and uniqueness checks.
  static String normalizeShortCode(String value) => value.trim().toUpperCase();

  Future<void> createRental({
    required Customer customer,
    required List<RentalLineInput> lines,
    String? nickname,
    int durationUnits = 1,
    DateTime? customEnd,
    BillingMode? billingModeOverride,
  }) async {
    final String? trimmedNick = nickname?.trim();
    final String? storedNick =
        (trimmedNick != null && trimmedNick.isNotEmpty) ? trimmedNick : null;
    if (isSelfCustomer(customer) && storedNick == null) {
      throw ArgumentError(
        'Nickname is required when issuing to $kSelfCustomerName',
      );
    }
    if (lines.isEmpty) {
      throw ArgumentError('At least one rental line is required');
    }

    final List<RentalLineInput> normalized = <RentalLineInput>[];
    final Set<String> batchCodes = <String>{};
    for (final RentalLineInput line in lines) {
      final String instanceName = line.instanceName.trim();
      final String shortCode = normalizeShortCode(line.shortCode);
      if (instanceName.isEmpty || shortCode.isEmpty) {
        throw ArgumentError('Instance name and short code are required');
      }
      if (!batchCodes.add(shortCode)) {
        throw DuplicateActiveShortCodeException(shortCode);
      }
      normalized.add(
        RentalLineInput(
          itemId: line.itemId,
          instanceName: instanceName,
          shortCode: shortCode,
        ),
      );
    }

    final DateTime now = DateTime.now();
    final String rentalId = 'REN-${now.millisecondsSinceEpoch}';
    final String qrCode = 'rental:${now.millisecondsSinceEpoch}';
    final int units = durationUnits < 1 ? 1 : durationUnits;

    await _db.transaction(() async {
      for (final RentalLineInput line in normalized) {
        await _assertShortCodeAvailable(line.shortCode);
      }

      final List<InventoryItemRow> itemRows = <InventoryItemRow>[];
      for (final RentalLineInput line in normalized) {
        final InventoryItemRow? row = await (_db.select(_db.inventoryItems)
              ..where((t) => t.id.equals(line.itemId)))
            .getSingleOrNull();
        if (row == null) {
          throw ArgumentError('Inventory item not found: ${line.itemId}');
        }
        itemRows.add(row);
      }

      // v1: duration UI follows primary (first) item mode; charges are per-line.
      final BillingMode mode = billingModeOverride ??
          BillingMode.parse(itemRows.first.billingMode);
      final DateTime dueAt = computeDueAt(
        start: now,
        mode: mode,
        durationUnits: units,
        customEnd: customEnd,
      );

      int baseAmount = 0;
      int lateFeePerDay = 0;
      for (final InventoryItemRow row in itemRows) {
        final BillingMode lineMode = BillingMode.parse(row.billingMode);
        baseAmount += computeBaseAmount(
          mode: lineMode,
          rateAmount: row.rateAmount,
          start: now,
          due: dueAt,
        );
        lateFeePerDay += row.lateFeePerDay;
      }

      await _db.into(_db.rentals).insert(
        RentalsCompanion.insert(
          id: rentalId,
          customerId: customer.id,
          startedAt: now,
          dueAt: dueAt,
          qrCode: qrCode,
          nickname: Value<String?>(storedNick),
          billingMode: Value<String>(mode.name),
          rateAmount: Value<int>(itemRows.first.rateAmount),
          lateFeePerDay: Value<int>(lateFeePerDay),
          baseAmount: Value<int>(baseAmount),
          lateAmount: const Value<int>(0),
          totalAmount: Value<int>(baseAmount),
          durationUnits: Value<int>(units),
        ),
      );

      for (var i = 0; i < normalized.length; i++) {
        final RentalLineInput line = normalized[i];
        final InventoryItemRow row = itemRows[i];
        await _db.into(_db.rentalItems).insert(
          RentalItemsCompanion.insert(
            rentalId: rentalId,
            itemId: line.itemId,
            instanceName: Value<String>(line.instanceName),
            shortCode: Value<String>(line.shortCode),
          ),
        );

        final int nextAvailable =
            (row.availableUnits - 1).clamp(0, row.totalUnits);
        await (_db.update(_db.inventoryItems)..where((t) => t.id.equals(line.itemId)))
            .write(
          InventoryItemsCompanion(
            availableUnits: Value<int>(nextAvailable),
            status: Value<String>(
              nextAvailable == 0
                  ? AssetStatus.rented.name
                  : AssetStatus.available.name,
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

  Future<void> _assertShortCodeAvailable(String normalizedCode) async {
    final List<RentalItemRow> links = await _db.select(_db.rentalItems).get();
    for (final RentalItemRow link in links) {
      if (normalizeShortCode(link.shortCode) != normalizedCode) {
        continue;
      }
      final RentalRow? rental = await (_db.select(_db.rentals)
            ..where((t) => t.id.equals(link.rentalId)))
          .getSingleOrNull();
      if (rental != null && rental.returnedAt == null) {
        throw DuplicateActiveShortCodeException(normalizedCode);
      }
    }
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

      final int lateAmount = computeLateAmount(
        due: rental.dueAt,
        asOf: now,
        lateFeePerDay: rental.lateFeePerDay,
      );
      final int totalAmount = computeTotalAmount(
        baseAmount: rental.baseAmount,
        lateAmount: lateAmount,
      );

      await (_db.update(_db.rentals)..where((t) => t.id.equals(rentalId))).write(
        RentalsCompanion(
          returnedAt: Value<DateTime?>(now),
          lateAmount: Value<int>(lateAmount),
          totalAmount: Value<int>(totalAmount),
        ),
      );

      await _db.into(_db.rentalEvents).insert(
        RentalEventsCompanion.insert(
          rentalId: rentalId,
          title: 'Returned',
          subtitle: lateAmount > 0
              ? 'Marked as returned by staff. Late fee applied.'
              : 'Marked as returned by staff.',
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
    BillingMode billingMode = BillingMode.weekly,
    int rateAmount = 0,
    int lateFeePerDay = 0,
    String currencyCode = 'INR',
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
        billingMode: Value<String>(billingMode.name),
        rateAmount: Value<int>(rateAmount < 0 ? 0 : rateAmount),
        lateFeePerDay: Value<int>(lateFeePerDay < 0 ? 0 : lateFeePerDay),
        currencyCode: Value<String>(
          currencyCode.trim().isEmpty ? 'INR' : currencyCode.trim().toUpperCase(),
        ),
      ),
    );
  }

  /// Merge selected template items into inventory. Same name (case-insensitive) is skipped.
  Future<TemplateImportResult> importTemplateInventory(
    List<TemplateInventoryItem> selected,
  ) async {
    if (selected.isEmpty) {
      return const TemplateImportResult(added: 0, skipped: 0);
    }

    final List<InventoryItem> existing = await listInventory();
    final Set<String> existingNames = existing
        .map((item) => item.name.trim().toLowerCase())
        .toSet();

    int added = 0;
    int skipped = 0;
    // Stagger ids when inserting multiple items in one tick.
    int stamp = DateTime.now().millisecondsSinceEpoch;

    for (final TemplateInventoryItem item in selected) {
      final String key = item.name.trim().toLowerCase();
      if (key.isEmpty || existingNames.contains(key)) {
        skipped += 1;
        continue;
      }
      final int units = item.defaultUnits < 1 ? 1 : item.defaultUnits;
      await _db.into(_db.inventoryItems).insert(
        InventoryItemsCompanion.insert(
          id: 'INV-$stamp',
          name: item.name.trim(),
          category: item.category.trim(),
          availableUnits: units,
          totalUnits: units,
          status: AssetStatus.available.name,
          qrCode: 'inventory:$stamp',
          notes: Value<String?>(item.notes?.isEmpty == true ? null : item.notes),
          billingMode: Value<String>(item.billingMode.name),
          rateAmount: Value<int>(item.rateAmount < 0 ? 0 : item.rateAmount),
          lateFeePerDay: Value<int>(
            item.lateFeePerDay < 0 ? 0 : item.lateFeePerDay,
          ),
          currencyCode: Value<String>(
            item.currencyCode.trim().isEmpty
                ? 'INR'
                : item.currencyCode.trim().toUpperCase(),
          ),
        ),
      );
      existingNames.add(key);
      added += 1;
      stamp += 1;
    }

    return TemplateImportResult(added: added, skipped: skipped);
  }

  Future<void> updateInventory({
    required String id,
    required String name,
    required String category,
    required int units,
    String? notes,
    BillingMode? billingMode,
    int? rateAmount,
    int? lateFeePerDay,
    String? currencyCode,
  }) async {
    final InventoryItemRow? row = await (_db.select(_db.inventoryItems)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) {
      return;
    }

    final int nextTotal = units < 1 ? 1 : units;
    final int delta = nextTotal - row.totalUnits;
    int nextAvailable = row.availableUnits;
    if (delta > 0) {
      // Extra units start available.
      nextAvailable = row.availableUnits + delta;
    } else if (delta < 0) {
      nextAvailable = (row.availableUnits + delta).clamp(0, nextTotal);
    }
    nextAvailable = nextAvailable.clamp(0, nextTotal);

    await (_db.update(_db.inventoryItems)..where((t) => t.id.equals(id))).write(
      InventoryItemsCompanion(
        name: Value<String>(name.trim()),
        category: Value<String>(category.trim()),
        totalUnits: Value<int>(nextTotal),
        availableUnits: Value<int>(nextAvailable),
        status: Value<String>(
          nextAvailable > 0 ? AssetStatus.available.name : AssetStatus.rented.name,
        ),
        notes: Value<String?>(notes?.isEmpty == true ? null : notes),
        billingMode: billingMode == null
            ? const Value.absent()
            : Value<String>(billingMode.name),
        rateAmount: rateAmount == null
            ? const Value.absent()
            : Value<int>(rateAmount < 0 ? 0 : rateAmount),
        lateFeePerDay: lateFeePerDay == null
            ? const Value.absent()
            : Value<int>(lateFeePerDay < 0 ? 0 : lateFeePerDay),
        currencyCode: currencyCode == null
            ? const Value.absent()
            : Value<String>(
                currencyCode.trim().isEmpty
                    ? 'INR'
                    : currencyCode.trim().toUpperCase(),
              ),
      ),
    );
  }

  Future<Customer> upsertCustomerByPhone({
    required String phone,
    String? fallbackName,
  }) async {
    if (isSelfCustomerPhone(phone)) {
      return ensureSelfCustomer();
    }
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
    bool rentalMatches(Rental rental) {
      if (rental.id.toLowerCase().contains(q) ||
          rental.qrCode.toLowerCase().contains(q) ||
          (rental.nickname?.toLowerCase().contains(q) ?? false)) {
        return true;
      }
      for (final RentalLine line in rental.lines) {
        if (line.instanceName.toLowerCase().contains(q) ||
            line.shortCode.toLowerCase().contains(q) ||
            line.catalogName.toLowerCase().contains(q) ||
            line.displayLabel.toLowerCase().contains(q)) {
          return true;
        }
      }
      return false;
    }

    final List<Rental> currentRentals =
        rentals.where((rental) => rental.isActive && rentalMatches(rental)).toList();
    final List<Rental> previousRentals =
        rentals.where((rental) => !rental.isActive && rentalMatches(rental)).toList();

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
            nickname: Value<String?>(rental.nickname),
            billingMode: Value<String>(rental.billingMode.name),
            rateAmount: Value<int>(rental.rateAmount),
            lateFeePerDay: Value<int>(rental.lateFeePerDay),
            baseAmount: Value<int>(rental.baseAmount),
            lateAmount: Value<int>(rental.lateAmount),
            totalAmount: Value<int>(rental.totalAmount),
            durationUnits: Value<int>(rental.durationUnits),
          ),
        );
        for (final RentalLine line in rental.lines) {
          final String instanceName = line.instanceName.trim().isEmpty
              ? line.catalogName.trim()
              : line.instanceName.trim();
          final String shortCode = LocalRepository.normalizeShortCode(
            line.shortCode.trim().isEmpty ? 'LEGACY' : line.shortCode,
          );
          await _db.into(_db.rentalItems).insertOnConflictUpdate(
            RentalItemsCompanion.insert(
              rentalId: rental.id,
              itemId: line.itemId,
              instanceName: Value<String>(instanceName),
              shortCode: Value<String>(shortCode),
            ),
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
      billingMode: Value<String>(item.billingMode.name),
      rateAmount: Value<int>(item.rateAmount),
      lateFeePerDay: Value<int>(item.lateFeePerDay),
      currencyCode: Value<String>(item.currencyCode),
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
      billingMode: BillingMode.parse(row.billingMode),
      rateAmount: row.rateAmount,
      lateFeePerDay: row.lateFeePerDay,
      currencyCode: row.currencyCode,
    );
  }

  Future<Rental> _mapRental(RentalRow row) async {
    final List<RentalItemRow> links = await (_db.select(_db.rentalItems)
          ..where((t) => t.rentalId.equals(row.id)))
        .get();
    final eventQuery = _db.select(_db.rentalEvents)..where((t) => t.rentalId.equals(row.id));
    final List<RentalEventRow> events = await eventQuery.get();
    events.sort((a, b) => b.at.compareTo(a.at));

    final List<RentalLine> lines = <RentalLine>[];
    for (final RentalItemRow link in links) {
      final InventoryItemRow? item = await (_db.select(_db.inventoryItems)
            ..where((t) => t.id.equals(link.itemId)))
          .getSingleOrNull();
      lines.add(
        RentalLine(
          itemId: link.itemId,
          catalogName: item?.name ?? link.itemId,
          instanceName: link.instanceName,
          shortCode: link.shortCode,
        ),
      );
    }

    return Rental(
      id: row.id,
      customerId: row.customerId,
      lines: lines,
      startedAt: row.startedAt,
      dueAt: row.dueAt,
      returnedAt: row.returnedAt,
      qrCode: row.qrCode,
      nickname: row.nickname,
      billingMode: BillingMode.parse(row.billingMode),
      rateAmount: row.rateAmount,
      lateFeePerDay: row.lateFeePerDay,
      baseAmount: row.baseAmount,
      lateAmount: row.lateAmount,
      totalAmount: row.totalAmount,
      durationUnits: row.durationUnits,
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
    buildSelfCustomer(),
    const Customer(
      id: 'CUS-1001',
      name: 'Priya Patel',
      phone: '6666666666',
      isTrusted: true,
      qrCode: 'customer:1001',
    ),
    const Customer(
      id: 'CUS-1002',
      name: 'Amit Sharma',
      phone: '7777777777',
      isTrusted: false,
      qrCode: 'customer:1002',
    ),
    const Customer(
      id: 'CUS-1003',
      name: 'Ravi Das',
      phone: '9999999999',
      isTrusted: true,
      qrCode: 'customer:1003',
    ),
  ];

  // Camera-light + one tools item so Home/rentals stay coherent with templates.
  final List<InventoryItem> seedInventory = <InventoryItem>[
    const InventoryItem(
      id: 'INV-2001',
      name: 'DSLR',
      category: 'Camera',
      availableUnits: 2,
      totalUnits: 3,
      status: AssetStatus.available,
      qrCode: 'inventory:2001',
      billingMode: BillingMode.daily,
      rateAmount: 150000,
      lateFeePerDay: 20000,
    ),
    const InventoryItem(
      id: 'INV-2002',
      name: 'Drill Kit',
      category: 'Tools',
      availableUnits: 0,
      totalUnits: 2,
      status: AssetStatus.rented,
      qrCode: 'inventory:2002',
      billingMode: BillingMode.daily,
      rateAmount: 25000,
      lateFeePerDay: 5000,
    ),
    const InventoryItem(
      id: 'INV-2003',
      name: 'Tripod',
      category: 'Camera',
      availableUnits: 1,
      totalUnits: 1,
      status: AssetStatus.available,
      qrCode: 'inventory:2003',
      billingMode: BillingMode.daily,
      rateAmount: 20000,
    ),
  ];

  final List<Rental> seedRentals = <Rental>[
    Rental(
      id: 'REN-3001',
      customerId: seedCustomers[1].id,
      lines: const <RentalLine>[
        RentalLine(
          itemId: 'INV-2002',
          catalogName: 'Drill Kit',
          instanceName: 'Workshop set A',
          shortCode: 'DRL-001',
        ),
      ],
      startedAt: clock.subtract(const Duration(days: 2)),
      dueAt: clock,
      billingMode: BillingMode.daily,
      rateAmount: 25000,
      lateFeePerDay: 5000,
      baseAmount: 50000,
      lateAmount: 0,
      totalAmount: 50000,
      durationUnits: 2,
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
      customerId: seedCustomers[2].id,
      lines: const <RentalLine>[
        RentalLine(
          itemId: 'INV-2001',
          catalogName: 'DSLR',
          instanceName: 'Body unit 1',
          shortCode: 'CAM-001',
        ),
      ],
      startedAt: clock.subtract(const Duration(days: 5)),
      dueAt: clock.subtract(const Duration(days: 1)),
      billingMode: BillingMode.daily,
      rateAmount: 150000,
      lateFeePerDay: 20000,
      baseAmount: 600000,
      lateAmount: 0,
      totalAmount: 600000,
      durationUnits: 4,
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
