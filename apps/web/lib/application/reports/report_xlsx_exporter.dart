import 'dart:typed_data';

import 'package:excel/excel.dart';

import 'report_document.dart';

Uint8List exportReportXlsx(ReportDocument doc) {
  final Excel workbook = Excel.createExcel();
  final String sheetName = _sanitizeSheetName(doc.title);
  final String? defaultSheet = workbook.getDefaultSheet();
  if (defaultSheet != null && defaultSheet != sheetName) {
    workbook.rename(defaultSheet, sheetName);
  }
  final Sheet sheet = workbook[sheetName];
  int rowIndex = 0;

  void writeRow(List<String> cells) {
    for (int col = 0; col < cells.length; col++) {
      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex),
          )
          .value = TextCellValue(cells[col]);
    }
    rowIndex++;
  }

  writeRow(<String>[doc.title]);
  writeRow(<String>[doc.rangeLabel]);
  if (doc.typeHeading.trim().isNotEmpty) {
    writeRow(<String>[doc.typeHeading]);
  }
  rowIndex++;

  for (final ReportKpi kpi in doc.kpis) {
    writeRow(<String>[kpi.label, kpi.value]);
  }
  if (doc.kpis.isNotEmpty) {
    rowIndex++;
  }

  for (final ReportTableSection section in doc.sections) {
    if (section.title.trim().isNotEmpty) {
      writeRow(<String>[section.title]);
    }
    if (section.emptyMessage != null && section.emptyMessage!.isNotEmpty) {
      writeRow(<String>[section.emptyMessage!]);
      rowIndex++;
      continue;
    }
    if (section.columns.isNotEmpty) {
      writeRow(section.columns);
      for (final List<String> dataRow in section.rows) {
        writeRow(dataRow);
      }
    }
    if (section.moreLabel != null && section.moreLabel!.isNotEmpty) {
      writeRow(<String>[section.moreLabel!]);
    }
    rowIndex++;
  }

  final List<int>? encoded = workbook.encode();
  return Uint8List.fromList(encoded ?? <int>[]);
}

String _sanitizeSheetName(String raw) {
  final String trimmed = raw.trim().isEmpty ? 'Report' : raw.trim();
  final String sanitized =
      trimmed.replaceAll(RegExp(r'[\\/*?:\[\]]'), '_').substring(
            0,
            trimmed.length > 31 ? 31 : trimmed.length,
          );
  return sanitized.isEmpty ? 'Report' : sanitized;
}
