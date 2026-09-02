import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Triggers a browser download of [json] as a UTF-8 JSON file via Blob + anchor.
Future<void> saveBackupFile(String json, String filename) async {
  final web.Blob blob = web.Blob(
    <JSString>[json.toJS].toJS,
    web.BlobPropertyBag(type: 'application/json'),
  );
  final String url = web.URL.createObjectURL(blob);
  final web.HTMLAnchorElement anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}

/// Opens a hidden `<input type=file>` and reads the chosen file's text.
///
/// Returns null if the user cancels or the file cannot be read.
Future<String?> pickBackupFile() async {
  final Completer<String?> completer = Completer<String?>();
  final web.HTMLInputElement input =
      web.document.createElement('input') as web.HTMLInputElement
        ..type = 'file'
        ..accept = '.json,application/json';
  input.style.display = 'none';
  web.document.body?.append(input);

  void finish(String? value) {
    if (!completer.isCompleted) {
      completer.complete(value);
    }
    input.remove();
  }

  input.addEventListener(
    'change',
    (web.Event _) {
      final web.FileList? files = input.files;
      if (files == null || files.length == 0) {
        finish(null);
        return;
      }
      final web.File file = files.item(0)!;
      final web.FileReader reader = web.FileReader();
      reader.addEventListener(
        'load',
        (web.Event _) {
          final JSAny? result = reader.result;
          final bool isString = result != null && result.isA<JSString>();
          finish(isString ? (result as JSString).toDart : null);
        }.toJS,
      );
      reader.addEventListener(
        'error',
        (web.Event _) {
          finish(null);
        }.toJS,
      );
      reader.readAsText(file);
    }.toJS,
  );
  // Fired by modern browsers when the picker is dismissed without a selection.
  input.addEventListener(
    'cancel',
    (web.Event _) {
      finish(null);
    }.toJS,
  );

  return completer.future;
}
