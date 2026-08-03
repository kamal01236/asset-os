import 'dart:math' show max;

import 'entities.dart';

/// Customer wallet + accrued charges from active rentals as of [asOf].
class CustomerBalanceAsOf {
  const CustomerBalanceAsOf({
    required this.advancePaise,
    required this.pendingPaise,
    this.openItemsCount = 0,
  });

  /// Deposit wallet (`customer.depositBalance`).
  final int advancePaise;

  /// Sum of `rental.totalAmountAsOf(asOf)` over active rentals for the customer.
  final int pendingPaise;

  /// Open lines across those active rentals.
  final int openItemsCount;

  /// Cash still owed if settled today: `max(0, pending - advance)`.
  int get duePaise => max(0, pendingPaise - advancePaise);

  /// True when deposit, accrued charges, or open items are present.
  bool get hasActivity =>
      advancePaise > 0 || pendingPaise > 0 || openItemsCount > 0;
}

/// Computes advance / pending / due for [customer] from [allRentals] as of [asOf].
CustomerBalanceAsOf customerBalanceAsOf(
  Customer customer,
  List<Rental> allRentals,
  DateTime asOf,
) {
  int pending = 0;
  int openItems = 0;
  for (final Rental rental in allRentals) {
    if (rental.customerId != customer.id || !rental.isActive) {
      continue;
    }
    pending += rental.totalAmountAsOf(asOf);
    openItems += rental.openLines.length;
  }
  return CustomerBalanceAsOf(
    advancePaise: customer.depositBalance,
    pendingPaise: pending,
    openItemsCount: openItems,
  );
}
