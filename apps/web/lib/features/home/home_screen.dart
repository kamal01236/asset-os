import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n_ext.dart';
import '../../core/models/entities.dart';
import '../../core/models/unknown_customer.dart';
import '../../core/pricing/rental_pricing.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/global_search_typeahead.dart';
import '../../core/widgets/ui_primitives.dart';
import '../loans/loan_detail_screen.dart';
import '../loans/loans_list_screen.dart';

/// Composes Home from enabled modules (search always present).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    required this.onNewRental,
    required this.onReturnItem,
    required this.onAddInventory,
    required this.onOpenCustomer,
    required this.onOpenRental,
    required this.onOpenInventory,
    super.key,
  });

  final VoidCallback onNewRental;
  final VoidCallback onReturnItem;
  final VoidCallback onAddInventory;
  final ValueChanged<Customer> onOpenCustomer;
  final ValueChanged<Rental> onOpenRental;
  final ValueChanged<InventoryItem> onOpenInventory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<InventoryItem>> inventoryAsync =
        ref.watch(inventoryProvider);
    final AsyncValue<List<Rental>> rentalsAsync = ref.watch(rentalsProvider);
    final AsyncValue<List<Customer>> customersAsync =
        ref.watch(customersProvider);
    final AsyncValue<List<MoneyLoan>> loansAsync =
        ref.watch(moneyLoansProvider);

    if (inventoryAsync.isLoading || rentalsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<HomeModuleId> modules = ref.watch(homeModulesProvider);
    final HomeFilter? filter = ref.watch(homeFilterProvider);
    final List<InventoryItem> inventory =
        inventoryAsync.valueOrNull ?? const <InventoryItem>[];
    final List<Rental> rentals =
        rentalsAsync.valueOrNull ?? const <Rental>[];
    final List<Customer> customers =
        customersAsync.valueOrNull ?? const <Customer>[];
    final List<MoneyLoan> moneyLoans =
        loansAsync.valueOrNull ?? const <MoneyLoan>[];

    final List<Widget> children = <Widget>[];
    for (final HomeModuleId id in _orderedModules(modules)) {
      final Widget? section = _buildModule(
        context: context,
        ref: ref,
        id: id,
        filter: filter,
        inventory: inventory,
        rentals: rentals,
        customers: customers,
        moneyLoans: moneyLoans,
      );
      if (section != null) {
        if (children.isNotEmpty) {
          children.add(const SizedBox(height: 14));
        }
        children.add(section);
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: children,
    );
  }

  List<HomeModuleId> _orderedModules(List<HomeModuleId> enabled) {
    const List<HomeModuleId> order = HomeModuleId.values;
    return order.where(enabled.contains).toList();
  }

  Widget? _buildModule({
    required BuildContext context,
    required WidgetRef ref,
    required HomeModuleId id,
    required HomeFilter? filter,
    required List<InventoryItem> inventory,
    required List<Rental> rentals,
    required List<Customer> customers,
    required List<MoneyLoan> moneyLoans,
  }) {
    switch (id) {
      case HomeModuleId.search:
        return GlobalSearchTypeahead(
          hintText: context.l10n.searchAnything,
          onOpenCustomer: onOpenCustomer,
          onOpenRental: onOpenRental,
          onOpenInventory: onOpenInventory,
        );
      case HomeModuleId.kpis:
        return HomeKpisSection(
          inventory: inventory,
          rentals: rentals,
          onSelect: (HomeFilter next) => _navigateWithFilter(ref, next),
        );
      case HomeModuleId.filterResults:
        if (filter == null) {
          return null;
        }
        return HomeFilterResultsSection(
          filter: filter,
          inventory: inventory,
          rentals: rentals,
          customers: customers,
          onClear: () => ref.read(homeFilterProvider.notifier).state = null,
          onOpenRental: onOpenRental,
          onOpenInventory: onOpenInventory,
          onNewRental: onNewRental,
          onAddInventory: onAddInventory,
        );
      case HomeModuleId.needsAttention:
        if (filter != null) {
          return null;
        }
        return HomeNeedsAttentionSection(
          rentals: rentals,
          customers: customers,
          onOpenRental: onOpenRental,
        );
      case HomeModuleId.pendingJobs:
        if (filter != null) {
          return null;
        }
        return HomePendingJobsSection(
          rentals: rentals,
          customers: customers,
          onOpenRental: onOpenRental,
        );
      case HomeModuleId.pendingLoans:
        if (filter != null) {
          return null;
        }
        return HomePendingLoansSection(
          moneyLoans: moneyLoans,
          customers: customers,
        );
      case HomeModuleId.dueLoans:
        if (filter != null) {
          return null;
        }
        return HomeDueLoansSection(
          moneyLoans: moneyLoans,
          customers: customers,
        );
      case HomeModuleId.quickActions:
        return HomeQuickActionsSection(
          onNewRental: onNewRental,
          onReturnItem: onReturnItem,
          onAddInventory: onAddInventory,
        );
      case HomeModuleId.recentActivity:
        return HomeRecentActivitySection(
          rentals: rentals,
          customers: customers,
          onOpenRental: onOpenRental,
        );
      case HomeModuleId.suggestions:
        return const HomeSuggestionsSection();
    }
  }

  void _navigateWithFilter(WidgetRef ref, HomeFilter filter) {
    ref.read(homeFilterProvider.notifier).state = null;
    switch (filter) {
      case HomeFilter.active:
        ref.read(rentalsListFilterProvider.notifier).state =
            RentalsListFilter.active;
        ref.read(currentTabIndexProvider.notifier).state = kTabIndexRentals;
      case HomeFilter.dueToday:
        ref.read(rentalsListFilterProvider.notifier).state =
            RentalsListFilter.dueToday;
        ref.read(currentTabIndexProvider.notifier).state = kTabIndexRentals;
      case HomeFilter.overdue:
        ref.read(rentalsListFilterProvider.notifier).state =
            RentalsListFilter.overdue;
        ref.read(currentTabIndexProvider.notifier).state = kTabIndexRentals;
      case HomeFilter.available:
        ref.read(inventoryListFilterProvider.notifier).state =
            InventoryListFilter.available;
        ref.read(currentTabIndexProvider.notifier).state = kTabIndexInventory;
    }
  }
}

