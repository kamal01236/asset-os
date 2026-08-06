import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/india_date_format.dart';
import '../../core/l10n/l10n_ext.dart';
import '../../core/models/entities.dart';
import '../../core/providers/app_providers.dart';
import '../../core/transactions/transaction_list_item.dart';
import '../../core/validation/text_rules.dart';
import '../../core/widgets/scoped_search_field.dart';
import '../../core/widgets/ui_primitives.dart';
import '../loans/loan_create_screen.dart';
import '../loans/loan_detail_screen.dart';
import '../orders/new_order_flow_screen.dart';
import '../orders/rental_detail_nav.dart';

/// Unified Orders + Loans list (engines remain separate).
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TransactionListItem> _applyHomeOrderFilter(
    List<TransactionListItem> items,
    RentalsListFilter? homeFilter,
  ) {
    if (homeFilter == null) {
      return items;
    }
    final DateTime now = DateTime.now();
    return items.where((TransactionListItem item) {
      if (item is! OrderTransactionItem) {
        return false;
      }
      return item.rental.statusFor(now) == homeFilter.status;
    }).toList();
  }

  List<TransactionListItem> _applyTypeFilter(
    List<TransactionListItem> items,
    TransactionsTypeFilter filter,
    RentalsListFilter? homeFilter,
  ) {
    if (homeFilter != null) {
      return items.whereType<OrderTransactionItem>().toList();
    }
    switch (filter) {
      case TransactionsTypeFilter.all:
        return items;
      case TransactionsTypeFilter.orders:
        return items.whereType<OrderTransactionItem>().toList();
      case TransactionsTypeFilter.loans:
        return items.whereType<LoanTransactionItem>().toList();
    }
  }

  List<TransactionListItem> _applySearch(
    List<TransactionListItem> items,
    Map<String, Customer> customersById,
  ) {
    final String q = _query.trim().toLowerCase();
    if (q.length < kMinMeaningfulTextLength) {
      return items;
    }
    return items.where((TransactionListItem item) {
      if (item.id.toLowerCase().contains(q)) {
        return true;
      }
      final String party = item.partyLabel(customersById).toLowerCase();
      if (party.contains(q)) {
        return true;
      }
      final Customer? customer = customersById[item.customerId];
      if (customer != null && customer.phone.toLowerCase().contains(q)) {
        return true;
      }
      if (item is OrderTransactionItem) {
        for (final RentalLine line in item.rental.lines) {
          if (line.displayLabel.toLowerCase().contains(q) ||
              line.catalogName.toLowerCase().contains(q) ||
              line.shortCode.toLowerCase().contains(q)) {
            return true;
          }
        }
      }
      return false;
    }).toList();
  }

  Future<void> _openNewChooser({
    required bool canOrder,
    required bool canLoan,
  }) async {
    if (!canOrder && !canLoan) {
      return;
    }
    if (canOrder && !canLoan) {
      await _openNewOrder();
      return;
    }
    if (!canOrder && canLoan) {
      await _openNewLoan();
      return;
    }
    final AppLocalizations l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: Text(l10n.newOrder),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openNewOrder();
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: Text(l10n.newLoan),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openNewLoan();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openNewOrder() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const NewOrderFlowScreen(),
      ),
    );
  }

  Future<void> _openNewLoan() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const LoanCreateScreen(),
      ),
    );
  }

  void _openItem(TransactionListItem item) {
    if (item is OrderTransactionItem) {
      pushRentalDetail(context, rentalId: item.rental.id);
      return;
    }
    if (item is LoanTransactionItem) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LoanDetailScreen(loanId: item.loan.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<Rental>> rentalsAsync = ref.watch(rentalsProvider);
    final AsyncValue<List<MoneyLoan>> loansAsync = ref.watch(moneyLoansProvider);
    final AsyncValue<List<Customer>> customersAsync =
        ref.watch(customersProvider);
    final RentalsListFilter? homeFilter = ref.watch(rentalsListFilterProvider);
    final TransactionsTypeFilter typeFilter =
        ref.watch(transactionsTypeFilterProvider);
    final List<ResourceType> enabled =
        ref.watch(enabledResourceTypesProvider);

    if (rentalsAsync.isLoading || loansAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (rentalsAsync.hasError) {
      return Center(child: Text('${rentalsAsync.error}'));
    }
    if (loansAsync.hasError) {
      return Center(child: Text('${loansAsync.error}'));
    }

    final List<Rental> rentals =
        rentalsAsync.valueOrNull ?? const <Rental>[];
    final List<MoneyLoan> loans =
        loansAsync.valueOrNull ?? const <MoneyLoan>[];
    final List<Customer> customers =
        customersAsync.valueOrNull ?? const <Customer>[];
    final Map<String, Customer> customersById = <String, Customer>{
      for (final Customer c in customers) c.id: c,
    };

    final bool showOrders =
        showOrdersTransactionFilter(enabled, rentals);
    final bool showLoans = showLoansTransactionFilter(enabled, loans) ||
        typeFilter == TransactionsTypeFilter.loans;
    final bool canOrder = canCreateOrderTransaction(enabled);
    final bool canLoan = canCreateLoanTransaction(enabled);

    final List<TransactionListItem> merged = mergeTransactionListItems(
      rentals: rentals,
      loans: loans,
    );

    if (merged.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: EmptyStatePane(
          title: l10n.noTransactionsYetTitle,
          subtitle: l10n.noTransactionsYetSubtitle,
          ctaLabel: l10n.newTransaction,
          onPressed: () => _openNewChooser(canOrder: canOrder, canLoan: canLoan),
        ),
      );
    }

    final List<TransactionListItem> typed =
        _applyTypeFilter(merged, typeFilter, homeFilter);
    final List<TransactionListItem> homeFiltered =
        _applyHomeOrderFilter(typed, homeFilter);
    final List<TransactionListItem> visible =
        _applySearch(homeFiltered, customersById);

    final String? homeFilterLabel = homeFilter == null
        ? null
        : _homeFilterLabel(l10n, homeFilter);
    final bool showTypeChips = homeFilter == null && showOrders && showLoans;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: ScopedSearchField(
                controller: _searchController,
                hintText: l10n.searchTransactionsHint,
                minLengthHint: l10n.searchTypeMinChars,
                noResultsText: l10n.searchNoResults,
                suggestions: const <SearchSuggestion>[],
                showSuggestionList: false,
                onQueryChanged: (String value) {
                  setState(() => _query = value);
                },
                onSelected: (_) {},
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () =>
                  _openNewChooser(canOrder: canOrder, canLoan: canLoan),
              icon: const Icon(Icons.add),
              label: Text(l10n.newTransaction),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (homeFilterLabel != null)
          ActiveFilterBar(
            label: homeFilterLabel,
            onClear: () =>
                ref.read(rentalsListFilterProvider.notifier).state = null,
          )
        else if (showTypeChips)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ChoiceChip(
                label: Text(l10n.transactionsFilterAll),
                selected: typeFilter == TransactionsTypeFilter.all,
                onSelected: (_) => ref
                    .read(transactionsTypeFilterProvider.notifier)
                    .state = TransactionsTypeFilter.all,
              ),
              if (showOrders)
                ChoiceChip(
                  label: Text(l10n.transactionsFilterOrders),
                  selected: typeFilter == TransactionsTypeFilter.orders,
                  onSelected: (_) => ref
                      .read(transactionsTypeFilterProvider.notifier)
                      .state = TransactionsTypeFilter.orders,
                ),
              if (showLoans)
                ChoiceChip(
                  label: Text(l10n.transactionsFilterLoans),
                  selected: typeFilter == TransactionsTypeFilter.loans,
                  onSelected: (_) => ref
                      .read(transactionsTypeFilterProvider.notifier)
                      .state = TransactionsTypeFilter.loans,
                ),
            ],
          ),
        const SizedBox(height: 12),
        if (visible.isEmpty)
          CompactEmptyState(
            message: homeFilterLabel != null
                ? l10n.homeFilterEmptyRentalsSubtitle(homeFilterLabel)
                : l10n.homeFilterEmptyTitle,
            ctaLabel: l10n.newTransaction,
            onPressed: () =>
                _openNewChooser(canOrder: canOrder, canLoan: canLoan),
          )
        else
          ...visible.map(
            (TransactionListItem item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TransactionRow(
                item: item,
                customersById: customersById,
                onTap: () => _openItem(item),
              ),
            ),
          ),
      ],
    );
  }
}

