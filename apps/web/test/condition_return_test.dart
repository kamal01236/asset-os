@Tags(['unit'])
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/application/local_repository.dart';
import 'package:asset_os/domain/models/entities.dart';
import 'package:asset_os/infrastructure/media/media_store_stub.dart';

import 'support/test_harness.dart';

void main() {
  setUp(resetMediaStoreForTests);

  test('return with condition note and media persists timeline event', () async {
    final LocalRepository repository = await bootRepo(seedDemo: true);
    final List<Rental> rentals = await repository.watchRentals().first;
    final Rental rental = rentals.firstWhere((Rental r) => r.isActive);
    final List<String> lineIds =
        rental.openRentLines.map((RentalLine l) => l.id).toList();
    expect(lineIds, isNotEmpty);

    final attachment = await repository.attachMedia(
      'rental',
      rental.id,
      Uint8List.fromList(<int>[9, 9, 9]),
    );

    final RentalReturnResult? result = await repository.returnRentalLines(
      rental.id,
      lineIds,
      conditionNote: 'Minor scratch on case',
      mediaIds: <String>[attachment.id],
    );
    expect(result, isNotNull);

    final List<Rental> after = await repository.watchRentals().first;
    final Rental updated =
        after.firstWhere((Rental r) => r.id == rental.id);
    expect(
      updated.timeline.any((RentalEvent e) => e.title == 'condition_recorded'),
      isTrue,
    );
    expect(await repository.listMedia('rental', rental.id), isNotEmpty);
  });
}
