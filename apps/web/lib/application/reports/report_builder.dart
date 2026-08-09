import 'package:flutter/widgets.dart';

import '../config/app_branding.dart';
import '../inventory/unit_code_pool.dart';
import '../l10n/india_date_format.dart';
import '../l10n/l10n_ext.dart';
import '../loans/loan_balance.dart';
import '../loans/loan_models.dart';
import '../models/entities.dart';
import '../pricing/rental_pricing.dart';
import 'report_models.dart';
import 'report_widgets.dart';

/// Soft cap for WhatsApp URL length; longer text is truncated with a note.
const int kReportMaxChars = 3500;

/// Builds plain-text business reports from local Drift-backed entities.
class ReportBuilder {
  const ReportBuilder({
    this.appName = kAppDisplayName,
    this.maxChars = kReportMaxChars,
  });

  final String appName;
  final int maxChars;

  /// Legacy type-based entry; [ReportType.summary] uses [widgets].
  String build({
    required AppLocalizations l10n,
    required ReportType type,
    required ReportDateRange range,
    required List<Customer> customers,
    required List<InventoryItem> inventory,
    required List<Rental> rentals,
    DateTime? now,
    List<ReportWidgetId>? widgets,
    Locale locale = const Locale('en'),
    List<MoneyLoan> moneyLoans = const <MoneyLoan>[],
  }) {
    final DateTime clock = now ?? range.end;
    final String body;
    switch (type) {
      case ReportType.summary:
        body = buildFromWidgets(
          l10n: l10n,
          locale: locale,
          widgets: widgets ?? kDefaultReportWidgets,
          range: range,
          customers: customers,
          inventory: inventory,
          rentals: rentals,
          moneyLoans: moneyLoans,
          now: clock,
          includeTypeHeading: true,
        );
      case ReportType.customerWise:
        body = _buildCustomerWise(l10n, range, customers, inventory, rentals, clock);
      case ReportType.inventoryWise:
        body = _buildInventoryWise(l10n, range, inventory, rentals);
      case ReportType.unitOccupancy:
        body = _buildUnitOccupancy(l10n, customers, inventory, rentals);
    }
    final String header =
        '${l10n.reportHeader(appName)}\n${formatIndiaDate(range.start)} → ${formatIndiaDate(range.end)}\n';
    return _truncate(l10n, '$header\n$body'.trimRight());
  }

  /// Compose a report body from ordered [widgets] (no header).
  String buildFromWidgets({
    required AppLocalizations l10n,
    required List<ReportWidgetId> widgets,
    required ReportDateRange range,
    required List<Customer> customers,
    required List<InventoryItem> inventory,
    required List<Rental> rentals,
    DateTime? now,
    Locale locale = const Locale('en'),
    bool includeTypeHeading = false,
    List<MoneyLoan> moneyLoans = const <MoneyLoan>[],
  }) {
    final DateTime clock = now ?? range.end;
    final List<String> sections = <String>[];
    if (includeTypeHeading) {
      sections.add(l10n.reportTypeSummary);
    }
    for (final ReportWidgetId id in widgets) {
      final String section = _buildWidget(
        id: id,
        l10n: l10n,
        locale: locale,
        range: range,
        customers: customers,
        inventory: inventory,
        rentals: rentals,
        moneyLoans: moneyLoans,
        clock: clock,
      );
      if (section.trim().isNotEmpty) {
        sections.add(section);
      }
    }
    return sections.join('\n\n');
  }