String _homeFilterLabel(AppLocalizations l10n, RentalsListFilter filter) {
  switch (filter) {
    case RentalsListFilter.active:
      return l10n.kpiActive;
    case RentalsListFilter.dueToday:
      return l10n.statusDueToday;
    case RentalsListFilter.overdue:
      return l10n.statusOverdue;
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.item,
    required this.customersById,
    required this.onTap,
  });

  final TransactionListItem item;
  final Map<String, Customer> customersById;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final DateTime now = DateTime.now();
    final String typeLabel = item.kind == TransactionKind.order
        ? l10n.transactionTypeOrder
        : l10n.transactionTypeLoan;
    final IconData icon = item.kind == TransactionKind.order
        ? Icons.receipt_long_outlined
        : Icons.account_balance_wallet_outlined;
    final String status = item.statusLabel(
      now: now,
      orderStatus: (OrderStatus s) => localizedOrderStatus(l10n, s),
      assetStatus: (AssetStatus s) => localizedStatusLabel(l10n, s),
      loanStatus: (MoneyLoanStatus s) => switch (s) {
        MoneyLoanStatus.pending => l10n.loanStatusPending,
        MoneyLoanStatus.closed => l10n.loanStatusClosed,
        MoneyLoanStatus.cancelled => l10n.loanStatusCancelled,
      },
    );

    return ListEntityRow(
      title: item.partyLabel(customersById),
      leadingIcon: icon,
      secondary: status,
      tertiary: formatIndiaDate(item.activityAt),
      pill: _TypeBadge(label: typeLabel),
      trailing: Text(
        item.amountLabel(now: now),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
      onTap: onTap,
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.onSecondaryContainer,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

/// Opens the New Order | New Loan chooser (shared with customer profile).
Future<void> showNewTransactionChooser(
  BuildContext context, {
  required bool canOrder,
  required bool canLoan,
  String? customerId,
}) async {
  if (!canOrder && !canLoan) {
    return;
  }
  final AppLocalizations l10n = context.l10n;
  Future<void> openOrder() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NewOrderFlowScreen(initialCustomerId: customerId),
      ),
    );
  }

  Future<void> openLoan() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LoanCreateScreen(initialCustomerId: customerId),
      ),
    );
  }

  if (canOrder && !canLoan) {
    await openOrder();
    return;
  }
  if (!canOrder && canLoan) {
    await openLoan();
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext sheetContext) {
      return SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: Text(l10n.newOrder),
              onTap: () {
                Navigator.of(sheetContext).pop();
                openOrder();
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: Text(l10n.newLoan),
              onTap: () {
                Navigator.of(sheetContext).pop();
                openLoan();
              },
            ),
          ],
        ),
      );
    },
  );
}
