import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/app_database.dart';
import '../home/home_modules.dart';
import '../inventory/unit_code_pool.dart';
import '../l10n/timeline_l10n.dart';
import '../loans/loan_balance.dart';
import '../loans/loan_models.dart';
import '../models/entities.dart';
import '../models/unknown_customer.dart';
import '../pricing/rental_pricing.dart';
import '../reports/report_widgets.dart';
import '../search/search_scope.dart';
import '../templates/field_defs.dart';
import '../templates/industry_templates.dart';
import '../templates/workflows.dart';
import '../validation/text_rules.dart';
export '../inventory/unit_code_pool.dart'
    show generateUnitPool, normalizeUnitCodePrefix, UnitOccupancyRow;
export '../loans/loan_models.dart';
export '../loans/loan_balance.dart'
    show
        computeLoanScenario,
        periodInterestPaise,
        proRataPeriodInterestPaise,
        accrualFraction,
        signedInterestPaise,
        nextInterestPeriodEnd,
        LoanScenario,
        LoanTimelineEvent,
        LoanTimelineKind;

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

/// Process-local monotonic stamp so IDs stay unique within the same millisecond.
int _idSeq = 0;

String _nextStamp() {
  _idSeq += 1;
  return '${DateTime.now().millisecondsSinceEpoch}-$_idSeq';
}

/// Human-readable unique id, e.g. `INV-1710000000000-1`.
String nextId(String prefix) => '$prefix-${_nextStamp()}';

/// Drift-backed facade preserving the UI call surface from the prefs era.
class LocalRepository {
  LocalRepository(this._db, this._preferences);

  static const String snapshotKey = 'asset_os_snapshot_v1';
  static const String _migrationMetaKey = 'prefs_snapshot_migrated_v1';
  static const String industryTemplateMetaKey = 'industry_template_id';

  final AppDatabase _db;
  final SharedPreferences _preferences;

  AppDatabase get database => _db;

  /// Open DB, migrate SharedPreferences snapshot once, or seed demo data.
  ///
  /// Production boots use [seedDemo] false: empty DB gets only the Unknown
  /// sentinel; industry sample inventory comes from onboarding.
  /// Pass [seedDemo] true only from the test harness for widget smokes that
  /// assert legacy Priya/DSLR demo names.
  Future<void> initialize({bool seedDemo = false}) async {
    final bool alreadyMigrated = await _isMigrationComplete();
    final List<CustomerRow> existingCustomers = await _db.select(_db.customers).get();

    if (existingCustomers.isNotEmpty) {
      if (!alreadyMigrated) {
        await _markMigrationComplete();
      }
      await ensureUnknownCustomer();
      await ensureEnabledResourceTypes();
      return;
    }

    final String? source = _preferences.getString(snapshotKey);
    if (source != null && source.isNotEmpty) {
      final AppDataSnapshot snapshot = AppDataSnapshot.decode(source);
      await _insertSnapshot(snapshot);
      await _markMigrationComplete();
      await _preferences.remove(snapshotKey);
      await ensureUnknownCustomer();
      await ensureEnabledResourceTypes();
      return;
    }

    if (seedDemo) {
      await _insertSnapshot(buildDemoSnapshot());
      // Demo inventory is rental-only; seed fallback types when prefs are
      // unset so Sell/Job stay available. Explicit prefs (tests / owner) win.
      final String? raw =
          _preferences.getString(kEnabledResourceTypesPrefsKey);
      if (raw == null || raw.trim().isEmpty) {
        await setEnabledResourceTypes(kFallbackEnabledResourceTypes);
      }
    }
    await _markMigrationComplete();
    await ensureUnknownCustomer();
    await ensureEnabledResourceTypes();
  }

