import '../../domain/loans/loan_balance.dart';
import '../../domain/loans/loan_models.dart';
import '../../domain/models/entities.dart';
import '../../domain/models/unknown_customer.dart';
import '../../domain/pricing/rental_pricing.dart';

/// Product-level type for the unified Transactions list (engines stay separate).
enum TransactionKind { order, loan }

/// Lightweight row for the Transactions tab / customer Transactions section.
sealed class TransactionListItem {
  const TransactionListItem();

  String get id;
  String get customerId;
  TransactionKind get kind;
  DateTime get activityAt;

  String partyLabel(Map<String, Customer> customersById);
  String statusLabel({
    required DateTime now,
    required String Function(OrderStatus) orderStatus,
    required String Function(AssetStatus) assetStatus,
    required String Function(MoneyLoanStatus) loanStatus,
  });
  String amountLabel({required DateTime now});
}

/// Order / rental engine row.
final class OrderTransactionItem extends TransactionListItem {
  const OrderTransactionItem(this.rental);

  final Rental rental;

  @override
  String get id => rental.id;

  @override
  String get customerId => rental.customerId;

  @override
  TransactionKind get kind => TransactionKind.order;

  @override
  DateTime get activityAt => rental.startedAt;

  @override
  String partyLabel(Map<String, Customer> customersById) {
    final Customer customer = customersById[rental.customerId] ??
        Customer(
          id: rental.customerId,
          name: '',
          phone: '',
          isTrusted: false,
          qrCode: rental.customerId,
        );
    return rentalPartyLabel(customer, rental);
  }

  @override
  String statusLabel({
    required DateTime now,
    required String Function(OrderStatus) orderStatus,
    required String Function(AssetStatus) assetStatus,
    required String Function(MoneyLoanStatus) loanStatus,
  }) {
    if (rental.orderStatus == OrderStatus.open) {
      final AssetStatus urgency = rental.statusFor(now);
      if (urgency == AssetStatus.dueToday || urgency == AssetStatus.overdue) {
        return assetStatus(urgency);
      }
    }
    return orderStatus(rental.orderStatus);
  }

  @override
  String amountLabel({required DateTime now}) {
    return formatMoney(rental.billChargesAsOf(now));
  }
}

/// Cash money-loan engine row.
final class LoanTransactionItem extends TransactionListItem {
  const LoanTransactionItem(this.loan);

  final MoneyLoan loan;

  @override
  String get id => loan.id;

  @override
  String get customerId => loan.customerId;

  @override
  TransactionKind get kind => TransactionKind.loan;

  @override
  DateTime get activityAt => loan.closedAt ?? loan.createdAt;

  @override
  String partyLabel(Map<String, Customer> customersById) {
    return customersById[loan.customerId]?.name ?? loan.customerId;
  }

  @override
  String statusLabel({
    required DateTime now,
    required String Function(OrderStatus) orderStatus,
    required String Function(AssetStatus) assetStatus,
    required String Function(MoneyLoanStatus) loanStatus,
  }) {
    return loanStatus(loan.status);
  }

  @override
  String amountLabel({required DateTime now}) {
    final LoanScenario scenario = computeLoanScenario(loan: loan, now: now);
    return formatMoney(scenario.pendingPaise, currencyCode: loan.currencyCode);
  }
}

/// Whether New Order should appear in the Transactions create chooser.
bool canCreateOrderTransaction(Iterable<ResourceType> enabled) {
  return enabled.any((ResourceType t) => t != ResourceType.financial);
}

/// Whether New Loan should appear (money lending / financial enabled).
bool canCreateLoanTransaction(Iterable<ResourceType> enabled) {
  return enabled.contains(ResourceType.financial);
}

/// Orders filter chip: order-capable types, or existing rentals.
bool showOrdersTransactionFilter(
  Iterable<ResourceType> enabled,
  Iterable<Rental> rentals,
) {
  return canCreateOrderTransaction(enabled) || rentals.isNotEmpty;
}

/// Loans filter chip: financial enabled, or existing loans.
bool showLoansTransactionFilter(
  Iterable<ResourceType> enabled,
  Iterable<MoneyLoan> loans,
) {
  return canCreateLoanTransaction(enabled) || loans.isNotEmpty;
}

/// Merge orders + loans and sort newest activity first.
List<TransactionListItem> mergeTransactionListItems({
  required Iterable<Rental> rentals,
  required Iterable<MoneyLoan> loans,
}) {
  final List<TransactionListItem> items = <TransactionListItem>[
    for (final Rental rental in rentals) OrderTransactionItem(rental),
    for (final MoneyLoan loan in loans) LoanTransactionItem(loan),
  ];
  items.sort(
    (TransactionListItem a, TransactionListItem b) =>
        b.activityAt.compareTo(a.activityAt),
  );
  return items;
}
