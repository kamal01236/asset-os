import 'package:flutter/widgets.dart';

import '../../domain/config/app_branding.dart';
import '../../infrastructure/l10n/india_date_format.dart';
import '../../infrastructure/l10n/l10n_ext.dart';
import '../../domain/loans/loan_models.dart';
import '../../domain/models/entities.dart';
import '../../domain/pricing/rental_pricing.dart';
import '../../domain/reports/report_models.dart';
import '../../domain/reports/report_snapshot.dart';
import '../../domain/reports/report_widgets.dart';
import 'report_document.dart';

/// Soft cap for WhatsApp URL length; longer text is truncated with a note.
const int kReportMaxChars = 3500;

/// Builds snapshot-backed business reports (text, preview tables, print).
class ReportBuilder {
  const ReportBuilder({
    this.appName = kAppDisplayName,
    this.maxChars = kReportMaxChars,
  });

  final String appName;
  final int maxChars;

  ReportSnapshot snapshot({
    required ReportType type,
    required ReportDateRange range,
    required List<Customer> customers,
    required List<InventoryItem> inventory,
    required List<Rental> rentals,
    List<ReportWidgetId>? widgets,
    List<MoneyLoan> moneyLoans = const <MoneyLoan>[],
  }) {
    return ReportSnapshot.assemble(
      type: type,
      range: range,
      customers: customers,
      inventory: inventory,
      rentals: rentals,
      moneyLoans: moneyLoans,
      widgets: widgets,
    );
  }

  /// Snapshot + localized tables + truncated WhatsApp text.
  ReportDocument document({
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
    final ReportSnapshot snap = snapshot(
      type: type,
      range: range,
      customers: customers,
      inventory: inventory,
      rentals: rentals,
      widgets: widgets,
      moneyLoans: moneyLoans,
    );
    return compose(snapshot: snap, l10n: l10n, locale: locale);
  }

  ReportDocument compose({
    required ReportSnapshot snapshot,
    required AppLocalizations l10n,
    Locale locale = const Locale('en'),
  }) {
    final String title = l10n.reportHeader(appName);
    final String rangeLabel =
        '${formatIndiaDate(snapshot.range.start)} → ${formatIndiaDate(snapshot.range.end)}';
    final String typeHeading = _typeHeading(l10n, snapshot.type);
    final List<ReportKpi> kpis = <ReportKpi>[];
    final List<ReportTableSection> sections = <ReportTableSection>[];

    switch (snapshot.type) {
      case ReportType.summary:
        _composeSummary(
          snapshot: snapshot,
          l10n: l10n,
          locale: locale,
          kpis: kpis,
          sections: sections,
        );
      case ReportType.customerWise:
        _composeCustomerWise(
          snapshot: snapshot,
          l10n: l10n,
          kpis: kpis,
          sections: sections,
        );
      case ReportType.inventoryWise:
        _composeResources(
          snapshot: snapshot,
          l10n: l10n,
          sections: sections,
        );
      case ReportType.unitOccupancy:
        _composeOccupancy(
          snapshot: snapshot,
          l10n: l10n,
          locale: locale,
          sections: sections,
          standalone: true,
        );
    }

    if (kpis.isEmpty && sections.isEmpty) {
      sections.add(
        ReportTableSection(
          title: typeHeading,
          columns: const <String>[],
          rows: const <List<String>>[],
          emptyMessage: _emptyMessage(l10n, snapshot.type),
        ),
      );
    }

    final String text = _truncate(
      l10n,
      _formatText(
        title: title,
        rangeLabel: rangeLabel,
        typeHeading: typeHeading,
        kpis: kpis,
        sections: sections,
      ),
    );
    return ReportDocument(
      snapshot: snapshot,
      title: title,
      rangeLabel: rangeLabel,
      typeHeading: typeHeading,
      kpis: kpis,
      sections: sections,
      text: text,
    );
  }

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
    return document(
      l10n: l10n,
      type: type,
      range: range,
      customers: customers,
      inventory: inventory,
      rentals: rentals,
      now: now,
      widgets: widgets,
      locale: locale,
      moneyLoans: moneyLoans,
    ).text;
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
    final ReportDocument doc = document(
      l10n: l10n,
      type: ReportType.summary,
      range: range,
      customers: customers,
      inventory: inventory,
      rentals: rentals,
      now: now,
      widgets: widgets,
      locale: locale,
      moneyLoans: moneyLoans,
    );
    final String body = _formatBody(
      typeHeading: includeTypeHeading ? doc.typeHeading : '',
      kpis: doc.kpis,
      sections: doc.sections,
    );
    return body.trim();
  }

