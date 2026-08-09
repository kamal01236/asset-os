@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/infrastructure/l10n/india_date_format.dart';

void main() {
  group('formatIndiaDate', () {
    test('formats as dd/MM/yyyy', () {
      expect(formatIndiaDate(DateTime(2026, 8, 6)), '06/08/2026');
      expect(formatIndiaDate(DateTime(2026, 1, 9)), '09/01/2026');
    });
  });

  group('formatIndiaDateTime', () {
    test('formats as dd/MM/yyyy HH:mm', () {
      expect(
        formatIndiaDateTime(DateTime(2026, 8, 6, 15, 5)),
        '06/08/2026 15:05',
      );
      expect(
        formatIndiaDateTime(DateTime(2026, 12, 31, 0, 0)),
        '31/12/2026 00:00',
      );
    });
  });
}
