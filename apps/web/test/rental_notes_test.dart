import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/core/models/entities.dart';
import 'package:asset_os/core/repositories/local_repository.dart';

import 'support/test_harness.dart';

void main() {
  group('rental order notes', () {
    Future<({LocalRepository repository, Rental rental})> seedOrder() async {
      final LocalRepository repository = await bootRepo();
      final Customer customer = await ensureCustomer(repository);
      await repository.addInventory(
        name: 'Note Novel',
        category: 'Library',
        units: 2,
        billingMode: BillingMode.weekly,
        rateAmount: 5000,
      );
      final InventoryItem novel = (await repository.listInventory())
          .firstWhere((InventoryItem i) => i.name == 'Note Novel');
      await repository.createRental(
        customer: customer,
        lines: <RentalLineInput>[
          RentalLineInput(
            itemId: novel.id,
            instanceName: 'Copy A',
            shortCode: 'NOTE-01',
          ),
          RentalLineInput(
            itemId: novel.id,
            instanceName: 'Copy B',
            shortCode: 'NOTE-02',
          ),
        ],
        durationUnits: 1,
      );
      final Rental rental = (await repository.listRentals()).first;
      return (repository: repository, rental: rental);
    }

    test('addRentalNote persists multiple notes newest-first', () async {
      final (:repository, :rental) = await seedOrder();

      final RentalNote first = await repository.addRentalNote(
        rentalId: rental.id,
        body: 'First order note',
        kind: 'general',
      );
      final RentalNote second = await repository.addRentalNote(
        rentalId: rental.id,
        body: 'Terms for weekend pickup',
        kind: 'terms',
      );

      final Rental refreshed =
          (await repository.listRentals()).firstWhere((Rental r) => r.id == rental.id);
      expect(refreshed.notes, hasLength(2));
      expect(
        refreshed.notes.map((RentalNote n) => n.body),
        containsAll(<String>['First order note', 'Terms for weekend pickup']),
      );
      expect(refreshed.notes.first.id, second.id);
      expect(refreshed.notes.first.kind, RentalNoteKind.terms);
      expect(refreshed.notes.last.id, first.id);
      expect(
        refreshed.timeline.any((RentalEvent e) => e.title == 'Note added'),
        isTrue,
      );
    });

    test('addRentalNote links optional rental line', () async {
      final (:repository, :rental) = await seedOrder();
      final String lineId = rental.lines.first.id;

      final RentalNote note = await repository.addRentalNote(
        rentalId: rental.id,
        rentalItemId: lineId,
        body: 'Waist 32 inches',
        kind: 'measurement',
      );
      expect(note.rentalItemId, lineId);
      expect(note.kind, RentalNoteKind.measurement);

      final Rental refreshed =
          (await repository.listRentals()).firstWhere((Rental r) => r.id == rental.id);
      expect(refreshed.notes.single.rentalItemId, lineId);
    });

    test('addRentalNote rejects short body', () async {
      final (:repository, :rental) = await seedOrder();
      expect(
        () => repository.addRentalNote(rentalId: rental.id, body: 'ab'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('addRentalNote rejects foreign line id', () async {
      final (:repository, :rental) = await seedOrder();
      expect(
        () => repository.addRentalNote(
          rentalId: rental.id,
          rentalItemId: 'RLI-NOT-ON-THIS-ORDER',
          body: 'Should not save',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