  void _composeSummary({
    required ReportSnapshot snapshot,
    required AppLocalizations l10n,
    required Locale locale,
    required List<ReportKpi> kpis,
    required List<ReportTableSection> sections,
  }) {
    final bool onlyLoansGiven = snapshot.widgets.length == 1 &&
        snapshot.hasWidget(ReportWidgetId.outstandingLoansGiven);
    final bool onlyLoansTaken = snapshot.widgets.length == 1 &&
        snapshot.hasWidget(ReportWidgetId.outstandingLoansTaken);
    final bool onlyLoans = snapshot.widgets.isNotEmpty &&
        snapshot.widgets.every(
          (ReportWidgetId id) =>
              id == ReportWidgetId.outstandingLoansGiven ||
              id == ReportWidgetId.outstandingLoansTaken,
        );

    if (snapshot.hasWidget(ReportWidgetId.transactionsToday)) {
      if (snapshot.issued.isNotEmpty) {
        kpis.add(
          ReportKpi(
            label: l10n.reportKpiIssued,
            value: '${snapshot.issued.length}',
          ),
        );
      }
      if (snapshot.returned.isNotEmpty) {
        kpis.add(
          ReportKpi(
            label: l10n.reportKpiReturned,
            value: '${snapshot.returned.length}',
          ),
        );
      }
      if (snapshot.stillOut.isNotEmpty) {
        kpis.add(
          ReportKpi(
            label: l10n.reportKpiStillOut,
            value: '${snapshot.stillOut.length}',
          ),
        );
      }
      if (snapshot.pendingLoansCount > 0) {
        kpis.add(
          ReportKpi(
            label: l10n.reportKpiPendingLoans,
            value: '${snapshot.pendingLoansCount}',
          ),
        );
      }
    }
    if (snapshot.hasWidget(ReportWidgetId.overdue) && snapshot.overdueCount > 0) {
      kpis.add(
        ReportKpi(
          label: l10n.reportKpiOverdue,
          value: '${snapshot.overdueCount}',
        ),
      );
    }
    if (snapshot.hasWidget(ReportWidgetId.summaryRevenue)) {
      if (snapshot.chargesOpenedPaise != 0) {
        kpis.add(
          ReportKpi(
            label: l10n.reportKpiChargesOpened,
            value: formatMoney(snapshot.chargesOpenedPaise),
          ),
        );
      }
      if (snapshot.chargesReturnedPaise != 0) {
        kpis.add(
          ReportKpi(
            label: l10n.reportKpiChargesReturned,
            value: formatMoney(snapshot.chargesReturnedPaise),
          ),
        );
      }
      if (snapshot.depositAppliedPaise != 0) {
        kpis.add(
          ReportKpi(
            label: l10n.reportKpiDepositApplied,
            value: formatMoney(snapshot.depositAppliedPaise),
          ),
        );
      }
      if (snapshot.sellCollectedPaise != 0) {
        kpis.add(
          ReportKpi(
            label: l10n.reportKpiSellCollected,
            value: formatMoney(snapshot.sellCollectedPaise),
          ),
        );
      }
      if (snapshot.balanceDueReturnedPaise != 0) {
        kpis.add(
          ReportKpi(
            label: l10n.reportKpiBalanceDue,
            value: formatMoney(snapshot.balanceDueReturnedPaise),
          ),
        );
      }
    }

    if (snapshot.hasWidget(ReportWidgetId.transactionsToday)) {
      _addOrderTable(
        sections: sections,
        title: l10n.reportSectionIssued,
        snapshotRows: snapshot.issued,
        l10n: l10n,
        cap: kReportSummaryRowCap,
      );
      _addOrderTable(
        sections: sections,
        title: l10n.reportSectionReturned,
        snapshotRows: snapshot.returned,
        l10n: l10n,
        cap: kReportSummaryRowCap,
      );
      _addOrderTable(
        sections: sections,
        title: l10n.reportStillOutAsOf(formatIndiaDate(snapshot.asOf)),
        snapshotRows: snapshot.stillOut,
        l10n: l10n,
        cap: kReportSummaryRowCap,
        includeNickname: true,
      );
    }

    if (snapshot.hasWidget(ReportWidgetId.topCustomers) &&
        snapshot.topCustomers.isNotEmpty) {
      sections.add(
        ReportTableSection(
          title: _widgetTitle(locale, ReportWidgetId.topCustomers, l10n.reportTypeCustomerWise),
          columns: <String>[
            l10n.reportColParty,
            l10n.reportColIssued,
            l10n.reportColAmount,
          ],
          rows: snapshot.topCustomers
              .map(
                (ReportTopCustomerRow row) => <String>[
                  _partyName(row.name, row.phone),
                  '${row.orderCount}',
                  formatMoney(row.chargesPaise),
                ],
              )
              .toList(growable: false),
        ),
      );
    }

    if (snapshot.hasWidget(ReportWidgetId.resourcesUtilisation) &&
        snapshot.resources.isNotEmpty) {
      sections.add(
        _resourcesSection(
          title: _widgetTitle(
            locale,
            ReportWidgetId.resourcesUtilisation,
            l10n.reportTypeResourcesWise,
          ),
          rows: snapshot.resources,
          l10n: l10n,
          cap: kReportSummaryRowCap,
        ),
      );
    }

    if (snapshot.hasWidget(ReportWidgetId.unitOccupancy)) {
      _composeOccupancy(
        snapshot: snapshot,
        l10n: l10n,
        locale: locale,
        sections: sections,
        standalone: false,
      );
    }

    if (snapshot.hasWidget(ReportWidgetId.outstandingLoansGiven)) {
      _addLoanSection(
        sections: sections,
        title: _widgetTitle(
          locale,
          ReportWidgetId.outstandingLoansGiven,
          l10n.reportKpiPendingLoans,
        ),
        rows: snapshot.loansGiven,
        l10n: l10n,
        forceEmpty: onlyLoansGiven || onlyLoans,
      );
    }
    if (snapshot.hasWidget(ReportWidgetId.outstandingLoansTaken)) {
      _addLoanSection(
        sections: sections,
        title: _widgetTitle(
          locale,
          ReportWidgetId.outstandingLoansTaken,
          l10n.reportKpiPendingLoans,
        ),
        rows: snapshot.loansTaken,
        l10n: l10n,
        forceEmpty: onlyLoansTaken || onlyLoans,
      );
    }
  }

