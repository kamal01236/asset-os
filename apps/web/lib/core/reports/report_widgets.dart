import 'package:flutter/widgets.dart';

bool _isHindi(Locale locale) => locale.languageCode == 'hi';

/// Composable plain-text report sections (no charts).
enum ReportWidgetId {
  summaryRevenue,
  transactionsToday,
  overdue,
  topCustomers,
  resourcesUtilisation,
  outstandingLoansGiven,
  outstandingLoansTaken,
}

/// Label + id for a report section (en/hi inline like field defs).
class ReportWidgetDef {
  const ReportWidgetDef({
    required this.id,
    required this.labelEn,
    this.labelHi = '',
  });

  final ReportWidgetId id;
  final String labelEn;
  final String labelHi;

  String localizedLabel(Locale locale) =>
      _isHindi(locale) && labelHi.isNotEmpty ? labelHi : labelEn;
}

/// Prefs key for comma-separated [ReportWidgetId.name] values.
const String kReportWidgetsPrefsKey = 'asset_os_report_widgets';

const List<ReportWidgetDef> kReportWidgetDefs = <ReportWidgetDef>[
  ReportWidgetDef(
    id: ReportWidgetId.summaryRevenue,
    labelEn: 'Revenue',
    labelHi: 'राजस्व',
  ),
  ReportWidgetDef(
    id: ReportWidgetId.transactionsToday,
    labelEn: 'Activity',
    labelHi: 'गतिविधि',
  ),
  ReportWidgetDef(
    id: ReportWidgetId.overdue,
    labelEn: 'Overdue',
    labelHi: 'अतिदेय',
  ),
  ReportWidgetDef(
    id: ReportWidgetId.topCustomers,
    labelEn: 'Top customers',
    labelHi: 'शीर्ष ग्राहक',
  ),
  ReportWidgetDef(
    id: ReportWidgetId.resourcesUtilisation,
    labelEn: 'Resource utilisation',
    labelHi: 'संसाधन उपयोग',
  ),
  ReportWidgetDef(
    id: ReportWidgetId.outstandingLoansGiven,
    labelEn: 'Outstanding given',
    labelHi: 'बाहर दिया बकाया',
  ),
  ReportWidgetDef(
    id: ReportWidgetId.outstandingLoansTaken,
    labelEn: 'Outstanding taken',
    labelHi: 'लिया बकाया',
  ),
];

/// Default share pack when template / prefs omit widgets.
const List<ReportWidgetId> kDefaultReportWidgets = <ReportWidgetId>[
  ReportWidgetId.transactionsToday,
  ReportWidgetId.overdue,
  ReportWidgetId.summaryRevenue,
];

const List<ReportWidgetId> kRentalReportWidgets = kDefaultReportWidgets;

const List<ReportWidgetId> kJobReportWidgets = <ReportWidgetId>[
  ReportWidgetId.transactionsToday,
  ReportWidgetId.overdue,
  ReportWidgetId.summaryRevenue,
];

const List<ReportWidgetId> kBoutiqueReportWidgets = <ReportWidgetId>[
  ReportWidgetId.summaryRevenue,
  ReportWidgetId.overdue,
  ReportWidgetId.topCustomers,
  ReportWidgetId.resourcesUtilisation,
];

const List<ReportWidgetId> kMembershipReportWidgets = <ReportWidgetId>[
  ReportWidgetId.summaryRevenue,
  ReportWidgetId.transactionsToday,
  ReportWidgetId.topCustomers,
];

const List<ReportWidgetId> kLibraryReportWidgets = <ReportWidgetId>[
  ReportWidgetId.transactionsToday,
  ReportWidgetId.overdue,
  ReportWidgetId.resourcesUtilisation,
];

const List<ReportWidgetId> kMoneyLendingReportWidgets = <ReportWidgetId>[
  ReportWidgetId.outstandingLoansGiven,
  ReportWidgetId.outstandingLoansTaken,
  ReportWidgetId.transactionsToday,
];

ReportWidgetDef? reportWidgetDefById(ReportWidgetId id) {
  for (final ReportWidgetDef def in kReportWidgetDefs) {
    if (def.id == id) {
      return def;
    }
  }
  return null;
}

ReportWidgetId? parseReportWidgetId(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return null;
  }
  for (final ReportWidgetId id in ReportWidgetId.values) {
    if (id.name == raw.trim()) {
      return id;
    }
  }
  return null;
}

List<ReportWidgetId> parseReportWidgets(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return List<ReportWidgetId>.from(kDefaultReportWidgets);
  }
  final List<ReportWidgetId> out = <ReportWidgetId>[];
  final Set<ReportWidgetId> seen = <ReportWidgetId>{};
  for (final String part in raw.split(',')) {
    final ReportWidgetId? id = parseReportWidgetId(part);
    if (id == null) {
      continue;
    }
    if (seen.add(id)) {
      out.add(id);
    }
  }
  return out.isEmpty
      ? List<ReportWidgetId>.from(kDefaultReportWidgets)
      : out;
}

String encodeReportWidgets(Iterable<ReportWidgetId> widgets) {
  final List<ReportWidgetId> ordered = <ReportWidgetId>[];
  final Set<ReportWidgetId> seen = <ReportWidgetId>{};
  for (final ReportWidgetId id in widgets) {
    if (seen.add(id)) {
      ordered.add(id);
    }
  }
  return ordered.map((ReportWidgetId id) => id.name).join(',');
}

List<ReportWidgetId> resolveReportWidgets({String? prefsRaw}) {
  if (prefsRaw == null || prefsRaw.trim().isEmpty) {
    return List<ReportWidgetId>.from(kDefaultReportWidgets);
  }
  return parseReportWidgets(prefsRaw);
}
