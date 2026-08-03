import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/app_database.dart';
import '../models/entities.dart';
import '../models/self_customer.dart';
import '../pricing/rental_pricing.dart';
import '../search/search_scope.dart';
import '../templates/industry_templates.dart';
import '../validation/text_rules.dart';

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

  /// Auto short code for catalog items that do not require unit identity.
  static String generateAutoShortCode({
    required String catalogName,
    required int index,
    required Set<String> usedCodes,
  }) {
    final String cleaned = catalogName.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    final String upper = cleaned.toUpperCase();
    final String prefix = upper.isEmpty
        ? 'UNT'
        : (upper.length >= 3 ? upper.substring(0, 3) : upper.padRight(3, 'X'));
    int n = index < 1 ? 1 : index;
    String code;
    do {
      code = normalizeShortCode('$prefix-$n');
      n += 1;
    } while (usedCodes.contains(code));
    return code;
  }

  Future<String> createRental({
    required Customer customer,
    required List<RentalLineInput> lines,
    String? nickname,
    int durationUnits = 1,
    DateTime? customEnd,
    BillingMode? billingModeOverride,
    String? replacedFromRentalId,
    bool openEnded = false,
  }) async {
    final String? trimmedNick = nickname?.trim();
    final String? storedNick =
        (trimmedNick != null && trimmedNick.isNotEmpty) ? trimmedNick : null;
    if (isSelfCustomer(customer) && storedNick == null) {
      throw ArgumentError(
        'Nickname is required when issuing to $kSelfCustomerName',
      );
    }
    if (storedNick != null && !meetsMinMeaningfulText(storedNick)) {
      throw ArgumentError(
        'Nickname must be at least $kMinMeaningfulTextLength characters',
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
      if (!meetsMinMeaningfulText(instanceName)) {
        throw ArgumentError(
          'Instance name must be at least $kMinMeaningfulTextLength characters',
        );
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
    final String? replacedFrom =
        (replacedFromRentalId != null && replacedFromRentalId.trim().isNotEmpty)
            ? replacedFromRentalId.trim()
            : null;

    await _db.transaction(() async {
      for (final RentalLineInput line in normalized) {
        await _assertShortCodeAvailable(line.shortCode);
      }

      final List<InventoryItemRow> itemRows = <InventoryItemRow>[];
      final Map<String, int> neededByItem = <String, int>{};
      for (final RentalLineInput line in normalized) {
        neededByItem[line.itemId] = (neededByItem[line.itemId] ?? 0) + 1;
      }
      final Map<String, InventoryItemRow> itemById = <String, InventoryItemRow>{};
      for (final String itemId in neededByItem.keys) {
        final InventoryItemRow? row = await (_db.select(_db.inventoryItems)
              ..where((t) => t.id.equals(itemId)))
            .getSingleOrNull();
        if (row == null) {
          throw ArgumentError('Inventory item not found: $itemId');
        }
        if (row.availableUnits < neededByItem[itemId]!) {
          throw ArgumentError(
            'Not enough units available for ${row.name} '
            '(need ${neededByItem[itemId]}, have ${row.availableUnits})',
          );
        }
        itemById[itemId] = row;
      }
      for (final RentalLineInput line in normalized) {
        itemRows.add(itemById[line.itemId]!);
      }

      // v1: duration UI follows primary (first) item mode; charges are per-line.
      final BillingMode mode = billingModeOverride ??
          BillingMode.parse(itemRows.first.billingMode);

      if (openEnded) {
        for (final InventoryItemRow row in itemById.values) {
          if (!row.dueDateOptional) {
            throw ArgumentError(
              'Open-ended rental requires all items to allow optional due date',
            );
          }
        }
      }

      final DateTime? dueAt = openEnded
          ? null
          : computeDueAt(
              start: now,
              mode: mode,
              durationUnits: units,
              customEnd: customEnd,
            );
      final int storedDurationUnits = openEnded ? 0 : units;

      final List<int> lineBaseAmounts = <int>[];
      int baseAmount = 0;
      int lateFeePerDay = 0;
      for (final InventoryItemRow row in itemRows) {
        final BillingMode lineMode = BillingMode.parse(row.billingMode);
        final int lineBase = openEnded
            ? 0
            : computeBaseAmount(
                mode: lineMode,
                rateAmount: row.rateAmount,
                start: now,
                due: dueAt!,
              );
        lineBaseAmounts.add(lineBase);
        baseAmount += lineBase;
        lateFeePerDay += row.lateFeePerDay;
      }

      await _db.into(_db.rentals).insert(
        RentalsCompanion.insert(
          id: rentalId,
          customerId: customer.id,
          startedAt: now,
          dueAt: Value<DateTime?>(dueAt),
          qrCode: qrCode,
          nickname: Value<String?>(storedNick),
          billingMode: Value<String>(mode.name),
          rateAmount: Value<int>(itemRows.first.rateAmount),
          lateFeePerDay: Value<int>(lateFeePerDay),
          baseAmount: Value<int>(baseAmount),
          lateAmount: const Value<int>(0),
          totalAmount: Value<int>(baseAmount),
          durationUnits: Value<int>(storedDurationUnits),
          replacedFromRentalId: Value<String?>(replacedFrom),
        ),
      );

      final Map<String, int> remainingByItem = <String, int>{
        for (final MapEntry<String, InventoryItemRow> e in itemById.entries)
          e.key: e.value.availableUnits,
      };

      for (var i = 0; i < normalized.length; i++) {
        final RentalLineInput line = normalized[i];
        final InventoryItemRow row = itemRows[i];
        final String lineId =
            'RLI-${now.millisecondsSinceEpoch}-${i.toString().padLeft(2, '0')}';
        await _db.into(_db.rentalItems).insert(
          RentalItemsCompanion.insert(
            id: lineId,
            rentalId: rentalId,
            itemId: line.itemId,
            instanceName: Value<String>(line.instanceName),
            shortCode: Value<String>(line.shortCode),
            baseAmount: Value<int>(lineBaseAmounts[i]),
          ),
        );

        final int nextAvailable =
            (remainingByItem[line.itemId]! - 1).clamp(0, row.totalUnits);
        remainingByItem[line.itemId] = nextAvailable;
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
          title: replacedFrom != null ? 'Replacement opened' : 'Rental opened',
          subtitle: replacedFrom != null
              ? 'Replacement for $replacedFrom.'
              : 'Created from phone-first quick flow.',
          at: now,
        ),
      );
    });

    return rentalId;
  }

  Future<void> _assertShortCodeAvailable(String normalizedCode) async {
    final List<RentalItemRow> links = await _db.select(_db.rentalItems).get();
    for (final RentalItemRow link in links) {
      if (link.returnedAt != null) {
        continue;
      }
      if (normalizeShortCode(link.shortCode) != normalizedCode) {
        continue;
      }
      throw DuplicateActiveShortCodeException(normalizedCode);
    }
  }

  /// Returns all open lines on the rental (full return).
  Future<RentalReturnResult?> returnRental(String rentalId) async {
    final Rental? rental = await _findRental(rentalId);
    if (rental == null || !rental.isActive) {
      return null;
    }
    final List<String> openIds =
        rental.openLines.map((RentalLine l) => l.id).toList();
    if (openIds.isEmpty) {
      return null;
    }
    return returnRentalLines(rentalId, openIds);
  }

  /// Settles selected open lines; closes parent when none remain open.
  Future<RentalReturnResult?> returnRentalLines(
    String rentalId,
    List<String> lineIds,
  ) async {
    if (lineIds.isEmpty) {
      return null;
    }
    final DateTime now = DateTime.now();
    final Set<String> wanted = lineIds.toSet();

    return _db.transaction(() async {
      final RentalRow? rental = await (_db.select(_db.rentals)
            ..where((t) => t.id.equals(rentalId)))
          .getSingleOrNull();
      if (rental == null || rental.returnedAt != null) {
        return null;
      }

      final List<RentalItemRow> links = await (_db.select(_db.rentalItems)
            ..where((t) => t.rentalId.equals(rentalId)))
          .get();
      final List<RentalItemRow> toReturn = links
          .where(
            (RentalItemRow link) =>
                wanted.contains(link.id) && link.returnedAt == null,
          )
          .toList();
      if (toReturn.isEmpty) {
        return null;
      }

      CustomerRow? customer = await (_db.select(_db.customers)
            ..where((t) => t.id.equals(rental.customerId)))
          .getSingleOrNull();
      int depositBalance = customer?.depositBalance ?? 0;

      int batchTotal = 0;
      int batchDeposit = 0;
      final List<String> returnedIds = <String>[];
      final Map<String, int> stockBump = <String, int>{};

      for (final RentalItemRow link in toReturn) {
        final InventoryItemRow? item = await (_db.select(_db.inventoryItems)
              ..where((t) => t.id.equals(link.itemId)))
            .getSingleOrNull();
        final int lineBase;
        final int lineLate;
        if (rental.dueAt == null) {
          lineBase = computeBaseAmount(
            mode: BillingMode.parse(item?.billingMode),
            rateAmount: item?.rateAmount ?? 0,
            start: rental.startedAt,
            due: now,
          );
          lineLate = 0;
        } else {
          lineBase = link.baseAmount;
          lineLate = computeLateAmount(
            due: rental.dueAt!,
            asOf: now,
            lateFeePerDay: item?.lateFeePerDay ?? 0,
          );
        }
        final int lineTotal = computeTotalAmount(
          baseAmount: lineBase,
          lateAmount: lineLate,
        );
        final int lineDeposit =
            depositBalance < lineTotal ? depositBalance : lineTotal;
        depositBalance -= lineDeposit;
        batchTotal += lineTotal;
        batchDeposit += lineDeposit;
        returnedIds.add(link.id);

        await (_db.update(_db.rentalItems)..where((t) => t.id.equals(link.id)))
            .write(
          RentalItemsCompanion(
            returnedAt: Value<DateTime?>(now),
            baseAmount: Value<int>(lineBase),
            lateAmount: Value<int>(lineLate),
            depositApplied: Value<int>(lineDeposit),
          ),
        );

        if (item != null) {
          stockBump[item.id] = (stockBump[item.id] ?? 0) + 1;
        }

        if (customer != null && lineDeposit > 0) {
          await (_db.update(_db.customers)
                ..where((t) => t.id.equals(customer.id)))
              .write(
            CustomersCompanion(depositBalance: Value<int>(depositBalance)),
          );
          await _db.into(_db.depositLedger).insert(
            DepositLedgerCompanion.insert(
              id: 'DEP-${now.millisecondsSinceEpoch}-${link.id}',
              customerId: customer.id,
              rentalId: Value<String?>(rentalId),
              type: DepositLedgerType.apply.storageValue,
              amount: -lineDeposit,
              balanceAfter: depositBalance,
              note: Value<String?>('Applied on return of ${link.shortCode}'),
              at: now,
            ),
          );
        }
      }

      for (final MapEntry<String, int> bump in stockBump.entries) {
        final InventoryItemRow? item = await (_db.select(_db.inventoryItems)
              ..where((t) => t.id.equals(bump.key)))
            .getSingleOrNull();
        if (item == null) {
          continue;
        }
        final int nextAvailable =
            (item.availableUnits + bump.value).clamp(0, item.totalUnits);
        await (_db.update(_db.inventoryItems)..where((t) => t.id.equals(item.id)))
            .write(
          InventoryItemsCompanion(
            availableUnits: Value<int>(nextAvailable),
            status: Value<String>(AssetStatus.available.name),
          ),
        );
      }

      final List<RentalItemRow> refreshed = await (_db.select(_db.rentalItems)
            ..where((t) => t.rentalId.equals(rentalId)))
          .get();
      final bool allReturned =
          refreshed.every((RentalItemRow l) => l.returnedAt != null);

      int parentBase = 0;
      int parentLate = 0;
      int parentDeposit = 0;
      int openLateFeePerDay = 0;
      for (final RentalItemRow link in refreshed) {
        parentBase += link.baseAmount;
        parentLate += link.lateAmount;
        parentDeposit += link.depositApplied;
        if (link.returnedAt == null) {
          final InventoryItemRow? item = await (_db.select(_db.inventoryItems)
                ..where((t) => t.id.equals(link.itemId)))
              .getSingleOrNull();
          openLateFeePerDay += item?.lateFeePerDay ?? 0;
        }
      }
      final int parentTotal = parentBase + parentLate;

      await (_db.update(_db.rentals)..where((t) => t.id.equals(rentalId))).write(
        RentalsCompanion(
          returnedAt: Value<DateTime?>(allReturned ? now : null),
          baseAmount: Value<int>(parentBase),
          lateAmount: Value<int>(parentLate),
          totalAmount: Value<int>(parentTotal),
          depositApplied: Value<int>(parentDeposit),
          lateFeePerDay: Value<int>(
            allReturned ? rental.lateFeePerDay : openLateFeePerDay,
          ),
        ),
      );

      final String subtitle = allReturned
          ? (batchTotal > parentBase
                ? 'All lines returned. Late fee applied.'
                : 'All lines returned by staff.')
          : 'Returned ${returnedIds.length} of ${refreshed.length} lines.';

      await _db.into(_db.rentalEvents).insert(
        RentalEventsCompanion.insert(
          rentalId: rentalId,
          title: allReturned ? 'Returned' : 'Partial return',
          subtitle: subtitle,
          at: now,
        ),
      );

      return RentalReturnResult(
        rentalId: rentalId,
        totalAmount: batchTotal,
        depositApplied: batchDeposit,
        depositBalanceAfter: depositBalance,
        returnedLineIds: returnedIds,
        rentalClosed: allReturned,
      );
    });
  }

  /// Return one open line and open a replacement rental for the same customer.
  Future<RentalReplaceResult?> replaceRentalLine({
    required String rentalId,
    required String lineId,
    required RentalLineInput newLine,
    String? nickname,
    int durationUnits = 1,
    DateTime? customEnd,
    BillingMode? billingModeOverride,
  }) async {
    final Rental? rental = await _findRental(rentalId);
    if (rental == null || !rental.isActive) {
      return null;
    }
    final bool hasLine = rental.openLines.any((RentalLine l) => l.id == lineId);
    if (!hasLine) {
      return null;
    }

    final Customer? customer = await customerById(rental.customerId);
    if (customer == null) {
      throw ArgumentError('Customer not found: ${rental.customerId}');
    }

    final RentalReturnResult? returned =
        await returnRentalLines(rentalId, <String>[lineId]);
    if (returned == null) {
      return null;
    }

    final String? nick = nickname ?? rental.nickname;
    final String newRentalId = await createRental(
      customer: customer,
      lines: <RentalLineInput>[newLine],
      nickname: isSelfCustomer(customer) ? nick : nickname,
      durationUnits: durationUnits,
      customEnd: customEnd,
      billingModeOverride: billingModeOverride,
      replacedFromRentalId: rentalId,
    );

    return RentalReplaceResult(
      returnResult: returned,
      newRentalId: newRentalId,
    );
  }

  Future<Rental?> _findRental(String rentalId) async {
    final RentalRow? row = await (_db.select(_db.rentals)
          ..where((t) => t.id.equals(rentalId)))
        .getSingleOrNull();
    if (row == null) {
      return null;
    }
    return _mapRental(row);
  }

  Future<Customer?> customerById(String customerId) async {
    final CustomerRow? row = await (_db.select(_db.customers)
          ..where((t) => t.id.equals(customerId)))
        .getSingleOrNull();
    return row == null ? null : _mapCustomer(row);
  }

  /// Credit the customer deposit wallet. [amountPaise] must be &gt; 0.
  Future<Customer> topUpDeposit(
    String customerId,
    int amountPaise, {
    String? note,
  }) async {
    if (amountPaise <= 0) {
      throw ArgumentError('Top-up amount must be greater than zero');
    }
    final DateTime now = DateTime.now();
    return _db.transaction(() async {
      final CustomerRow? row = await (_db.select(_db.customers)
            ..where((t) => t.id.equals(customerId)))
          .getSingleOrNull();
      if (row == null) {
        throw ArgumentError('Customer not found: $customerId');
      }
      final int balanceAfter = row.depositBalance + amountPaise;
      await (_db.update(_db.customers)..where((t) => t.id.equals(customerId)))
          .write(
        CustomersCompanion(depositBalance: Value<int>(balanceAfter)),
      );
      await _db.into(_db.depositLedger).insert(
        DepositLedgerCompanion.insert(
          id: 'DEP-${DateTime.now().microsecondsSinceEpoch}-topup',
          customerId: customerId,
          type: DepositLedgerType.topUp.storageValue,
          amount: amountPaise,
          balanceAfter: balanceAfter,
          note: Value<String?>(
            note == null || note.trim().isEmpty ? null : note.trim(),
          ),
          at: now,
        ),
      );
      return _mapCustomer(row).copyWith(depositBalance: balanceAfter);
    });
  }

  /// Debit the customer deposit wallet. Cannot exceed current balance.
  Future<Customer> refundDeposit(
    String customerId,
    int amountPaise, {
    String? note,
  }) async {
    if (amountPaise <= 0) {
      throw ArgumentError('Refund amount must be greater than zero');
    }
    final DateTime now = DateTime.now();
    return _db.transaction(() async {
      final CustomerRow? row = await (_db.select(_db.customers)
            ..where((t) => t.id.equals(customerId)))
          .getSingleOrNull();
      if (row == null) {
        throw ArgumentError('Customer not found: $customerId');
      }
      if (amountPaise > row.depositBalance) {
        throw ArgumentError('Refund cannot exceed deposit balance');
      }
      final int balanceAfter = row.depositBalance - amountPaise;
      await (_db.update(_db.customers)..where((t) => t.id.equals(customerId)))
          .write(
        CustomersCompanion(depositBalance: Value<int>(balanceAfter)),
      );
      await _db.into(_db.depositLedger).insert(
        DepositLedgerCompanion.insert(
          id: 'DEP-${DateTime.now().microsecondsSinceEpoch}-refund',
          customerId: customerId,
          type: DepositLedgerType.refund.storageValue,
          amount: -amountPaise,
          balanceAfter: balanceAfter,
          note: Value<String?>(
            note == null || note.trim().isEmpty ? null : note.trim(),
          ),
          at: now,
        ),
      );
      return _mapCustomer(row).copyWith(depositBalance: balanceAfter);
    });
  }

  Stream<List<DepositLedgerEntry>> watchDepositLedger(String customerId) {
    final query = _db.select(_db.depositLedger)
      ..where((t) => t.customerId.equals(customerId))
      ..orderBy([(t) => OrderingTerm.desc(t.at)]);
    return query.watch().map(
      (rows) => rows.map(_mapDepositLedger).toList(growable: false),
    );
  }

  Future<List<DepositLedgerEntry>> listDepositLedger(
    String customerId, {
    int limit = 20,
  }) async {
    final query = _db.select(_db.depositLedger)
      ..where((t) => t.customerId.equals(customerId))
      ..orderBy([(t) => OrderingTerm.desc(t.at)])
      ..limit(limit);
    final List<DepositLedgerRow> rows = await query.get();
    return rows.map(_mapDepositLedger).toList(growable: false);
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
    bool dueDateOptional = false,
    bool requiresUnitIdentity = true,
  }) async {
    final String trimmedName = name.trim();
    final String trimmedCategory = category.trim();
    final String? trimmedNotes = notes?.trim();
    if (!meetsMinMeaningfulText(trimmedName) ||
        !meetsMinMeaningfulText(trimmedCategory)) {
      throw ArgumentError(
        'Name and category must be at least $kMinMeaningfulTextLength characters',
      );
    }
    if (!meetsMinMeaningfulText(trimmedNotes, allowEmpty: true)) {
      throw ArgumentError(
        'Notes must be at least $kMinMeaningfulTextLength characters when set',
      );
    }
    final DateTime now = DateTime.now();
    await _db.into(_db.inventoryItems).insert(
      InventoryItemsCompanion.insert(
        id: 'INV-${now.millisecondsSinceEpoch}',
        name: trimmedName,
        category: trimmedCategory,
        availableUnits: units,
        totalUnits: units,
        status: AssetStatus.available.name,
        qrCode: 'inventory:${now.millisecondsSinceEpoch}',
        notes: Value<String?>(
          (trimmedNotes == null || trimmedNotes.isEmpty) ? null : trimmedNotes,
        ),
        billingMode: Value<String>(billingMode.name),
        rateAmount: Value<int>(rateAmount < 0 ? 0 : rateAmount),
        lateFeePerDay: Value<int>(lateFeePerDay < 0 ? 0 : lateFeePerDay),
        currencyCode: Value<String>(
          currencyCode.trim().isEmpty ? 'INR' : currencyCode.trim().toUpperCase(),
        ),
        dueDateOptional: Value<bool>(dueDateOptional),
        requiresUnitIdentity: Value<bool>(requiresUnitIdentity),
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
    bool? dueDateOptional,
    bool? requiresUnitIdentity,
  }) async {
    final String trimmedName = name.trim();
    final String trimmedCategory = category.trim();
    final String? trimmedNotes = notes?.trim();
    if (!meetsMinMeaningfulText(trimmedName) ||
        !meetsMinMeaningfulText(trimmedCategory)) {
      throw ArgumentError(
        'Name and category must be at least $kMinMeaningfulTextLength characters',
      );
    }
    if (!meetsMinMeaningfulText(trimmedNotes, allowEmpty: true)) {
      throw ArgumentError(
        'Notes must be at least $kMinMeaningfulTextLength characters when set',
      );
    }
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
        name: Value<String>(trimmedName),
        category: Value<String>(trimmedCategory),
        totalUnits: Value<int>(nextTotal),
        availableUnits: Value<int>(nextAvailable),
        status: Value<String>(
          nextAvailable > 0 ? AssetStatus.available.name : AssetStatus.rented.name,
        ),
        notes: Value<String?>(
          (trimmedNotes == null || trimmedNotes.isEmpty) ? null : trimmedNotes,
        ),
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
        dueDateOptional: dueDateOptional == null
            ? const Value.absent()
            : Value<bool>(dueDateOptional),
        requiresUnitIdentity: requiresUnitIdentity == null
            ? const Value.absent()
            : Value<bool>(requiresUnitIdentity),
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
    final String? trimmedName = fallbackName?.trim();
    if (trimmedName != null &&
        trimmedName.isNotEmpty &&
        !meetsMinMeaningfulText(trimmedName)) {
      throw ArgumentError(
        'Customer name must be at least $kMinMeaningfulTextLength characters',
      );
    }
    final DateTime now = DateTime.now();
    final int count = (await _db.select(_db.customers).get()).length;
    final Customer customer = Customer(
      id: 'CUS-${now.millisecondsSinceEpoch}',
      name: trimmedName != null && trimmedName.isNotEmpty
          ? trimmedName
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

  Future<SearchResults> search(
    String query, {
    SearchScope scope = SearchScope.global,
  }) async {
    final String q = query.trim().toLowerCase();
    if (q.length < kMinMeaningfulTextLength) {
      return const SearchResults(
        customers: <Customer>[],
        currentRentals: <Rental>[],
        previousRentals: <Rental>[],
        inventory: <InventoryItem>[],
      );
    }

    final List<Customer> allCustomers = await listCustomers();
    final List<Rental> rentals = await listRentals();
    final List<InventoryItem> allInventory = await listInventory();

    List<Customer> customers = const <Customer>[];
    List<Rental> currentRentals = const <Rental>[];
    List<Rental> previousRentals = const <Rental>[];
    List<InventoryItem> inventory = const <InventoryItem>[];

    if (scope == SearchScope.global || scope == SearchScope.customers) {
      final Set<String> nicknameMatchedCustomerIds = <String>{};
      if (scope == SearchScope.customers || scope == SearchScope.global) {
        for (final Rental rental in rentals) {
          if (rental.nickname?.toLowerCase().contains(q) ?? false) {
            nicknameMatchedCustomerIds.add(rental.customerId);
          }
        }
      }

      customers = allCustomers.where((customer) {
        final bool directMatch = customer.name.toLowerCase().contains(q) ||
            customer.phone.toLowerCase().contains(q) ||
            customer.id.toLowerCase().contains(q);
        if (directMatch) {
          return true;
        }
        if (scope == SearchScope.customers) {
          return nicknameMatchedCustomerIds.contains(customer.id);
        }
        return false;
      }).toList();
    }

    if (scope == SearchScope.global) {
      bool rentalMatches(Rental rental) {
        if (rental.id.toLowerCase().contains(q) ||
            rental.qrCode.toLowerCase().contains(q) ||
            (rental.nickname?.toLowerCase().contains(q) ?? false)) {
          return true;
        }
        for (final RentalLine line in rental.lines) {
          if (line.instanceName.toLowerCase().contains(q) ||
              line.catalogName.toLowerCase().contains(q)) {
            return true;
          }
          // Short codes: open lines for active rentals; any line when closed.
          if (line.shortCode.toLowerCase().contains(q)) {
            if (!rental.isActive || line.isOpen) {
              return true;
            }
          }
        }
        return false;
      }

      currentRentals =
          rentals.where((rental) => rental.isActive && rentalMatches(rental)).toList();
      previousRentals =
          rentals.where((rental) => !rental.isActive && rentalMatches(rental)).toList();
    }

    if (scope == SearchScope.global || scope == SearchScope.inventory) {
      inventory = allInventory.where((item) {
        return item.name.toLowerCase().contains(q) ||
            item.category.toLowerCase().contains(q) ||
            item.id.toLowerCase().contains(q) ||
            (item.notes?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

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
            dueAt: Value<DateTime?>(rental.dueAt),
            returnedAt: Value<DateTime?>(rental.returnedAt),
            qrCode: rental.qrCode,
            nickname: Value<String?>(rental.nickname),
            billingMode: Value<String>(rental.billingMode.name),
            rateAmount: Value<int>(rental.rateAmount),
            lateFeePerDay: Value<int>(rental.lateFeePerDay),
            baseAmount: Value<int>(rental.baseAmount),
            lateAmount: Value<int>(rental.lateAmount),
            totalAmount: Value<int>(rental.totalAmount),
            depositApplied: Value<int>(rental.depositApplied),
            durationUnits: Value<int>(rental.durationUnits),
            replacedFromRentalId: Value<String?>(rental.replacedFromRentalId),
          ),
        );
        for (var i = 0; i < rental.lines.length; i++) {
          final RentalLine line = rental.lines[i];
          final String instanceName = line.instanceName.trim().isEmpty
              ? line.catalogName.trim()
              : line.instanceName.trim();
          final String shortCode = LocalRepository.normalizeShortCode(
            line.shortCode.trim().isEmpty ? 'LEGACY' : line.shortCode,
          );
          final String lineId = line.id.trim().isEmpty
              ? 'RLI-${rental.id}-$i'
              : line.id;
          final DateTime? lineReturned =
              line.returnedAt ?? rental.returnedAt;
          await _db.into(_db.rentalItems).insertOnConflictUpdate(
            RentalItemsCompanion.insert(
              id: lineId,
              rentalId: rental.id,
              itemId: line.itemId,
              instanceName: Value<String>(instanceName),
              shortCode: Value<String>(shortCode),
              returnedAt: Value<DateTime?>(lineReturned),
              baseAmount: Value<int>(line.baseAmount),
              lateAmount: Value<int>(line.lateAmount),
              depositApplied: Value<int>(line.depositApplied),
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
      depositBalance: Value<int>(customer.depositBalance),
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
      dueDateOptional: Value<bool>(item.dueDateOptional),
      requiresUnitIdentity: Value<bool>(item.requiresUnitIdentity),
    );
  }

  Customer _mapCustomer(CustomerRow row) {
    return Customer(
      id: row.id,
      name: row.name,
      phone: row.phone,
      isTrusted: row.isTrusted,
      qrCode: row.qrCode,
      depositBalance: row.depositBalance,
    );
  }

  DepositLedgerEntry _mapDepositLedger(DepositLedgerRow row) {
    return DepositLedgerEntry(
      id: row.id,
      customerId: row.customerId,
      rentalId: row.rentalId,
      type: DepositLedgerType.parse(row.type),
      amount: row.amount,
      balanceAfter: row.balanceAfter,
      note: row.note,
      at: row.at,
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
      dueDateOptional: row.dueDateOptional,
      requiresUnitIdentity: row.requiresUnitIdentity,
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
          id: link.id,
          itemId: link.itemId,
          catalogName: item?.name ?? link.itemId,
          instanceName: link.instanceName,
          shortCode: link.shortCode,
          returnedAt: link.returnedAt,
          baseAmount: link.baseAmount,
          lateAmount: link.lateAmount,
          depositApplied: link.depositApplied,
          lateFeePerDay: item?.lateFeePerDay ?? 0,
          billingMode: BillingMode.parse(item?.billingMode),
          rateAmount: item?.rateAmount ?? 0,
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
      depositApplied: row.depositApplied,
      durationUnits: row.durationUnits,
      replacedFromRentalId: row.replacedFromRentalId,
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
          id: 'RLI-REN-3001-INV-2002',
          itemId: 'INV-2002',
          catalogName: 'Drill Kit',
          instanceName: 'Workshop set A',
          shortCode: 'DRL-001',
          baseAmount: 50000,
          lateFeePerDay: 5000,
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
      lines: <RentalLine>[
        RentalLine(
          id: 'RLI-REN-3002-INV-2001',
          itemId: 'INV-2001',
          catalogName: 'DSLR',
          instanceName: 'Body unit 1',
          shortCode: 'CAM-001',
          baseAmount: 600000,
          lateFeePerDay: 20000,
          returnedAt: clock.subtract(const Duration(days: 1)),
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
