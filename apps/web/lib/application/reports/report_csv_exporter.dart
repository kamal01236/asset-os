import 'package:csv/csv.dart';

import 'report_document.dart';

/// UTF-8 CSV with BOM for Excel compatibility.
String exportReportCsv(ReportDocument doc) {
  final List<List<dynamic>> rows = <List<dynamic>>[];

  for (final ReportKpi kpi in doc.kpis) {
    rows.add(<String>[kpi.label, kpi.value]);
  }
  if (doc.kpis.isNotEmpty) {
    rows.add(<String>[]);
  }

  for (final ReportTableSection section in doc.sections) {
    if (section.title.trim().isNotEmpty) {
      rows.add(<String>[section.title]);
    }
    if (section.emptyMessage != null && section.emptyMessage!.isNotEmpty) {
      rows.add(<String>[section.emptyMessage!]);
      rows.add(<String>[]);
      continue;
    }
    if (section.columns.isNotEmpty) {
      rows.add(section.columns);
      for (final List<String> dataRow in section.rows) {
        rows.add(dataRow);
      }
    }
    if (section.moreLabel != null && section.moreLabel!.isNotEmpty) {
      rows.add(<String>[section.moreLabel!]);
    }
    rows.add(<String>[]);
  }

  final String csv = const ListToCsvConverter().convert(rows);
  return '\uFEFF$csv';
}
