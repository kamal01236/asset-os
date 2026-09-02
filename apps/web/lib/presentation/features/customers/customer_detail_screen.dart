import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/app_providers.dart';
import '../../../domain/models/customer_balance.dart';
import '../../../domain/models/entities.dart';
import '../../../domain/subscriptions/subscription_coverage.dart';
import '../../../domain/subscriptions/subscription_models.dart';
import '../../../infrastructure/l10n/india_date_format.dart';
import '../../../infrastructure/l10n/l10n_ext.dart';
import '../../privacy/privacy_display.dart';
import '../../theme/app_theme.dart';
import '../../transactions/transaction_list_item.dart';
import '../../widgets/ui_primitives.dart';
import '../loans/loan_detail_screen.dart';
import '../orders/rental_detail_nav.dart';
import '../orders/rental_labels.dart';
import '../transactions/transactions_screen.dart';

class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({
    required this.customerId,
    super.key,
  });

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<Customer>> customersAsync = ref.watch(customersProvider);
    final AsyncValue<List<Rental>> rentalsAsync = ref.watch(rentalsProvider);
    final AsyncValue<List<MoneyLoan>> loansAsync =
        ref.watch(moneyLoansForCustomerProvider(customerId));
    final AsyncValue<List<CustomerSubscription>> subsAsync =
        ref.watch(customerSubscriptionsForCustomerProvider(customerId));

    if (customersAsync.isLoading || rentalsAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<Customer> customers = customersAsync.valueOrNull ?? const <Customer>[];
    final List<Rental> rentals = rentalsAsync.valueOrNull ?? const <Rental>[];
    final Customer customer = customers.firstWhere((entry) => entry.id == customerId);
    final List<Rental> customerRentals =
        rentals.where((entry) => entry.customerId == customer.id).toList();
    final CustomerBalanceAsOf balance =
        customerBalanceAsOf(customer, rentals, DateTime.now());
    final List<MoneyLoan> customerLoans =
        loansAsync.valueOrNull ?? const <MoneyLoan>[];
    final List<ResourceType> enabled = ref.watch(enabledResourceTypesProvider);
    final bool canOrder = canCreateOrderTransaction(enabled);
    final bool canLoan = canCreateLoanTransaction(enabled);
    final List<TransactionListItem> customerTxns = mergeTransactionListItems(
      rentals: customerRentals,
      loans: customerLoans,
    );
    final DateTime now = DateTime.now();
    final List<CustomerSubscription> subscriptions =
        List<CustomerSubscription>.of(
      subsAsync.valueOrNull ?? const <CustomerSubscription>[],
    )..sort(
        (CustomerSubscription a, CustomerSubscription b) =>
            b.validUntil.compareTo(a.validUntil),
      );
    final CustomerSubscription? activeSub =
        highestActiveSubscription(subscriptions, now);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.customerProfileTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          ListEntityRow(
            title: customer.name,
            secondary: displayPhone(context, ref, customer.phone),
            leadingIcon: Icons.person_outline,
            pill: TierPill(trusted: customer.isTrusted),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.balancesAsOfTodayHeading,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  balanceLabeledRow(
                    context,
                    label: l10n.balanceAdvanceLabel,
                    amount: displayMoney(context, ref, balance.advancePaise),
                  ),
                  const SizedBox(height: 6),
                  balanceLabeledRow(
                    context,
                    label: l10n.balancePendingLabel,
                    amount: displayMoney(context, ref, balance.pendingPaise),
                  ),
                  if (balance.openItemsCount > 0) ...<Widget>[
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Text(
                        l10n.balanceOpenItemsCount(balance.openItemsCount),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  balanceLabeledRow(
                    context,
                    label: balance.netPaise < 0
                        ? l10n.balanceCreditLabel
                        : l10n.balanceNetLabel,
                    amount: displayMoney(context, ref, balance.netPaise),
                    emphasize: balance.netPaise != 0,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.subscriptionHistoryHeading,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    activeSub == null
                        ? l10n.subscriptionNoneActive
                        : l10n.subscriptionUntilLabel(
                            localizedSubscriptionTier(l10n, activeSub.tier),
                            formatIndiaDate(activeSub.validUntil),
                          ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (subscriptions.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 10),
                    ...subscriptions.map((CustomerSubscription row) {
                      final String status;
                      if (row.status == CustomerSubscriptionStatus.cancelled) {
                        status = l10n.subscriptionStatusCancelled;
                      } else if (!row.isActiveAt(now)) {
                        status = l10n.subscriptionStatusExpired;
                      } else {
                        status = localizedSubscriptionTier(l10n, row.tier);
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '${localizedSubscriptionTier(l10n, row.tier)} · '
                          '${formatIndiaDate(row.startsAt)} – '
                          '${formatIndiaDate(row.validUntil)}'
                          '${row.isActiveAt(now) && row.status == CustomerSubscriptionStatus.active ? '' : ' · $status'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.call_outlined),
                  title: Text(l10n.callAction),
                  subtitle: Text(customer.phone),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.callPlaceholder)),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.chat_outlined),
                  title: Text(l10n.whatsAppAction),
                  subtitle: Text(l10n.whatsAppSubtitle),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.whatsAppPlaceholder)),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l10n.customerTransactionsHeading,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              if (canOrder || canLoan)
                TextButton(
                  onPressed: () {
                    showNewTransactionChooser(
                      context,
                      canOrder: canOrder,
                      canLoan: canLoan,
                      customerId: customer.id,
                    );
                  },
                  child: Text(l10n.newTransaction),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (customerTxns.isEmpty)
            Text(l10n.customerTransactionsEmpty)
          else
            ...customerTxns.take(8).map((TransactionListItem item) {
              final DateTime now = DateTime.now();
              final String typeLabel = item.kind == TransactionKind.order
                  ? l10n.transactionTypeOrder
                  : l10n.transactionTypeLoan;
              final String status = item.statusLabel(
                now: now,
                orderStatus: (OrderStatus s) =>
                    localizedOrderStatus(l10n, s),
                assetStatus: (AssetStatus s) =>
                    localizedStatusLabel(l10n, s),
                loanStatus: (MoneyLoanStatus s) => switch (s) {
                  MoneyLoanStatus.pending => l10n.loanStatusPending,
                  MoneyLoanStatus.closed => l10n.loanStatusClosed,
                  MoneyLoanStatus.cancelled => l10n.loanStatusCancelled,
                },
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListEntityRow(
                  title: item.kind == TransactionKind.order
                      ? rentalLinesLabel(
                          (item as OrderTransactionItem).rental,
                        )
                      : status,
                  leadingIcon: item.kind == TransactionKind.order
                      ? Icons.receipt_long_outlined
                      : Icons.account_balance_wallet_outlined,
                  secondary: item.kind == TransactionKind.order
                      ? status
                      : item.amountLabel(now: now),
                  tertiary: typeLabel,
                  trailing: item.kind == TransactionKind.order
                      ? Text(
                          item.amountLabel(now: now),
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: () {
                    if (item is OrderTransactionItem) {
                      pushRentalDetail(
                        context,
                        rentalId: item.rental.id,
                      );
                    } else if (item is LoanTransactionItem) {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              LoanDetailScreen(loanId: item.loan.id),
                        ),
                      );
                    }
                  },
                ),
              );
            }),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: FilledButton(
          onPressed: () {
            showNewTransactionChooser(
              context,
              canOrder: canOrder,
              canLoan: canLoan,
              customerId: customer.id,
            );
          },
          child: Text(
            canLoan && !canOrder
                ? l10n.newLoan
                : canOrder && !canLoan
                    ? l10n.issueToCustomerAction
                    : l10n.newTransaction,
          ),
        ),
      ),
    );
  }
}

Widget balanceLabeledRow(
  BuildContext context, {
  required String label,
  required String amount,
  bool emphasize = false,
}) {
  final TextStyle? amountStyle = emphasize
      ? Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppTheme.overdue,
          fontWeight: FontWeight.w700,
        )
      : Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        );
  return Row(
    children: <Widget>[
      Expanded(
        child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ),
      Text(amount, style: amountStyle),
    ],
  );
}