class HomeKpisSection extends StatelessWidget {
  const HomeKpisSection({
    required this.inventory,
    required this.rentals,
    required this.onSelect,
    super.key,
  });

  final List<InventoryItem> inventory;
  final List<Rental> rentals;
  final ValueChanged<HomeFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.todayAtAGlance,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            KpiChip(
              label: l10n.kpiActive,
              value: summaryCount(
                status: AssetStatus.rented,
                inventory: inventory,
                rentals: rentals,
              ),
              status: AssetStatus.rented,
              onTap: () => onSelect(HomeFilter.active),
            ),
            KpiChip(
              label: l10n.statusDueToday,
              value: summaryCount(
                status: AssetStatus.dueToday,
                inventory: inventory,
                rentals: rentals,
              ),
              status: AssetStatus.dueToday,
              onTap: () => onSelect(HomeFilter.dueToday),
            ),
            KpiChip(
              label: l10n.statusOverdue,
              value: summaryCount(
                status: AssetStatus.overdue,
                inventory: inventory,
                rentals: rentals,
              ),
              status: AssetStatus.overdue,
              onTap: () => onSelect(HomeFilter.overdue),
            ),
            KpiChip(
              label: l10n.statusAvailable,
              value: summaryCount(
                status: AssetStatus.available,
                inventory: inventory,
                rentals: rentals,
              ),
              status: AssetStatus.available,
              onTap: () => onSelect(HomeFilter.available),
            ),
          ],
        ),
      ],
    );
  }
}

class HomeFilterResultsSection extends StatelessWidget {
  const HomeFilterResultsSection({
    required this.filter,
    required this.inventory,
    required this.rentals,
    required this.customers,
    required this.onClear,
    required this.onOpenRental,
    required this.onOpenInventory,
    required this.onNewRental,
    required this.onAddInventory,
    super.key,
  });