  String _buildWidget({
    required ReportWidgetId id,
    required AppLocalizations l10n,
    required Locale locale,
    required ReportDateRange range,
    required List<Customer> customers,
    required List<InventoryItem> inventory,
    required List<Rental> rentals,
    required List<MoneyLoan> moneyLoans,
    required DateTime clock,
  }) {
    final ReportWidgetDef? def = reportWidgetDefById(id);
    final String title = def?.localizedLabel(locale) ?? id.name;
    switch (id) {
      case ReportWidgetId.summaryRevenue:
        return <String>[
          title,
          l10n.reportChargesOpened(formatMoney(_sumOpenedCharges(rentals, range))),
          l10n.reportChargesReturned(
            formatMoney(_sumReturnedCharges(rentals, range)),
          ),
          l10n.reportDepositAppliedRange(
            formatMoney(_sumDepositApplied(rentals, range)),
          ),
          l10n.reportBalanceDueReturned(
            formatMoney(_sumBalanceDue(rentals, range)),
          ),
        ].join('\n');
      case ReportWidgetId.transactionsToday:
        final int active = rentals.where((Rental r) => r.isActive).length;
        final int opened =
            rentals.where((Rental r) => _inRange(r.startedAt, range)).length;
        final int returned = rentals
            .where(
              (Rental r) =>
                  r.returnedAt != null && _inRange(r.returnedAt!, range),
            )
            .length;
        final int pendingLoans = moneyLoans
            .where((MoneyLoan l) => l.status == MoneyLoanStatus.pending)
            .length;
        return <String>[
          title,
          l10n.reportActiveCount(active),
          l10n.reportOpenedCount(opened),
          l10n.reportReturnedCount(returned),
          if (moneyLoans.isNotEmpty) l10n.reportPendingLoansCount(pendingLoans),
        ].join('\n');
      case ReportWidgetId.overdue:
        final int overdue = rentals
            .where((Rental r) => r.statusFor(clock) == AssetStatus.overdue)
            .length;
        return <String>[
          title,
          l10n.reportOverdueCount(overdue),
        ].join('\n');
      case ReportWidgetId.topCustomers:
        return _buildTopCustomers(
          title: title,
          l10n: l10n,
          range: range,
          customers: customers,
          rentals: rentals,
          clock: clock,
        );
      case ReportWidgetId.resourcesUtilisation:
        return _buildResourcesUtilisation(
          title: title,
          l10n: l10n,
          range: range,
          inventory: inventory,
          rentals: rentals,
        );
      case ReportWidgetId.outstandingLoansGiven:
        return _buildOutstandingLoans(
          title: title,
          l10n: l10n,
          customers: customers,
          moneyLoans: moneyLoans,
          direction: MoneyLoanDirection.given,
          clock: clock,
        );
      case ReportWidgetId.outstandingLoansTaken:
        return _buildOutstandingLoans(
          title: title,
          l10n: l10n,
          customers: customers,
          moneyLoans: moneyLoans,
          direction: MoneyLoanDirection.taken,
          clock: clock,
        );
      case ReportWidgetId.unitOccupancy:
        return _buildUnitOccupancy(
          l10n,
          customers,
          inventory,
          rentals,
          title: title,
        );
    }
  }

  String _buildOutstandingLoans({
    required String title,
    required AppLocalizations l10n,
    required List<Customer> customers,
    required List<MoneyLoan> moneyLoans,
    required MoneyLoanDirection direction,
    required DateTime clock,
  }) {
    final Map<String, Customer> byId = <String, Customer>{
      for (final Customer c in customers) c.id: c,
    };
    final List<MoneyLoan> pending = moneyLoans
        .where(
          (MoneyLoan l) =>
              l.status == MoneyLoanStatus.pending && l.direction == direction,
        )
        .toList();
    if (pending.isEmpty) {
      return '$title\n${l10n.reportNoOutstandingLoans}';
    }
    int totalPending = 0;
    final List<String> lines = <String>[title];
    for (final MoneyLoan loan in pending) {
      final LoanScenario scenario =
          computeLoanScenario(loan: loan, now: clock);
      totalPending += scenario.pendingPaise;
      final Customer? customer = byId[loan.customerId];
      final String name = customer?.name ?? loan.customerId;
      lines.add(
        '• $name: ${formatMoney(scenario.pendingPaise, currencyCode: loan.currencyCode)}',
      );
    }
    lines.insert(
      1,
      l10n.reportOutstandingLoansTotal(
        formatMoney(totalPending),
        pending.length,
      ),
    );
    return lines.join('\n');
  }

