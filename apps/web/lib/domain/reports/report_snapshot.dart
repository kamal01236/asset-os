import '../inventory/unit_code_pool.dart';
import '../loans/loan_balance.dart';
import '../loans/loan_models.dart';
import '../models/entities.dart';
import 'report_models.dart';
import 'report_widgets.dart';

/// Max short-table rows on the 360° summary (preview, WhatsApp, print).
const int kReportSummaryRowCap = 15;

/// Top-customer rank size for summary utilisation.
const int kReportTopCustomerCap = 5;

/// Period vs still-out filter: [startedAt] inside [range].
bool reportWasIssuedInRange(Rental rental, ReportDateRange range) {
  return range.contains(rental.startedAt);
}

/// Period close: order [returnedAt] (return / sold / job completed) inside [range].
bool reportWasClosedInRange(Rental rental, ReportDateRange range) {
  final DateTime? closed = rental.returnedAt;
  return closed != null && range.contains(closed);
}

/// Line close date inside [range] (partial returns / sold / completed jobs).
bool reportLineWasClosedInRange(RentalLine line, ReportDateRange range) {
  final DateTime? closed = line.returnedAt;
  return closed != null && range.contains(closed);
}

/// Open as of [asOf]: started on/before [asOf] and not yet closed (or closed after).
/// Cancelled orders are never still out. Idle catalog is not represented here.
bool reportIsStillOutAsOf(Rental rental, DateTime asOf) {
  if (rental.orderStatus == OrderStatus.cancelled) {
    return false;
  }
  if (rental.startedAt.isAfter(asOf)) {
    return false;
  }
  final DateTime? closed = rental.returnedAt;
  if (closed == null) {
    return rental.isActive;
  }
  return closed.isAfter(asOf);
}

/// Unit/line still out as of [asOf] (historical-safe).
bool reportLineIsOutAsOf({
  required RentalLine line,
  required Rental rental,
  required DateTime asOf,
}) {
  if (rental.orderStatus == OrderStatus.cancelled) {
    return false;
  }
  if (rental.startedAt.isAfter(asOf)) {
    return false;
  }
  final DateTime? closed = line.returnedAt;
  return closed == null || closed.isAfter(asOf);
}

/// Status for an order that is still out as of [asOf].
AssetStatus reportStatusAsOf(Rental rental, DateTime asOf) {
  if (!reportIsStillOutAsOf(rental, asOf)) {
    if (rental.orderStatus == OrderStatus.cancelled) {
      return AssetStatus.archived;
    }
    return AssetStatus.available;
  }
  final DateTime? due = rental.dueAt;
  if (due == null) {
    return AssetStatus.rented;
  }
  if (due.year == asOf.year && due.month == asOf.month && due.day == asOf.day) {
    return AssetStatus.dueToday;
  }
  if (due.isBefore(asOf)) {
    return AssetStatus.overdue;
  }
  return AssetStatus.rented;
}

AssetStatus reportWorseStatus(AssetStatus a, AssetStatus b) {
  int rank(AssetStatus s) {
    switch (s) {
      case AssetStatus.overdue:
        return 4;
      case AssetStatus.dueToday:
        return 3;
      case AssetStatus.rented:
        return 2;
      case AssetStatus.available:
        return 1;
      case AssetStatus.archived:
        return 0;
    }
  }

  return rank(a) >= rank(b) ? a : b;
}

/// One order row for issued / returned / still-out tables.
class ReportOrderRow {
  const ReportOrderRow({
    required this.rentalId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.itemsLabel,
    required this.amountPaise,
    required this.status,
    required this.orderStatus,
    required this.startedAt,
    this.nickname,
    this.dueAt,
    this.returnedAt,
    this.depositAppliedPaise = 0,
    this.sellPaidPaise = 0,
  });