  final HomeFilter filter;
  final List<InventoryItem> inventory;
  final List<Rental> rentals;
  final List<Customer> customers;
  final VoidCallback onClear;
  final ValueChanged<Rental> onOpenRental;
  final ValueChanged<InventoryItem> onOpenInventory;
  final VoidCallback onNewRental;
  final VoidCallback onAddInventory;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final DateTime now = DateTime.now();
    final String filterLabel = _filterLabel(l10n, filter);

    if (filter == HomeFilter.available) {
      final List<InventoryItem> items =
          inventory.where((InventoryItem item) => item.availableUnits > 0).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ActiveFilterBar(label: filterLabel, onClear: onClear),
          const SizedBox(height: 8),
          if (items.isEmpty)
            EmptyStatePane(
              title: l10n.homeFilterEmptyTitle,
              subtitle: l10n.homeFilterEmptyResourcesSubtitle,
              ctaLabel: l10n.actionAddResource,
              onPressed: onAddInventory,
            )
          else
            ..._inventoryCards(context, items, onOpenInventory),
        ],
      );
    }

    final AssetStatus status = filter.status;
    final List<Rental> matched = rentals
        .where((Rental rental) => rental.statusFor(now) == status)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ActiveFilterBar(label: filterLabel, onClear: onClear),
        const SizedBox(height: 8),
        if (matched.isEmpty)
          EmptyStatePane(
            title: l10n.homeFilterEmptyTitle,
            subtitle: l10n.homeFilterEmptyRentalsSubtitle(filterLabel),
            ctaLabel: l10n.actionNewRental,
            onPressed: onNewRental,
          )
        else
          ..._rentalCards(context, matched, customers, onOpenRental),
      ],
    );
  }
}

class HomeNeedsAttentionSection extends StatelessWidget {
  const HomeNeedsAttentionSection({
    required this.rentals,
    required this.customers,
    required this.onOpenRental,
    super.key,
  });

  final List<Rental> rentals;
  final List<Customer> customers;
  final ValueChanged<Rental> onOpenRental;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final DateTime now = DateTime.now();
    final List<Rental> attention = rentals.where((Rental rental) {
      final AssetStatus status = rental.statusFor(now);
      return status == AssetStatus.dueToday || status == AssetStatus.overdue;
    }).toList()
      ..sort((Rental a, Rental b) {
        final DateTime? aDue = a.dueAt;
        final DateTime? bDue = b.dueAt;
        if (aDue == null && bDue == null) {
          return 0;
        }
        if (aDue == null) {
          return 1;
        }
        if (bDue == null) {
          return -1;
        }
        return aDue.compareTo(bDue);
      });
    final List<Rental> limited = attention.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.needsAttentionTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (limited.isEmpty)
          CompactEmptyState(
            message: l10n.needsAttentionEmptySubtitle,
          )
        else
          ..._rentalCards(context, limited, customers, onOpenRental),
      ],
    );
  }
}

class HomePendingJobsSection extends StatelessWidget {
  const HomePendingJobsSection({
    required this.rentals,
    required this.customers,
    required this.onOpenRental,
    super.key,
  });

  final List<Rental> rentals;
  final List<Customer> customers;
  final ValueChanged<Rental> onOpenRental;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final List<Rental> pending = rentals
        .where((Rental rental) => rental.hasPendingJobs)
        .toList()
      ..sort((Rental a, Rental b) => b.startedAt.compareTo(a.startedAt));
    final List<Rental> limited = pending.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.pendingJobsTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (limited.isEmpty)
          CompactEmptyState(
            message: l10n.pendingJobsEmptySubtitle,
          )
        else
          ..._rentalCards(context, limited, customers, onOpenRental),
      ],
    );
  }
}

class HomePendingLoansSection extends StatelessWidget {
  const HomePendingLoansSection({
    required this.moneyLoans,
    required this.customers,
    super.key,
  });