  String _buildTopCustomers({
    required String title,
    required AppLocalizations l10n,
    required ReportDateRange range,
    required List<Customer> customers,
    required List<Rental> rentals,
    required DateTime clock,
  }) {
    final Map<String, Customer> byId = <String, Customer>{
      for (final Customer c in customers) c.id: c,
    };
    final Map<String, int> counts = <String, int>{};
    final Map<String, int> charges = <String, int>{};
    for (final Rental r in rentals) {
      final bool inScope = _inRange(r.startedAt, range) ||
          (r.returnedAt != null && _inRange(r.returnedAt!, range)) ||
          (r.isActive && !r.startedAt.isAfter(range.end));
      if (!inScope) {
        continue;
      }
      counts[r.customerId] = (counts[r.customerId] ?? 0) + 1;
      final int amount =
          r.isActive ? r.totalAmountAsOf(clock) : r.totalAmount;
      charges[r.customerId] = (charges[r.customerId] ?? 0) + amount;
    }
    if (counts.isEmpty) {
      return '$title\n${l10n.reportNoRentalsInRange}';
    }
    final List<String> ranked = counts.keys.toList()
      ..sort((String a, String b) {
        final int byCount = (counts[b] ?? 0).compareTo(counts[a] ?? 0);
        if (byCount != 0) {
          return byCount;
        }
        return (charges[b] ?? 0).compareTo(charges[a] ?? 0);
      });
    final List<String> lines = <String>[title];
    for (final String customerId in ranked.take(5)) {
      final Customer? customer = byId[customerId];
      final String name = customer?.name ?? customerId;
      final String phone = customer?.phone ?? '';
      final String header = phone.isEmpty ? name : '$name ($phone)';
      lines.add(
        '• $header: ${counts[customerId]} · ${formatMoney(charges[customerId] ?? 0)}',
      );
    }
    return lines.join('\n');
  }

  String _buildResourcesUtilisation({
    required String title,
    required AppLocalizations l10n,
    required ReportDateRange range,
    required List<InventoryItem> inventory,
    required List<Rental> rentals,
  }) {
    if (inventory.isEmpty) {
      return '$title\n${l10n.reportNoResources}';
    }
    final List<Rental> openedInRange =
        rentals.where((Rental r) => _inRange(r.startedAt, range)).toList();
    final Map<String, int> rentCount = <String, int>{
      for (final InventoryItem i in inventory) i.id: 0,
    };
    final Map<String, int> unitsOut = <String, int>{
      for (final InventoryItem i in inventory) i.id: 0,
    };
    for (final Rental rental in openedInRange) {
      for (final RentalLine line in rental.lines) {
        rentCount[line.itemId] = (rentCount[line.itemId] ?? 0) + 1;
      }
    }
    for (final Rental rental in rentals.where((Rental r) => r.isActive)) {
      for (final RentalLine line in rental.openLines) {
        unitsOut[line.itemId] = (unitsOut[line.itemId] ?? 0) + 1;
      }
    }
    final List<InventoryItem> sorted = List<InventoryItem>.from(inventory)
      ..sort((InventoryItem a, InventoryItem b) {
        final int byOut =
            (unitsOut[b.id] ?? 0).compareTo(unitsOut[a.id] ?? 0);
        if (byOut != 0) {
          return byOut;
        }
        return (rentCount[b.id] ?? 0).compareTo(rentCount[a.id] ?? 0);
      });
    final List<String> lines = <String>[title];
    for (final InventoryItem item in sorted.take(8)) {
      lines.add(
        l10n.reportInventoryItemLine(
          item.name,
          rentCount[item.id] ?? 0,
          unitsOut[item.id] ?? 0,
          item.availableUnits,
          item.totalUnits,
          localizedBillingMode(l10n, item.billingMode),
          formatMoney(item.rateAmount, currencyCode: item.currencyCode),
        ),
      );
    }
    return lines.join('\n');
  }

  int _sumOpenedCharges(List<Rental> rentals, ReportDateRange range) {
    int total = 0;
    for (final Rental r in rentals) {
      if (_inRange(r.startedAt, range)) {
        total += r.baseAmount;
      }
    }
    return total;
  }

  int _sumReturnedCharges(List<Rental> rentals, ReportDateRange range) {
    int total = 0;
    for (final Rental r in rentals) {
      if (r.returnedAt != null && _inRange(r.returnedAt!, range)) {
        total += r.totalAmount;
      }
    }
    return total;
  }

  int _sumDepositApplied(List<Rental> rentals, ReportDateRange range) {
    int total = 0;
    for (final Rental r in rentals) {
      if (r.returnedAt != null && _inRange(r.returnedAt!, range)) {
        total += r.depositApplied;
      }
    }
    return total;
  }

  int _sumBalanceDue(List<Rental> rentals, ReportDateRange range) {
    int total = 0;
    for (final Rental r in rentals) {
      if (r.returnedAt != null && _inRange(r.returnedAt!, range)) {
        total += r.amountDueAfterDeposit;
      }
    }
    return total;
  }