  final String rentalId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String? nickname;
  final String itemsLabel;
  final int amountPaise;
  final AssetStatus status;
  final OrderStatus orderStatus;
  final DateTime startedAt;
  final DateTime? dueAt;
  final DateTime? returnedAt;
  final int depositAppliedPaise;
  final int sellPaidPaise;
}

/// Customer-wise period aggregate (issued/returned in range only).
class ReportCustomerRow {
  const ReportCustomerRow({
    required this.customerId,
    required this.name,
    required this.phone,
    required this.issuedCount,
    required this.returnedCount,
    required this.amountPaise,
    required this.depositBalancePaise,
    this.periodStatus,
  });

  final String customerId;
  final String name;
  final String phone;
  final int issuedCount;
  final int returnedCount;
  final int amountPaise;
  final int depositBalancePaise;
  final AssetStatus? periodStatus;
}

class ReportTopCustomerRow {
  const ReportTopCustomerRow({
    required this.customerId,
    required this.name,
    required this.phone,
    required this.orderCount,
    required this.chargesPaise,
  });

  final String customerId;
  final String name;
  final String phone;
  final int orderCount;
  final int chargesPaise;
}

class ReportResourceRow {
  const ReportResourceRow({
    required this.itemId,
    required this.name,
    required this.issuedCount,
    required this.returnedCount,
    required this.outCount,
    required this.availableUnits,
    required this.totalUnits,
  });

  final String itemId;
  final String name;
  final int issuedCount;
  final int returnedCount;
  final int outCount;
  final int availableUnits;
  final int totalUnits;
}

class ReportOccupancyUnit {
  const ReportOccupancyUnit({
    required this.code,
    required this.holderName,
  });

  final String code;
  final String holderName;
}

class ReportOccupancyPool {
  const ReportOccupancyPool({
    required this.itemName,
    required this.outCount,
    required this.totalUnits,
    required this.units,
  });

  final String itemName;
  final int outCount;
  final int totalUnits;
  final List<ReportOccupancyUnit> units;
}

class ReportLoanRow {
  const ReportLoanRow({
    required this.loanId,
    required this.customerName,
    required this.pendingPaise,
    required this.currencyCode,
  });

  final String loanId;
  final String customerName;
  final int pendingPaise;
  final String currencyCode;
}

/// Structured report input. Presentation must not re-filter entities.
class ReportSnapshot {
  const ReportSnapshot({
    required this.type,
    required this.range,
    required this.asOf,
    required this.widgets,
    required this.issued,
    required this.returned,
    required this.stillOut,
    required this.overdueCount,
    required this.chargesOpenedPaise,
    required this.chargesReturnedPaise,
    required this.depositAppliedPaise,
    required this.sellCollectedPaise,
    required this.balanceDueReturnedPaise,
    required this.customersPeriod,
    required this.topCustomers,
    required this.resources,
    required this.occupancy,
    required this.loansGiven,
    required this.loansTaken,
  });

  final ReportType type;
  final ReportDateRange range;
  final DateTime asOf;
  final List<ReportWidgetId> widgets;
  final List<ReportOrderRow> issued;
  final List<ReportOrderRow> returned;
  final List<ReportOrderRow> stillOut;
  final int overdueCount;
  final int chargesOpenedPaise;
  final int chargesReturnedPaise;
  final int depositAppliedPaise;
  final int sellCollectedPaise;
  final int balanceDueReturnedPaise;
  final List<ReportCustomerRow> customersPeriod;
  final List<ReportTopCustomerRow> topCustomers;
  final List<ReportResourceRow> resources;
  final List<ReportOccupancyPool> occupancy;
  final List<ReportLoanRow> loansGiven;
  final List<ReportLoanRow> loansTaken;

  bool hasWidget(ReportWidgetId id) => widgets.contains(id);

  int get pendingLoansCount => loansGiven.length + loansTaken.length;