  final List<MoneyLoan> moneyLoans;
  final List<Customer> customers;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final DateTime now = DateTime.now();
    final Map<String, Customer> byId = <String, Customer>{
      for (final Customer c in customers) c.id: c,
    };
    final List<MoneyLoan> pending = moneyLoans
        .where((MoneyLoan l) => l.status == MoneyLoanStatus.pending)
        .toList()
      ..sort((MoneyLoan a, MoneyLoan b) => b.createdAt.compareTo(a.createdAt));
    final List<MoneyLoan> limited = pending.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                l10n.pendingLoansTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const LoansListScreen(),
                  ),
                );
              },
              child: Text(l10n.customerLoansViewAll),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (limited.isEmpty)
          CompactEmptyState(message: l10n.pendingLoansEmptySubtitle)
        else
          ...limited.map((MoneyLoan loan) {
            final LoanScenario scenario =
                computeLoanScenario(loan: loan, now: now);
            final Customer? customer = byId[loan.customerId];
            final String direction =
                loan.direction == MoneyLoanDirection.given
                    ? l10n.loanDirectionGiven
                    : l10n.loanDirectionTaken;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: EntityCard(
                title: customer?.name ?? loan.customerId,
                subtitle:
                    '$direction · ${formatMoney(scenario.pendingPaise, currencyCode: loan.currencyCode)}',
                leadingIcon: Icons.account_balance_wallet_outlined,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => LoanDetailScreen(loanId: loan.id),
                    ),
                  );
                },
              ),
            );
          }),
      ],
    );
  }
}

class HomeDueLoansSection extends StatelessWidget {
  const HomeDueLoansSection({
    required this.moneyLoans,
    required this.customers,
    super.key,
  });

  final List<MoneyLoan> moneyLoans;
  final List<Customer> customers;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final DateTime now = DateTime.now();
    final Map<String, Customer> byId = <String, Customer>{
      for (final Customer c in customers) c.id: c,
    };
    final List<MoneyLoan> due = moneyLoans
        .where((MoneyLoan l) => isMoneyLoanDue(l, now))
        .toList()
      ..sort((MoneyLoan a, MoneyLoan b) {
        final DateTime aDue = a.interestEndedAt!;
        final DateTime bDue = b.interestEndedAt!;
        return aDue.compareTo(bDue);
      });
    final List<MoneyLoan> limited = due.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.dueLoansTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        if (limited.isEmpty)
          CompactEmptyState(message: l10n.dueLoansEmptySubtitle)
        else
          ...limited.map((MoneyLoan loan) {
            final LoanScenario scenario =
                computeLoanScenario(loan: loan, now: now);
            final Customer? customer = byId[loan.customerId];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: EntityCard(
                title: customer?.name ?? loan.customerId,
                subtitle: formatMoney(
                  scenario.pendingPaise,
                  currencyCode: loan.currencyCode,
                ),
                leadingIcon: Icons.event_busy_outlined,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => LoanDetailScreen(loanId: loan.id),
                    ),
                  );
                },
              ),
            );
          }),
      ],
    );
  }
}

class HomeQuickActionsSection extends StatelessWidget {
  const HomeQuickActionsSection({
    required this.onNewRental,
    required this.onReturnItem,
    required this.onAddInventory,
    super.key,
  });

  final VoidCallback onNewRental;
  final VoidCallback onReturnItem;
  final VoidCallback onAddInventory;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.quickActions,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            FilledButton.icon(
              onPressed: onNewRental,
              icon: const Icon(Icons.playlist_add_circle_outlined),
              label: Text(l10n.actionNewRental),
            ),
            FilledButton.tonalIcon(
              onPressed: onReturnItem,
              icon: const Icon(Icons.assignment_return_outlined),
              label: Text(l10n.actionReturnItem),
            ),
            FilledButton.tonalIcon(
              onPressed: onAddInventory,
              icon: const Icon(Icons.add_box_outlined),
              label: Text(l10n.actionAddResource),
            ),
          ],
        ),
      ],
    );
  }
}

class HomeRecentActivitySection extends StatelessWidget {
  const HomeRecentActivitySection({
    required this.rentals,
    required this.customers,
    required this.onOpenRental,
    super.key,
  });