  void _composeCustomerWise({
    required ReportSnapshot snapshot,
    required AppLocalizations l10n,
    required List<ReportKpi> kpis,
    required List<ReportTableSection> sections,
  }) {
    final bool showDeposit = snapshot.customersPeriod
        .any((ReportCustomerRow r) => r.depositBalancePaise > 0);
    if (snapshot.customersPeriod.isNotEmpty) {
      final List<String> columns = <String>[
        l10n.reportColParty,
        l10n.reportColIssued,
        l10n.reportColReturned,
        l10n.reportColAmount,
        l10n.reportColStatus,
        if (showDeposit) l10n.reportKpiDepositApplied,
      ];
      sections.add(
        ReportTableSection(
          title: '',
          columns: columns,
          rows: snapshot.customersPeriod.map((ReportCustomerRow row) {
            final List<String> cells = <String>[
              _partyName(row.name, row.phone),
              '${row.issuedCount}',
              '${row.returnedCount}',
              formatMoney(row.amountPaise),
              row.periodStatus == null
                  ? l10n.orderStatusCompleted
                  : localizedStatusLabel(l10n, row.periodStatus!),
            ];
            if (showDeposit) {
              cells.add(
                row.depositBalancePaise > 0
                    ? formatMoney(row.depositBalancePaise)
                    : '',
              );
            }
            return cells;
          }).toList(growable: false),
        ),
      );
    }
    if (snapshot.stillOut.isNotEmpty) {
      _addOrderTable(
        sections: sections,
        title: l10n.reportStillOutAsOf(formatIndiaDate(snapshot.asOf)),
        snapshotRows: snapshot.stillOut,
        l10n: l10n,
        includeNickname: true,
      );
    }
  }

  void _composeResources({
    required ReportSnapshot snapshot,
    required AppLocalizations l10n,
    required List<ReportTableSection> sections,
  }) {
    if (snapshot.resources.isEmpty) {
      sections.add(
        ReportTableSection(
          title: '',
          columns: const <String>[],
          rows: const <List<String>>[],
          emptyMessage: l10n.reportNoResources,
        ),
      );
      return;
    }
    sections.add(
      _resourcesSection(
        title: '',
        rows: snapshot.resources,
        l10n: l10n,
      ),
    );
  }