  /// Build period + still-out buckets. Does not localize.
  factory ReportSnapshot.assemble({
    required ReportType type,
    required ReportDateRange range,
    required List<Customer> customers,
    required List<InventoryItem> inventory,
    required List<Rental> rentals,
    List<MoneyLoan> moneyLoans = const <MoneyLoan>[],
    List<ReportWidgetId>? widgets,
  }) {
    final DateTime asOf = range.end;
    final List<ReportWidgetId> resolved =
        widgets ?? List<ReportWidgetId>.from(kDefaultReportWidgets);
    final Map<String, Customer> customersById = <String, Customer>{
      for (final Customer c in customers) c.id: c,
    };
    final Map<String, InventoryItem> itemsById = <String, InventoryItem>{
      for (final InventoryItem i in inventory) i.id: i,
    };

    final List<Rental> issuedRentals = rentals
        .where((Rental r) => reportWasIssuedInRange(r, range))
        .toList(growable: false);
    final List<Rental> returnedRentals = rentals
        .where((Rental r) => reportWasClosedInRange(r, range))
        .toList(growable: false);
    final List<Rental> stillOutRentals = rentals
        .where((Rental r) => reportIsStillOutAsOf(r, asOf))
        .toList(growable: false);

    final List<ReportOrderRow> issued = issuedRentals
        .map(
          (Rental r) => _orderRow(
            rental: r,
            customersById: customersById,
            itemsById: itemsById,
            asOf: asOf,
            amountPaise: r.isActive ? r.totalAmountAsOf(asOf) : r.totalAmount,
          ),
        )
        .toList(growable: false);
    final List<ReportOrderRow> returned = returnedRentals
        .map(
          (Rental r) => _orderRow(
            rental: r,
            customersById: customersById,
            itemsById: itemsById,
            asOf: asOf,
            amountPaise: r.totalAmount,
          ),
        )
        .toList(growable: false);
    final List<ReportOrderRow> stillOut = stillOutRentals
        .map(
          (Rental r) => _orderRow(
            rental: r,
            customersById: customersById,
            itemsById: itemsById,
            asOf: asOf,
            amountPaise: r.totalAmountAsOf(asOf),
          ),
        )
        .toList(growable: false);

    int overdueCount = 0;
    for (final Rental r in stillOutRentals) {
      if (reportStatusAsOf(r, asOf) == AssetStatus.overdue) {
        overdueCount++;
      }
    }

    int chargesOpened = 0;
    int sellCollected = 0;
    for (final Rental r in issuedRentals) {
      chargesOpened += r.baseAmount;
      sellCollected += r.sellPaidPaise;
    }
    int chargesReturned = 0;
    int depositApplied = 0;
    int balanceDue = 0;
    for (final Rental r in returnedRentals) {
      chargesReturned += r.totalAmount;
      depositApplied += r.depositApplied;
      balanceDue += r.amountDueAfterDeposit;
    }

    return ReportSnapshot(
      type: type,
      range: range,
      asOf: asOf,
      widgets: resolved,
      issued: issued,
      returned: returned,
      stillOut: stillOut,
      overdueCount: overdueCount,
      chargesOpenedPaise: chargesOpened,
      chargesReturnedPaise: chargesReturned,
      depositAppliedPaise: depositApplied,
      sellCollectedPaise: sellCollected,
      balanceDueReturnedPaise: balanceDue,
      customersPeriod: _assembleCustomersPeriod(
        issuedRentals: issuedRentals,
        returnedRentals: returnedRentals,
        customersById: customersById,
        asOf: asOf,
      ),
      topCustomers: _assembleTopCustomers(
        issuedRentals: issuedRentals,
        returnedRentals: returnedRentals,
        customersById: customersById,
        asOf: asOf,
      ),
      resources: _assembleResources(
        inventory: inventory,
        rentals: rentals,
        range: range,
        asOf: asOf,
      ),
      occupancy: _assembleOccupancy(
        customersById: customersById,
        inventory: inventory,
        rentals: rentals,
        asOf: asOf,
      ),
      loansGiven: _assembleLoans(
        customersById: customersById,
        moneyLoans: moneyLoans,
        direction: MoneyLoanDirection.given,
        asOf: asOf,
      ),
      loansTaken: _assembleLoans(
        customersById: customersById,
        moneyLoans: moneyLoans,
        direction: MoneyLoanDirection.taken,
        asOf: asOf,
      ),
    );
  }
}