  final List<Rental> rentals;
  final List<Customer> customers;
  final ValueChanged<Rental> onOpenRental;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final List<Rental> recent = List<Rental>.from(rentals)
      ..sort((Rental a, Rental b) {
        final DateTime aAt = a.returnedAt ?? a.startedAt;
        final DateTime bAt = b.returnedAt ?? b.startedAt;
        return bAt.compareTo(aAt);
      });
    final List<Rental> limited = recent.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.recentActivityTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (limited.isEmpty)
          Text(
            l10n.recentActivityEmpty,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          )
        else
          ..._rentalCards(context, limited, customers, onOpenRental),
      ],
    );
  }
}

class HomeSuggestionsSection extends StatelessWidget {
  const HomeSuggestionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.aiSuggestionsTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.aiSuggestionsBody,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

String _filterLabel(AppLocalizations l10n, HomeFilter filter) {
  switch (filter) {
    case HomeFilter.active:
      return l10n.kpiActive;
    case HomeFilter.dueToday:
      return l10n.statusDueToday;
    case HomeFilter.overdue:
      return l10n.statusOverdue;
    case HomeFilter.available:
      return l10n.statusAvailable;
  }
}

List<Widget> _rentalCards(
  BuildContext context,
  List<Rental> rentals,
  List<Customer> customers,
  ValueChanged<Rental> onOpenRental,
) {
  final AppLocalizations l10n = context.l10n;
  final DateTime now = DateTime.now();
  final List<Widget> cards = <Widget>[];
  for (int i = 0; i < rentals.length; i++) {
    final Rental rental = rentals[i];
    final Customer customer = customers.firstWhere(
      (Customer item) => item.id == rental.customerId,
      orElse: () => Customer(
        id: 'unknown',
        name: l10n.unknownCustomer,
        phone: '--',
        isTrusted: false,
        qrCode: 'unknown',
      ),
    );
    if (i > 0) {
      cards.add(const SizedBox(height: 10));
    }
    cards.add(
      EntityCard(
        title: _rentalLinesLabel(rental),
        subtitle:
            '${rentalPartyLabel(customer, rental)} · ${_rentalAmountSubtitle(l10n, rental)}',
        leadingIcon: Icons.assignment_outlined,
        status: rental.statusFor(now),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => onOpenRental(rental),
      ),
    );
  }
  return cards;
}

List<Widget> _inventoryCards(
  BuildContext context,
  List<InventoryItem> items,
  ValueChanged<InventoryItem> onOpenInventory,
) {
  final AppLocalizations l10n = context.l10n;
  final List<Widget> cards = <Widget>[];
  for (int i = 0; i < items.length; i++) {
    final InventoryItem item = items[i];
    if (i > 0) {
      cards.add(const SizedBox(height: 10));
    }
    cards.add(
      EntityCard(
        title: item.name,
        subtitle: l10n.inventoryAvailableSubtitle(
          item.category,
          item.availableUnits,
          item.totalUnits,
        ),
        leadingIcon: Icons.inventory_2_outlined,
        status: AssetStatus.available,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => onOpenInventory(item),
      ),
    );
  }
  return cards;
}

String _rentalLinesLabel(Rental rental) {
  final List<RentalLine> preferred =
      rental.isActive ? rental.openLines : rental.lines;
  final List<RentalLine> source =
      preferred.isNotEmpty ? preferred : rental.lines;
  if (source.isEmpty) {
    return rental.id;
  }
  return source.map((RentalLine line) => line.displayLabel).join(', ');
}

String _shortDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

String _rentalAmountSubtitle(AppLocalizations l10n, Rental rental) {
  final DateTime now = DateTime.now();
  final String amount = formatMoney(rental.totalAmountAsOf(now));
  if (rental.isOpenEnded) {
    return l10n.rentalAmountOpenEnded(amount);
  }
  return l10n.rentalAmountSubtitle(
    _shortDate(rental.dueAt!),
    amount,
  );
}
