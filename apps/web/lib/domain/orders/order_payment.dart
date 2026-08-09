import '../models/entities.dart';

/// How cash received is split across sell due and order advance/security.
class OrderPaymentAllocation {
  const OrderPaymentAllocation({
    required this.sellPaidDelta,
    required this.sellDiscountDelta,
    required this.advanceDelta,
  });

  final int sellPaidDelta;
  final int sellDiscountDelta;
  final int advanceDelta;
}

/// Allocate [amountReceivedPaise] sell-first, then advance/security.
///
/// When received is less than [sellOutstandingPaise], the shortfall becomes
/// [OrderPaymentAllocation.sellDiscountDelta]. Excess over [securityPaise]
/// becomes additional advance unless [treatExcessAsDiscount] is true (then
/// advance is capped at [securityPaise]).
OrderPaymentAllocation allocateOrderPayment({
  required int sellOutstandingPaise,
  required int amountReceivedPaise,
  required int securityPaise,
  bool treatExcessAsDiscount = false,
}) {
  if (amountReceivedPaise < 0) {
    throw ArgumentError('Amount received cannot be negative');
  }
  if (securityPaise < 0) {
    throw ArgumentError('Security amount cannot be negative');
  }
  final int outstanding =
      sellOutstandingPaise < 0 ? 0 : sellOutstandingPaise;
  final int sellCover = amountReceivedPaise < outstanding
      ? amountReceivedPaise
      : outstanding;
  final int shortfall = outstanding - sellCover;
  final int remainder = amountReceivedPaise - sellCover;
  final int advanceDelta;
  if (treatExcessAsDiscount) {
    advanceDelta = remainder < securityPaise ? remainder : securityPaise;
  } else {
    advanceDelta = remainder;
  }
  return OrderPaymentAllocation(
    sellPaidDelta: sellCover,
    sellDiscountDelta: shortfall,
    advanceDelta: advanceDelta,
  );
}

/// Sum of catalog [InventoryItem.securityDepositPaise] for each rent line.
int computeSuggestedSecurityPaise(
  Rental rental,
  Map<String, InventoryItem> inventoryById,
) {
  int sum = 0;
  for (final RentalLine line in rental.lines) {
    if (!line.isRent) {
      continue;
    }
    final InventoryItem? item = inventoryById[line.itemId];
    final int perUnit = item?.securityDepositPaise ?? 0;
    sum += perUnit < 0 ? 0 : perUnit;
  }
  return sum;
}

/// True when catalog type is typically rented (security deposit is meaningful).
bool catalogSupportsSecurityDeposit(ResourceType type) {
  return type.defaultFulfillment == LineFulfillment.rent;
}