ReportOrderRow _orderRow({
  required Rental rental,
  required Map<String, Customer> customersById,
  required Map<String, InventoryItem> itemsById,
  required DateTime asOf,
  required int amountPaise,
}) {
  final Customer? customer = customersById[rental.customerId];
  return ReportOrderRow(
    rentalId: rental.id,
    customerId: rental.customerId,
    customerName: customer?.name ?? rental.customerId,
    customerPhone: customer?.phone ?? '',
    nickname: rental.nickname,
    itemsLabel: _itemsLabel(rental, itemsById),
    amountPaise: amountPaise,
    status: reportStatusAsOf(rental, asOf),
    orderStatus: rental.orderStatus,
    startedAt: rental.startedAt,
    dueAt: rental.dueAt,
    returnedAt: rental.returnedAt,
    depositAppliedPaise: rental.depositApplied,
    sellPaidPaise: rental.sellPaidPaise,
  );
}

String _itemsLabel(Rental rental, Map<String, InventoryItem> itemsById) {
  return rental.lines
      .map((RentalLine line) {
        if (line.catalogName.trim().isNotEmpty) {
          return line.displayLabel;
        }
        final String fallback = itemsById[line.itemId]?.name ?? line.itemId;
        return RentalLine(
          id: line.id,
          itemId: line.itemId,
          catalogName: fallback,
          instanceName: line.instanceName,
          shortCode: line.shortCode,
          returnedAt: line.returnedAt,
          fulfillment: line.fulfillment,
        ).displayLabel;
      })
      .join(', ');
}

List<ReportCustomerRow> _assembleCustomersPeriod({
  required List<Rental> issuedRentals,
  required List<Rental> returnedRentals,
  required Map<String, Customer> customersById,
  required DateTime asOf,
}) {
  final Set<String> issuedIds = issuedRentals.map((Rental r) => r.id).toSet();
  final Map<String, _CustomerAgg> aggs = <String, _CustomerAgg>{};

  _CustomerAgg aggFor(String customerId) {
    return aggs.putIfAbsent(customerId, () {
      final Customer? customer = customersById[customerId];
      return _CustomerAgg(
        customerId: customerId,
        name: customer?.name ?? customerId,
        phone: customer?.phone ?? '',
        depositBalancePaise: customer?.depositBalance ?? 0,
      );
    });
  }

  for (final Rental r in issuedRentals) {
    final _CustomerAgg agg = aggFor(r.customerId);
    agg.issuedCount++;
    final bool closedInSamePass =
        returnedRentals.any((Rental o) => o.id == r.id);
    if (!closedInSamePass) {
      agg.amountPaise += r.isActive ? r.totalAmountAsOf(asOf) : r.totalAmount;
    }
    if (reportIsStillOutAsOf(r, asOf)) {
      final AssetStatus status = reportStatusAsOf(r, asOf);
      agg.periodStatus = agg.periodStatus == null
          ? status
          : reportWorseStatus(agg.periodStatus!, status);
    }
  }
  for (final Rental r in returnedRentals) {
    final _CustomerAgg agg = aggFor(r.customerId);
    agg.returnedCount++;
    agg.amountPaise += r.totalAmount;
    if (!issuedIds.contains(r.id) && agg.periodStatus == null) {
      agg.periodStatus = AssetStatus.available;
    }
  }

  final List<ReportCustomerRow> rows = aggs.values
      .map(
        ( _CustomerAgg a) => ReportCustomerRow(
          customerId: a.customerId,
          name: a.name,
          phone: a.phone,
          issuedCount: a.issuedCount,
          returnedCount: a.returnedCount,
          amountPaise: a.amountPaise,
          depositBalancePaise: a.depositBalancePaise,
          periodStatus: a.periodStatus,
        ),
      )
      .toList()
    ..sort((ReportCustomerRow a, ReportCustomerRow b) => a.name.compareTo(b.name));
  return rows;
}

