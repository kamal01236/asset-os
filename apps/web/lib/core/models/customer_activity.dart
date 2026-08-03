import 'entities.dart';

enum CustomerActivityKind { issued, returned, event }

/// One row on the customer profile activity timeline.
class CustomerActivityEntry {
  const CustomerActivityEntry({
    required this.at,
    required this.kind,
    required this.title,
    required this.subtitle,
    this.rentalId,
  });

  final DateTime at;
  final CustomerActivityKind kind;
  final String title;
  final String subtitle;
  final String? rentalId;
}

/// Summary counts for one rental order (issued / still out / returned).
class RentalOrderStatusSummary {
  const RentalOrderStatusSummary({
    required this.issued,
    required this.pending,
    required this.returned,
  });

  final int issued;
  final int pending;
  final int returned;

  factory RentalOrderStatusSummary.fromRental(Rental rental) {
    final int issued = rental.lines.length;
    final int pending = rental.openLines.length;
    return RentalOrderStatusSummary(
      issued: issued,
      pending: pending,
      returned: issued - pending,
    );
  }
}

/// Build a datetime-sorted activity feed from the customer's rentals.
///
/// Includes issue (at [Rental.startedAt]), each line return (at
/// [RentalLine.returnedAt]), and stored [RentalEvent] rows.
List<CustomerActivityEntry> buildCustomerActivity(List<Rental> rentals) {
  final List<CustomerActivityEntry> entries = <CustomerActivityEntry>[];

  for (final Rental rental in rentals) {
    final String labels = rental.lines
        .map((RentalLine line) => line.displayLabel)
        .join(', ');
    entries.add(
      CustomerActivityEntry(
        at: rental.startedAt,
        kind: CustomerActivityKind.issued,
        title: 'Issued',
        subtitle: labels.isEmpty ? rental.id : labels,
        rentalId: rental.id,
      ),
    );

    for (final RentalLine line in rental.returnedLines) {
      final DateTime? returnedAt = line.returnedAt;
      if (returnedAt == null) {
        continue;
      }
      entries.add(
        CustomerActivityEntry(
          at: returnedAt,
          kind: CustomerActivityKind.returned,
          title: 'Returned',
          subtitle: line.displayLabel,
          rentalId: rental.id,
        ),
      );
    }

    for (final RentalEvent event in rental.timeline) {
      entries.add(
        CustomerActivityEntry(
          at: event.at,
          kind: CustomerActivityKind.event,
          title: event.title,
          subtitle: event.subtitle,
          rentalId: rental.id,
        ),
      );
    }
  }

  entries.sort((CustomerActivityEntry a, CustomerActivityEntry b) {
    final int byTime = b.at.compareTo(a.at);
    if (byTime != 0) {
      return byTime;
    }
    return a.kind.index.compareTo(b.kind.index);
  });
  return entries;
}