  String _buildCustomerWise(
    AppLocalizations l10n,
    ReportDateRange range,
    List<Customer> customers,
    List<InventoryItem> inventory,
    List<Rental> rentals,
    DateTime clock,
  ) {
    final Map<String, Customer> byId = <String, Customer>{
      for (final Customer c in customers) c.id: c,
    };
    final Map<String, InventoryItem> itemsById = <String, InventoryItem>{
      for (final InventoryItem i in inventory) i.id: i,
    };

    final List<Rental> inScope = rentals.where((Rental r) {
      if (_inRange(r.startedAt, range)) {
        return true;
      }
      if (r.returnedAt != null && _inRange(r.returnedAt!, range)) {
        return true;
      }
      // Active rentals that overlap the window (due/open during period).
      if (r.isActive && !r.startedAt.isAfter(range.end)) {
        return true;
      }
      return false;
    }).toList();

    final Map<String, List<Rental>> byCustomer = <String, List<Rental>>{};
    for (final Rental r in inScope) {
      byCustomer.putIfAbsent(r.customerId, () => <Rental>[]).add(r);
    }

    if (byCustomer.isEmpty) {
      return '${l10n.reportTypeCustomerWise}\n${l10n.reportNoRentalsInRange}';
    }

    final List<String> lines = <String>[l10n.reportTypeCustomerWise];
    final List<String> customerIds = byCustomer.keys.toList()..sort();
    for (final String customerId in customerIds) {
      final Customer? customer = byId[customerId];
      final String name = customer?.name ?? customerId;
      final String phone = customer?.phone ?? '';
      lines.add('');
      final String header = phone.isEmpty ? name : '$name ($phone)';
      final int deposit = customer?.depositBalance ?? 0;
      lines.add(
        deposit > 0
            ? l10n.reportCustomerWithDeposit(header, formatMoney(deposit))
            : header,
      );
      for (final Rental rental in byCustomer[customerId]!) {
        final String itemNames = rental.lines
            .map((RentalLine line) {
              final String statusBit = line.isOpen
                  ? ''
                  : ' ${_reportClosedLineStatusBit(l10n, line)}';
              if (line.catalogName.trim().isEmpty) {
                final String fallback =
                    itemsById[line.itemId]?.name ?? line.itemId;
                return '${RentalLine(
                  id: line.id,
                  itemId: line.itemId,
                  catalogName: fallback,
                  instanceName: line.instanceName,
                  shortCode: line.shortCode,
                ).displayLabel}$statusBit';
              }
              return '${line.displayLabel}$statusBit';
            })
            .join(', ');
        final AssetStatus status = rental.statusFor(clock);
        final String nick = rental.nickname?.trim() ?? '';
        final String prefix = nick.isNotEmpty ? '$nick — ' : '';
        final int amount = rental.isActive
            ? rental.totalAmountAsOf(clock)
            : rental.totalAmount;
        final int openCount = rental.openLines.length;
        final int returnedCount = rental.returnedLines.length;
        final String partialBit = rental.isActive && returnedCount > 0
            ? l10n.reportLinesPartialBit(openCount, returnedCount)
            : '';
        final String depositBit = rental.depositApplied > 0
            ? l10n.reportDepositDueBit(
                formatMoney(rental.depositApplied),
                formatMoney(rental.amountDueAfterDeposit),
              )
            : '';
        final String dueBit = rental.dueAt == null
            ? l10n.reportOpenEnded
            : l10n.reportDueDateBit(formatIndiaDate(rental.dueAt!));
        lines.add(
          l10n.reportCustomerRentalLine(
            prefix,
            rental.id,
            itemNames,
            dueBit,
            localizedStatusLabel(l10n, status),
            formatMoney(amount),
            partialBit,
            depositBit,
          ),
        );
      }
    }
    return lines.join('\n');
  }

  String _buildInventoryWise(
    AppLocalizations l10n,
    ReportDateRange range,
    List<InventoryItem> inventory,
    List<Rental> rentals,
  ) {
    final List<Rental> openedInRange =
        rentals.where((Rental r) => _inRange(r.startedAt, range)).toList();

    final Map<String, int> rentCount = <String, int>{};
    final Map<String, int> unitsOut = <String, int>{};
    final Map<String, List<String>> activeLabels = <String, List<String>>{};

    for (final InventoryItem item in inventory) {
      rentCount[item.id] = 0;
      unitsOut[item.id] = 0;
      activeLabels[item.id] = <String>[];
    }

    for (final Rental rental in openedInRange) {
      for (final RentalLine line in rental.lines) {
        rentCount[line.itemId] = (rentCount[line.itemId] ?? 0) + 1;
      }
    }

    for (final Rental rental in rentals.where((Rental r) => r.isActive)) {
      for (final RentalLine line in rental.openLines) {
        unitsOut[line.itemId] = (unitsOut[line.itemId] ?? 0) + 1;
        final String label = line.instanceName.trim().isEmpty
            ? line.shortCode
            : '${line.instanceName} (${line.shortCode})';
        activeLabels.putIfAbsent(line.itemId, () => <String>[]).add(label);
      }
    }

    if (inventory.isEmpty) {
      return '${l10n.reportTypeResourcesWise}\n${l10n.reportNoResources}';
    }

    final List<String> lines = <String>[l10n.reportTypeResourcesWise];
    final List<InventoryItem> sorted = List<InventoryItem>.from(inventory)
      ..sort((InventoryItem a, InventoryItem b) => a.name.compareTo(b.name));
    for (final InventoryItem item in sorted) {
      final int rented = rentCount[item.id] ?? 0;
      final int out = unitsOut[item.id] ?? 0;
      lines.add(
        l10n.reportInventoryItemLine(
          item.name,
          rented,
          out,
          item.availableUnits,
          item.totalUnits,
          localizedBillingMode(l10n, item.billingMode),
          formatMoney(item.rateAmount, currencyCode: item.currencyCode),
        ),
      );
      final List<String> labels = activeLabels[item.id] ?? const <String>[];
      for (final String label in labels) {
        lines.add('  - $label');
      }
    }
    return lines.join('\n');
  }

  String _buildUnitOccupancy(
    AppLocalizations l10n,
    List<Customer> customers,
    List<InventoryItem> inventory,
    List<Rental> rentals, {
    String? title,
  }) {
    final Map<String, Customer> customersById = <String, Customer>{
      for (final Customer c in customers) c.id: c,
    };
    final Map<String, ({String rentalId, String customerId, String instanceName})>
        occupiedByCode = <String, ({String rentalId, String customerId, String instanceName})>{};
    for (final Rental rental in rentals.where((Rental r) => r.isActive)) {
      for (final RentalLine line in rental.openRentLines) {
        final String code = line.shortCode.trim().toUpperCase();
        if (code.isEmpty) {
          continue;
        }
        occupiedByCode[code] = (
          rentalId: rental.id,
          customerId: rental.customerId,
          instanceName: line.instanceName,
        );
      }
    }

    final List<InventoryItem> poolItems = inventory
        .where((InventoryItem i) => i.hasUnitCodePool)
        .toList()
      ..sort((InventoryItem a, InventoryItem b) => a.name.compareTo(b.name));

    final String heading = title ?? l10n.reportTypeUnitOccupancy;
    if (poolItems.isEmpty) {
      return '$heading\n${l10n.reportNoUnitPools}';
    }

    final List<String> lines = <String>[heading];
    for (final InventoryItem item in poolItems) {
      lines.add(l10n.reportUnitOccupancyItemHeading(item.name, item.totalUnits));
      final List<String> pool = generateUnitPool(
        prefix: item.unitCodePrefix!,
        total: item.totalUnits,
      );
      for (final String code in pool) {
        final occupied = occupiedByCode[code];
        if (occupied == null) {
          lines.add(
            l10n.reportUnitOccupancyRow(
              code,
              l10n.reportUnitStatusAvailable,
              '—',
            ),
          );
        } else {
          final Customer? customer = customersById[occupied.customerId];
          final String who = customer?.name.trim().isNotEmpty == true
              ? customer!.name
              : (occupied.instanceName.trim().isNotEmpty
                  ? occupied.instanceName
                  : occupied.customerId);
          lines.add(
            l10n.reportUnitOccupancyRow(
              code,
              l10n.reportUnitStatusOccupied,
              who,
            ),
          );
        }
      }
    }
    return lines.join('\n');
  }

  bool _inRange(DateTime value, ReportDateRange range) {
    return !value.isBefore(range.start) && !value.isAfter(range.end);
  }

  String _truncate(AppLocalizations l10n, String text) {
    if (text.length <= maxChars) {
      return text;
    }
    final String suffix = l10n.reportTruncatedSuffix(appName);
    final int keep = maxChars - suffix.length;
    if (keep <= 0) {
      return suffix.trim();
    }
    return '${text.substring(0, keep)}$suffix';
  }
}

String _reportClosedLineStatusBit(AppLocalizations l10n, RentalLine line) {
  if (line.isSell) {
    return l10n.reportStatusSoldBit;
  }
  if (line.isJob) {
    return l10n.reportStatusCompletedBit;
  }
  return l10n.reportStatusReturnedBit;
}