  /// Chosen industry template id from first-load onboarding, if any.
  Future<String?> selectedIndustryTemplateId() async {
    final AppMetaRow? row = await (_db.select(_db.appMeta)
          ..where((t) => t.key.equals(industryTemplateMetaKey)))
        .getSingleOrNull();
    final String? value = row?.value.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  /// True when no template has been chosen and inventory is still empty.
  /// Existing DBs with inventory are not forced through onboarding.
  Future<bool> needsIndustryOnboarding() async {
    if (await selectedIndustryTemplateId() != null) {
      return false;
    }
    final List<InventoryItem> inventory = await listInventory();
    return inventory.isEmpty;
  }

  /// Import the full template pack, apply its Home modules, and persist the choice.
  ///
  /// [locale] selects which catalog language is written into inventory name/category.
  Future<void> completeIndustryOnboarding(
    IndustryTemplate template, {
    Locale locale = const Locale('en'),
  }) async {
    await importTemplateInventory(template.items, locale: locale);
    await activateIndustryTemplate(template);
  }

  /// Switch the active industry pack mid-life: persist id and replace Home /
  /// types / workflow / fields / report widgets. Does **not** wipe loans,
  /// orders, or existing inventory (optional starter import is a separate step).
  Future<void> activateIndustryTemplate(IndustryTemplate template) async {
    await _setHomeModules(template.defaultHomeModules);
    await setEnabledResourceTypes(template.enabledResourceTypes);
    await setActiveWorkflowId(template.workflowId);
    await setExtraFieldIds(template.extraFieldIds);
    await setReportWidgets(template.defaultReportWidgets);
    await _db.into(_db.appMeta).insertOnConflictUpdate(
      AppMetaCompanion.insert(
        key: industryTemplateMetaKey,
        value: template.id,
      ),
    );
  }

  Future<void> _setHomeModules(List<HomeModuleId> modules) async {
    await _preferences.setString(
      kHomeModulesPrefsKey,
      encodeHomeModules(modules),
    );
    await _preferences.setBool(kHomeModulesCustomizedKey, false);
  }

  /// Persisted enabled resource types (comma-separated names).
  List<ResourceType> enabledResourceTypes() {
    return resolveEnabledResourceTypes(
      prefsRaw: _preferences.getString(kEnabledResourceTypesPrefsKey),
    );
  }

  /// Replace enabled types (onboarding / full template apply).
  Future<void> setEnabledResourceTypes(List<ResourceType> types) async {
    await _preferences.setString(
      kEnabledResourceTypesPrefsKey,
      encodeEnabledResourceTypes(types),
    );
  }

  /// Active status pipeline for this business (template preset id).
  WorkflowDefinition activeWorkflow() {
    return resolveWorkflow(
      prefsId: _preferences.getString(kActiveWorkflowIdPrefsKey),
    );
  }

  Future<void> setActiveWorkflowId(String workflowId) async {
    final WorkflowDefinition workflow = resolveWorkflow(prefsId: workflowId);
    await _preferences.setString(kActiveWorkflowIdPrefsKey, workflow.id);
  }

  /// Extra field ids from the active template pack.
  List<String> extraFieldIds() {
    return parseExtraFieldIds(_preferences.getString(kExtraFieldIdsPrefsKey));
  }

  Future<void> setExtraFieldIds(List<String> ids) async {
    await _preferences.setString(
      kExtraFieldIdsPrefsKey,
      encodeExtraFieldIds(ids),
    );
  }

  /// Report widget composition for Share Reports (summary pack).
  List<ReportWidgetId> reportWidgets() {
    return resolveReportWidgets(
      prefsRaw: _preferences.getString(kReportWidgetsPrefsKey),
    );
  }

  Future<void> setReportWidgets(List<ReportWidgetId> widgets) async {
    await _preferences.setString(
      kReportWidgetsPrefsKey,
      encodeReportWidgets(widgets),
    );
  }

  /// Union [extra] into the enabled set without shrinking existing types.
  Future<List<ResourceType>> unionEnabledResourceTypes(
    Iterable<ResourceType> extra,
  ) async {
    final String? raw =
        _preferences.getString(kEnabledResourceTypesPrefsKey);
    final List<ResourceType> current;
    if (raw != null && raw.trim().isNotEmpty) {
      current = parseEnabledResourceTypes(raw);
    } else {
      final List<InventoryItemRow> rows =
          await _db.select(_db.inventoryItems).get();
      current = resolveEnabledResourceTypes(
        prefsRaw: null,
        inventoryKinds: rows.map(
          (InventoryItemRow row) => ResourceType.parse(row.defaultItemKind),
        ),
      );
    }
    final List<ResourceType> merged = resourceTypesFromItems(
      <ResourceType>[...current, ...extra],
    );
    await setEnabledResourceTypes(merged);
    return merged;
  }

  /// Seed prefs from inventory when missing (legacy DBs).
  ///
  /// Uses a one-shot Drift [get] (not [listInventory]/[watchInventory].first)
  /// so it is safe during [initialize] before the widget binding pumps frames.
  Future<List<ResourceType>> ensureEnabledResourceTypes() async {
    final String? raw =
        _preferences.getString(kEnabledResourceTypesPrefsKey);
    if (raw != null && raw.trim().isNotEmpty) {
      return parseEnabledResourceTypes(raw);
    }
    final List<InventoryItemRow> rows =
        await _db.select(_db.inventoryItems).get();
    final List<ResourceType> resolved = resolveEnabledResourceTypes(
      prefsRaw: null,
      inventoryKinds: rows.map(
        (InventoryItemRow row) => ResourceType.parse(row.defaultItemKind),
      ),
    );
    await setEnabledResourceTypes(resolved);
    return resolved;
  }

  /// Inserts the fixed Unknown sentinel if missing; migrates legacy CUS-SELF.
  Future<Customer> ensureUnknownCustomer() async {
    await _migrateLegacySelfCustomer();

    final CustomerRow? byId = await (_db.select(_db.customers)
          ..where((t) => t.id.equals(kUnknownCustomerId)))
        .getSingleOrNull();
    if (byId != null) {
      return _mapCustomer(byId);
    }

    final CustomerRow? byPhone = await (_db.select(_db.customers)
          ..where((t) => t.phone.equals(kUnknownCustomerPhone)))
        .getSingleOrNull();
    if (byPhone != null) {
      return _mapCustomer(byPhone);
    }

    final Customer unknown = buildUnknownCustomer();
    await _db.into(_db.customers).insert(_customerCompanion(unknown));
    return unknown;
  }

  /// Remaps rentals/ledger from legacy SELF Known onto [kUnknownCustomerId].
  Future<void> _migrateLegacySelfCustomer() async {
    final CustomerRow? legacy = await (_db.select(_db.customers)
          ..where((t) => t.id.equals(kLegacySelfCustomerId)))
        .getSingleOrNull();
    if (legacy == null) {
      return;
    }

    await _db.transaction(() async {
      CustomerRow? unknown = await (_db.select(_db.customers)
            ..where((t) => t.id.equals(kUnknownCustomerId)))
          .getSingleOrNull();
      if (unknown == null) {
        final Customer seed = buildUnknownCustomer();
        await _db.into(_db.customers).insert(
              _customerCompanion(seed).copyWith(
                depositBalance: Value<int>(legacy.depositBalance),
              ),
            );
      } else {
        final int merged = unknown.depositBalance + legacy.depositBalance;
        await (_db.update(_db.customers)
              ..where((t) => t.id.equals(kUnknownCustomerId)))
            .write(CustomersCompanion(depositBalance: Value<int>(merged)));
      }

      await (_db.update(_db.rentals)
            ..where((t) => t.customerId.equals(kLegacySelfCustomerId)))
          .write(
            const RentalsCompanion(customerId: Value<String>(kUnknownCustomerId)),
          );
      await (_db.update(_db.depositLedger)
            ..where((t) => t.customerId.equals(kLegacySelfCustomerId)))
          .write(
            const DepositLedgerCompanion(
              customerId: Value<String>(kUnknownCustomerId),
            ),
          );
      await (_db.delete(_db.customers)
            ..where((t) => t.id.equals(kLegacySelfCustomerId)))
          .go();
    });
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

  /// Available codes from an item's prefix pool (open rent lines excluded).
  Future<List<String>> listAvailableUnitCodes(String itemId) async {
    final InventoryItemRow? row = await (_db.select(_db.inventoryItems)
          ..where((t) => t.id.equals(itemId)))
        .getSingleOrNull();
    if (row == null) {
      return const <String>[];
    }
    final String prefix = normalizeUnitCodePrefix(row.unitCodePrefix);
    if (prefix.isEmpty) {
      return const <String>[];
    }
    final List<String> pool = generateUnitPool(
      prefix: prefix,
      total: row.totalUnits,
    );
    if (pool.isEmpty) {
      return const <String>[];
    }
    final Set<String> taken = await _activeShortCodes();
    return pool
        .where((String code) => !taken.contains(normalizeShortCode(code)))
        .toList(growable: false);
  }

  /// Occupancy table for an item with a unit-code prefix pool.
  Future<List<UnitOccupancyRow>> listUnitOccupancy(String itemId) async {
    final InventoryItemRow? row = await (_db.select(_db.inventoryItems)
          ..where((t) => t.id.equals(itemId)))
        .getSingleOrNull();
    if (row == null) {
      return const <UnitOccupancyRow>[];
    }
    final String prefix = normalizeUnitCodePrefix(row.unitCodePrefix);
    if (prefix.isEmpty) {
      return const <UnitOccupancyRow>[];
    }
    final List<String> pool = generateUnitPool(
      prefix: prefix,
      total: row.totalUnits,
    );
    final List<RentalItemRow> links = await _db.select(_db.rentalItems).get();
    final Map<String, RentalItemRow> openByCode = <String, RentalItemRow>{};
    for (final RentalItemRow link in links) {
      if (link.returnedAt != null || link.itemId != itemId) {
        continue;
      }
      if (LineFulfillment.parse(link.fulfillment) != LineFulfillment.rent) {
        continue;
      }
      openByCode[normalizeShortCode(link.shortCode)] = link;
    }
    final Map<String, CustomerRow> customersById = <String, CustomerRow>{};
    final List<UnitOccupancyRow> rows = <UnitOccupancyRow>[];
    for (final String code in pool) {
      final RentalItemRow? link = openByCode[code];
      if (link == null) {
        rows.add(UnitOccupancyRow(code: code, occupied: false));
        continue;
      }
      final RentalRow? rental = await (_db.select(_db.rentals)
            ..where((t) => t.id.equals(link.rentalId)))
          .getSingleOrNull();
      CustomerRow? customer;
      if (rental != null) {
        customer = customersById[rental.customerId];
        if (customer == null) {
          customer = await (_db.select(_db.customers)
                ..where((t) => t.id.equals(rental.customerId)))
              .getSingleOrNull();
          if (customer != null) {
            customersById[rental.customerId] = customer;
          }
        }
      }
      rows.add(
        UnitOccupancyRow(
          code: code,
          occupied: true,
          customerName: customer?.name,
          customerId: customer?.id,
          rentalId: link.rentalId,
          instanceName: link.instanceName,
        ),
      );
    }
    return rows;
  }

  Future<Set<String>> _activeShortCodes() async {
    final List<RentalItemRow> links = await _db.select(_db.rentalItems).get();
    final Set<String> taken = <String>{};
    for (final RentalItemRow link in links) {
      if (link.returnedAt != null) {
        continue;
      }
      taken.add(normalizeShortCode(link.shortCode));
    }
    return taken;
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
    int depositTopUpPaise = 0,
  }) async {
    final String? trimmedNick = nickname?.trim();
    final String? storedNick =
        (trimmedNick != null && trimmedNick.isNotEmpty) ? trimmedNick : null;
    if (storedNick != null && !meetsMinMeaningfulText(storedNick)) {
      throw ArgumentError(
        'Nickname must be at least $kMinMeaningfulTextLength characters',
      );
    }
    if (lines.isEmpty) {
      throw ArgumentError('At least one rental line is required');
    }
    if (depositTopUpPaise < 0) {
      throw ArgumentError('Deposit top-up cannot be negative');
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
      if (line.usesManualAmount) {
        final int saleAmount = line.manualSaleAmountPaise ?? 0;
        if (saleAmount <= 0) {
          throw ArgumentError(
            line.isJob
                ? 'Job amount must be greater than zero'
                : 'Sale amount must be greater than zero',
          );
        }
      }
      normalized.add(
        RentalLineInput(
          itemId: line.itemId,
          instanceName: instanceName,
          shortCode: shortCode,
          durationUnits: line.durationUnits,
          customEnd: line.customEnd,
          openEnded: line.openEnded,
          fulfillment: line.fulfillment,
          manualSaleAmountPaise: line.manualSaleAmountPaise,
          rateAmountOverride: line.rateAmountOverride,
        ),
      );
    }

    final DateTime now = DateTime.now();
    final String rentalStamp = _nextStamp();
    final String rentalId = 'REN-$rentalStamp';
    final String qrCode = 'rental:$rentalStamp';
    final int parentUnits = durationUnits < 1 ? 1 : durationUnits;
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
        itemById[itemId] = row;
      }
      for (final RentalLineInput line in normalized) {
        itemRows.add(itemById[line.itemId]!);
      }

      final List<LineFulfillment> lineFulfillments = <LineFulfillment>[];
      final List<bool> lineOpenEndedFlags = <bool>[];
      final List<DateTime?> lineDues = <DateTime?>[];
      final List<int> lineBaseAmounts = <int>[];
      final List<int> lineDurationUnits = <int>[];
      final List<BillingMode> lineBillingModes = <BillingMode>[];
      final List<int> lineRateAmounts = <int>[];
      final List<int> lineLateFees = <int>[];
      int baseAmount = 0;
      int lateFeePerDay = 0;

      for (var i = 0; i < normalized.length; i++) {
        final RentalLineInput line = normalized[i];
        final InventoryItemRow row = itemRows[i];
        final LineFulfillment fulfillment = line.fulfillment;
        lineFulfillments.add(fulfillment);

        final BillingMode lineMode = BillingMode.parse(row.billingMode);
        final int catalogRate = row.rateAmount < 0 ? 0 : row.rateAmount;
        final int catalogLate = row.lateFeePerDay < 0 ? 0 : row.lateFeePerDay;
        int effectiveRate = catalogRate;
        if (line.rateAmountOverride != null) {
          if (!row.allowsDynamicPricing) {
            throw ArgumentError(
              'Rate override requires item to allow dynamic pricing: ${row.id}',
            );
          }
          effectiveRate =
              line.rateAmountOverride! < 0 ? 0 : line.rateAmountOverride!;
        }
        lineBillingModes.add(lineMode);
        lineRateAmounts.add(effectiveRate);
        lineLateFees.add(catalogLate);

        if (line.usesManualAmount) {
          final int saleAmount = line.manualSaleAmountPaise!;
          lineOpenEndedFlags.add(false);
          lineDues.add(null);
          lineBaseAmounts.add(saleAmount);
          lineDurationUnits.add(0);
          baseAmount += saleAmount;
          continue;
        }

        final bool lineOpenEnded = line.openEnded ?? openEnded;
        lineOpenEndedFlags.add(lineOpenEnded);

        if (lineOpenEnded) {
          if (!row.dueDateOptional) {
            throw ArgumentError(
              'Open-ended rental requires item to allow optional due date',
            );
          }
          lineDues.add(null);
          lineBaseAmounts.add(0);
          lineDurationUnits.add(0);
          lateFeePerDay += catalogLate;
          continue;
        }

        final int lineUnitsRaw = line.durationUnits ?? parentUnits;
        final int lineUnits = lineUnitsRaw < 1 ? 1 : lineUnitsRaw;
        final DateTime? lineCustomEnd = line.customEnd ?? customEnd;
        final DateTime lineDue = computeDueAt(
          start: now,
          mode: lineMode,
          durationUnits: lineUnits,
          customEnd: lineMode == BillingMode.custom ? lineCustomEnd : null,
        );
        final int lineBase = computeBaseAmount(
          mode: lineMode,
          rateAmount: effectiveRate,
          start: now,
          due: lineDue,
        );
        lineDues.add(lineDue);
        lineBaseAmounts.add(lineBase);
        lineDurationUnits.add(lineUnits);
        baseAmount += lineBase;
        lateFeePerDay += catalogLate;
      }

      DateTime? dueAt;
      for (var i = 0; i < lineDues.length; i++) {
        if (lineFulfillments[i] != LineFulfillment.rent) {
          continue;
        }
        final DateTime? lineDue = lineDues[i];
        if (lineDue == null) {
          continue;
        }
        if (dueAt == null || lineDue.isBefore(dueAt)) {
          dueAt = lineDue;
        }
      }

      final bool allSold =
          lineFulfillments.every((LineFulfillment f) => f == LineFulfillment.sell);
      final bool hasSell =
          lineFulfillments.any((LineFulfillment f) => f == LineFulfillment.sell);
      final bool hasRent =
          lineFulfillments.any((LineFulfillment f) => f == LineFulfillment.rent);
      final bool hasJob =
          lineFulfillments.any((LineFulfillment f) => f == LineFulfillment.job);
      final OrderStatus orderStatus =
          allSold ? OrderStatus.completed : OrderStatus.open;
      final WorkflowDefinition workflow = activeWorkflow();
      final String workflowStatusId = allSold
          ? terminalWorkflowStatusForOrder(
              workflow: workflow,
              hasRent: hasRent,
              hasJob: hasJob,
              hasSell: hasSell,
            )
          : workflow.initial.id;
      int snapshotIndex = 0;
      for (var i = 0; i < lineOpenEndedFlags.length; i++) {
        if (lineFulfillments[i] != LineFulfillment.rent) {
          continue;
        }
        if (!lineOpenEndedFlags[i]) {
          snapshotIndex = i;
          break;
        }
        snapshotIndex = i;
      }
      if (allSold) {
        snapshotIndex = 0;
      }
      final BillingMode mode = billingModeOverride ??
          lineBillingModes[snapshotIndex];
      final Iterable<MapEntry<int, bool>> rentOpenFlags = lineOpenEndedFlags
          .asMap()
          .entries
          .where(
            (MapEntry<int, bool> e) =>
                lineFulfillments[e.key] == LineFulfillment.rent,
          );
      final int storedDurationUnits = allSold ||
              (rentOpenFlags.isNotEmpty &&
                  rentOpenFlags.every((MapEntry<int, bool> e) => e.value))
          ? 0
          : lineDurationUnits[snapshotIndex];

      await _db.into(_db.rentals).insert(
        RentalsCompanion.insert(
          id: rentalId,
          customerId: customer.id,
          startedAt: now,
          dueAt: Value<DateTime?>(dueAt),
          returnedAt: Value<DateTime?>(allSold ? now : null),
          qrCode: qrCode,
          nickname: Value<String?>(storedNick),
          billingMode: Value<String>(mode.name),
          rateAmount: Value<int>(lineRateAmounts[snapshotIndex]),
          lateFeePerDay: Value<int>(lateFeePerDay),
          baseAmount: Value<int>(baseAmount),
          lateAmount: const Value<int>(0),
          totalAmount: Value<int>(baseAmount),
          depositAmount: Value<int>(depositTopUpPaise),
          orderStatus: Value<String>(orderStatus.storageValue),
          workflowStatus: Value<String?>(workflowStatusId),
          durationUnits: Value<int>(storedDurationUnits),
          replacedFromRentalId: Value<String?>(replacedFrom),
        ),
      );

      final Map<String, int> remainingAvailable = <String, int>{
        for (final MapEntry<String, InventoryItemRow> e in itemById.entries)
          e.key: e.value.availableUnits,
      };
      final Map<String, int> remainingTotal = <String, int>{
        for (final MapEntry<String, InventoryItemRow> e in itemById.entries)
          e.key: e.value.totalUnits,
      };

      for (var i = 0; i < normalized.length; i++) {
        final RentalLineInput line = normalized[i];
        final String lineId = '${nextId('RLI')}-${i.toString().padLeft(2, '0')}';
        final LineFulfillment fulfillment = lineFulfillments[i];
        final bool closesAtCreate = fulfillment == LineFulfillment.sell;
        final bool permanentStock =
            fulfillment == LineFulfillment.sell ||
            fulfillment == LineFulfillment.job;
        await _db.into(_db.rentalItems).insert(
          RentalItemsCompanion.insert(
            id: lineId,
            rentalId: rentalId,
            itemId: line.itemId,
            instanceName: Value<String>(line.instanceName),
            shortCode: Value<String>(line.shortCode),
            returnedAt: Value<DateTime?>(closesAtCreate ? now : null),
            baseAmount: Value<int>(lineBaseAmounts[i]),
            lateAmount: const Value<int>(0),
            billingMode: Value<String>(lineBillingModes[i].name),
            rateAmount: Value<int>(lineRateAmounts[i]),
            lateFeePerDay: Value<int>(lineLateFees[i]),
            fulfillment: Value<String>(fulfillment.storageValue),
          ),
        );

        final int nextAvailable =
            (remainingAvailable[line.itemId]! - 1).clamp(0, 1 << 30);
        remainingAvailable[line.itemId] = nextAvailable;
        if (permanentStock) {
          final int nextTotal =
              (remainingTotal[line.itemId]! - 1).clamp(0, 1 << 30);
          remainingTotal[line.itemId] = nextTotal;
          final String statusName;
          if (nextTotal == 0) {
            statusName = AssetStatus.archived.name;
          } else if (nextAvailable == 0) {
            statusName = AssetStatus.rented.name;
          } else {
            statusName = AssetStatus.available.name;
          }
          await (_db.update(_db.inventoryItems)
                ..where((t) => t.id.equals(line.itemId)))
              .write(
            InventoryItemsCompanion(
              availableUnits: Value<int>(nextAvailable),
              totalUnits: Value<int>(nextTotal),
              status: Value<String>(statusName),
            ),
          );
        } else {
          await (_db.update(_db.inventoryItems)
                ..where((t) => t.id.equals(line.itemId)))
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
      }

      final String eventTitle;
      final String eventSubtitle;
      if (replacedFrom != null) {
        eventTitle = TimelineTitleKey.replacementOpened;
        eventSubtitle = encodeTimelineSubtitle(
          TimelineSubtitleKey.replacementFor,
          args: <String>[replacedFrom],
        );
      } else if (allSold) {
        eventTitle = TimelineTitleKey.saleCompleted;
        eventSubtitle = encodeTimelineSubtitle(
          TimelineSubtitleKey.createdOrderFlowSale,
        );
      } else if (hasJob && !hasRent && !hasSell) {
        eventTitle = TimelineTitleKey.jobOpened;
        eventSubtitle = encodeTimelineSubtitle(
          TimelineSubtitleKey.createdOrderFlowJob,
        );
      } else if (hasSell || hasJob) {
        eventTitle = TimelineTitleKey.orderOpened;
        eventSubtitle = encodeTimelineSubtitle(
          TimelineSubtitleKey.createdOrderFlowMixed,
        );
      } else {
        eventTitle = TimelineTitleKey.orderOpened;
        eventSubtitle = encodeTimelineSubtitle(
          TimelineSubtitleKey.createdOrderFlow,
        );
      }
      await _db.into(_db.rentalEvents).insert(
        RentalEventsCompanion.insert(
          rentalId: rentalId,
          title: eventTitle,
          subtitle: eventSubtitle,
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
        rental.openRentLines.map((RentalLine l) => l.id).toList();
    if (openIds.isEmpty) {
      return null;
    }
    return returnRentalLines(rentalId, openIds);
  }

  /// Resolves [quantitiesByItemId] to open rent line ids (oldest first per SKU).
  Future<RentalReturnResult?> returnRentalQuantities(
    String rentalId,
    Map<String, int> quantitiesByItemId, {
    int? chargedTotalPaise,
    String? note,
  }) async {
    final List<String> lineIds = await _resolveOpenRentLineIdsByQuantity(
      rentalId,
      quantitiesByItemId,
    );
    if (lineIds.isEmpty) {
      return null;
    }
    return returnRentalLines(
      rentalId,
      lineIds,
      chargedTotalPaise: chargedTotalPaise,
      note: note,
    );
  }

  /// Settles selected open lines; closes parent when none remain open.
  ///
  /// [chargedTotalPaise] caps the batch total (remainder treated as discount).
  /// When null, the full computed total is charged.
  Future<RentalReturnResult?> returnRentalLines(
    String rentalId,
    List<String> lineIds, {
    int? chargedTotalPaise,
    String? note,
  }) async {
    return _settleOpenRentLines(
      rentalId: rentalId,
      lineIds: lineIds,
      disposition: ReturnDisposition.returned,
      restoreStock: true,
      chargedTotalPaise: chargedTotalPaise,
      note: note,
    );
  }

  /// Closes open rent lines as lost (no stock restore); same close rules.
  Future<RentalReturnResult?> markRentalLinesLost(
    String rentalId,
    List<String> lineIds, {
    int? chargedTotalPaise,
    String? note,
  }) async {
    return _settleOpenRentLines(
      rentalId: rentalId,
      lineIds: lineIds,
      disposition: ReturnDisposition.lost,
      restoreStock: false,
      chargedTotalPaise: chargedTotalPaise,
      note: note,
    );
  }

  /// Marks [quantitiesByItemId] open rent units lost (oldest first per SKU).
  Future<RentalReturnResult?> markRentalQuantitiesLost(
    String rentalId,
    Map<String, int> quantitiesByItemId, {
    int? chargedTotalPaise,
    String? note,
  }) async {
    final List<String> lineIds = await _resolveOpenRentLineIdsByQuantity(
      rentalId,
      quantitiesByItemId,
    );
    if (lineIds.isEmpty) {
      return null;
    }
    return markRentalLinesLost(
      rentalId,
      lineIds,
      chargedTotalPaise: chargedTotalPaise,
      note: note,
    );
  }

  Future<List<String>> _resolveOpenRentLineIdsByQuantity(
    String rentalId,
    Map<String, int> quantitiesByItemId,
  ) async {
    if (quantitiesByItemId.isEmpty) {
      return const <String>[];
    }
    final List<RentalItemRow> links = await (_db.select(_db.rentalItems)
          ..where((t) => t.rentalId.equals(rentalId)))
        .get();
    final Map<String, List<RentalItemRow>> openByItem =
        <String, List<RentalItemRow>>{};
    for (final RentalItemRow link in links) {
      if (link.returnedAt != null) {
        continue;
      }
      if (LineFulfillment.parse(link.fulfillment) != LineFulfillment.rent) {
        continue;
      }
      openByItem.putIfAbsent(link.itemId, () => <RentalItemRow>[]).add(link);
    }
    final List<String> resolved = <String>[];
    for (final MapEntry<String, int> entry in quantitiesByItemId.entries) {
      final int qty = entry.value;
      if (qty <= 0) {
        continue;
      }
      final List<RentalItemRow> open =
          openByItem[entry.key] ?? const <RentalItemRow>[];
      final int take = qty < open.length ? qty : open.length;
      for (int i = 0; i < take; i++) {
        resolved.add(open[i].id);
      }
    }
    return resolved;
  }

  static String _itemQtySummary({
    required List<RentalItemRow> lines,
    required Map<String, String> catalogNames,
  }) {
    final Map<String, int> counts = <String, int>{};
    for (final RentalItemRow link in lines) {
      counts[link.itemId] = (counts[link.itemId] ?? 0) + 1;
    }
    final List<String> parts = <String>[];
    for (final MapEntry<String, int> entry in counts.entries) {
      final String name = catalogNames[entry.key] ?? entry.key;
      parts.add(entry.value <= 1 ? name : '$name × ${entry.value}');
    }
    return parts.join(', ');
  }

  /// Shared settle path for return (stock restore) and lost (no restore).
  Future<RentalReturnResult?> _settleOpenRentLines({
    required String rentalId,
    required List<String> lineIds,
    required ReturnDisposition disposition,
    required bool restoreStock,
    int? chargedTotalPaise,
    String? note,
    bool autoVacate = false,
  }) async {
    if (lineIds.isEmpty) {
      return null;
    }
    final String? trimmedNote = note?.trim();
    if (!meetsMinMeaningfulText(trimmedNote, allowEmpty: true)) {
      throw ArgumentError(
        'Note must be at least $kMinMeaningfulTextLength characters when set',
      );
    }
    final DateTime now = DateTime.now();
    final Set<String> wanted = lineIds.toSet();

    return _db.transaction(() async {
      final RentalRow? rental = await (_db.select(_db.rentals)
            ..where((t) => t.id.equals(rentalId)))
          .getSingleOrNull();
      if (rental == null ||
          OrderStatus.parse(rental.orderStatus) != OrderStatus.open) {
        return null;
      }

      final List<RentalItemRow> links = await (_db.select(_db.rentalItems)
            ..where((t) => t.rentalId.equals(rentalId)))
          .get();
      final List<RentalItemRow> toSettle = links
          .where(
            (RentalItemRow link) =>
                wanted.contains(link.id) &&
                link.returnedAt == null &&
                LineFulfillment.parse(link.fulfillment) == LineFulfillment.rent,
          )
          .toList();
      if (toSettle.isEmpty) {
        return null;
      }

      int depositRemaining =
          (rental.depositAmount - rental.depositApplied).clamp(0, 1 << 30);

      final List<({RentalItemRow link, InventoryItemRow? item, int base, int late})>
          computed =
          <({RentalItemRow link, InventoryItemRow? item, int base, int late})>[];
      final Map<String, String> catalogNames = <String, String>{};
      for (final RentalItemRow link in toSettle) {
        final InventoryItemRow? item = await (_db.select(_db.inventoryItems)
              ..where((t) => t.id.equals(link.itemId)))
            .getSingleOrNull();
        if (item != null) {
          catalogNames[item.id] = item.name;
        }
        final int lineBase;
        final int lineLate;
        if (rental.dueAt == null) {
          lineBase = computeBaseAmount(
            mode: BillingMode.parse(link.billingMode),
            rateAmount: link.rateAmount,
            start: rental.startedAt,
            due: now,
          );
          lineLate = 0;
        } else {
          lineBase = link.baseAmount;
          lineLate = computeLateAmount(
            due: rental.dueAt!,
            asOf: now,
            lateFeePerDay: link.lateFeePerDay,
          );
        }
        computed.add((link: link, item: item, base: lineBase, late: lineLate));
      }

      final List<int> naturalTotals = computed
          .map(
            (row) => computeTotalAmount(baseAmount: row.base, lateAmount: row.late),
          )
          .toList();
      final int naturalSum =
          naturalTotals.fold<int>(0, (int a, int b) => a + b);
      final int charged = (chargedTotalPaise ?? naturalSum).clamp(0, naturalSum);
      final int discount = naturalSum - charged;
      final List<int> chargedPerLine =
          _allocateChargedTotals(naturalTotals, charged);

      int batchTotal = 0;
      int batchDeposit = 0;
      final List<String> settledIds = <String>[];
      final Map<String, int> stockBump = <String, int>{};

      for (int i = 0; i < computed.length; i++) {
        final row = computed[i];
        final RentalItemRow link = row.link;
        final InventoryItemRow? item = row.item;
        final int lineCharged = chargedPerLine[i];
        final ({int base, int late}) settled = _applyLineDiscount(
          naturalBase: row.base,
          naturalLate: row.late,
          chargedTotal: lineCharged,
        );
        final int lineDeposit =
            depositRemaining < lineCharged ? depositRemaining : lineCharged;
        depositRemaining -= lineDeposit;
        batchTotal += lineCharged;
        batchDeposit += lineDeposit;
        settledIds.add(link.id);

        await (_db.update(_db.rentalItems)..where((t) => t.id.equals(link.id)))
            .write(
          RentalItemsCompanion(
            returnedAt: Value<DateTime?>(now),
            baseAmount: Value<int>(settled.base),
            lateAmount: Value<int>(settled.late),
            depositApplied: Value<int>(lineDeposit),
            returnDisposition: Value<String?>(disposition.storageValue),
          ),
        );

        if (restoreStock && item != null) {
          stockBump[item.id] = (stockBump[item.id] ?? 0) + 1;
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
      final bool noOpenWork = refreshed.every(
        (RentalItemRow l) =>
            l.returnedAt != null ||
            LineFulfillment.parse(l.fulfillment) == LineFulfillment.sell,
      );

      int parentBase = 0;
      int parentLate = 0;
      int parentDeposit = 0;
      int openLateFeePerDay = 0;
      for (final RentalItemRow link in refreshed) {
        parentBase += link.baseAmount;
        parentLate += link.lateAmount;
        parentDeposit += link.depositApplied;
        if (link.returnedAt == null &&
            LineFulfillment.parse(link.fulfillment) == LineFulfillment.rent) {
          openLateFeePerDay += link.lateFeePerDay;
        }
      }
      final int parentTotal = parentBase + parentLate;
      final OrderStatus nextStatus =
          noOpenWork ? OrderStatus.completed : OrderStatus.open;
      final WorkflowDefinition workflow = activeWorkflow();
      final bool hasSell = refreshed.any(
        (RentalItemRow l) =>
            LineFulfillment.parse(l.fulfillment) == LineFulfillment.sell,
      );
      final bool hasRent = refreshed.any(
        (RentalItemRow l) =>
            LineFulfillment.parse(l.fulfillment) == LineFulfillment.rent,
      );
      final bool hasJob = refreshed.any(
        (RentalItemRow l) =>
            LineFulfillment.parse(l.fulfillment) == LineFulfillment.job,
      );
      final String? nextWorkflow = noOpenWork
          ? terminalWorkflowStatusForOrder(
              workflow: workflow,
              hasRent: hasRent,
              hasJob: hasJob,
              hasSell: hasSell,
            )
          : effectiveWorkflowStatusId(
              stored: rental.workflowStatus,
              orderStatus: OrderStatus.open,
              workflow: workflow,
            );

      await (_db.update(_db.rentals)..where((t) => t.id.equals(rentalId))).write(
        RentalsCompanion(
          returnedAt: Value<DateTime?>(noOpenWork ? now : null),
          orderStatus: Value<String>(nextStatus.storageValue),
          workflowStatus: Value<String?>(nextWorkflow),
          baseAmount: Value<int>(parentBase),
          lateAmount: Value<int>(parentLate),
          totalAmount: Value<int>(parentTotal),
          depositApplied: Value<int>(parentDeposit),
          lateFeePerDay: Value<int>(
            noOpenWork ? rental.lateFeePerDay : openLateFeePerDay,
          ),
        ),
      );

      final String itemSummary = _itemQtySummary(
        lines: toSettle,
        catalogNames: catalogNames,
      );
      final String titleKey;
      final String subtitleKey;
      final List<String> subtitleArgs;
      if (disposition == ReturnDisposition.lost) {
        titleKey = TimelineTitleKey.unitsLost;
        subtitleKey = TimelineSubtitleKey.unitsLostQty;
        subtitleArgs = <String>[itemSummary, '${settledIds.length}'];
      } else if (autoVacate) {
        titleKey = TimelineTitleKey.autoVacated;
        subtitleKey = TimelineSubtitleKey.autoVacated;
        subtitleArgs = <String>[itemSummary, '${settledIds.length}'];
      } else if (noOpenWork) {
        titleKey = TimelineTitleKey.returned;
        subtitleKey = parentLate > 0
            ? TimelineSubtitleKey.allLinesReturnedLate
            : TimelineSubtitleKey.allLinesReturned;
        subtitleArgs = const <String>[];
      } else {
        titleKey = TimelineTitleKey.partialReturn;
        subtitleKey = TimelineSubtitleKey.partialReturnQty;
        subtitleArgs = <String>[
          itemSummary,
          '${settledIds.length}',
          '${refreshed.length}',
        ];
      }
      final String subtitle = encodeTimelineSubtitle(
        subtitleKey,
        args: subtitleArgs,
        discountFormatted: discount > 0 ? formatMoney(discount) : null,
        note: trimmedNote,
      );

      await _db.into(_db.rentalEvents).insert(
        RentalEventsCompanion.insert(
          rentalId: rentalId,
          title: titleKey,
          subtitle: subtitle,
          at: now,
        ),
      );

      if (noOpenWork) {
        final String? fromStatus = effectiveWorkflowStatusId(
          stored: rental.workflowStatus,
          orderStatus: OrderStatus.open,
          workflow: workflow,
        );
        if (fromStatus != nextWorkflow) {
          await _db.into(_db.rentalEvents).insert(
            RentalEventsCompanion.insert(
              rentalId: rentalId,
              title: TimelineTitleKey.statusChanged,
              subtitle: encodeTimelineSubtitle(
                TimelineSubtitleKey.statusChanged,
                args: <String>[fromStatus ?? '', nextWorkflow ?? ''],
              ),
              at: now,
            ),
          );
        }
      }

      final bool isLost = disposition == ReturnDisposition.lost;
      return RentalReturnResult(
        rentalId: rentalId,
        totalAmount: batchTotal,
        depositApplied: batchDeposit,
        depositBalanceAfter:
            (rental.depositAmount - parentDeposit).clamp(0, rental.depositAmount),
        returnedLineIds: isLost ? const <String>[] : settledIds,
        lostLineIds: isLost ? settledIds : const <String>[],
        rentalClosed: noOpenWork,
      );
    });
  }

  /// Marks selected open job lines complete; does not restore stock.
  Future<RentalReturnResult?> completeJobLines(
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
      if (rental == null ||
          OrderStatus.parse(rental.orderStatus) != OrderStatus.open) {
        return null;
      }

      final List<RentalItemRow> links = await (_db.select(_db.rentalItems)
            ..where((t) => t.rentalId.equals(rentalId)))
          .get();
      final List<RentalItemRow> toComplete = links
          .where(
            (RentalItemRow link) =>
                wanted.contains(link.id) &&
                link.returnedAt == null &&
                LineFulfillment.parse(link.fulfillment) == LineFulfillment.job,
          )
          .toList();
      if (toComplete.isEmpty) {
        return null;
      }

      final List<String> completedIds = <String>[];
      int batchTotal = 0;
      for (final RentalItemRow link in toComplete) {
        completedIds.add(link.id);
        batchTotal += link.baseAmount + link.lateAmount;
        await (_db.update(_db.rentalItems)..where((t) => t.id.equals(link.id)))
            .write(
          RentalItemsCompanion(
            returnedAt: Value<DateTime?>(now),
          ),
        );
      }

      final List<RentalItemRow> refreshed = await (_db.select(_db.rentalItems)
            ..where((t) => t.rentalId.equals(rentalId)))
          .get();
      final bool noOpenWork = refreshed.every(
        (RentalItemRow l) =>
            l.returnedAt != null ||
            LineFulfillment.parse(l.fulfillment) == LineFulfillment.sell,
      );

      int parentBase = 0;
      int parentLate = 0;
      int parentDeposit = 0;
      int openLateFeePerDay = 0;
      for (final RentalItemRow link in refreshed) {
        parentBase += link.baseAmount;
        parentLate += link.lateAmount;
        parentDeposit += link.depositApplied;
        if (link.returnedAt == null &&
            LineFulfillment.parse(link.fulfillment) == LineFulfillment.rent) {
          openLateFeePerDay += link.lateFeePerDay;
        }
      }
      final int parentTotal = parentBase + parentLate;
      final OrderStatus nextStatus =
          noOpenWork ? OrderStatus.completed : OrderStatus.open;
      final WorkflowDefinition workflow = activeWorkflow();
      final String? fromStatus = effectiveWorkflowStatusId(
        stored: rental.workflowStatus,
        orderStatus: OrderStatus.open,
        workflow: workflow,
      );
      final bool hasSell = refreshed.any(
        (RentalItemRow l) =>
            LineFulfillment.parse(l.fulfillment) == LineFulfillment.sell,
      );
      final bool hasRent = refreshed.any(
        (RentalItemRow l) =>
            LineFulfillment.parse(l.fulfillment) == LineFulfillment.rent,
      );
      final bool hasJob = refreshed.any(
        (RentalItemRow l) =>
            LineFulfillment.parse(l.fulfillment) == LineFulfillment.job,
      );
      final String? nextWorkflow;
      if (noOpenWork) {
        nextWorkflow = terminalWorkflowStatusForOrder(
          workflow: workflow,
          hasRent: hasRent,
          hasJob: hasJob,
          hasSell: hasSell,
        );
      } else {
        final WorkflowStatus? advanced = workflow.immediateNext(fromStatus);
        nextWorkflow = advanced != null && !advanced.isTerminal
            ? advanced.id
            : fromStatus;
      }

      await (_db.update(_db.rentals)..where((t) => t.id.equals(rentalId))).write(
        RentalsCompanion(
          returnedAt: Value<DateTime?>(noOpenWork ? now : null),
          orderStatus: Value<String>(nextStatus.storageValue),
          workflowStatus: Value<String?>(nextWorkflow),
          baseAmount: Value<int>(parentBase),
          lateAmount: Value<int>(parentLate),
          totalAmount: Value<int>(parentTotal),
          depositApplied: Value<int>(parentDeposit),
          lateFeePerDay: Value<int>(
            noOpenWork ? rental.lateFeePerDay : openLateFeePerDay,
          ),
        ),
      );

      await _db.into(_db.rentalEvents).insert(
        RentalEventsCompanion.insert(
          rentalId: rentalId,
          title: noOpenWork
              ? TimelineTitleKey.jobsCompleted
              : TimelineTitleKey.jobCompleted,
          subtitle: noOpenWork
              ? encodeTimelineSubtitle(TimelineSubtitleKey.allJobsComplete)
              : encodeTimelineSubtitle(
                  TimelineSubtitleKey.jobsCompletedCount,
                  args: <String>['${completedIds.length}'],
                ),
          at: now,
        ),
      );

      if (nextWorkflow != null &&
          fromStatus != null &&
          nextWorkflow != fromStatus) {
        await _db.into(_db.rentalEvents).insert(
          RentalEventsCompanion.insert(
            rentalId: rentalId,
            title: TimelineTitleKey.statusChanged,
            subtitle: encodeTimelineSubtitle(
              TimelineSubtitleKey.statusChanged,
              args: <String>[fromStatus, nextWorkflow],
            ),
            at: now,
          ),
        );
      }

      return RentalReturnResult(
        rentalId: rentalId,
        totalAmount: batchTotal,
        depositApplied: 0,
        depositBalanceAfter:
            (rental.depositAmount - parentDeposit).clamp(0, rental.depositAmount),
        returnedLineIds: completedIds,
        rentalClosed: noOpenWork,
      );
    });
  }

  /// Moves [dueAt] forward for an open rental; keeps the same lines and short codes.
  ///
  /// [newDueAt] must be today or later, and strictly after the current due date
  /// when one is set. Recomputes open rent line base charges through the new due.
  Future<bool> extendRentalDue(String rentalId, DateTime newDueAt) async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime newDueDay = DateTime(
      newDueAt.year,
      newDueAt.month,
      newDueAt.day,
      23,
      59,
      59,
    );
    final DateTime newDueDateOnly =
        DateTime(newDueAt.year, newDueAt.month, newDueAt.day);
    if (newDueDateOnly.isBefore(today)) {
      throw ArgumentError('New due date must be today or later');
    }

    return _db.transaction(() async {
      final RentalRow? rental = await (_db.select(_db.rentals)
            ..where((t) => t.id.equals(rentalId)))
          .getSingleOrNull();
      if (rental == null ||
          OrderStatus.parse(rental.orderStatus) != OrderStatus.open) {
        return false;
      }
      if (rental.dueAt != null) {
        final DateTime currentDue = DateTime(
          rental.dueAt!.year,
          rental.dueAt!.month,
          rental.dueAt!.day,
        );
        if (!newDueDateOnly.isAfter(currentDue)) {
          throw ArgumentError('New due date must be after the current due date');
        }
      }

      final List<RentalItemRow> links = await (_db.select(_db.rentalItems)
            ..where((t) => t.rentalId.equals(rentalId)))
          .get();
      int parentBase = 0;
      int parentLate = 0;
      int parentDeposit = rental.depositApplied;
      for (final RentalItemRow link in links) {
        if (link.returnedAt != null) {
          parentBase += link.baseAmount;
          parentLate += link.lateAmount;
          continue;
        }
        if (LineFulfillment.parse(link.fulfillment) != LineFulfillment.rent) {
          parentBase += link.baseAmount;
          parentLate += link.lateAmount;
          continue;
        }
        final int lineBase = computeBaseAmount(
          mode: BillingMode.parse(link.billingMode),
          rateAmount: link.rateAmount,
          start: rental.startedAt,
          due: newDueDay,
        );
        await (_db.update(_db.rentalItems)..where((t) => t.id.equals(link.id)))
            .write(
          RentalItemsCompanion(
            baseAmount: Value<int>(lineBase),
            lateAmount: const Value<int>(0),
          ),
        );
        parentBase += lineBase;
      }

      await (_db.update(_db.rentals)..where((t) => t.id.equals(rentalId))).write(
        RentalsCompanion(
          dueAt: Value<DateTime?>(newDueDay),
          baseAmount: Value<int>(parentBase),
          lateAmount: Value<int>(parentLate),
          totalAmount: Value<int>(
            computeTotalAmount(baseAmount: parentBase, lateAmount: parentLate),
          ),
          depositApplied: Value<int>(parentDeposit),
        ),
      );

      await _db.into(_db.rentalEvents).insert(
        RentalEventsCompanion.insert(
          rentalId: rentalId,
          title: TimelineTitleKey.dueExtended,
          subtitle: encodeTimelineSubtitle(
            TimelineSubtitleKey.dueExtended,
            args: <String>[
              rental.dueAt == null
                  ? ''
                  : '${rental.dueAt!.year}-${rental.dueAt!.month.toString().padLeft(2, '0')}-${rental.dueAt!.day.toString().padLeft(2, '0')}',
              '${newDueDateOnly.year}-${newDueDateOnly.month.toString().padLeft(2, '0')}-${newDueDateOnly.day.toString().padLeft(2, '0')}',
            ],
          ),
          at: now,
        ),
      );
      return true;
    });
  }

  /// Settles open rent lines on rentals whose due date is before [asOf]'s calendar day.
  ///
  /// Idempotent: already-closed or due-today rentals are skipped. Restores stock
  /// and frees short codes via the normal return path.
  Future<int> autoVacateOverdueRentals({DateTime? asOf}) async {
    final DateTime clock = asOf ?? DateTime.now();
    final DateTime today = DateTime(clock.year, clock.month, clock.day);
    final List<Rental> rentals = await listRentals();
    int vacated = 0;
    for (final Rental rental in rentals) {
      if (!rental.isActive || rental.dueAt == null) {
        continue;
      }
      final DateTime dueDay = DateTime(
        rental.dueAt!.year,
        rental.dueAt!.month,
        rental.dueAt!.day,
      );
      if (!dueDay.isBefore(today)) {
        continue;
      }
      final List<String> openIds =
          rental.openRentLines.map((RentalLine l) => l.id).toList();
      if (openIds.isEmpty) {
        continue;
      }
      final RentalReturnResult? result = await _settleOpenRentLines(
        rentalId: rental.id,
        lineIds: openIds,
        disposition: ReturnDisposition.returned,
        restoreStock: true,
        autoVacate: true,
      );
      if (result != null) {
        vacated += 1;
      }
    }
    return vacated;
  }

  /// Advances the order along the active workflow (immediate next, or [toStatusId]).
  ///
  /// Terminal statuses set [OrderStatus.completed]. Cancelled orders are unchanged.
  Future<Rental?> advanceWorkflowStatus(
    String rentalId, {
    String? toStatusId,
  }) async {
    final DateTime now = DateTime.now();
    return _db.transaction(() async {
      final RentalRow? rental = await (_db.select(_db.rentals)
            ..where((t) => t.id.equals(rentalId)))
          .getSingleOrNull();
      if (rental == null) {
        return null;
      }
      final OrderStatus orderStatus = OrderStatus.parse(rental.orderStatus);
      if (orderStatus == OrderStatus.cancelled) {
        return null;
      }
      if (orderStatus == OrderStatus.completed) {
        return _findRental(rentalId);
      }

      final WorkflowDefinition workflow = activeWorkflow();
      final String? fromStatus = effectiveWorkflowStatusId(
        stored: rental.workflowStatus,
        orderStatus: orderStatus,
        workflow: workflow,
      );
      final List<WorkflowStatus> allowed = workflow.nextAllowed(fromStatus);
      if (allowed.isEmpty) {
        return _findRental(rentalId);
      }

      final WorkflowStatus target;
      if (toStatusId == null || toStatusId.isEmpty) {
        target = allowed.first;
      } else {
        WorkflowStatus? picked;
        for (final WorkflowStatus status in allowed) {
          if (status.id == toStatusId) {
            picked = status;
            break;
          }
        }
        if (picked == null) {
          throw ArgumentError('Status $toStatusId is not allowed from $fromStatus');
        }
        target = picked;
      }

      if (fromStatus == target.id) {
        return _findRental(rentalId);
      }

      final bool terminal = target.isTerminal;
      await (_db.update(_db.rentals)..where((t) => t.id.equals(rentalId))).write(
        RentalsCompanion(
          workflowStatus: Value<String?>(target.id),
          orderStatus: Value<String>(
            terminal
                ? OrderStatus.completed.storageValue
                : OrderStatus.open.storageValue,
          ),
          returnedAt: terminal
              ? Value<DateTime?>(rental.returnedAt ?? now)
              : const Value<DateTime?>.absent(),
        ),
      );

      await _db.into(_db.rentalEvents).insert(
        RentalEventsCompanion.insert(
          rentalId: rentalId,
          title: TimelineTitleKey.statusChanged,
          subtitle: encodeTimelineSubtitle(
            TimelineSubtitleKey.statusChanged,
            args: <String>[fromStatus ?? '', target.id],
          ),
          at: now,
        ),
      );

      return _findRental(rentalId);
    });
  }

  /// Cancels an active order with no returned lines; restores stock and settles
  /// deposit (kept vs returned).
  Future<OrderCancelResult?> cancelOrder({
    required String rentalId,
    int amountKeptPaise = 0,
    int amountReturnedPaise = 0,
    String? note,
  }) async {
    if (amountKeptPaise < 0 || amountReturnedPaise < 0) {
      throw ArgumentError('Settlement amounts must be non-negative');
    }
    final String? trimmedNote = note?.trim();
    if (!meetsMinMeaningfulText(trimmedNote, allowEmpty: true)) {
      throw ArgumentError(
        'Note must be at least $kMinMeaningfulTextLength characters when set',
      );
    }
    final DateTime now = DateTime.now();

    return _db.transaction(() async {
      final RentalRow? rental = await (_db.select(_db.rentals)
            ..where((t) => t.id.equals(rentalId)))
          .getSingleOrNull();
      if (rental == null ||
          OrderStatus.parse(rental.orderStatus) != OrderStatus.open) {
        return null;
      }

      final List<RentalItemRow> links = await (_db.select(_db.rentalItems)
            ..where((t) => t.rentalId.equals(rentalId)))
          .get();
      if (links.any(
        (RentalItemRow l) =>
            l.returnedAt != null &&
            LineFulfillment.parse(l.fulfillment) != LineFulfillment.sell,
      )) {
        throw StateError('Cannot delete order after partial return');
      }
      if (links.isEmpty) {
        return null;
      }

      final int depositRemaining =
          (rental.depositAmount - rental.depositApplied).clamp(0, 1 << 30);
      final int settlement = amountKeptPaise + amountReturnedPaise;
      if (settlement > depositRemaining) {
        throw ArgumentError('Settlement exceeds order deposit');
      }

      final Map<String, int> availableBump = <String, int>{};
      final Map<String, int> totalBump = <String, int>{};
      for (final RentalItemRow link in links) {
        if (link.returnedAt != null) {
          continue;
        }
        await (_db.update(_db.rentalItems)..where((t) => t.id.equals(link.id)))
            .write(
          RentalItemsCompanion(
            returnedAt: Value<DateTime?>(now),
            baseAmount: const Value<int>(0),
            lateAmount: const Value<int>(0),
            depositApplied: const Value<int>(0),
          ),
        );
        availableBump[link.itemId] = (availableBump[link.itemId] ?? 0) + 1;
        if (LineFulfillment.parse(link.fulfillment) == LineFulfillment.job) {
          totalBump[link.itemId] = (totalBump[link.itemId] ?? 0) + 1;
        }
      }

      for (final MapEntry<String, int> bump in availableBump.entries) {
        final InventoryItemRow? item = await (_db.select(_db.inventoryItems)
              ..where((t) => t.id.equals(bump.key)))
            .getSingleOrNull();
        if (item == null) {
          continue;
        }
        final int nextTotal =
            (item.totalUnits + (totalBump[bump.key] ?? 0)).clamp(0, 1 << 30);
        final int nextAvailable =
            (item.availableUnits + bump.value).clamp(0, nextTotal);
        await (_db.update(_db.inventoryItems)..where((t) => t.id.equals(item.id)))
            .write(
          InventoryItemsCompanion(
            availableUnits: Value<int>(nextAvailable),
            totalUnits: Value<int>(nextTotal),
            status: Value<String>(AssetStatus.available.name),
          ),
        );
      }

      await (_db.update(_db.rentals)..where((t) => t.id.equals(rentalId))).write(
        RentalsCompanion(
          returnedAt: Value<DateTime?>(now),
          orderStatus: Value<String>(OrderStatus.cancelled.storageValue),
          baseAmount: const Value<int>(0),
          lateAmount: const Value<int>(0),
          totalAmount: const Value<int>(0),
          depositApplied: Value<int>(rental.depositApplied + settlement),
        ),
      );

      final String subtitle = encodeTimelineSubtitle(
        TimelineSubtitleKey.cancelSettlement,
        args: <String>[
          formatMoney(amountKeptPaise),
          formatMoney(amountReturnedPaise),
        ],
        note: trimmedNote,
      );

      await _db.into(_db.rentalEvents).insert(
        RentalEventsCompanion.insert(
          rentalId: rentalId,
          title: TimelineTitleKey.orderCancelled,
          subtitle: subtitle,
          at: now,
        ),
      );

      return OrderCancelResult(
        rentalId: rentalId,
        amountKeptPaise: amountKeptPaise,
        amountReturnedPaise: amountReturnedPaise,
        depositBalanceAfter: depositRemaining - settlement,
      );
    });
  }

  /// Split [charged] across lines proportional to [naturalTotals]; last line
  /// absorbs rounding remainder so the batch sums exactly.
  static List<int> _allocateChargedTotals(List<int> naturalTotals, int charged) {
    if (naturalTotals.isEmpty) {
      return const <int>[];
    }
    final int sum = naturalTotals.fold<int>(0, (int a, int b) => a + b);
    if (sum <= 0 || charged <= 0) {
      return List<int>.filled(naturalTotals.length, 0);
    }
    if (charged >= sum) {
      return List<int>.from(naturalTotals);
    }
    final List<int> out = List<int>.filled(naturalTotals.length, 0);
    int allocated = 0;
    for (int i = 0; i < naturalTotals.length; i++) {
      if (i == naturalTotals.length - 1) {
        out[i] = charged - allocated;
      } else {
        final int share = (charged * naturalTotals[i]) ~/ sum;
        out[i] = share;
        allocated += share;
      }
    }
    return out;
  }

  /// Prefer reducing late fees first, then base, to reach [chargedTotal].
  static ({int base, int late}) _applyLineDiscount({
    required int naturalBase,
    required int naturalLate,
    required int chargedTotal,
  }) {
    final int natural = naturalBase + naturalLate;
    final int target = chargedTotal.clamp(0, natural);
    int reduce = natural - target;
    int late = naturalLate;
    int base = naturalBase;
    if (reduce > 0) {
      final int lateCut = reduce > late ? late : reduce;
      late -= lateCut;
      reduce -= lateCut;
      base -= reduce;
    }
    return (base: base, late: late);
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

  /// Append an order note (body ≥3 chars). Optional [rentalItemId] must belong
  /// to this rental. Also records a short timeline event.
  Future<RentalNote> addRentalNote({
    required String rentalId,
    String? rentalItemId,
    required String body,
    String kind = 'general',
  }) async {
    final String trimmed = body.trim();
    if (!meetsMinMeaningfulText(trimmed)) {
      throw ArgumentError(
        'Note must be at least $kMinMeaningfulTextLength characters',
      );
    }
    final RentalNoteKind parsedKind = RentalNoteKind.parse(kind);
    final Rental? rental = await _findRental(rentalId);
    if (rental == null) {
      throw ArgumentError('Rental not found: $rentalId');
    }
    final String? lineId = rentalItemId?.trim();
    final String? storedLineId =
        (lineId == null || lineId.isEmpty) ? null : lineId;
    if (storedLineId != null &&
        !rental.lines.any((RentalLine line) => line.id == storedLineId)) {
      throw ArgumentError(
        'Rental line $storedLineId does not belong to rental $rentalId',
      );
    }

    final DateTime now = DateTime.now();
    final String noteId = nextId('NOTE');
    final String truncatedBody = trimmed.length > 80
        ? '${trimmed.substring(0, 80)}…'
        : trimmed;
    final String eventSubtitle = encodeTimelineSubtitle(
      TimelineSubtitleKey.noteBody,
      args: <String>[parsedKind.storageValue, truncatedBody],
    );

    await _db.transaction(() async {
      await _db.into(_db.rentalNotes).insert(
        RentalNotesCompanion.insert(
          id: noteId,
          rentalId: rentalId,
          rentalItemId: Value<String?>(storedLineId),
          kind: Value<String>(parsedKind.storageValue),
          body: trimmed,
          createdAt: now,
        ),
      );
      await _db.into(_db.rentalEvents).insert(
        RentalEventsCompanion.insert(
          rentalId: rentalId,
          title: TimelineTitleKey.noteAdded,
          subtitle: eventSubtitle,
          at: now,
        ),
      );
      // Notes/events are not watched by rentalsProvider; nudge the parent row.
      _db.notifyUpdates(<TableUpdate>{
        TableUpdate.onTable(_db.rentals, kind: UpdateKind.update),
      });
    });

    return RentalNote(
      id: noteId,
      rentalId: rentalId,
      rentalItemId: storedLineId,
      kind: parsedKind,
      body: trimmed,
      createdAt: now,
    );
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
          id: '${nextId('DEP')}-topup',
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
          id: '${nextId('DEP')}-refund',
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

  // --- Cash money loans (not physical ResourceType.loan) ---

  Stream<List<MoneyLoan>> watchMoneyLoans({String? customerId}) {
    final query = _db.select(_db.moneyLoans);
    if (customerId != null) {
      query.where((t) => t.customerId.equals(customerId));
    }
    query.orderBy([
      (t) => OrderingTerm.desc(t.createdAt),
    ]);
    return query.watch().asyncMap((List<MoneyLoanRow> rows) async {
      final List<MoneyLoan> loans = <MoneyLoan>[];
      for (final MoneyLoanRow row in rows) {
        loans.add(await _mapMoneyLoan(row));
      }
      return loans;
    });
  }

  Future<List<MoneyLoan>> listMoneyLoans({
    String? customerId,
    MoneyLoanStatus? status,
  }) async {
    final List<MoneyLoan> all = await watchMoneyLoans(customerId: customerId).first;
    if (status == null) {
      return all;
    }
    return all.where((MoneyLoan l) => l.status == status).toList();
  }

  Future<MoneyLoan?> getMoneyLoan(String loanId) async {
    final MoneyLoanRow? row = await (_db.select(_db.moneyLoans)
          ..where((t) => t.id.equals(loanId)))
        .getSingleOrNull();
    if (row == null) {
      return null;
    }
    return _mapMoneyLoan(row);
  }

  Future<String> createMoneyLoan({
    required String customerId,
    required MoneyLoanDirection direction,
    required int principalPaise,
    required DateTime interestStartedAt,
    MoneyInterestKind? interestKind,
    MoneyCapitalizationPolicy? capitalizationPolicy,
    MoneyCapitalizationCycle? capitalizationCycle,
    int rateBps = 0,
    MoneyRatePeriod ratePeriod = MoneyRatePeriod.monthly,
    MoneyInterestAccrual interestAccrual = MoneyInterestAccrual.calendar,
    MoneyPrepaymentAllocation prepaymentAllocation =
        MoneyPrepaymentAllocation.interestThenPrincipal,
    DateTime? interestEndedAt,
    String? note,
    String currencyCode = 'INR',
  }) async {
    if (principalPaise <= 0) {
      throw ArgumentError('Principal must be positive');
    }
    if (rateBps < 0) {
      throw ArgumentError('Rate cannot be negative');
    }
    final MoneyCapitalizationPolicy effectivePolicy = capitalizationPolicy ??
        (interestKind == null
            ? MoneyCapitalizationPolicy.never
            : MoneyCapitalizationPolicy.fromLegacyInterestKind(interestKind));
    final MoneyCapitalizationCycle effectiveCycle = capitalizationCycle ??
        MoneyCapitalizationCycle.fromRatePeriod(ratePeriod);
    final MoneyInterestKind legacyKind = effectivePolicy.legacyInterestKind;
    final DateTime start = DateTime(
      interestStartedAt.year,
      interestStartedAt.month,
      interestStartedAt.day,
    );
    final DateTime? ended = interestEndedAt == null
        ? null
        : DateTime(
            interestEndedAt.year,
            interestEndedAt.month,
            interestEndedAt.day,
          );
    if (ended != null && ended.isBefore(start)) {
      throw ArgumentError('Due date must be on or after interest start');
    }
    final String? trimmedNote = note?.trim();
    final String id = nextId('MLN');
    final DateTime now = DateTime.now();
    await _db.into(_db.moneyLoans).insert(
      MoneyLoansCompanion.insert(
        id: id,
        customerId: customerId,
        direction: direction.name,
        principalPaise: principalPaise,
        currencyCode: Value<String>(
          currencyCode.trim().isEmpty
              ? 'INR'
              : currencyCode.trim().toUpperCase(),
        ),
        interestKind: Value<String>(legacyKind.name),
        rateBps: Value<int>(rateBps),
        ratePeriod: Value<String>(ratePeriod.name),
        interestAccrual: Value<String>(interestAccrual.name),
        capitalizationPolicy: Value<String>(effectivePolicy.name),
        capitalizationCycle: Value<String>(effectiveCycle.name),
        interestStartedAt: start,
        interestEndedAt: Value<DateTime?>(ended),
        prepaymentAllocation: Value<String>(prepaymentAllocation.name),
        status: Value<String>(MoneyLoanStatus.pending.name),
        note: Value<String?>(
          (trimmedNote == null || trimmedNote.isEmpty) ? null : trimmedNote,
        ),
        createdAt: now,
      ),
    );
    return id;
  }

  Future<void> updateMoneyLoan({
    required String loanId,
    MoneyLoanDirection? direction,
    int? principalPaise,
    MoneyInterestKind? interestKind,
    MoneyCapitalizationPolicy? capitalizationPolicy,
    MoneyCapitalizationCycle? capitalizationCycle,
    int? rateBps,
    MoneyRatePeriod? ratePeriod,
    MoneyInterestAccrual? interestAccrual,
    MoneyPrepaymentAllocation? prepaymentAllocation,
    DateTime? interestStartedAt,
    DateTime? interestEndedAt,
    bool clearInterestEndedAt = false,
    String? note,
    bool clearNote = false,
    String? currencyCode,
  }) async {
    final MoneyLoan? existing = await getMoneyLoan(loanId);
    if (existing == null) {
      throw StateError('Loan not found: $loanId');
    }
    if (existing.status != MoneyLoanStatus.pending) {
      throw StateError('Only pending loans can be edited');
    }
    final int nextPrincipal = principalPaise ?? existing.principalPaise;
    if (nextPrincipal <= 0) {
      throw ArgumentError('Principal must be positive');
    }
    final int nextRate = rateBps ?? existing.rateBps;
    if (nextRate < 0) {
      throw ArgumentError('Rate cannot be negative');
    }
    final MoneyCapitalizationPolicy nextPolicy = capitalizationPolicy ??
        (interestKind == null
            ? existing.capitalizationPolicy
            : MoneyCapitalizationPolicy.fromLegacyInterestKind(interestKind));
    final MoneyRatePeriod nextRatePeriod = ratePeriod ?? existing.ratePeriod;
    final MoneyInterestAccrual nextAccrual =
        interestAccrual ?? existing.interestAccrual;
    final MoneyCapitalizationCycle nextCycle = capitalizationCycle ??
        existing.capitalizationCycle;
    final MoneyPrepaymentAllocation nextPrepayment =
        prepaymentAllocation ?? existing.prepaymentAllocation;
    final MoneyInterestKind legacyKind = nextPolicy.legacyInterestKind;
    final DateTime start = interestStartedAt == null
        ? existing.interestStartedAt
        : DateTime(
            interestStartedAt.year,
            interestStartedAt.month,
            interestStartedAt.day,
          );
    DateTime? ended = existing.interestEndedAt;
    if (clearInterestEndedAt) {
      ended = null;
    } else if (interestEndedAt != null) {
      ended = DateTime(
        interestEndedAt.year,
        interestEndedAt.month,
        interestEndedAt.day,
      );
    }
    if (ended != null && ended.isBefore(start)) {
      throw ArgumentError('Due date must be on or after interest start');
    }
    String? nextNote = existing.note;
    if (clearNote) {
      nextNote = null;
    } else if (note != null) {
      final String trimmed = note.trim();
      nextNote = trimmed.isEmpty ? null : trimmed;
    }

    await (_db.update(_db.moneyLoans)..where((t) => t.id.equals(loanId))).write(
      MoneyLoansCompanion(
        direction: Value<String>((direction ?? existing.direction).name),
        principalPaise: Value<int>(nextPrincipal),
        currencyCode: Value<String>(
          currencyCode?.trim().isNotEmpty == true
              ? currencyCode!.trim().toUpperCase()
              : existing.currencyCode,
        ),
        interestKind: Value<String>(legacyKind.name),
        rateBps: Value<int>(nextRate),
        ratePeriod: Value<String>(nextRatePeriod.name),
        interestAccrual: Value<String>(nextAccrual.name),
        capitalizationPolicy: Value<String>(nextPolicy.name),
        capitalizationCycle: Value<String>(nextCycle.name),
        prepaymentAllocation: Value<String>(nextPrepayment.name),
        interestStartedAt: Value<DateTime>(start),
        interestEndedAt: Value<DateTime?>(ended),
        note: Value<String?>(nextNote),
      ),
    );
  }

  Future<String> addMoneyLoanEntry({
    required String loanId,
    required DateTime entryAt,
    required int amountPaise,
    required MoneyLoanEntryKind kind,
    String? note,
  }) async {
    final MoneyLoan? loan = await getMoneyLoan(loanId);
    if (loan == null) {
      throw StateError('Loan not found: $loanId');
    }
    if (loan.status != MoneyLoanStatus.pending) {
      throw StateError('Entries can only be added to pending loans');
    }
    if ((kind == MoneyLoanEntryKind.repayment ||
            kind == MoneyLoanEntryKind.disbursement) &&
        amountPaise <= 0) {
      throw ArgumentError('Amount must be positive');
    }
    if (kind == MoneyLoanEntryKind.adjustment && amountPaise == 0) {
      throw ArgumentError('Adjustment amount cannot be zero');
    }
    if (kind == MoneyLoanEntryKind.capitalization && amountPaise < 0) {
      throw ArgumentError('Capitalization amount cannot be negative');
    }
    final DateTime at = DateTime(entryAt.year, entryAt.month, entryAt.day);
    final DateTime today = DateTime.now();
    final DateTime todayOnly = DateTime(today.year, today.month, today.day);
    if (at.isAfter(todayOnly)) {
      throw ArgumentError('Entry date cannot be after today');
    }
    final String? trimmedNote = note?.trim();
    final String id = nextId('MLE');
    await _db.into(_db.moneyLoanEntries).insert(
      MoneyLoanEntriesCompanion.insert(
        id: id,
        loanId: loanId,
        entryAt: at,
        amountPaise: amountPaise,
        kind: kind.name,
        note: Value<String?>(
          (trimmedNote == null || trimmedNote.isEmpty) ? null : trimmedNote,
        ),
      ),
    );
    // Entries are not watched by moneyLoansProvider; nudge the parent row.
    _db.notifyUpdates(<TableUpdate>{
      TableUpdate.onTable(_db.moneyLoans, kind: UpdateKind.update),
    });
    return id;
  }

  /// Adds principal via a [MoneyLoanEntryKind.disbursement] entry.
  Future<String> addMoneyLoanPrincipal({
    required String loanId,
    required int amountPaise,
    required DateTime entryAt,
    String? note,
  }) {
    return addMoneyLoanEntry(
      loanId: loanId,
      entryAt: entryAt,
      amountPaise: amountPaise,
      kind: MoneyLoanEntryKind.disbursement,
      note: note,
    );
  }

  /// Inserts a manual capitalization marker for [MoneyCapitalizationPolicy.manual].
  Future<String> capitalizeMoneyLoanInterest(
    String loanId, {
    DateTime? at,
    String? note,
  }) async {
    final MoneyLoan? loan = await getMoneyLoan(loanId);
    if (loan == null) {
      throw StateError('Loan not found: $loanId');
    }
    if (loan.capitalizationPolicy != MoneyCapitalizationPolicy.manual) {
      throw StateError('Manual capitalize is only for manual policy loans');
    }
    final DateTime when = at ?? DateTime.now();
    final LoanScenario scenario = computeLoanScenario(loan: loan, now: when);
    final int unpaid = scenario.unpaidInterestPaise;
    if (unpaid == 0) {
      throw StateError('No unpaid interest to capitalize');
    }
    return addMoneyLoanEntry(
      loanId: loanId,
      entryAt: when,
      amountPaise: unpaid.abs(),
      kind: MoneyLoanEntryKind.capitalization,
      note: note,
    );
  }

  Future<void> updateMoneyLoanEntry({
    required String entryId,
    DateTime? entryAt,
    int? amountPaise,
    MoneyLoanEntryKind? kind,
    String? note,
    bool clearNote = false,
  }) async {
    final MoneyLoanEntryRow? row = await (_db.select(_db.moneyLoanEntries)
          ..where((t) => t.id.equals(entryId)))
        .getSingleOrNull();
    if (row == null) {
      throw StateError('Entry not found: $entryId');
    }
    final MoneyLoan? loan = await getMoneyLoan(row.loanId);
    if (loan == null || loan.status != MoneyLoanStatus.pending) {
      throw StateError('Only pending loan entries can be edited');
    }
    final MoneyLoanEntryKind nextKind =
        kind ?? MoneyLoanEntryKind.parse(row.kind);
    final int nextAmount = amountPaise ?? row.amountPaise;
    if ((nextKind == MoneyLoanEntryKind.repayment ||
            nextKind == MoneyLoanEntryKind.disbursement) &&
        nextAmount <= 0) {
      throw ArgumentError('Amount must be positive');
    }
    if (nextKind == MoneyLoanEntryKind.adjustment && nextAmount == 0) {
      throw ArgumentError('Adjustment amount cannot be zero');
    }
    DateTime at = row.entryAt;
    if (entryAt != null) {
      at = DateTime(entryAt.year, entryAt.month, entryAt.day);
      final DateTime today = DateTime.now();
      final DateTime todayOnly = DateTime(today.year, today.month, today.day);
      if (at.isAfter(todayOnly)) {
        throw ArgumentError('Entry date cannot be after today');
      }
    }
    String? nextNote = row.note;
    if (clearNote) {
      nextNote = null;
    } else if (note != null) {
      final String trimmed = note.trim();
      nextNote = trimmed.isEmpty ? null : trimmed;
    }
    await (_db.update(_db.moneyLoanEntries)..where((t) => t.id.equals(entryId)))
        .write(
      MoneyLoanEntriesCompanion(
        entryAt: Value<DateTime>(at),
        amountPaise: Value<int>(nextAmount),
        kind: Value<String>(nextKind.name),
        note: Value<String?>(nextNote),
      ),
    );
    _db.notifyUpdates(<TableUpdate>{
      TableUpdate.onTable(_db.moneyLoans, kind: UpdateKind.update),
    });
  }

  Future<void> deleteMoneyLoanEntry(String entryId) async {
    final MoneyLoanEntryRow? row = await (_db.select(_db.moneyLoanEntries)
          ..where((t) => t.id.equals(entryId)))
        .getSingleOrNull();
    if (row == null) {
      return;
    }
    final MoneyLoan? loan = await getMoneyLoan(row.loanId);
    if (loan == null || loan.status != MoneyLoanStatus.pending) {
      throw StateError('Only pending loan entries can be deleted');
    }
    await (_db.delete(_db.moneyLoanEntries)..where((t) => t.id.equals(entryId)))
        .go();
    _db.notifyUpdates(<TableUpdate>{
      TableUpdate.onTable(_db.moneyLoans, kind: UpdateKind.update),
    });
  }

  /// Explicit close — never auto-closes on payment.
  Future<void> closeMoneyLoan(String loanId, {DateTime? closedAt}) async {
    final MoneyLoan? loan = await getMoneyLoan(loanId);
    if (loan == null) {
      throw StateError('Loan not found: $loanId');
    }
    if (loan.status == MoneyLoanStatus.closed) {
      return;
    }
    if (loan.status == MoneyLoanStatus.cancelled) {
      throw StateError('Cancelled loans cannot be closed');
    }
    final DateTime at = closedAt ?? DateTime.now();
    final DateTime closed = DateTime(at.year, at.month, at.day);
    await (_db.update(_db.moneyLoans)..where((t) => t.id.equals(loanId))).write(
      MoneyLoansCompanion(
        status: Value<String>(MoneyLoanStatus.closed.name),
        closedAt: Value<DateTime>(closed),
      ),
    );
  }

  Future<void> reopenMoneyLoan(String loanId) async {
    final MoneyLoan? loan = await getMoneyLoan(loanId);
    if (loan == null) {
      throw StateError('Loan not found: $loanId');
    }
    if (loan.status != MoneyLoanStatus.closed) {
      throw StateError('Only closed loans can be reopened');
    }
    await (_db.update(_db.moneyLoans)..where((t) => t.id.equals(loanId))).write(
      const MoneyLoansCompanion(
        status: Value<String>('pending'),
        closedAt: Value<DateTime?>(null),
      ),
    );
  }

  Future<MoneyLoan> _mapMoneyLoan(MoneyLoanRow row) async {
    final List<MoneyLoanEntryRow> entryRows = await (_db.select(
      _db.moneyLoanEntries,
    )..where((t) => t.loanId.equals(row.id))
      ..orderBy([(t) => OrderingTerm.asc(t.entryAt)]))
        .get();
    final MoneyInterestKind legacyKind =
        MoneyInterestKind.parse(row.interestKind);
    // Prefer stored policy; fall back to legacy simple/compound mapping.
    final MoneyCapitalizationPolicy policy = row.capitalizationPolicy.isEmpty
        ? MoneyCapitalizationPolicy.fromLegacyInterestKind(legacyKind)
        : MoneyCapitalizationPolicy.parse(row.capitalizationPolicy);
    final MoneyCapitalizationCycle cycle = row.capitalizationCycle.isEmpty
        ? MoneyCapitalizationCycle.fromRatePeriod(
            MoneyRatePeriod.parse(row.ratePeriod),
          )
        : MoneyCapitalizationCycle.parse(row.capitalizationCycle);
    // Legacy rate_period=daily → yearly + daily365 (also handled by v18 migrate).
    final bool legacyDaily = row.ratePeriod == 'daily';
    final MoneyRatePeriod ratePeriod = MoneyRatePeriod.parse(row.ratePeriod);
    final MoneyInterestAccrual interestAccrual = legacyDaily
        ? MoneyInterestAccrual.daily365
        : MoneyInterestAccrual.parse(row.interestAccrual);
    return MoneyLoan(
      id: row.id,
      customerId: row.customerId,
      direction: MoneyLoanDirection.parse(row.direction),
      principalPaise: row.principalPaise,
      currencyCode: row.currencyCode,
      interestKind: legacyKind,
      rateBps: row.rateBps,
      ratePeriod: ratePeriod,
      interestAccrual: interestAccrual,
      capitalizationPolicy: policy,
      capitalizationCycle: cycle,
      interestStartedAt: row.interestStartedAt,
      interestEndedAt: row.interestEndedAt,
      prepaymentAllocation:
          MoneyPrepaymentAllocation.parse(row.prepaymentAllocation),
      status: MoneyLoanStatus.parse(row.status),
      closedAt: row.closedAt,
      note: row.note,
      createdAt: row.createdAt,
      entries: entryRows.map(_mapMoneyLoanEntry).toList(growable: false),
    );
  }

  MoneyLoanEntry _mapMoneyLoanEntry(MoneyLoanEntryRow row) {
    return MoneyLoanEntry(
      id: row.id,
      loanId: row.loanId,
      entryAt: row.entryAt,
      amountPaise: row.amountPaise,
      kind: MoneyLoanEntryKind.parse(row.kind),
      note: row.note,
    );
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
    bool requiresUnitIdentity = false,
    String? unitCodePrefix,
    bool allowsDynamicPricing = false,
    ResourceType defaultItemKind = ResourceType.rental,
    Map<String, Object?> metadata = const <String, Object?>{},
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
    final String? storedPrefix = _storedUnitCodePrefix(unitCodePrefix);
    final String stamp = _nextStamp();
    await _db.into(_db.inventoryItems).insert(
      InventoryItemsCompanion.insert(
        id: 'INV-$stamp',
        name: trimmedName,
        category: trimmedCategory,
        availableUnits: units,
        totalUnits: units,
        status: AssetStatus.available.name,
        qrCode: 'inventory:$stamp',
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
        unitCodePrefix: Value<String?>(storedPrefix),
        allowsDynamicPricing: Value<bool>(allowsDynamicPricing),
        defaultItemKind: Value<String>(defaultItemKind.storageValue),
        metadata: Value<String?>(encodeMetadata(metadata)),
      ),
    );
  }

  /// Merge selected template items into inventory. Same name (case-insensitive) is skipped.
  ///
  /// When [locale] is Hindi (`hi`), stores [TemplateInventoryItem.nameHi] /
  /// [TemplateInventoryItem.categoryHi]; otherwise English fields. Dedup uses the
  /// resolved name.
  Future<TemplateImportResult> importTemplateInventory(
    List<TemplateInventoryItem> selected, {
    Locale locale = const Locale('en'),
  }) async {
    if (selected.isEmpty) {
      return const TemplateImportResult(added: 0, skipped: 0);
    }

    final List<InventoryItem> existing = await listInventory();
    final Set<String> existingNames = existing
        .map((item) => item.name.trim().toLowerCase())
        .toSet();

    int added = 0;
    int skipped = 0;

    for (final TemplateInventoryItem raw in selected) {
      final TemplateInventoryItem item = raw.resolvedForLocale(locale);
      final String key = item.name.trim().toLowerCase();
      if (key.isEmpty || existingNames.contains(key)) {
        skipped += 1;
        continue;
      }
      final int units = item.defaultUnits < 1 ? 1 : item.defaultUnits;
      final String stamp = _nextStamp();
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
          dueDateOptional: Value<bool>(item.dueDateOptional),
          requiresUnitIdentity: Value<bool>(item.requiresUnitIdentity),
          unitCodePrefix: Value<String?>(_storedUnitCodePrefix(item.unitCodePrefix)),
          allowsDynamicPricing: const Value<bool>(false),
          defaultItemKind: Value<String>(item.defaultItemKind.storageValue),
        ),
      );
      existingNames.add(key);
      added += 1;
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
    String? unitCodePrefix,
    bool updateUnitCodePrefix = false,
    bool? allowsDynamicPricing,
    ResourceType? defaultItemKind,
    Map<String, Object?>? metadata,
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

    final Value<String?> prefixValue = updateUnitCodePrefix
        ? Value<String?>(_storedUnitCodePrefix(unitCodePrefix))
        : const Value.absent();

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
        unitCodePrefix: prefixValue,
        allowsDynamicPricing: allowsDynamicPricing == null
            ? const Value.absent()
            : Value<bool>(allowsDynamicPricing),
        defaultItemKind: defaultItemKind == null
            ? const Value.absent()
            : Value<String>(defaultItemKind.storageValue),
        metadata: metadata == null
            ? const Value.absent()
            : Value<String?>(encodeMetadata(metadata)),
      ),
    );
  }

  Future<Customer> upsertCustomerByPhone({
    required String phone,
    String? fallbackName,
  }) async {
    final String normalized = phone.trim();
    if (normalized.isEmpty) {
      throw ArgumentError('Phone is required');
    }
    if (isUnknownCustomerPhone(normalized)) {
      throw ArgumentError('Reserved phone cannot create a customer');
    }
    final Customer? existing = await customerByPhone(normalized);
    if (existing != null) {
      return existing;
    }
    final String? trimmedName = fallbackName?.trim();
    if (trimmedName == null ||
        trimmedName.isEmpty ||
        !meetsMinMeaningfulText(trimmedName)) {
      throw ArgumentError(
        'Customer name must be at least $kMinMeaningfulTextLength characters',
      );
    }
    final String stamp = _nextStamp();
    final Customer customer = Customer(
      id: 'CUS-$stamp',
      name: trimmedName,
      phone: normalized,
      isTrusted: false,
      qrCode: 'customer:$stamp',
    );
    await _db.into(_db.customers).insert(_customerCompanion(customer));
    return customer;
  }

  /// Typeahead matches by name substring and/or phone digits (min length).
  /// Excludes the Unknown sentinel so it is only chosen via the no-phone path.
  Future<List<Customer>> searchCustomersByNameOrPhone(String query) async {
    final String q = query.trim().toLowerCase();
    if (q.length < kMinMeaningfulTextLength) {
      return const <Customer>[];
    }
    final List<CustomerRow> rows = await _db.select(_db.customers).get();
    return rows
        .map(_mapCustomer)
        .where((Customer customer) {
          if (isUnknownCustomer(customer)) {
            return false;
          }
          return customer.name.toLowerCase().contains(q) ||
              customer.phone.toLowerCase().contains(q);
        })
        .toList();
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
            depositAmount: Value<int>(rental.depositAmount),
            orderStatus: Value<String>(rental.orderStatus.storageValue),
            workflowStatus: Value<String?>(rental.workflowStatus),
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
              billingMode: Value<String>(line.billingMode.name),
              rateAmount: Value<int>(line.rateAmount),
              lateFeePerDay: Value<int>(line.lateFeePerDay),
              fulfillment: Value<String>(line.fulfillment.storageValue),
              returnDisposition: Value<String?>(
                line.returnDisposition?.storageValue ??
                    (lineReturned != null && line.isRent
                        ? ReturnDisposition.returned.storageValue
                        : null),
              ),
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
        for (final RentalNote note in rental.notes) {
          await _db.into(_db.rentalNotes).insertOnConflictUpdate(
            RentalNotesCompanion.insert(
              id: note.id,
              rentalId: rental.id,
              rentalItemId: Value<String?>(note.rentalItemId),
              kind: Value<String>(note.kind.storageValue),
              body: note.body,
              createdAt: note.createdAt,
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
      unitCodePrefix: Value<String?>(_storedUnitCodePrefix(item.unitCodePrefix)),
      allowsDynamicPricing: Value<bool>(item.allowsDynamicPricing),
      defaultItemKind: Value<String>(item.defaultItemKind.storageValue),
      metadata: Value<String?>(encodeMetadata(item.metadata)),
    );
  }

  String? _storedUnitCodePrefix(String? raw) {
    final String normalized = normalizeUnitCodePrefix(raw);
    return normalized.isEmpty ? null : normalized;
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
      unitCodePrefix: row.unitCodePrefix,
      allowsDynamicPricing: row.allowsDynamicPricing,
      defaultItemKind: ResourceType.parse(row.defaultItemKind),
      metadata: decodeMetadata(row.metadata),
    );
  }

  Future<Rental> _mapRental(RentalRow row) async {
    final List<RentalItemRow> links = await (_db.select(_db.rentalItems)
          ..where((t) => t.rentalId.equals(row.id)))
        .get();
    final eventQuery = _db.select(_db.rentalEvents)..where((t) => t.rentalId.equals(row.id));
    final List<RentalEventRow> events = await eventQuery.get();
    events.sort((a, b) => b.at.compareTo(a.at));

    final List<RentalNoteRow> noteRows = await (_db.select(_db.rentalNotes)
          ..where((t) => t.rentalId.equals(row.id)))
        .get();
    noteRows.sort((a, b) {
      final int byTime = b.createdAt.compareTo(a.createdAt);
      if (byTime != 0) {
        return byTime;
      }
      return b.id.compareTo(a.id);
    });

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
          lateFeePerDay: link.lateFeePerDay,
          billingMode: BillingMode.parse(link.billingMode),
          rateAmount: link.rateAmount,
          fulfillment: LineFulfillment.parse(link.fulfillment),
          returnDisposition: ReturnDisposition.parse(link.returnDisposition),
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
      depositAmount: row.depositAmount,
      orderStatus: OrderStatus.parse(row.orderStatus),
      workflowStatus: row.workflowStatus,
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
      notes: noteRows
          .map(
            (RentalNoteRow note) => RentalNote(
              id: note.id,
              rentalId: note.rentalId,
              rentalItemId: note.rentalItemId,
              kind: RentalNoteKind.parse(note.kind),
              body: note.body,
              createdAt: note.createdAt,
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
    buildUnknownCustomer(),
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
          title: TimelineTitleKey.dueToday,
          subtitle: encodeTimelineSubtitle(TimelineSubtitleKey.autoReminder),
          at: clock.subtract(const Duration(hours: 2)),
        ),
        RentalEvent(
          title: TimelineTitleKey.rentalOpened,
          subtitle: encodeTimelineSubtitle(
            TimelineSubtitleKey.checkedOutByStaff,
          ),
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
          title: TimelineTitleKey.returned,
          subtitle: encodeTimelineSubtitle(
            TimelineSubtitleKey.closedAtCounter,
          ),
          at: clock.subtract(const Duration(days: 1)),
        ),
        RentalEvent(
          title: TimelineTitleKey.rentalOpened,
          subtitle: encodeTimelineSubtitle(TimelineSubtitleKey.manualWalkIn),
          at: clock.subtract(const Duration(days: 5)),
        ),
      ],
      qrCode: 'rental:3002',
      returnedAt: clock.subtract(const Duration(days: 1)),
      orderStatus: OrderStatus.completed,
    ),
  ];

  return AppDataSnapshot(
    customers: seedCustomers,
    inventory: seedInventory,
    rentals: seedRentals,
  );
}
