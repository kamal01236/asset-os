@Tags(['unit', 'reports'])
library;

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/application/reports/report_builder.dart';
import 'package:asset_os/application/reports/report_csv_exporter.dart';
import 'package:asset_os/application/reports/report_document.dart';
import 'package:asset_os/application/reports/report_pdf_exporter.dart';
import 'package:asset_os/application/reports/report_xlsx_exporter.dart';
import 'package:asset_os/domain/models/entities.dart';
import 'package:asset_os/domain/loans/loan_models.dart';
import 'package:asset_os/domain/reports/report_models.dart';
import 'package:asset_os/l10n/app_localizations.dart';
import 'package:asset_os/presentation/features/reports/report_print.dart';

void main() {
  late AppLocalizations l10n;
  late ReportDocument document;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  setUp(() {
    final DateTime now = DateTime(2026, 8, 2, 15, 30);
    final List<Customer> customers = <Customer>[
      const Customer(
        id: 'CUS-1',
        name: 'Priya Patel',
        phone: '6666666666',
        isTrusted: true,
        qrCode: 'customer:1',
      ),
    ];
    final List<InventoryItem> inventory = <InventoryItem>[
      const InventoryItem(
        id: 'INV-1',
        name: 'DSLR',
        category: 'Camera',
        availableUnits: 1,
        totalUnits: 2,
        status: AssetStatus.available,
        qrCode: 'inv:1',
      ),
    ];
    final List<Rental> rentals = <Rental>[
      Rental(
        id: 'REN-1',
        customerId: 'CUS-1',
        lines: const <RentalLine>[
          RentalLine(
            id: 'RLI-1',
            itemId: 'INV-1',
            catalogName: 'DSLR',
            instanceName: 'Body A',
            shortCode: 'CAM-100',
          ),
        ],
        startedAt: now.subtract(const Duration(days: 2)),
        dueAt: now,
        timeline: const <RentalEvent>[],
        qrCode: 'rental:1',
      ),
    ];
    document = const ReportBuilder().document(
      l10n: l10n,
      type: ReportType.summary,
      range: ReportDateRange(
        start: DateTime(2026, 7, 26),
        end: now,
      ),
      customers: customers,
      inventory: inventory,
      rentals: rentals,
      moneyLoans: const <MoneyLoan>[],
      now: now,
    );
  });

  test('CSV contains BOM, KPI labels, and section rows', () {
    final String csv = exportReportCsv(document);
    expect(csv.startsWith('\uFEFF'), isTrue);
    expect(csv, contains(document.kpis.first.label));
    expect(
      csv,
      contains(document.sections.first.title),
    );
    expect(csv.split('\n').length, greaterThan(5));
  });

  test('XLSX decodes to a non-empty workbook', () {
    final List<int> bytes = exportReportXlsx(document);
    expect(bytes, isNotEmpty);
    final Excel workbook = Excel.decodeBytes(bytes);
    expect(workbook.tables.keys, isNotEmpty);
    final Sheet sheet = workbook.tables.values.first;
    final CellValue? titleCell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value;
    expect(titleCell.toString(), contains(document.title));
    expect(sheet.rows.length, greaterThan(1));
  });

  test('PDF returns non-empty bytes', () async {
    final List<int> pdf = await exportReportPdf(document);
    expect(pdf, isNotEmpty);
    expect(String.fromCharCodes(pdf.take(4)), '%PDF');
  });

  test('HTML print path unchanged', () {
    final String html = buildReportPrintHtml(document);
    expect(html, contains('@page'));
    expect(html, contains(document.title));
  });
}
