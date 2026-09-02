import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/config/app_branding.dart';
import 'report_document.dart';

Future<Uint8List> exportReportPdf(ReportDocument doc, {String appName = kAppDisplayName}) async {
  final pw.Document pdf = pw.Document();
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (pw.Context context) => <pw.Widget>[
        pw.Text(doc.title, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(
          '${doc.rangeLabel} · $appName',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
        if (doc.typeHeading.trim().isNotEmpty) ...<pw.Widget>[
          pw.SizedBox(height: 8),
          pw.Text(doc.typeHeading, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        ],
        if (doc.kpis.isNotEmpty) ...<pw.Widget>[
          pw.SizedBox(height: 10),
          pw.Wrap(
            spacing: 8,
            runSpacing: 8,
            children: doc.kpis
                .map(
                  (ReportKpi kpi) => pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: <pw.Widget>[
                        pw.Text(kpi.label, style: const pw.TextStyle(fontSize: 8)),
                        pw.Text(
                          kpi.value,
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
        for (final ReportTableSection section in doc.sections) ...<pw.Widget>[
          pw.SizedBox(height: 12),
          if (section.title.trim().isNotEmpty)
            pw.Text(section.title, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          if (section.emptyMessage != null && section.emptyMessage!.isNotEmpty)
            pw.Text(section.emptyMessage!, style: const pw.TextStyle(fontSize: 9))
          else if (section.columns.isNotEmpty && section.rows.isNotEmpty)
            pw.TableHelper.fromTextArray(
              headers: section.columns,
              data: section.rows,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
              cellStyle: const pw.TextStyle(fontSize: 8),
              border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            ),
          if (section.moreLabel != null && section.moreLabel!.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(section.moreLabel!, style: const pw.TextStyle(fontSize: 8)),
            ),
        ],
      ],
    ),
  );
  return await pdf.save();
}