class _CustomerAgg {
  _CustomerAgg({
    required this.customerId,
    required this.name,
    required this.phone,
    required this.depositBalancePaise,
  });

  final String customerId;
  final String name;
  final String phone;
  final int depositBalancePaise;
  int issuedCount = 0;
  int returnedCount = 0;
  int amountPaise = 0;
  AssetStatus? periodStatus;
}

List<ReportTopCustomerRow> _assembleTopCustomers({
  required List<Rental> issuedRentals,
  required List<Rental> returnedRentals,
  required Map<String, Customer> customersById,
  required DateTime asOf,
}) {
  final Map<String, int> counts = <String, int>{};
  final Map<String, int> charges = <String, int>{};
  final Set<String> seen = <String>{};

  void add(Rental r, int amount) {
    if (!seen.add(r.id)) {
      return;
    }
    counts[r.customerId] = (counts[r.customerId] ?? 0) + 1;
    charges[r.customerId] = (charges[r.customerId] ?? 0) + amount;
  }

  for (final Rental r in issuedRentals) {
    final bool alsoReturned = returnedRentals.any((Rental o) => o.id == r.id);
    add(r, alsoReturned ? r.totalAmount : (r.isActive ? r.totalAmountAsOf(asOf) : r.totalAmount));
  }
  for (final Rental r in returnedRentals) {
    add(r, r.totalAmount);
  }
  if (counts.isEmpty) {
    return const <ReportTopCustomerRow>[];
  }
  final List<String> ranked = counts.keys.toList()
    ..sort((String a, String b) {
      final int byCount = (counts[b] ?? 0).compareTo(counts[a] ?? 0);
      if (byCount != 0) {
        return byCount;
      }
      return (charges[b] ?? 0).compareTo(charges[a] ?? 0);
    });
  return ranked.take(kReportTopCustomerCap).map((String id) {
    final Customer? customer = customersById[id];
    return ReportTopCustomerRow(
      customerId: id,
      name: customer?.name ?? id,
      phone: customer?.phone ?? '',
      orderCount: counts[id] ?? 0,
      chargesPaise: charges[id] ?? 0,
    );
  }).toList(growable: false);
}

List<ReportResourceRow> _assembleResources({
  required List<InventoryItem> inventory,
  required List<Rental> rentals,
  required ReportDateRange range,
  required DateTime asOf,
}) {
  if (inventory.isEmpty) {
    return const <ReportResourceRow>[];
  }
  final Map<String, int> issued = <String, int>{};
  final Map<String, int> returned = <String, int>{};
  final Map<String, int> out = <String, int>{};
  for (final Rental rental in rentals) {
    final bool issuedInRange = reportWasIssuedInRange(rental, range);
    for (final RentalLine line in rental.lines) {
      if (issuedInRange) {
        issued[line.itemId] = (issued[line.itemId] ?? 0) + 1;
      }
      if (reportLineWasClosedInRange(line, range)) {
        returned[line.itemId] = (returned[line.itemId] ?? 0) + 1;
      }
      if (reportLineIsOutAsOf(line: line, rental: rental, asOf: asOf)) {
        out[line.itemId] = (out[line.itemId] ?? 0) + 1;
      }
    }
  }
  final List<ReportResourceRow> rows = <ReportResourceRow>[];
  for (final InventoryItem item in inventory) {
    final int issuedCount = issued[item.id] ?? 0;
    final int returnedCount = returned[item.id] ?? 0;
    final int outCount = out[item.id] ?? 0;
    if (issuedCount == 0 && returnedCount == 0 && outCount == 0) {
      continue;
    }
    rows.add(
      ReportResourceRow(
        itemId: item.id,
        name: item.name,
        issuedCount: issuedCount,
        returnedCount: returnedCount,
        outCount: outCount,
        availableUnits: item.availableUnits,
        totalUnits: item.totalUnits,
      ),
    );
  }
  rows.sort((ReportResourceRow a, ReportResourceRow b) {
    final int byOut = b.outCount.compareTo(a.outCount);
    if (byOut != 0) {
      return byOut;
    }
    final int byIssued = b.issuedCount.compareTo(a.issuedCount);
    if (byIssued != 0) {
      return byIssued;
    }
    return a.name.compareTo(b.name);
  });
  return rows;
}

