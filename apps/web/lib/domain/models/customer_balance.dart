import 'dart:math' show max;

import 'entities.dart';

/// Signed aggregate of a customer's orders as of [asOf].
///
/// Positive [netPaise] means the customer owes the shop; negative is credit.
class CustomerBalanceAsOf {
  const CustomerBalanceAsOf({
    required this.advancePaise,
    required this.pendingPaise,
    required this.netPaise,
    this.openItemsCount = 0,
  });

  /// Sum of order deposits (`rental.depositAmount`) across non-cancelled orders.
  final int advancePaise;

  /// Sum of bill charges across non-cancelled orders.
  final int pendingPaise;

  /// Signed net: `pendingPaise - advancePaise` (cancelled orders contribute 0).
  final int netPaise;

  /// Open rent lines across open orders.
  final int openItemsCount;

  /// Cash still owed if settled today: `max(0, net)`.
  int get duePaise => max(0, netPaise);

  /// Credit when deposits exceed charges: `max(0, -net)`.
  int get creditPaise => max(0, -netPaise);

  /// True when deposits, charges, open items, or a non-zero net are present.
  bool get hasActivity =>
      advancePaise > 0 ||
      pendingPaise > 0 ||
      openItemsCount > 0 ||
      netPaise != 0;
}

/// Computes advance / pending / signed net for [customer] from [allRentals].
CustomerBalanceAsOf customerBalanceAsOf(
  Customer customer,
  List<Rental> allRentals,
  DateTime asOf,
) {
  int advance = 0;
  int pending = 0;
  int openItems = 0;
  int net = 0;
  for (final Rental rental in allRentals) {
    if (rental.customerId != customer.id) {
      continue;
    }
    if (rental.orderStatus == OrderStatus.cancelled) {
      continue;
    }
    advance += rental.depositAmount;
    pending += rental.billChargesAsOf(asOf);
    net += rental.orderNetAsOf(asOf);
    if (rental.isActive) {
      openItems += rental.openRentLines.length;
    }
  }
  return CustomerBalanceAsOf(
    advancePaise: advance,
    pendingPaise: pending,
    netPaise: net,
    openItemsCount: openItems,
  );
}
