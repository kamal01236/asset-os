import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Opens a blank window and invokes the browser print dialog (A4 CSS).
void printHtmlDocument(String html) {
  final web.Window? popup = web.window.open('about:blank', 'hando-report');
  if (popup == null) {
    return;
  }
  popup.document.open();
  popup.document.write(html.toJS);
  popup.document.close();
  popup.focus();
  popup.print();
}
