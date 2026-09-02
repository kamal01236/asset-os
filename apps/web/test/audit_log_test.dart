@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/application/local_repository.dart';
import 'package:asset_os/domain/models/entities.dart';

import 'support/test_harness.dart';

void main() {
  group('audit log', () {
    test('customer upsert appends customer_upsert and list returns it', () async {
      final LocalRepository repository = await bootRepo(seedDemo: false);

      final Customer customer = await repository.upsertCustomerByPhone(
        phone: '9988776655',
        fallbackName: 'Audit Customer',
      );

      final List<AuditEvent> events = await repository.listAuditEvents();
      expect(events, isNotEmpty);
      expect(events.first.event, 'customer_upsert');
      expect(events.first.entityType, 'customer');
      expect(events.first.entityId, customer.id);
    });

    test('backup restore writes backup_restore audit', () async {
      final LocalRepository repository = await bootRepo(seedDemo: true);
      final String json = await repository.exportBackupJson();

      await repository.importBackupJson(json, replaceExisting: true);

      final List<AuditEvent> events = await repository.listAuditEvents();
      expect(
        events.any((AuditEvent e) => e.event == 'backup_restore'),
        isTrue,
      );
    });
  });
}
