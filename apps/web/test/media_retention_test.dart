@Tags(['unit'])
library;

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/application/local_repository.dart';
import 'package:asset_os/application/privacy/media_retention_service.dart';
import 'package:asset_os/infrastructure/db/app_database.dart';

import 'support/test_harness.dart';

Future<void> _insertMedia(
  LocalRepository repository, {
  required String id,
  required String entityId,
  required DateTime createdAt,
}) async {
  final AppDatabase db = repository.database;
  await db.into(db.mediaAttachments).insert(
        MediaAttachmentsCompanion.insert(
          id: id,
          entityType: 'rental',
          entityId: entityId,
          filePath: 'photos/$id.jpg',
          mimeType: const Value<String>('image/jpeg'),
          sizeBytes: const Value<int>(100),
          createdAt: createdAt,
        ),
      );
}

void main() {
  group('purgeExpiredMedia', () {
    test('respects retentionDays zero (keep forever)', () async {
      final LocalRepository repository = await bootRepo();
      final DateTime old = DateTime.now().subtract(const Duration(days: 90));
      await _insertMedia(
        repository,
        id: 'MEDIA-OLD',
        entityId: 'REN-1',
        createdAt: old,
      );

      final int purged =
          await repository.purgeExpiredMedia(retentionDays: 0);
      expect(purged, 0);
      final int remaining = (await repository.database
              .select(repository.database.mediaAttachments)
              .get())
          .length;
      expect(remaining, 1);
    });

    test('deletes attachments older than retention window', () async {
      final LocalRepository repository = await bootRepo();
      final DateTime old = DateTime.now().subtract(const Duration(days: 90));
      final DateTime recent = DateTime.now().subtract(const Duration(days: 5));
      await _insertMedia(
        repository,
        id: 'MEDIA-OLD',
        entityId: 'REN-1',
        createdAt: old,
      );
      await _insertMedia(
        repository,
        id: 'MEDIA-NEW',
        entityId: 'REN-2',
        createdAt: recent,
      );

      final int purged = await MediaRetentionService(repository)
          .purgeExpired(retentionDays: 30);
      expect(purged, 1);
      final List<String> ids = (await repository.database
              .select(repository.database.mediaAttachments)
              .get())
          .map((MediaAttachmentRow row) => row.id)
          .toList();
      expect(ids, <String>['MEDIA-NEW']);
    });
  });
}