  void _composeOccupancy({
    required ReportSnapshot snapshot,
    required AppLocalizations l10n,
    required Locale locale,
    required List<ReportTableSection> sections,
    required bool standalone,
  }) {
    if (snapshot.occupancy.isEmpty) {
      if (standalone) {
        sections.add(
          ReportTableSection(
            title: '',
            columns: const <String>[],
            rows: const <List<String>>[],
            emptyMessage: l10n.reportNoOccupiedUnits,
          ),
        );
      }
      return;
    }
    if (!standalone) {
      sections.add(
        ReportTableSection(
          title: _widgetTitle(
            locale,
            ReportWidgetId.unitOccupancy,
            l10n.reportTypeUnitOccupancy,
          ),
          columns: const <String>[],
          rows: const <List<String>>[],
        ),
      );
    }
    for (final ReportOccupancyPool pool in snapshot.occupancy) {
      sections.add(
        ReportTableSection(
          title: l10n.reportUnitOccupancyItemHeading(
            pool.itemName,
            pool.outCount,
            pool.totalUnits,
          ),
          columns: <String>[l10n.reportColCode, l10n.reportColCustomer],
          rows: pool.units
              .map(
                (ReportOccupancyUnit u) => <String>[u.code, u.holderName],
              )
              .toList(growable: false),
        ),
      );
    }
  }

  void _addOrderTable({
    required List<ReportTableSection> sections,
    required String title,
    required List<ReportOrderRow> snapshotRows,
    required AppLocalizations l10n,
    int? cap,
    bool includeNickname = false,
  }) {
    if (snapshotRows.isEmpty) {
      return;
    }
    final bool showSell =
        snapshotRows.any((ReportOrderRow r) => r.sellPaidPaise > 0);
    final bool showDeposit =
        snapshotRows.any((ReportOrderRow r) => r.depositAppliedPaise > 0);
    final int take = cap ?? snapshotRows.length;
    final List<ReportOrderRow> visible = snapshotRows.take(take).toList();
    final int extra = snapshotRows.length - visible.length;
    final List<String> columns = <String>[
      l10n.reportColParty,
      l10n.reportColItems,
      l10n.reportColAmount,
      l10n.reportColStatus,
      if (showSell) l10n.reportKpiSellCollected,
      if (showDeposit) l10n.reportKpiDepositApplied,
    ];
    sections.add(
      ReportTableSection(
        title: title,
        columns: columns,
        rows: visible.map((ReportOrderRow row) {
          final String party = includeNickname
              ? _partyWithNickname(row)
              : _partyName(row.customerName, row.customerPhone);
          final List<String> cells = <String>[
            party,
            row.itemsLabel,
            formatMoney(row.amountPaise),
            _orderStatusLabel(l10n, row),
          ];
          if (showSell) {
            cells.add(
              row.sellPaidPaise > 0 ? formatMoney(row.sellPaidPaise) : '',
            );
          }
          if (showDeposit) {
            cells.add(
              row.depositAppliedPaise > 0
                  ? formatMoney(row.depositAppliedPaise)
                  : '',
            );
          }
          return cells;
        }).toList(growable: false),
        moreLabel: extra > 0 ? l10n.reportMoreCount(extra) : null,
      ),
    );
  }

  ReportTableSection _resourcesSection({
    required String title,
    required List<ReportResourceRow> rows,
    required AppLocalizations l10n,
    int? cap,
  }) {
    final int take = cap ?? rows.length;
    final List<ReportResourceRow> visible = rows.take(take).toList();
    final int extra = rows.length - visible.length;
    return ReportTableSection(
      title: title,
      columns: <String>[
        l10n.reportColResource,
        l10n.reportColIssued,
        l10n.reportColReturned,
        l10n.reportColOut,
        l10n.reportColAvail,
      ],
      rows: visible
          .map(
            (ReportResourceRow row) => <String>[
              row.name,
              '${row.issuedCount}×',
              '${row.returnedCount}×',
              '${row.outCount}',
              '${row.availableUnits}/${row.totalUnits}',
            ],
          )
          .toList(growable: false),
      moreLabel: extra > 0 ? l10n.reportMoreCount(extra) : null,
    );
  }

