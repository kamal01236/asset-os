@Tags(['unit'])
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/application/local_repository.dart';
import 'package:asset_os/domain/verification/verification_models.dart';
import 'package:asset_os/infrastructure/media/media_store_stub.dart';

import 'support/test_harness.dart';

void main() {
  setUp(resetMediaStoreForTests);

  test('attachMedia listMedia deleteMedia round-trip', () async {
    final LocalRepository repository = await bootRepo(seedDemo: true);
    final Uint8List bytes = Uint8List.fromList(<int>[1, 2, 3, 4]);

    final MediaAttachment attached = await repository.attachMedia(
      'rental',
      'RNT-TEST',
      bytes,
      caption: 'test',
    );
    expect(attached.sizeBytes, 4);
    expect(attached.entityType, 'rental');

    final List<MediaAttachment> listed =
        await repository.listMedia('rental', 'RNT-TEST');
    expect(listed.length, 1);
    expect(listed.first.id, attached.id);

    final Uint8List? read = await repository.readMediaBytes(attached.id);
    expect(read, bytes);

    await repository.deleteMedia(attached.id);
    expect(await repository.listMedia('rental', 'RNT-TEST'), isEmpty);
  });
}
