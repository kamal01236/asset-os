import '../../../application/reports/report_document.dart';
import '../../../domain/config/app_branding.dart';
import 'report_browser_print_stub.dart'
    if (dart.library.js_interop) 'report_browser_print_web.dart' as browser;

/// Print the current report via the browser (no PDF package).
void printReportDocument(ReportDocument doc) {
  browser.printHtmlDocument(buildReportPrintHtml(doc));
}

/// Dense A4 HTML from a pre-composed [ReportDocument].
String buildReportPrintHtml(ReportDocument doc, {String appName = kAppDisplayName}) {
  final StringBuffer body = StringBuffer();
  body.write('<h1>${_escape(doc.title)}</h1>');
  body.write('<p class="meta">${_escape(doc.rangeLabel)} · ${_escape(appName)}</p>');
  if (doc.typeHeading.trim().isNotEmpty) {
    body.write('<h2>${_escape(doc.typeHeading)}</h2>');
  }
  if (doc.kpis.isNotEmpty) {
    body.write('<table class="kpis"><tbody><tr>');
    for (final ReportKpi kpi in doc.kpis) {
      body.write(
        '<td><span class="k">${_escape(kpi.label)}</span>'
        '<span class="v">${_escape(kpi.value)}</span></td>',
      );
    }
    body.write('</tr></tbody></table>');
  }
  for (final ReportTableSection section in doc.sections) {
    body.write('<section>');
    if (section.title.trim().isNotEmpty) {
      body.write('<h2>${_escape(section.title)}</h2>');
    }
    if (section.emptyMessage != null && section.emptyMessage!.isNotEmpty) {
      body.write('<p>${_escape(section.emptyMessage!)}</p>');
      body.write('</section>');
      continue;
    }
    if (section.columns.isNotEmpty && section.rows.isNotEmpty) {
      body.write('<table><thead><tr>');
      for (final String col in section.columns) {
        body.write('<th>${_escape(col)}</th>');
      }
      body.write('</tr></thead><tbody>');
      for (final List<String> row in section.rows) {
        body.write('<tr>');
        for (final String cell in row) {
          body.write('<td>${_escape(cell)}</td>');
        }
        body.write('</tr>');
      }
      body.write('</tbody></table>');
    }
    if (section.moreLabel != null && section.moreLabel!.isNotEmpty) {
      body.write('<p class="more">${_escape(section.moreLabel!)}</p>');
    }
    body.write('</section>');
  }

  return '''<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>${_escape(doc.title)}</title>
<style>
  @page { size: A4; margin: 12mm; }
  * { box-sizing: border-box; }
  body {
    margin: 0;
    color: #000;
    background: #fff;
    font: 9pt/1.25 "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
  }
  h1 { font-size: 13pt; margin: 0 0 4pt; }
  h2 { font-size: 10pt; margin: 10pt 0 4pt; page-break-after: avoid; }
  .meta { margin: 0 0 8pt; }
  section { page-break-inside: avoid; }
  table { width: 100%; border-collapse: collapse; margin: 0 0 6pt; }
  th, td { border: 1px solid #222; padding: 2pt 4pt; text-align: left; vertical-align: top; }
  th { font-weight: 700; }
  .kpis td { width: 1%; white-space: nowrap; }
  .kpis .k { display: block; font-size: 8pt; }
  .kpis .v { font-weight: 700; }
  .more { margin: 0 0 6pt; }
</style>
</head>
<body>
$body
</body>
</html>''';
}

String _escape(String raw) {
  return raw
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}
