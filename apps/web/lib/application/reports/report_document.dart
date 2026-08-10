import '../../domain/reports/report_snapshot.dart';

/// One KPI cell for preview / print / compact text.
class ReportKpi {
  const ReportKpi({required this.label, required this.value});

  final String label;
  final String value;
}

/// A titled table (or heading + lines) derived from [ReportSnapshot].
class ReportTableSection {
  const ReportTableSection({
    required this.title,
    required this.columns,
    required this.rows,
    this.moreLabel,
    this.emptyMessage,
  });

  final String title;
  final List<String> columns;
  final List<List<String>> rows;
  final String? moreLabel;
  final String? emptyMessage;

  bool get isEmpty => rows.isEmpty && (emptyMessage == null || emptyMessage!.isEmpty);
}

/// Localized, presentation-ready report. Do not re-filter entities from this.
class ReportDocument {
  const ReportDocument({
    required this.snapshot,
    required this.title,
    required this.rangeLabel,
    required this.typeHeading,
    required this.kpis,
    required this.sections,
    required this.text,
  });

  final ReportSnapshot snapshot;
  final String title;
  final String rangeLabel;
  final String typeHeading;
  final List<ReportKpi> kpis;
  final List<ReportTableSection> sections;
  final String text;
}
