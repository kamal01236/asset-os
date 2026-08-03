import '../config/app_branding.dart';
import '../models/entities.dart';
import '../pricing/rental_pricing.dart';
import 'report_models.dart';

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

  String build({
    required ReportType type,
    required ReportDateRange range,
    required List<Customer> customers,
    required List<InventoryItem> inventory,
    required List<Rental> rentals,
    DateTime? now,
  }) {
    final DateTime clock = now ?? range.end;
    final String body;
    switch (type) {
      case ReportType.summary:
        body = _buildSummary(range, rentals, clock);
      case ReportType.customerWise:
        body = _buildCustomerWise(range, customers, inventory, rentals, clock);
      case ReportType.inventoryWise:
        body = _buildInventoryWise(range, inventory, rentals);
    }
    final String header =
        '$appName report\n${_formatDate(range.start)} → ${_formatDate(range.end)}\n';
    return _truncate('$header\n$body'.trimRight());
  }

  String _buildSummary(ReportDateRange range, List<Rental> rentals, DateTime clock) {
    final int active = rentals.where((Rental r) => r.isActive).length;
    final int opened = rentals
        .where((Rental r) => _inRange(r.startedAt, range))
        .length;
    final int returned = rentals
        .where(
          (Rental r) => r.returnedAt != null && _inRange(r.returnedAt!, range),
        )
        .length;
    final int overdue = rentals
        .where((Rental r) => r.statusFor(clock) == AssetStatus.overdue)
        .length;

    return <String>[
      'Summary',
      'Active: $active',
      'Opened: $opened',
      'Returned: $returned',
      'Overdue: $overdue',
      'Charges (opened in range): ${formatMoney(_sumOpenedCharges(rentals, range))}',
      'Charges (returned in range): ${formatMoney(_sumReturnedCharges(rentals, range))}',
      'Deposit applied (returned in range): ${formatMoney(_sumDepositApplied(rentals, range))}',
      'Balance due after deposit (returned): ${formatMoney(_sumBalanceDue(rentals, range))}',
    ].join('\n');
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
      return 'Customer-wise\n(no rentals in range)';
    }

    final List<String> lines = <String>['Customer-wise'];
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
            ? '$header | deposit ${formatMoney(deposit)}'
            : header,
      );
      for (final Rental rental in byCustomer[customerId]!) {
        final String itemNames = rental.lines
            .map((RentalLine line) {
              final String statusBit = line.isOpen ? '' : ' [returned]';
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
            ? ' | lines $openCount open/$returnedCount returned'
            : '';
        final String depositBit = rental.depositApplied > 0
            ? ' | deposit ${formatMoney(rental.depositApplied)} | due ${formatMoney(rental.amountDueAfterDeposit)}'
            : '';
        lines.add(
          '  • $prefix${rental.id}: $itemNames | due ${_formatDate(rental.dueAt)} | ${status.label} | ${formatMoney(amount)}$partialBit$depositBit',
        );
      }
    }
    return lines.join('\n');
  }

  String _buildInventoryWise(
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
      return 'Inventory-wise\n(no inventory)';
    }

    final List<String> lines = <String>['Inventory-wise'];
    final List<InventoryItem> sorted = List<InventoryItem>.from(inventory)
      ..sort((InventoryItem a, InventoryItem b) => a.name.compareTo(b.name));
    for (final InventoryItem item in sorted) {
      final int rented = rentCount[item.id] ?? 0;
      final int out = unitsOut[item.id] ?? 0;
      lines.add(
        '• ${item.name}: rented $rented× | out $out | avail ${item.availableUnits}/${item.totalUnits} | ${item.billingMode.name} ${formatMoney(item.rateAmount, currencyCode: item.currencyCode)}',
      );
      final List<String> labels = activeLabels[item.id] ?? const <String>[];
      for (final String label in labels) {
        lines.add('  - $label');
      }
    }
    return lines.join('\n');
  }

  bool _inRange(DateTime value, ReportDateRange range) {
    return !value.isBefore(range.start) && !value.isAfter(range.end);
  }

  String _formatDate(DateTime value) {
    final String y = value.year.toString().padLeft(4, '0');
    final String m = value.month.toString().padLeft(2, '0');
    final String d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _truncate(String text) {
    if (text.length <= maxChars) {
      return text;
    }
    final String suffix = '\n…(truncated — open $appName for full)';
    final int keep = maxChars - suffix.length;
    if (keep <= 0) {
      return suffix.trim();
    }
    return '${text.substring(0, keep)}$suffix';
  }
}