List<ReportOccupancyPool> _assembleOccupancy({
  required Map<String, Customer> customersById,
  required List<InventoryItem> inventory,
  required List<Rental> rentals,
  required DateTime asOf,
}) {
  final Map<String, ({String customerId, String instanceName})> occupiedByCode =
      <String, ({String customerId, String instanceName})>{};
  for (final Rental rental in rentals) {
    for (final RentalLine line in rental.lines) {
      if (!line.isRent) {
        continue;
      }
      if (!reportLineIsOutAsOf(line: line, rental: rental, asOf: asOf)) {
        continue;
      }
      final String code = line.shortCode.trim().toUpperCase();
      if (code.isEmpty) {
        continue;
      }
      occupiedByCode[code] = (
        customerId: rental.customerId,
        instanceName: line.instanceName,
      );
    }
  }

  final List<InventoryItem> poolItems = inventory
      .where((InventoryItem i) => i.hasUnitCodePool)
      .toList()
    ..sort((InventoryItem a, InventoryItem b) => a.name.compareTo(b.name));

  final List<ReportOccupancyPool> pools = <ReportOccupancyPool>[];
  for (final InventoryItem item in poolItems) {
    final List<String> pool = generateUnitPool(
      prefix: item.unitCodePrefix!,
      total: item.totalUnits,
    );
    final List<ReportOccupancyUnit> units = <ReportOccupancyUnit>[];
    for (final String code in pool) {
      final occupied = occupiedByCode[code];
      if (occupied == null) {
        continue;
      }
      final Customer? customer = customersById[occupied.customerId];
      final String who = customer?.name.trim().isNotEmpty == true
          ? customer!.name
          : (occupied.instanceName.trim().isNotEmpty
              ? occupied.instanceName
              : occupied.customerId);
      units.add(ReportOccupancyUnit(code: code, holderName: who));
    }
    if (units.isEmpty) {
      continue;
    }
    pools.add(
      ReportOccupancyPool(
        itemName: item.name,
        outCount: units.length,
        totalUnits: item.totalUnits,
        units: units,
      ),
    );
  }
  return pools;
}

List<ReportLoanRow> _assembleLoans({
  required Map<String, Customer> customersById,
  required List<MoneyLoan> moneyLoans,
  required MoneyLoanDirection direction,
  required DateTime asOf,
}) {
  final List<ReportLoanRow> rows = <ReportLoanRow>[];
  for (final MoneyLoan loan in moneyLoans) {
    if (loan.status != MoneyLoanStatus.pending || loan.direction != direction) {
      continue;
    }
    final LoanScenario scenario = computeLoanScenario(loan: loan, now: asOf);
    final Customer? customer = customersById[loan.customerId];
    rows.add(
      ReportLoanRow(
        loanId: loan.id,
        customerName: customer?.name ?? loan.customerId,
        pendingPaise: scenario.pendingPaise,
        currencyCode: loan.currencyCode,
      ),
    );
  }
  return rows;
}