  void _addLoanSection({
    required List<ReportTableSection> sections,
    required String title,
    required List<ReportLoanRow> rows,
    required AppLocalizations l10n,
    required bool forceEmpty,
  }) {
    if (rows.isEmpty) {
      if (forceEmpty) {
        sections.add(
          ReportTableSection(
            title: title,
            columns: const <String>[],
            rows: const <List<String>>[],
            emptyMessage: l10n.reportNoOutstandingLoans,
          ),
        );
      }
      return;
    }
    int total = 0;
    for (final ReportLoanRow row in rows) {
      total += row.pendingPaise;
    }
    sections.add(
      ReportTableSection(
        title: title,
        columns: <String>[l10n.reportColParty, l10n.reportColAmount],
        rows: rows
            .map(
              (ReportLoanRow row) => <String>[
                row.customerName,
                formatMoney(row.pendingPaise, currencyCode: row.currencyCode),
              ],
            )
            .toList(growable: false),
        moreLabel: l10n.reportOutstandingLoansTotal(formatMoney(total), rows.length),
      ),
    );
  }

  String _formatText({
    required String title,
    required String rangeLabel,
    required String typeHeading,
    required List<ReportKpi> kpis,
    required List<ReportTableSection> sections,
  }) {
    final List<String> lines = <String>[title, rangeLabel, ''];
    final String body = _formatBody(
      typeHeading: typeHeading,
      kpis: kpis,
      sections: sections,
    );
    if (body.isNotEmpty) {
      lines.add(body);
    }
    return lines.join('\n').trimRight();
  }

  String _formatBody({
    required String typeHeading,
    required List<ReportKpi> kpis,
    required List<ReportTableSection> sections,
  }) {
    final List<String> lines = <String>[];
    if (typeHeading.trim().isNotEmpty) {
      lines.add(typeHeading.trim());
    }
    for (final ReportKpi kpi in kpis) {
      lines.add('${kpi.label}: ${kpi.value}');
    }
    for (final ReportTableSection section in sections) {
      if (lines.isNotEmpty) {
        lines.add('');
      }
      if (section.title.trim().isNotEmpty) {
        lines.add(section.title.trim());
      }
      if (section.emptyMessage != null && section.emptyMessage!.isNotEmpty) {
        lines.add(section.emptyMessage!);
        continue;
      }
      if (section.columns.isNotEmpty && section.rows.isNotEmpty) {
        lines.add(section.columns.join('\t'));
      }
      for (final List<String> row in section.rows) {
        lines.add(row.join('\t'));
      }
      if (section.moreLabel != null && section.moreLabel!.isNotEmpty) {
        lines.add(section.moreLabel!);
      }
    }
    return lines.join('\n').trim();
  }

  String _typeHeading(AppLocalizations l10n, ReportType type) {
    switch (type) {
      case ReportType.summary:
        return l10n.reportTypeSummary;
      case ReportType.customerWise:
        return l10n.reportTypeCustomerWise;
      case ReportType.inventoryWise:
        return l10n.reportTypeResourcesWise;
      case ReportType.unitOccupancy:
        return l10n.reportTypeUnitOccupancy;
    }
  }

  String _emptyMessage(AppLocalizations l10n, ReportType type) {
    switch (type) {
      case ReportType.inventoryWise:
        return l10n.reportNoResources;
      case ReportType.unitOccupancy:
        return l10n.reportNoOccupiedUnits;
      case ReportType.summary:
      case ReportType.customerWise:
        return l10n.reportNoRentalsInRange;
    }
  }

  String _widgetTitle(Locale locale, ReportWidgetId id, String fallback) {
    return reportWidgetDefById(id)?.localizedLabel(locale) ?? fallback;
  }

  String _partyName(String name, String phone) {
    if (phone.trim().isEmpty) {
      return name;
    }
    return '$name ($phone)';
  }

  String _partyWithNickname(ReportOrderRow row) {
    final String nick = row.nickname?.trim() ?? '';
    final String base = _partyName(row.customerName, row.customerPhone);
    if (nick.isEmpty) {
      return base;
    }
    return '$nick · $base';
  }

  String _orderStatusLabel(AppLocalizations l10n, ReportOrderRow row) {
    if (row.orderStatus == OrderStatus.completed ||
        row.status == AssetStatus.available) {
      return localizedOrderStatus(l10n, OrderStatus.completed);
    }
    if (row.orderStatus == OrderStatus.cancelled) {
      return localizedOrderStatus(l10n, OrderStatus.cancelled);
    }
    return localizedStatusLabel(l10n, row.status);
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
