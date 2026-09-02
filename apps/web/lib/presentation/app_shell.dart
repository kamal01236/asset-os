import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/config/app_branding.dart';
import '../domain/inventory/inventory_categories.dart';
import '../infrastructure/l10n/india_date_format.dart';
import '../infrastructure/l10n/l10n_ext.dart';
import '../domain/models/customer_balance.dart';
import '../domain/models/entities.dart';
import '../domain/models/unknown_customer.dart';
import '../domain/orders/commercial_policy.dart';
import '../domain/orders/order_payment.dart';
import '../domain/pricing/rental_pricing.dart';
import '../domain/subscriptions/subscription_coverage.dart';
import '../domain/subscriptions/subscription_models.dart';
import '../domain/verification/verification_models.dart';
import '../application/providers/app_providers.dart';
import '../application/local_repository.dart';
import '../application/reminders/reminder_scheduler.dart';
import '../domain/search/search_scope.dart';
import '../domain/templates/field_defs.dart';
import '../domain/templates/workflows.dart';
import 'theme/app_theme.dart';
import 'transactions/transaction_list_item.dart';
import '../domain/validation/text_rules.dart';
import '../domain/payments/payment_reference.dart';
import 'widgets/category_picker_field.dart';
import 'widgets/dynamic_field_inputs.dart';
import 'widgets/global_search_typeahead.dart';
import 'widgets/reminder_digest_banner.dart';
import 'widgets/rental_timeline.dart';
import 'widgets/scoped_search_field.dart';
import 'widgets/subscription_catalog_fields.dart';
import 'widgets/ui_primitives.dart';
import 'features/home/customize_home_screen.dart';
import 'features/home/home_screen.dart';
import 'features/loans/loan_detail_screen.dart';
import 'features/orders/new_order_flow_screen.dart';
import 'features/orders/order_payment_screen.dart';
import 'features/orders/rental_detail_nav.dart';
import 'features/reports/share_reports_screen.dart';
import 'features/orders/return_verification_sheet.dart';
import 'features/settings/verification_settings_screen.dart';
import 'features/settings/backup_restore_screen.dart';
import 'features/settings/reminders_screen.dart';
import 'features/templates/business_templates_screen.dart';
import 'features/templates/enabled_resource_types_screen.dart';
import 'features/transactions/transactions_screen.dart';

export 'features/home/home_screen.dart' show HomeScreen;
export 'features/orders/new_order_flow_screen.dart'
    show NewOrderFlowScreen;

/// Registers [RentalDetailScreen] for New Order navigation (avoids circular import).
void ensureRentalDetailNavRegistered() {
  registerRentalDetailScreenFactory(
    ({required String rentalId}) => RentalDetailScreen(rentalId: rentalId),
  );
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  bool _lifecycleWorkRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_onAppResumed());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_onAppResumed());
    }
  }

  Future<void> _onAppResumed() async {
    if (_lifecycleWorkRunning || !mounted) {
      return;
    }
    _lifecycleWorkRunning = true;
    try {
      await ref.read(repositoryProvider).autoVacateOverdueRentals();
      if (!mounted) {
        return;
      }
      final ReminderScheduler scheduler =
          ReminderScheduler(ref.read(repositoryProvider));
      await scheduler.refreshScheduledReminders(
        settings: ref.read(reminderSettingsProvider),
        l10n: context.l10n,
      );
      if (mounted) {
        setState(() {});
      }
    } finally {
      _lifecycleWorkRunning = false;
    }
  }

  void _openReminderDigestTarget() {
    ref.read(currentTabIndexProvider.notifier).state = kTabIndexHome;
  }

  @override
  Widget build(BuildContext context) {
    ensureRentalDetailNavRegistered();
    final AppLocalizations l10n = context.l10n;
    final int tabIndex = ref.watch(currentTabIndexProvider);
    final bool offlineMode = ref.watch(offlineModeProvider);
    final List<Widget> pages = <Widget>[
      HomeScreen(
        onNewRental: () => _openNewRentalFlow(context),
        onReturnItem: () => _openReturnFlow(context),
        onAddInventory: () => _openAddInventoryFlow(context),
        onOpenCustomer: (Customer customer) =>
            _openCustomerDetail(context, customer),
        onOpenRental: (Rental rental) => _openRentalDetail(context, rental),
        onOpenInventory: (InventoryItem item) =>
            _openInventoryDetail(context, item),
      ),
      const TransactionsScreen(),
      InventoryScreen(
        onOpenInventory: (InventoryItem item) => _openInventoryDetail(context, item),
      ),
      CustomersScreen(
        onOpenCustomer: (Customer customer) => _openCustomerDetail(context, customer),
      ),
      const MoreScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(kAppDisplayName),
      ),
      body: Column(
        children: <Widget>[
          OfflineBanner(show: offlineMode),
          if (kIsWeb)
            ReminderDigestBanner(onView: _openReminderDigestTarget),
          Expanded(
            child: IndexedStack(
              index: tabIndex,
              children: pages,
            ),
          ),
        ],
      ),
      floatingActionButton: GlobalActionsButton(
        onSearch: () => _openSearch(context),
        onNewRental: () => _openNewRentalFlow(context),
        onReturnItem: () => _openReturnFlow(context),
        onAddInventory: () => _openAddInventoryFlow(context),
        onScan: () => _openScan(context),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabIndex,
        onDestinationSelected: (int index) {
          ref.read(currentTabIndexProvider.notifier).state = index;
        },
        destinations: <NavigationDestination>[
          NavigationDestination(icon: const Icon(Icons.home_outlined), label: l10n.navHome),
          NavigationDestination(icon: const Icon(Icons.assignment_outlined), label: l10n.navTransactions),
          NavigationDestination(icon: const Icon(Icons.inventory_2_outlined), label: l10n.navResources),
          NavigationDestination(icon: const Icon(Icons.groups_outlined), label: l10n.navCustomers),
          NavigationDestination(icon: const Icon(Icons.more_horiz), label: l10n.navMore),
        ],
      ),
    );
  }

  Future<void> _openSearch(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        final MediaQueryData media = MediaQuery.of(sheetContext);
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: media.viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: GlobalSearchTypeahead(
              autofocus: true,
              hintText: sheetContext.l10n.searchHint,
              onOpenCustomer: (Customer customer) {
                Navigator.of(sheetContext).pop();
                _openCustomerDetail(context, customer);
              },
              onOpenRental: (Rental rental) {
                Navigator.of(sheetContext).pop();
                _openRentalDetail(context, rental);
              },
              onOpenInventory: (InventoryItem item) {
                Navigator.of(sheetContext).pop();
                _openInventoryDetail(context, item);
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _openNewRentalFlow(
    BuildContext context, {
    String? customerId,
    List<String> itemIds = const <String>[],
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NewOrderFlowScreen(
          initialCustomerId: customerId,
          initialInventoryItemIds: itemIds,
        ),
      ),
    );
  }

  Future<void> _openReturnFlow(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ReturnFlowScreen(),
      ),
    );
  }

  Future<void> _openAddInventoryFlow(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AddInventoryFlowScreen(),
      ),
    );
  }

  Future<void> _openRentalDetail(BuildContext context, Rental rental) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RentalDetailScreen(rentalId: rental.id),
      ),
    );
  }

  Future<void> _openInventoryDetail(BuildContext context, InventoryItem item) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InventoryDetailScreen(itemId: item.id),
      ),
    );
  }

  Future<void> _openCustomerDetail(BuildContext context, Customer customer) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CustomerDetailScreen(customerId: customer.id),
      ),
    );
  }

  Future<void> _openScan(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ScanEntryScreen(),
      ),
    );
  }
}

enum _OrdersBillScope { all, open, completed, pendingJobs }

class RentalsScreen extends ConsumerStatefulWidget {
  const RentalsScreen({
    required this.onOpenRental,
    super.key,
  });

  final ValueChanged<Rental> onOpenRental;

  @override
  ConsumerState<RentalsScreen> createState() => _RentalsScreenState();
}

class _RentalsScreenState extends ConsumerState<RentalsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  _OrdersBillScope _scope = _OrdersBillScope.open;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Rental> _applyScope(List<Rental> rentals, RentalsListFilter? homeFilter) {
    if (homeFilter != null) {
      final DateTime now = DateTime.now();
      return rentals
          .where((Rental rental) => rental.statusFor(now) == homeFilter.status)
          .toList();
    }
    switch (_scope) {
      case _OrdersBillScope.all:
        return rentals;
      case _OrdersBillScope.open:
        return rentals
            .where((Rental rental) => rental.orderStatus == OrderStatus.open)
            .toList();
      case _OrdersBillScope.completed:
        return rentals
            .where(
              (Rental rental) => rental.orderStatus == OrderStatus.completed,
            )
            .toList();
      case _OrdersBillScope.pendingJobs:
        return rentals
            .where((Rental rental) => rental.hasPendingJobs)
            .toList();
    }
  }

  List<Rental> _applySearch(
    List<Rental> rentals,
    List<Customer> customers,
  ) {
    final String q = _query.trim().toLowerCase();
    if (q.length < kMinMeaningfulTextLength) {
      return rentals;
    }
    return rentals.where((Rental rental) {
      if (rental.id.toLowerCase().contains(q)) {
        return true;
      }
      final Customer customer = customers.firstWhere(
        (Customer item) => item.id == rental.customerId,
        orElse: () => Customer(
          id: 'unknown',
          name: '',
          phone: '',
          isTrusted: false,
          qrCode: 'unknown',
        ),
      );
      final String party = rentalPartyLabel(customer, rental).toLowerCase();
      if (party.contains(q) || customer.phone.toLowerCase().contains(q)) {
        return true;
      }
      for (final RentalLine line in rental.lines) {
        if (line.displayLabel.toLowerCase().contains(q) ||
            line.catalogName.toLowerCase().contains(q) ||
            line.shortCode.toLowerCase().contains(q)) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<Rental>> rentalsAsync = ref.watch(rentalsProvider);
    final AsyncValue<List<Customer>> customersAsync = ref.watch(customersProvider);
    final RentalsListFilter? listFilter = ref.watch(rentalsListFilterProvider);

    return rentalsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace _) => Center(child: Text('$error')),
      data: (List<Rental> rentals) {
        final List<Customer> customers =
            customersAsync.valueOrNull ?? const <Customer>[];
        if (rentals.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: EmptyStatePane(
              title: l10n.noRentalsYetTitle,
              subtitle: l10n.noRentalsYetSubtitle,
              ctaLabel: l10n.actionNewRental,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const NewOrderFlowScreen(),
                  ),
                );
              },
            ),
          );
        }

        final List<Rental> scoped = _applyScope(rentals, listFilter);
        final List<Rental> visible = _applySearch(scoped, customers);
        final String? filterLabel = listFilter == null
            ? null
            : _rentalsListFilterLabel(l10n, listFilter);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            ScopedSearchField(
              controller: _searchController,
              hintText: l10n.searchOrdersHint,
              noResultsText: l10n.searchNoResults,
              suggestions: const <SearchSuggestion>[],
              showSuggestionList: false,
              onQueryChanged: (String value) {
                setState(() => _query = value);
              },
              onSelected: (_) {},
            ),
            const SizedBox(height: 12),
            if (filterLabel != null)
              ActiveFilterBar(
                label: filterLabel,
                onClear: () =>
                    ref.read(rentalsListFilterProvider.notifier).state = null,
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  ChoiceChip(
                    label: Text(l10n.ordersFilterAll),
                    selected: _scope == _OrdersBillScope.all,
                    onSelected: (_) =>
                        setState(() => _scope = _OrdersBillScope.all),
                  ),
                  ChoiceChip(
                    label: Text(l10n.ordersFilterOpen),
                    selected: _scope == _OrdersBillScope.open,
                    onSelected: (_) =>
                        setState(() => _scope = _OrdersBillScope.open),
                  ),
                  ChoiceChip(
                    label: Text(l10n.ordersFilterCompleted),
                    selected: _scope == _OrdersBillScope.completed,
                    onSelected: (_) =>
                        setState(() => _scope = _OrdersBillScope.completed),
                  ),
                  ChoiceChip(
                    label: Text(l10n.ordersFilterPendingJobs),
                    selected: _scope == _OrdersBillScope.pendingJobs,
                    onSelected: (_) =>
                        setState(() => _scope = _OrdersBillScope.pendingJobs),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            if (visible.isEmpty)
              CompactEmptyState(
                message: filterLabel != null
                    ? l10n.homeFilterEmptyRentalsSubtitle(filterLabel)
                    : l10n.homeFilterEmptyTitle,
                ctaLabel: l10n.actionNewRental,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const NewOrderFlowScreen(),
                    ),
                  );
                },
              )
            else
              ...visible.map((Rental rental) {
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
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OrderBillCard(
                    rental: rental,
                    partyLabel: rentalPartyLabel(customer, rental),
                    linesLabel: _rentalLinesLabel(rental),
                    onTap: () => widget.onOpenRental(rental),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}

String _rentalsListFilterLabel(AppLocalizations l10n, RentalsListFilter filter) {
  switch (filter) {
    case RentalsListFilter.active:
      return l10n.kpiActive;
    case RentalsListFilter.dueToday:
      return l10n.statusDueToday;
    case RentalsListFilter.overdue:
      return l10n.statusOverdue;
  }
}

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({
    required this.onOpenInventory,
    super.key,
  });

  final ValueChanged<InventoryItem> onOpenInventory;

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  List<SearchSuggestion> _suggestions = const <SearchSuggestion>[];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onQueryChanged(String value) async {
    setState(() => _query = value);
    final String trimmed = value.trim();
    if (trimmed.length < kMinMeaningfulTextLength) {
      setState(() => _suggestions = const <SearchSuggestion>[]);
      return;
    }
    final SearchResults results;
    try {
      results = await ref.read(repositoryProvider).search(
            trimmed,
            scope: SearchScope.inventory,
          );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _suggestions = const <SearchSuggestion>[]);
      return;
    }
    if (!mounted) {
      return;
    }
    final AppLocalizations l10n = context.l10n;
    setState(() {
      _suggestions = results.inventory
          .map(
            (InventoryItem item) => SearchSuggestion(
              id: item.id,
              title: item.name,
              subtitle: l10n.inventoryAvailableSubtitle(
                item.category,
                item.availableUnits,
                item.totalUnits,
              ),
              leadingIcon: Icons.inventory_2_outlined,
            ),
          )
          .toList();
    });
  }

  List<InventoryItem> _visibleInventory(List<InventoryItem> inventory) {
    List<InventoryItem> visible = inventory;
    final InventoryListFilter? listFilter =
        ref.read(inventoryListFilterProvider);
    if (listFilter == InventoryListFilter.available) {
      visible = visible
          .where((InventoryItem item) => item.availableUnits > 0)
          .toList();
    }
    final String q = _query.trim().toLowerCase();
    if (q.length < kMinMeaningfulTextLength) {
      return visible;
    }
    return visible
        .where(
          (InventoryItem item) =>
              item.name.toLowerCase().contains(q) ||
              item.category.toLowerCase().contains(q) ||
              item.id.toLowerCase().contains(q) ||
              (item.notes?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<InventoryItem>> inventoryAsync =
        ref.watch(inventoryProvider);
    final InventoryListFilter? listFilter =
        ref.watch(inventoryListFilterProvider);
    return inventoryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace _) => Center(child: Text('$error')),
      data: (List<InventoryItem> inventory) {
        final List<InventoryItem> visible = _visibleInventory(inventory);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            ScopedSearchField(
              controller: _searchController,
              hintText: l10n.searchInventoryHint,
              noResultsText: l10n.searchNoResults,
              suggestions: _suggestions,
              onQueryChanged: _onQueryChanged,
              onSelected: (SearchSuggestion suggestion) {
                final InventoryItem item = inventory.firstWhere(
                  (InventoryItem entry) => entry.id == suggestion.id,
                );
                widget.onOpenInventory(item);
              },
            ),
            if (listFilter != null) ...<Widget>[
              const SizedBox(height: 12),
              ActiveFilterBar(
                label: l10n.statusAvailable,
                onClear: () =>
                    ref.read(inventoryListFilterProvider.notifier).state = null,
              ),
            ],
            const SizedBox(height: 12),
            if (visible.isEmpty && listFilter != null)
              EmptyStatePane(
                title: l10n.homeFilterEmptyTitle,
                subtitle: l10n.homeFilterEmptyResourcesSubtitle,
                ctaLabel: l10n.actionAddResource,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AddInventoryFlowScreen(),
                    ),
                  );
                },
              )
            else
              ...visible.map((InventoryItem item) {
                final AssetStatus status = item.availableUnits > 0
                    ? AssetStatus.available
                    : AssetStatus.rented;
                final String categoryLabel =
                    categoryWithResourceTypeBadge(l10n, item);
                final String stockMeta = l10n.inventoryStockMeta(
                  categoryLabel,
                  item.availableUnits,
                  item.totalUnits,
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ListEntityRow(
                    title: item.name,
                    secondary: stockMeta,
                    tertiary: l10n.inventoryRateSubtitle(
                      localizedBillingMode(l10n, item.billingMode),
                      formatMoney(
                        item.rateAmount,
                        currencyCode: item.currencyCode,
                      ),
                    ),
                    leadingIcon: Icons.inventory_2_outlined,
                    status: status,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => widget.onOpenInventory(item),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({
    required this.onOpenCustomer,
    super.key,
  });

  final ValueChanged<Customer> onOpenCustomer;

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  List<SearchSuggestion> _suggestions = const <SearchSuggestion>[];
  Set<String> _matchedIds = const <String>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onQueryChanged(String value) async {
    setState(() => _query = value);
    final String trimmed = value.trim();
    if (trimmed.length < kMinMeaningfulTextLength) {
      setState(() {
        _suggestions = const <SearchSuggestion>[];
        _matchedIds = const <String>{};
      });
      return;
    }
    final SearchResults results;
    try {
      results = await ref.read(repositoryProvider).search(
            trimmed,
            scope: SearchScope.customers,
          );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _suggestions = const <SearchSuggestion>[];
        _matchedIds = const <String>{};
      });
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _matchedIds = results.customers.map((Customer c) => c.id).toSet();
      _suggestions = results.customers
          .map(
            (Customer customer) => SearchSuggestion(
              id: customer.id,
              title: customer.name,
              subtitle: customer.phone,
              leadingIcon: Icons.person_outline,
            ),
          )
          .toList();
    });
  }

  List<Customer> _visibleCustomers(List<Customer> customers) {
    if (_query.trim().length < kMinMeaningfulTextLength) {
      return customers;
    }
    return customers
        .where((Customer customer) => _matchedIds.contains(customer.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<Customer>> customersAsync =
        ref.watch(customersProvider);
    final AsyncValue<List<Rental>> rentalsAsync = ref.watch(rentalsProvider);
    final AsyncValue<List<CustomerSubscription>> subsAsync =
        ref.watch(customerSubscriptionsProvider);
    if (customersAsync.isLoading || rentalsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (customersAsync.hasError) {
      return Center(child: Text('${customersAsync.error}'));
    }
    if (rentalsAsync.hasError) {
      return Center(child: Text('${rentalsAsync.error}'));
    }
    final List<Customer> customers =
        customersAsync.valueOrNull ?? const <Customer>[];
    final List<Rental> rentals = rentalsAsync.valueOrNull ?? const <Rental>[];
    final List<CustomerSubscription> subscriptions =
        subsAsync.valueOrNull ?? const <CustomerSubscription>[];
    final DateTime now = DateTime.now();
    final List<Customer> visible = _visibleCustomers(customers);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        ScopedSearchField(
          controller: _searchController,
          hintText: l10n.searchCustomersHint,
          noResultsText: l10n.searchNoResults,
          suggestions: _suggestions,
          onQueryChanged: _onQueryChanged,
          onSelected: (SearchSuggestion suggestion) {
            final Customer customer = customers.firstWhere(
              (Customer entry) => entry.id == suggestion.id,
            );
            widget.onOpenCustomer(customer);
          },
        ),
        const SizedBox(height: 12),
        ...visible.map((Customer customer) {
          final CustomerBalanceAsOf balance =
              customerBalanceAsOf(customer, rentals, now);
          final CustomerSubscription? activeSub = highestActiveSubscription(
            subscriptions.where(
              (CustomerSubscription s) => s.customerId == customer.id,
            ),
            now,
          );
          final ColorScheme scheme = Theme.of(context).colorScheme;
          final Color netColor = balance.netPaise > 0
              ? AppTheme.overdue
              : (balance.netPaise < 0
                  ? scheme.onSurfaceVariant
                  : scheme.onSurface);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ListEntityRow(
              title: customer.name,
              secondary: customer.phone,
              tertiary: activeSub == null
                  ? null
                  : l10n.customerSubscriptionMeta(
                      localizedSubscriptionTier(l10n, activeSub.tier),
                      formatIndiaDate(activeSub.validUntil),
                    ),
              leadingIcon: Icons.person_outline,
              pill: TierPill(trusted: customer.isTrusted),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (balance.hasActivity)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        formatMoney(balance.netPaise),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: netColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () => widget.onOpenCustomer(customer),
            ),
          );
        }),
      ],
    );
  }
}

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool offlineMode = ref.watch(offlineModeProvider);
    final Locale locale = ref.watch(localeProvider);
    final ThemeMode themeMode = ref.watch(themeModeProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Card(
          child: SwitchListTile(
            value: offlineMode,
            title: Text(l10n.offlineSimulationTitle),
            subtitle: Text(l10n.offlineSimulationSubtitle),
            onChanged: (bool value) {
              ref.read(offlineModeProvider.notifier).state = value;
            },
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.languageTitle),
                  subtitle: Text(l10n.languageSubtitle),
                  leading: const Icon(Icons.language),
                ),
                const SizedBox(height: 4),
                SegmentedButton<String>(
                  segments: <ButtonSegment<String>>[
                    ButtonSegment<String>(
                      value: 'en',
                      label: Text(l10n.languageEnglish),
                    ),
                    ButtonSegment<String>(
                      value: 'hi',
                      label: Text(l10n.languageHindi),
                    ),
                  ],
                  selected: <String>{locale.languageCode},
                  onSelectionChanged: (Set<String> selection) {
                    final String code = selection.first;
                    ref.read(localeProvider.notifier).setLocale(Locale(code));
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.themeTitle),
                  subtitle: Text(l10n.themeSubtitle),
                  leading: const Icon(Icons.dark_mode_outlined),
                ),
                const SizedBox(height: 4),
                SegmentedButton<ThemeMode>(
                  segments: <ButtonSegment<ThemeMode>>[
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      label: Text(l10n.themeDark),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      label: Text(l10n.themeLight),
                    ),
                  ],
                  selected: <ThemeMode>{themeMode},
                  onSelectionChanged: (Set<ThemeMode> selection) {
                    ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(selection.first);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const MyWhatsAppSettingsCard(),
        const SizedBox(height: 10),
        EntityCard(
          title: l10n.shareReportsTitle,
          subtitle: l10n.shareReportsSubtitle,
          leadingIcon: Icons.share_outlined,
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ShareReportsScreen()),
            );
          },
        ),
        const SizedBox(height: 10),
        EntityCard(
          title: l10n.remindersTitle,
          subtitle: l10n.remindersSubtitle(kAppDisplayName),
          leadingIcon: Icons.notifications_outlined,
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const RemindersScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        EntityCard(
          title: l10n.verificationSettingsTitle,
          subtitle: l10n.verificationSettingsCardSubtitle,
          leadingIcon: Icons.verified_user_outlined,
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const VerificationSettingsScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        EntityCard(
          title: l10n.backupRestoreTitle,
          subtitle: l10n.backupRestoreSubtitle,
          leadingIcon: Icons.backup_outlined,
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const BackupRestoreScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        EntityCard(
          title: l10n.customizeHomeTitle,
          subtitle: l10n.customizeHomeSubtitle,
          leadingIcon: Icons.view_quilt_outlined,
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CustomizeHomeScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        EntityCard(
          title: l10n.enabledResourceTypesTitle,
          subtitle: l10n.enabledResourceTypesSubtitle,
          leadingIcon: Icons.category_outlined,
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const EnabledResourceTypesScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        EntityCard(
          title: l10n.voiceSearchStubTitle,
          subtitle: l10n.voiceSearchStubSubtitle,
          leadingIcon: Icons.keyboard_voice_outlined,
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const VoiceSearchStubScreen()),
            );
          },
        ),
        const SizedBox(height: 10),
        EntityCard(
          title: l10n.businessTemplatesTitle,
          subtitle: l10n.businessTemplatesSubtitle,
          leadingIcon: Icons.dashboard_customize_outlined,
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const BusinessTemplatesScreen()),
            );
          },
        ),
      ],
    );
  }
}

class GlobalActionsButton extends StatelessWidget {
  const GlobalActionsButton({
    required this.onSearch,
    required this.onNewRental,
    required this.onReturnItem,
    required this.onAddInventory,
    required this.onScan,
    super.key,
  });

  final VoidCallback onSearch;
  final VoidCallback onNewRental;
  final VoidCallback onReturnItem;
  final VoidCallback onAddInventory;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return FloatingActionButton.extended(
      tooltip: l10n.actionActions,
      heroTag: 'global-actions-fab',
      onPressed: () {
        showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (BuildContext context) {
            final AppLocalizations sheetL10n = context.l10n;
            return SafeArea(
              child: Wrap(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.search),
                    title: Text(sheetL10n.actionSearch),
                    onTap: () {
                      Navigator.of(context).pop();
                      onSearch();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.playlist_add_circle_outlined),
                    title: Text(sheetL10n.actionNewRental),
                    onTap: () {
                      Navigator.of(context).pop();
                      onNewRental();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.assignment_return_outlined),
                    title: Text(sheetL10n.actionReturn),
                    onTap: () {
                      Navigator.of(context).pop();
                      onReturnItem();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.add_box_outlined),
                    title: Text(sheetL10n.actionAddResource),
                    onTap: () {
                      Navigator.of(context).pop();
                      onAddInventory();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.qr_code_scanner_outlined),
                    title: Text(sheetL10n.actionScan),
                    onTap: () {
                      Navigator.of(context).pop();
                      onScan();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
      icon: const Icon(Icons.flash_on),
      label: Text(l10n.actionActions),
    );
  }
}

String _closedLineStatusLabel(AppLocalizations l10n, RentalLine line) {
  if (line.isSell) {
    return l10n.soldLineBadge;
  }
  if (line.isJob) {
    return l10n.completedJobLineBadge;
  }
  if (line.isLost) {
    return l10n.lineLostLabel;
  }
  return l10n.lineReturnedLabel;
}

String _closedLinesHeading(AppLocalizations l10n, List<RentalLine> closed) {
  final bool anyRent = closed.any((RentalLine l) => l.isRent);
  final bool anySell = closed.any((RentalLine l) => l.isSell);
  final bool anyJob = closed.any((RentalLine l) => l.isJob);
  final bool anyLost = closed.any((RentalLine l) => l.isLost);
  final bool anyReturnedRent =
      closed.any((RentalLine l) => l.isRent && !l.isLost);
  if (anySell && !anyRent && !anyJob) {
    return l10n.soldLineBadge;
  }
  if (anyJob && !anyRent && !anySell) {
    return l10n.completedJobLineBadge;
  }
  if (anyLost && !anyReturnedRent && !anySell && !anyJob) {
    return l10n.lostLinesHeading;
  }
  return l10n.returnedLinesHeading;
}

/// Open rent lines grouped by catalog item (SKU), preserving first-seen order.
List<MapEntry<String, List<RentalLine>>> _groupRentLinesByItemId(
  List<RentalLine> lines,
) {
  final Map<String, List<RentalLine>> grouped = <String, List<RentalLine>>{};
  final List<String> order = <String>[];
  for (final RentalLine line in lines) {
    if (!grouped.containsKey(line.itemId)) {
      order.add(line.itemId);
      grouped[line.itemId] = <RentalLine>[];
    }
    grouped[line.itemId]!.add(line);
  }
  return order
      .map(
        (String itemId) => MapEntry<String, List<RentalLine>>(
          itemId,
          grouped[itemId]!,
        ),
      )
      .toList();
}

List<String> _resolveReturnLineIds({
  required Rental rental,
  required Map<String, int> qtyByItemId,
  required Set<String> selectedLineIds,
  required Map<String, bool> identityRequiredByItemId,
}) {
  final Set<String> resolved = <String>{...selectedLineIds};
  for (final MapEntry<String, int> entry in qtyByItemId.entries) {
    if (identityRequiredByItemId[entry.key] ?? true) {
      continue;
    }
    final int qty = entry.value;
    if (qty <= 0) {
      continue;
    }
    final List<RentalLine> open = rental.openRentLines
        .where((RentalLine l) => l.itemId == entry.key)
        .toList();
    final int take = qty < open.length ? qty : open.length;
    for (int i = 0; i < take; i++) {
      resolved.add(open[i].id);
    }
  }
  return resolved.toList();
}

class RentalDetailScreen extends ConsumerStatefulWidget {
  const RentalDetailScreen({
    required this.rentalId,
    super.key,
  });

  final String rentalId;

  @override
  ConsumerState<RentalDetailScreen> createState() => _RentalDetailScreenState();
}

class _RentalDetailScreenState extends ConsumerState<RentalDetailScreen> {
  final Set<String> _selectedRentLineIds = <String>{};
  final Set<String> _selectedJobLineIds = <String>{};
  final Map<String, int> _returnQtyByItemId = <String, int>{};

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<Rental>> rentalsAsync = ref.watch(rentalsProvider);
    final AsyncValue<List<Customer>> customersAsync = ref.watch(customersProvider);
    final List<InventoryItem> inventory =
        ref.watch(inventoryProvider).asData?.value ?? const <InventoryItem>[];
    final Map<String, bool> identityRequiredByItemId = <String, bool>{
      for (final InventoryItem item in inventory)
        item.id: item.requiresUnitIdentity,
    };

    if (rentalsAsync.isLoading || customersAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<Rental> rentals = rentalsAsync.valueOrNull ?? const <Rental>[];
    final List<Customer> customers = customersAsync.valueOrNull ?? const <Customer>[];

    final Rental rental = rentals.firstWhere((item) => item.id == widget.rentalId);
    final Customer customer = customers.firstWhere((item) => item.id == rental.customerId);
    final DateTime now = DateTime.now();
    final WorkflowDefinition workflow = ref.watch(activeWorkflowProvider);
    final String? workflowStatusId = effectiveWorkflowStatusId(
      stored: rental.workflowStatus,
      orderStatus: rental.orderStatus,
      workflow: workflow,
    );
    final WorkflowStatus? workflowStatus = resolveWorkflowStatusDisplay(
      workflow: workflow,
      statusId: workflowStatusId,
    );
    final List<WorkflowStatus> nextStatuses =
        rental.isActive ? workflow.nextAllowed(workflowStatusId) : const <WorkflowStatus>[];
    final int lateShown = rental.lateAmountAsOf(now);
    final int totalShown = rental.totalAmountAsOf(now);
    final List<RentalLine> openRentLines = rental.openRentLines;
    final List<RentalLine> openJobLines = rental.openJobLines;
    final List<RentalLine> closedLines = rental.returnedLines;
    final Set<String> openRentIds =
        openRentLines.map((RentalLine l) => l.id).toSet();
    final Set<String> openJobIds =
        openJobLines.map((RentalLine l) => l.id).toSet();
    final Set<String> selectedRentIds =
        _selectedRentLineIds.where(openRentIds.contains).toSet();
    final Set<String> selectedJobIds =
        _selectedJobLineIds.where(openJobIds.contains).toSet();
    final List<String> batchReturnIds = _resolveReturnLineIds(
      rental: rental,
      qtyByItemId: _returnQtyByItemId,
      selectedLineIds: selectedRentIds,
      identityRequiredByItemId: identityRequiredByItemId,
    );
    final List<MapEntry<String, List<RentalLine>>> openRentGroups =
        _groupRentLinesByItemId(openRentLines);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            Flexible(
              child: Text(
                shortOrderId(rental.id),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            OrderStatusPill(
              status: rental.orderStatus,
              urgency: rental.isActive ? rental.statusFor(now) : null,
            ),
            if (rental.hasUnpaidSell) ...<Widget>[
              const SizedBox(width: 8),
              Chip(
                label: Text(l10n.unpaidSellBadge),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor:
                    Theme.of(context).colorScheme.errorContainer,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          ListEntityRow(
            title: rentalPartyLabel(customer, rental),
            secondary: rental.nickname?.trim().isNotEmpty == true
                ? l10n.rentalNicknameSubtitle(customer.name, customer.phone)
                : l10n.phoneLabel(customer.phone),
            leadingIcon: Icons.person_outline,
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      CustomerDetailScreen(customerId: customer.id),
                ),
              );
            },
          ),
          if (rental.replacedFromRentalId != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              '← ${rental.replacedFromRentalId}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.workflowStatusHeading,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    workflowStatus?.localizedLabel(
                          Localizations.localeOf(context),
                        ) ??
                        localizedOrderStatus(l10n, rental.orderStatus),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (rental.isActive && nextStatuses.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              await ref
                                  .read(repositoryProvider)
                                  .advanceWorkflowStatus(rental.id);
                            },
                            child: Text(l10n.workflowAdvanceAction),
                          ),
                        ),
                        if (nextStatuses.length > 1) ...<Widget>[
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final String? picked =
                                    await showModalBottomSheet<String>(
                                  context: context,
                                  builder: (BuildContext sheetContext) {
                                    final Locale locale =
                                        Localizations.localeOf(sheetContext);
                                    return SafeArea(
                                      child: ListView(
                                        shrinkWrap: true,
                                        children: <Widget>[
                                          Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Text(
                                              l10n.workflowPickStatusAction,
                                              style: Theme.of(sheetContext)
                                                  .textTheme
                                                  .titleMedium,
                                            ),
                                          ),
                                          ...nextStatuses.map(
                                            (WorkflowStatus status) => ListTile(
                                              title: Text(
                                                status.localizedLabel(locale),
                                              ),
                                              onTap: () => Navigator.of(
                                                sheetContext,
                                              ).pop(status.id),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                                if (picked == null || !mounted) {
                                  return;
                                }
                                await ref
                                    .read(repositoryProvider)
                                    .advanceWorkflowStatus(
                                      rental.id,
                                      toStatusId: picked,
                                    );
                              },
                              child: Text(l10n.workflowPickStatusAction),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ] else if (!rental.isActive &&
                      rental.orderStatus == OrderStatus.completed) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      l10n.workflowStatusTerminalHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
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
                  Text(l10n.itemsHeading, style: Theme.of(context).textTheme.titleSmall),
                  if (rental.isActive &&
                      (openRentLines.isNotEmpty ||
                          openJobLines.isNotEmpty)) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      l10n.linesOpenCount(
                        openRentLines.length + openJobLines.length,
                        rental.lines.length,
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (rental.isActive && openRentLines.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(l10n.returnByQuantityHint),
                    ...openRentGroups.map((MapEntry<String, List<RentalLine>> group) {
                      final String itemId = group.key;
                      final List<RentalLine> openGroup = group.value;
                      final List<RentalLine> allForSku = rental.lines
                          .where(
                            (RentalLine l) =>
                                l.itemId == itemId && l.isRent,
                          )
                          .toList();
                      final int issued = allForSku.length;
                      final int returnedCount =
                          allForSku.where((RentalLine l) => !l.isOpen).length;
                      final int remaining = openGroup.length;
                      final String catalogName =
                          openGroup.first.catalogName.trim().isEmpty
                              ? itemId
                              : openGroup.first.catalogName.trim();
                      final bool needsIdentity =
                          identityRequiredByItemId[itemId] ?? true;
                      final int returnQty =
                          (_returnQtyByItemId[itemId] ?? 0).clamp(0, remaining);

                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              catalogName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              l10n.skuIssuedReturnedRemaining(
                                issued,
                                returnedCount,
                                remaining,
                              ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (needsIdentity) ...<Widget>[
                              const SizedBox(height: 4),
                              Text(
                                l10n.pickUnitsToReturn,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              ...openGroup.map((RentalLine line) {
                                  final bool selected =
                                      selectedRentIds.contains(line.id);
                                  final int lineTotal = line.totalAmountAsOf(
                                    rental.startedAt,
                                    rental.dueAt,
                                    now,
                                  );
                                  return CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                    value: selected,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedRentLineIds.add(line.id);
                                        } else {
                                          _selectedRentLineIds.remove(line.id);
                                        }
                                      });
                                    },
                                    title: Text(line.displayLabel),
                                    subtitle: Text(
                                      '${l10n.lineOpenLabel} · ${formatMoney(lineTotal)}',
                                    ),
                                  );
                                }),
                              if (selectedRentIds.any(
                                (String id) => openGroup
                                    .any((RentalLine l) => l.id == id),
                              ))
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton(
                                    onPressed: () async {
                                      final List<String> lostIds = openGroup
                                          .where(
                                            (RentalLine l) =>
                                                selectedRentIds.contains(l.id),
                                          )
                                          .map((RentalLine l) => l.id)
                                          .toList();
                                      final bool done =
                                          await _confirmAndMarkLinesLost(
                                        context: context,
                                        ref: ref,
                                        rental: rental,
                                        lineIds: lostIds,
                                      );
                                      if (!done || !mounted) {
                                        return;
                                      }
                                      setState(() {
                                        _selectedRentLineIds.removeAll(lostIds);
                                      });
                                      final Rental? updated = (await ref
                                              .read(repositoryProvider)
                                              .listRentals())
                                          .cast<Rental?>()
                                          .firstWhere(
                                            (Rental? r) => r?.id == rental.id,
                                            orElse: () => null,
                                          );
                                      if (!mounted) {
                                        return;
                                      }
                                      if (updated == null || !updated.isActive) {
                                        Navigator.of(this.context).pop();
                                      }
                                    },
                                    child: Text(l10n.markSelectedLostAction),
                                  ),
                                ),
                            ] else ...<Widget>[
                              const SizedBox(height: 6),
                              Row(
                                children: <Widget>[
                                  Text(l10n.returnQtyLabel),
                                  const Spacer(),
                                  IconButton(
                                    tooltip: l10n.returnQtyLabel,
                                    onPressed: returnQty <= 0
                                        ? null
                                        : () {
                                            setState(() {
                                              _returnQtyByItemId[itemId] =
                                                  returnQty - 1;
                                            });
                                          },
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                  ),
                                  Text(
                                    '$returnQty',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  IconButton(
                                    tooltip: l10n.returnQtyLabel,
                                    onPressed: returnQty >= remaining
                                        ? null
                                        : () {
                                            setState(() {
                                              _returnQtyByItemId[itemId] =
                                                  returnQty + 1;
                                            });
                                          },
                                    icon: const Icon(Icons.add_circle_outline),
                                  ),
                                ],
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: remaining == 0
                                      ? null
                                      : () async {
                                          final bool done =
                                              await _confirmAndMarkLinesLost(
                                            context: context,
                                            ref: ref,
                                            rental: rental,
                                            lineIds: openGroup
                                                .map((RentalLine l) => l.id)
                                                .toList(),
                                          );
                                          if (!done || !mounted) {
                                            return;
                                          }
                                          setState(() {
                                            _returnQtyByItemId.remove(itemId);
                                          });
                                          final Rental? updated = (await ref
                                                  .read(repositoryProvider)
                                                  .listRentals())
                                              .cast<Rental?>()
                                              .firstWhere(
                                                (Rental? r) =>
                                                    r?.id == rental.id,
                                                orElse: () => null,
                                              );
                                          if (!mounted) {
                                            return;
                                          }
                                          if (updated == null ||
                                              !updated.isActive) {
                                            Navigator.of(this.context).pop();
                                          }
                                        },
                                  child: Text(l10n.markRemainingLostAction),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                  if (rental.isActive && openJobLines.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(l10n.selectLinesToComplete),
                    ...openJobLines.map((RentalLine line) {
                      final bool selected = selectedJobIds.contains(line.id);
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        value: selected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedJobLineIds.add(line.id);
                            } else {
                              _selectedJobLineIds.remove(line.id);
                            }
                          });
                        },
                        title: Text(line.displayLabel),
                        subtitle: Text(
                          '${l10n.lineFulfillmentJob} · ${formatMoney(line.totalAmount)}',
                        ),
                      );
                    }),
                  ],
                  if (closedLines.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      _closedLinesHeading(l10n, closedLines),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    ...closedLines.map(
                      (RentalLine line) => Padding(
                        padding: const EdgeInsets.only(bottom: 4, top: 4),
                        child: Text(
                          '• ${line.displayLabel} — '
                          '${_closedLineStatusLabel(l10n, line)} · '
                          '${formatMoney(line.totalAmount)}'
                          '${line.depositApplied > 0 ? ' · ${l10n.depositAppliedLabel(formatMoney(line.depositApplied))}' : ''}',
                        ),
                      ),
                    ),
                  ],
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
                  Text(l10n.chargesHeading, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Text(
                    rental.isOpenEnded
                        ? l10n.reviewOpenEndedLabel
                        : (rental.dueAt == null
                            ? l10n.reviewOpenEndedLabel
                            : l10n.reviewDueLabel(formatIndiaDate(rental.dueAt!))),
                  ),
                  if (rental.isOpenEnded && rental.isActive)
                    Text(l10n.accruedAmountHint),
                  Text(
                    l10n.inventoryRateSubtitle(
                      localizedBillingMode(l10n, rental.billingMode),
                      formatMoney(rental.rateAmount),
                    ),
                  ),
                  const SizedBox(height: 8),
                  MoneyStack(
                    label: l10n.moneyLabelBase,
                    amount: formatMoney(
                      rental.isOpenEnded && rental.isActive
                          ? totalShown
                          : rental.baseAmount,
                    ),
                  ),
                  if (lateShown > 0)
                    MoneyStack(
                      label: l10n.moneyLabelLate,
                      amount: formatMoney(lateShown),
                    ),
                  MoneyStack(
                    label: l10n.moneyLabelTotal,
                    amount: formatMoney(totalShown),
                    emphasis: MoneyStackEmphasis.total,
                  ),
                  MoneyStack(
                    label: l10n.moneyLabelDeposit,
                    amount: formatMoney(
                      rental.isActive
                          ? rental.depositRemaining
                          : rental.depositAmount,
                    ),
                    emphasis: MoneyStackEmphasis.muted,
                  ),
                  if (rental.sellDuePaise > 0) ...<Widget>[
                    MoneyStack(
                      label: l10n.paymentMinSoldLabel,
                      amount: formatMoney(rental.sellDuePaise),
                      emphasis: MoneyStackEmphasis.muted,
                    ),
                    if (rental.sellPaidPaise > 0)
                      MoneyStack(
                        label: l10n.paymentSellPaidLabel,
                        amount: formatMoney(rental.sellPaidPaise),
                        emphasis: MoneyStackEmphasis.muted,
                      ),
                    if (rental.sellDiscountPaise > 0)
                      MoneyStack(
                        label: l10n.paymentSellDiscountLabel,
                        amount: formatMoney(rental.sellDiscountPaise),
                        emphasis: MoneyStackEmphasis.muted,
                      ),
                    if (rental.hasUnpaidSell)
                      MoneyStack(
                        label: l10n.paymentSellOutstandingLabel,
                        amount: formatMoney(rental.sellOutstandingPaise),
                        emphasis: MoneyStackEmphasis.due,
                      ),
                  ],
                  if (rental.isActive && openRentLines.isNotEmpty) ...<Widget>[
                    Builder(
                      builder: (BuildContext context) {
                        final List<RentalLine> settleLines = batchReturnIds.isEmpty
                            ? openRentLines
                            : openRentLines
                                .where(
                                  (RentalLine l) =>
                                      batchReturnIds.contains(l.id),
                                )
                                .toList();
                        int previewTotal = 0;
                        for (final RentalLine line in settleLines) {
                          previewTotal += line.totalAmountAsOf(
                            rental.startedAt,
                            rental.dueAt,
                            now,
                          );
                        }
                        final int willApply =
                            rental.depositRemaining < previewTotal
                                ? rental.depositRemaining
                                : previewTotal;
                        final int remainingDue = previewTotal - willApply;
                        final int leftover = rental.depositRemaining - willApply;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            MoneyStack(
                              label: l10n.moneyLabelWillApply,
                              amount: formatMoney(willApply),
                              emphasis: MoneyStackEmphasis.muted,
                            ),
                            if (remainingDue > 0)
                              MoneyStack(
                                label: l10n.moneyLabelRemainingDue,
                                amount: formatMoney(remainingDue),
                                emphasis: MoneyStackEmphasis.due,
                              )
                            else if (leftover > 0)
                              MoneyStack(
                                label: l10n.moneyLabelLeftover,
                                amount: formatMoney(leftover),
                                emphasis: MoneyStackEmphasis.muted,
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                  if (!rental.isActive) ...<Widget>[
                    if (rental.depositApplied > 0)
                      MoneyStack(
                        label: l10n.moneyLabelDeposit,
                        amount: formatMoney(rental.depositApplied),
                        emphasis: MoneyStackEmphasis.muted,
                      ),
                    MoneyStack(
                      label: l10n.moneyLabelNetDue,
                      amount: formatMoney(rental.amountDueAfterDeposit),
                      emphasis: rental.amountDueAfterDeposit > 0
                          ? MoneyStackEmphasis.due
                          : MoneyStackEmphasis.normal,
                    ),
                  ],
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
                    l10n.orderNotesHeading,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  if (rental.notes.isEmpty)
                    Text(
                      l10n.orderNotesEmpty,
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  else
                    ...rental.notes.map((RentalNote note) {
                      final RentalLine? linked = note.rentalItemId == null
                          ? null
                          : rental.lines
                              .where(
                                (RentalLine line) =>
                                    line.id == note.rentalItemId,
                              )
                              .firstOrNull;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              localizedRentalNoteKind(l10n, note.kind),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            if (linked != null)
                              Text(
                                linked.displayLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            Text(note.body),
                            Text(
                              formatIndiaDateTime(note.createdAt),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      );
                    }),
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
                  Text(l10n.returnEvidenceHeading, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  RentalMediaThumbnailGrid(rentalId: rental.id),
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
                  Text(l10n.timelineHeading, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  RentalTimeline(events: rental.timeline),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (rental.orderStatus != OrderStatus.cancelled) ...<Widget>[
              Builder(
                builder: (BuildContext context) {
                  final Map<String, InventoryItem> byId =
                      <String, InventoryItem>{
                    for (final InventoryItem item in inventory) item.id: item,
                  };
                  final AggregatedOrderCommercial payPolicy =
                      resolveRentalCommercial(rental, byId);
                  if (!shouldShowOrderPayCta(
                    aggregated: payPolicy,
                    rental: rental,
                  )) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => pushOrderPayment(
                            context,
                            rentalId: rental.id,
                          ),
                          icon: const Icon(Icons.payments_outlined),
                          label: Text(
                            rental.hasUnpaidSell
                                ? l10n.paymentPayAction
                                : l10n.paymentAddAdvanceAction,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                },
              ),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showAddOrderNoteSheet(
                  context: context,
                  ref: ref,
                  rental: rental,
                ),
                icon: const Icon(Icons.note_add_outlined),
                label: Text(l10n.addOrderNoteAction),
              ),
            ),
            if (rental.isActive && openRentLines.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _extendRentalDue(
                    context: context,
                    ref: ref,
                    rental: rental,
                  ),
                  icon: const Icon(Icons.event_available_outlined),
                  label: Text(l10n.extendAction),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final bool done = await _confirmAndReturnRental(
                          context: context,
                          ref: ref,
                          rental: rental,
                          customer: customer,
                          lineIds: openRentLines
                              .map((RentalLine l) => l.id)
                              .toList(),
                        );
                        if (done && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Text(l10n.returnAllAction),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: batchReturnIds.isEmpty
                          ? null
                          : () async {
                              final bool done = await _confirmAndReturnRental(
                                context: context,
                                ref: ref,
                                rental: rental,
                                customer: customer,
                                lineIds: batchReturnIds,
                              );
                              if (!done || !mounted) {
                                return;
                              }
                              final Rental? updated = (await ref
                                      .read(repositoryProvider)
                                      .listRentals())
                                  .cast<Rental?>()
                                  .firstWhere(
                                    (Rental? r) => r?.id == rental.id,
                                    orElse: () => null,
                                  );
                              if (!mounted) {
                                return;
                              }
                              if (updated == null || !updated.isActive) {
                                Navigator.of(this.context).pop();
                              } else {
                                setState(() {
                                  _selectedRentLineIds.clear();
                                  _returnQtyByItemId.clear();
                                });
                              }
                            },
                      child: Text(l10n.returnSelectedAction),
                    ),
                  ),
                ],
              ),
            ],
            if (rental.isActive && openJobLines.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final bool done = await _confirmAndCompleteJobs(
                          context: context,
                          ref: ref,
                          rental: rental,
                          lineIds: openJobLines
                              .map((RentalLine l) => l.id)
                              .toList(),
                        );
                        if (done && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Text(l10n.markCompleteAllAction),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: selectedJobIds.isEmpty
                          ? null
                          : () async {
                              final bool done = await _confirmAndCompleteJobs(
                                context: context,
                                ref: ref,
                                rental: rental,
                                lineIds: selectedJobIds.toList(),
                              );
                              if (!done || !mounted) {
                                return;
                              }
                              final Rental? updated = (await ref
                                      .read(repositoryProvider)
                                      .listRentals())
                                  .cast<Rental?>()
                                  .firstWhere(
                                    (Rental? r) => r?.id == rental.id,
                                    orElse: () => null,
                                  );
                              if (!mounted) {
                                return;
                              }
                              if (updated == null || !updated.isActive) {
                                Navigator.of(this.context).pop();
                              } else {
                                setState(() => _selectedJobLineIds.clear());
                              }
                            },
                      child: Text(l10n.markCompleteSelectedAction),
                    ),
                  ),
                ],
              ),
            ],
            if (rental.isActive && !rental.hasSettledWorkLines) ...<Widget>[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onPressed: () async {
                    final bool done = await _confirmAndCancelOrder(
                      context: context,
                      ref: ref,
                      rental: rental,
                      customer: customer,
                    );
                    if (done && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(l10n.deleteOrderAction),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class InventoryDetailScreen extends ConsumerStatefulWidget {
  const InventoryDetailScreen({
    required this.itemId,
    super.key,
  });

  final String itemId;

  @override
  ConsumerState<InventoryDetailScreen> createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends ConsumerState<InventoryDetailScreen> {
  bool _editing = false;
  bool _saving = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _customCategoryController = TextEditingController();
  final TextEditingController _unitsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _lateFeeController = TextEditingController();
  final TextEditingController _securityDepositController = TextEditingController();
  final TextEditingController _unitCodePrefixController = TextEditingController();
  final DynamicFieldEditors _extraFields = DynamicFieldEditors();
  String? _selectedCategory;
  BillingMode _billingMode = BillingMode.weekly;
  bool _dueDateOptional = false;
  bool _requiresUnitIdentity = true;
  bool _allowsDynamicPricing = false;
  ResourceType? _kindOverride;
  SubscriptionTier _skuTier = SubscriptionTier.basic;
  SubscriptionPeriodUnit _periodUnit = SubscriptionPeriodUnit.month;
  final TextEditingController _periodCountController =
      TextEditingController(text: '1');
  SubscriptionTier _minTier = SubscriptionTier.none;

  @override
  void dispose() {
    _nameController.dispose();
    _customCategoryController.dispose();
    _unitsController.dispose();
    _notesController.dispose();
    _rateController.dispose();
    _lateFeeController.dispose();
    _securityDepositController.dispose();
    _unitCodePrefixController.dispose();
    _periodCountController.dispose();
    _extraFields.dispose();
    super.dispose();
  }

  void _beginEdit(InventoryItem item, List<String> categoryOptions) {
    _nameController.text = item.name;
    final String existing = item.category.trim();
    if (existing.isNotEmpty && categoryOptions.contains(existing)) {
      _selectedCategory = existing;
      _customCategoryController.clear();
    } else if (existing.isEmpty) {
      _selectedCategory = kCategoryOther;
      _customCategoryController.clear();
    } else {
      _selectedCategory = existing;
      _customCategoryController.clear();
    }
    _unitsController.text = '${item.totalUnits}';
    _notesController.text = item.notes ?? '';
    _rateController.text = paiseToRupeesField(item.rateAmount);
    _lateFeeController.text = paiseToRupeesField(item.lateFeePerDay);
    _securityDepositController.text =
        paiseToRupeesField(item.securityDepositPaise);
    _unitCodePrefixController.text = item.unitCodePrefix ?? '';
    _billingMode = item.billingMode;
    _dueDateOptional = item.dueDateOptional;
    _requiresUnitIdentity = item.requiresUnitIdentity;
    _allowsDynamicPricing = item.allowsDynamicPricing;
    _kindOverride = null;
    _skuTier = subscriptionTierFromMetadata(
          item.metadata,
          fallback: SubscriptionTier.basic,
        ) ??
        SubscriptionTier.basic;
    _periodUnit = subscriptionPeriodUnitFromMetadata(item.metadata) ??
        SubscriptionPeriodUnit.month;
    _periodCountController.text =
        '${subscriptionPeriodCountFromMetadata(item.metadata) ?? 1}';
    _minTier = minSubscriptionTierFromMetadata(item.metadata);
    final List<String> templateFields = ref.read(extraFieldIdsProvider);
    final List<FieldDef> fields = resolveExtraFields(
      type: item.defaultItemKind,
      templateFieldIds: templateFields.isEmpty ? null : templateFields,
    );
    _extraFields.syncFields(fields, item.metadata);
    setState(() => _editing = true);
  }

  /// Kind on edit: keep existing unless category becomes/leaves General.
  ResourceType _resolvedEditKind({
    required InventoryItem item,
    required String category,
  }) {
    if (category == kCategoryGeneral) {
      return ResourceType.sale;
    }
    if (item.defaultItemKind == ResourceType.sale) {
      return ResourceType.rental;
    }
    return item.defaultItemKind;
  }

  ResourceType _editKind({
    required InventoryItem item,
    required String category,
  }) {
    return _kindOverride ?? _resolvedEditKind(item: item, category: category);
  }

  Future<void> _saveEdit() async {
    if (_saving) {
      return;
    }
    final AppLocalizations l10n = context.l10n;
    final String name = _nameController.text.trim();
    final String category = resolveSelectedCategory(
      selected: _selectedCategory,
      customText: _customCategoryController.text,
    );
    final String notes = _notesController.text.trim();
    if (!meetsMinMeaningfulText(name) || !meetsMinMeaningfulText(category)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.minMeaningfulTextError(kMinMeaningfulTextLength)),
        ),
      );
      return;
    }
    if (!meetsMinMeaningfulText(notes, allowEmpty: true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.minMeaningfulTextError(kMinMeaningfulTextLength)),
        ),
      );
      return;
    }
    final List<InventoryItem> inventory =
        ref.read(inventoryProvider).asData?.value ?? const <InventoryItem>[];
    final int existingIndex =
        inventory.indexWhere((InventoryItem entry) => entry.id == widget.itemId);
    if (existingIndex < 0) {
      return;
    }
    final InventoryItem existing = inventory[existingIndex];
    final int units = int.tryParse(_unitsController.text.trim()) ?? 1;
    final ResourceType kind =
        _editKind(item: existing, category: category);
    final List<String> templateFields = ref.read(extraFieldIdsProvider);
    final List<FieldDef> fields = resolveExtraFields(
      type: kind,
      templateFieldIds: templateFields.isEmpty ? null : templateFields,
    );
    setState(() => _saving = true);
    await ref.read(repositoryProvider).updateInventory(
      id: widget.itemId,
      name: name,
      category: category,
      units: units < 1 ? 1 : units,
      notes: notes,
      billingMode: _billingMode,
      rateAmount: parseRupeesToPaise(_rateController.text),
      lateFeePerDay: parseRupeesToPaise(_lateFeeController.text),
      securityDepositPaise: parseRupeesToPaise(_securityDepositController.text),
      dueDateOptional: _dueDateOptional,
      requiresUnitIdentity: _requiresUnitIdentity,
      unitCodePrefix: _unitCodePrefixController.text,
      updateUnitCodePrefix: true,
      allowsDynamicPricing: _allowsDynamicPricing,
      defaultItemKind: kind,
      metadata: applySubscriptionCatalogMetadata(
        <String, Object?>{
          ...existing.metadata,
          ..._extraFields.collect(fields),
        },
        skuTier: isSubscriptionCatalogType(kind) ? _skuTier : null,
        periodUnit: _periodUnit,
        periodCount: int.tryParse(_periodCountController.text.trim()),
        minTier: isSubscriptionCatalogType(kind) ? null : _minTier,
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _saving = false;
      _editing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.resourceUpdated)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<InventoryItem>> inventoryAsync =
        ref.watch(inventoryProvider);
    return inventoryAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (Object error, StackTrace _) => Scaffold(body: Center(child: Text('$error'))),
      data: (List<InventoryItem> inventory) {
        final int index =
            inventory.indexWhere((entry) => entry.id == widget.itemId);
        if (index < 0) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.resourceDetailTitle)),
            body: Center(child: Text(l10n.resourceDeletedSnack)),
          );
        }
        final InventoryItem item = inventory[index];
        final List<String> categoryOptions = buildCategoryOptions(
          inventory,
          locale: Localizations.localeOf(context),
        );
        final AssetStatus status =
            item.availableUnits > 0 ? AssetStatus.available : AssetStatus.rented;
        return Scaffold(
          appBar: AppBar(
            title: Text(_editing ? l10n.editResourceTitle : l10n.resourceDetailTitle),
            actions: <Widget>[
              if (!_editing)
                IconButton(
                  tooltip: l10n.editTooltip,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _beginEdit(item, categoryOptions),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: _editing
                ? <Widget>[
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: l10n.itemNameLabel),
                    ),
                    const SizedBox(height: 8),
                    CategoryPickerField(
                      fieldKeyPrefix: 'edit-category',
                      options: categoryOptions,
                      selectedValue: _selectedCategory,
                      customController: _customCategoryController,
                      onSelected: (String? value) {
                        setState(() => _selectedCategory = value);
                      },
                      categoryLabel: l10n.categoryLabel,
                      otherLabel: l10n.categoryOtherLabel,
                      generalLabel: l10n.categoryGeneralLabel,
                      customLabel: l10n.categoryCustomLabel,
                      customHint: l10n.categoryCustomHint,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _unitsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.totalUnitsLabel,
                        helperText: l10n.totalUnitsHelper,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _unitCodePrefixController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: l10n.unitCodePrefixLabel,
                        hintText: l10n.unitCodePrefixHint,
                        helperText: l10n.unitCodePrefixHelper,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.pricingSectionTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<BillingMode>(
                      key: ValueKey<String>('edit-billing-$_billingMode'),
                      initialValue: _billingMode,
                      decoration: InputDecoration(labelText: l10n.billingModeLabel),
                      items: BillingMode.values
                          .map(
                            (BillingMode mode) => DropdownMenuItem<BillingMode>(
                              value: mode,
                              child: Text(localizedBillingMode(l10n, mode)),
                            ),
                          )
                          .toList(),
                      onChanged: (BillingMode? mode) {
                        if (mode != null) {
                          setState(() => _billingMode = mode);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    MoneyAmountField(
                      controller: _rateController,
                      allowDecimal: true,
                      labelText: l10n.rateAmountLabel,
                      hintText: l10n.rateAmountHint,
                    ),
                    const SizedBox(height: 8),
                    MoneyAmountField(
                      controller: _lateFeeController,
                      allowDecimal: true,
                      labelText: l10n.lateFeePerDayLabel,
                      hintText: l10n.lateFeePerDayHint,
                    ),
                    if (catalogSupportsSecurityDeposit(
                      _editKind(
                        item: item,
                        category: resolveSelectedCategory(
                          selected: _selectedCategory,
                          customText: _customCategoryController.text,
                        ),
                      ),
                    )) ...<Widget>[
                      const SizedBox(height: 8),
                      MoneyAmountField(
                        controller: _securityDepositController,
                        allowDecimal: true,
                        labelText: l10n.securityDepositLabel,
                        hintText: l10n.securityDepositHint,
                        helperText: l10n.securityDepositHelper,
                      ),
                    ],
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _dueDateOptional,
                      title: Text(l10n.dueDateOptionalLabel),
                      subtitle: Text(l10n.dueDateOptionalSubtitle),
                      onChanged: (bool value) {
                        setState(() => _dueDateOptional = value);
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _requiresUnitIdentity,
                      title: Text(l10n.requiresUnitIdentityLabel),
                      subtitle: Text(l10n.requiresUnitIdentitySubtitle),
                      onChanged: (bool value) {
                        setState(() => _requiresUnitIdentity = value);
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _allowsDynamicPricing,
                      title: Text(l10n.allowsDynamicPricingLabel),
                      subtitle: Text(l10n.allowsDynamicPricingSubtitle),
                      onChanged: (bool value) {
                        setState(() => _allowsDynamicPricing = value);
                      },
                    ),
                    ...() {
                      final String category = resolveSelectedCategory(
                        selected: _selectedCategory,
                        customText: _customCategoryController.text,
                      );
                      final ResourceType kind =
                          _editKind(item: item, category: category);
                      final List<ResourceType> enabled =
                          ref.watch(enabledResourceTypesProvider);
                      final bool showKindPicker =
                          enabled.any(isSubscriptionCatalogType) ||
                              isSubscriptionCatalogType(kind);
                      final List<ResourceType> kindOptions = <ResourceType>{
                        ...enabled,
                        kind,
                      }.toList();
                      return <Widget>[
                        if (showKindPicker) ...<Widget>[
                          const SizedBox(height: 8),
                          DropdownButtonFormField<ResourceType>(
                            key: ValueKey<String>('edit-kind-$kind'),
                            initialValue: kind,
                            decoration: InputDecoration(
                              labelText: l10n.catalogResourceTypeLabel,
                            ),
                            items: kindOptions
                                .map(
                                  (ResourceType type) =>
                                      DropdownMenuItem<ResourceType>(
                                    value: type,
                                    child: Text(
                                      localizedResourceTypeLabel(l10n, type),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (ResourceType? value) {
                              if (value != null) {
                                setState(() => _kindOverride = value);
                              }
                            },
                          ),
                        ],
                        SubscriptionCatalogFields(
                          fieldKeyPrefix: 'edit-sub',
                          kind: kind,
                          skuTier: _skuTier,
                          periodUnit: _periodUnit,
                          periodCountController: _periodCountController,
                          minTier: _minTier,
                          onSkuTierChanged: (SubscriptionTier t) {
                            setState(() => _skuTier = t);
                          },
                          onPeriodUnitChanged: (SubscriptionPeriodUnit u) {
                            setState(() => _periodUnit = u);
                          },
                          onMinTierChanged: (SubscriptionTier t) {
                            setState(() => _minTier = t);
                          },
                        ),
                      ];
                    }(),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: l10n.notesLabel,
                        hintText: l10n.notesHint,
                      ),
                    ),
                    ...() {
                      final List<String> templateFields =
                          ref.watch(extraFieldIdsProvider);
                      final ResourceType kind = _editKind(
                        item: item,
                        category: resolveSelectedCategory(
                          selected: _selectedCategory,
                          customText: _customCategoryController.text,
                        ),
                      );
                      final List<FieldDef> fields = resolveExtraFields(
                        type: kind,
                        templateFieldIds:
                            templateFields.isEmpty ? null : templateFields,
                      );
                      return buildDynamicFieldInputs(
                        context: context,
                        fields: fields,
                        editors: _extraFields,
                        onChanged: () => setState(() {}),
                      );
                    }(),
                  ]
                : <Widget>[
                    EntityCard(
                      title: item.name,
                      subtitle: l10n.inventoryAvailableSubtitle(
                        categoryWithResourceTypeBadge(l10n, item),
                        item.availableUnits,
                        item.totalUnits,
                      ),
                      leadingIcon: Icons.inventory_2_outlined,
                      status: status,
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.payments_outlined),
                        title: Text(l10n.pricingSectionTitle),
                        subtitle: Text(
                          '${localizedBillingMode(l10n, item.billingMode)} · '
                          '${formatMoney(item.rateAmount, currencyCode: item.currencyCode)}'
                          '${item.lateFeePerDay > 0 ? ' · ${formatMoney(item.lateFeePerDay)}/day late' : ''}'
                          '${item.securityDepositPaise > 0 ? ' · ${l10n.securityDepositShort(formatMoney(item.securityDepositPaise))}' : ''}'
                          '${item.dueDateOptional ? ' · ${l10n.openEndedLabel}' : ''}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.label_outline),
                        title: Text(
                          item.requiresUnitIdentity
                              ? l10n.requiresUnitIdentityLabel
                              : l10n.labelsAutoAssignedHint,
                        ),
                        subtitle: () {
                          final List<String> bits = <String>[
                            if (item.requiresUnitIdentity)
                              l10n.inventoryInstancesNote,
                            if (item.hasUnitCodePool)
                              '${l10n.unitCodePrefixLabel}: ${item.unitCodePrefix}',
                          ];
                          if (bits.isEmpty) {
                            return null;
                          }
                          return Text(bits.join('\n'));
                        }(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.qr_code_2_outlined),
                        title: Text(l10n.qrCodeLabel),
                        subtitle: Text(item.qrCode),
                      ),
                    ),
                    if ((item.notes ?? '').isNotEmpty) ...<Widget>[
                      const SizedBox(height: 10),
                      Card(
                        child: ListTile(
                          title: Text(l10n.notesLabel),
                          subtitle: Text(item.notes!),
                        ),
                      ),
                    ],
                    ...() {
                      final Locale locale = Localizations.localeOf(context);
                      final List<String> templateFields =
                          ref.watch(extraFieldIdsProvider);
                      final List<FieldDef> fields = resolveExtraFields(
                        type: item.defaultItemKind,
                        templateFieldIds:
                            templateFields.isEmpty ? null : templateFields,
                      );
                      final List<Widget> metaCards = <Widget>[];
                      for (final FieldDef field in fields) {
                        final Object? value = item.metadata[field.id];
                        if (value == null ||
                            (value is String && value.trim().isEmpty)) {
                          continue;
                        }
                        metaCards.add(const SizedBox(height: 10));
                        metaCards.add(
                          Card(
                            child: ListTile(
                              title: Text(field.localizedLabel(locale)),
                              subtitle: Text(formatMetadataValue(field, value)),
                            ),
                          ),
                        );
                      }
                      return metaCards;
                    }(),
                  ],
          ),
          bottomNavigationBar: _editing
              ? SafeArea(
                  minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () => setState(() => _editing = false),
                          child: Text(l10n.cancel),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: _saving ? null : _saveEdit,
                          child: Text(_saving ? l10n.saving : l10n.saveChanges),
                        ),
                      ),
                    ],
                  ),
                )
              : item.availableUnits > 0
                  ? SafeArea(
                      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => NewOrderFlowScreen(
                                initialInventoryItemIds: <String>[item.id],
                              ),
                            ),
                          );
                        },
                        child: Text(l10n.issueItemAction),
                      ),
                    )
                  : null,
        );
      },
    );
  }
}

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
            secondary: customer.phone,
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
                  _balanceLabeledRow(
                    context,
                    label: l10n.balanceAdvanceLabel,
                    amount: formatMoney(balance.advancePaise),
                  ),
                  const SizedBox(height: 6),
                  _balanceLabeledRow(
                    context,
                    label: l10n.balancePendingLabel,
                    amount: formatMoney(balance.pendingPaise),
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
                  _balanceLabeledRow(
                    context,
                    label: balance.netPaise < 0
                        ? l10n.balanceCreditLabel
                        : l10n.balanceNetLabel,
                    amount: formatMoney(balance.netPaise),
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
                      ? _rentalLinesLabel(
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
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              RentalDetailScreen(rentalId: item.rental.id),
                        ),
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

class ReturnFlowScreen extends ConsumerWidget {
  const ReturnFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<Rental>> rentalsAsync = ref.watch(rentalsProvider);
    return rentalsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (Object error, StackTrace _) => Scaffold(body: Center(child: Text('$error'))),
      data: (List<Rental> rentals) {
        final List<Rental> active = rentals
            .where(
              (Rental item) =>
                  item.isActive && item.openRentLines.isNotEmpty,
            )
            .toList();
        return Scaffold(
          appBar: AppBar(title: Text(l10n.actionReturnItem)),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: active.isEmpty
                ? EmptyStatePane(
                    title: l10n.noActiveRentalsTitle,
                    subtitle: l10n.noActiveRentalsSubtitle,
                    ctaLabel: l10n.backToHome,
                    onPressed: () => Navigator.of(context).pop(),
                  )
                : ListView.separated(
                    itemBuilder: (BuildContext context, int index) {
                      final Rental rental = active[index];
                      final DateTime now = DateTime.now();
                      final int total = rental.totalAmountAsOf(now);
                      final int willApply = rental.depositRemaining < total
                          ? rental.depositRemaining
                          : total;
                      final String openBit = rental.openRentLines.length <
                              rental.lines.length
                          ? l10n.linesOpenCount(
                              rental.openRentLines.length,
                              rental.lines.length,
                            )
                          : '';
                      return EntityCard(
                        title: _rentalLinesLabel(rental),
                        subtitle: <String>[
                          rental.isOpenEnded
                              ? l10n.rentalAmountOpenEnded(formatMoney(total))
                              : l10n.rentalAmountSubtitle(
                                  formatIndiaDate(rental.dueAt!),
                                  formatMoney(total),
                                ),
                          if (rental.isOpenEnded) l10n.accruedAmountHint,
                          if (openBit.isNotEmpty) openBit,
                          if (rental.depositRemaining > 0)
                            l10n.depositWillApplyLabel(formatMoney(willApply)),
                        ].join('\n'),
                        leadingIcon: Icons.assignment_return_outlined,
                        status: rental.statusFor(now),
                        trailing: FilledButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    RentalDetailScreen(rentalId: rental.id),
                              ),
                            );
                          },
                          child: Text(l10n.actionReturn),
                        ),
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemCount: active.length,
                  ),
          ),
        );
      },
    );
  }
}

class AddInventoryFlowScreen extends ConsumerStatefulWidget {
  const AddInventoryFlowScreen({super.key});

  @override
  ConsumerState<AddInventoryFlowScreen> createState() => _AddInventoryFlowScreenState();
}

class _AddInventoryFlowScreenState extends ConsumerState<AddInventoryFlowScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _customCategoryController = TextEditingController();
  final TextEditingController _unitsController = TextEditingController(text: '1');
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _rateController = TextEditingController(text: '0');
  final TextEditingController _lateFeeController = TextEditingController(text: '0');
  final TextEditingController _securityDepositController =
      TextEditingController(text: '0');
  final TextEditingController _unitCodePrefixController = TextEditingController();
  final DynamicFieldEditors _extraFields = DynamicFieldEditors();
  late String _selectedCategory;
  BillingMode _billingMode = BillingMode.weekly;
  bool _dueDateOptional = false;
  bool _requiresUnitIdentity = false;
  bool _allowsDynamicPricing = false;
  bool _submitting = false;
  ResourceType? _kindOverride;
  SubscriptionTier _skuTier = SubscriptionTier.basic;
  SubscriptionPeriodUnit _periodUnit = SubscriptionPeriodUnit.month;
  final TextEditingController _periodCountController =
      TextEditingController(text: '1');
  SubscriptionTier _minTier = SubscriptionTier.none;

  @override
  void initState() {
    super.initState();
    _selectedCategory = kPresetInventoryCategories.isNotEmpty
        ? kPresetInventoryCategories.first
        : kCategoryOther;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customCategoryController.dispose();
    _unitsController.dispose();
    _notesController.dispose();
    _rateController.dispose();
    _lateFeeController.dispose();
    _securityDepositController.dispose();
    _unitCodePrefixController.dispose();
    _periodCountController.dispose();
    _extraFields.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final List<InventoryItem> inventory =
        ref.watch(inventoryProvider).asData?.value ?? const <InventoryItem>[];
    final List<String> categoryOptions = buildCategoryOptions(
      inventory,
      locale: Localizations.localeOf(context),
    );
    final String selectedCategory = categoryOptions.contains(_selectedCategory)
        ? _selectedCategory
        : (categoryOptions.isNotEmpty
            ? categoryOptions.first
            : kCategoryOther);
    final String addCategory = resolveSelectedCategory(
      selected: selectedCategory,
      customText: _customCategoryController.text,
    );
    final ResourceType addKind =
        _kindOverride ?? defaultKindForCategory(addCategory);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.actionAddResource)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(l10n.quickAdd),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: l10n.itemNameLabel),
          ),
          const SizedBox(height: 8),
          CategoryPickerField(
            fieldKeyPrefix: 'add-category',
            options: categoryOptions,
            selectedValue: selectedCategory,
            customController: _customCategoryController,
            onSelected: (String? value) {
              if (value != null) {
                setState(() => _selectedCategory = value);
              }
            },
            categoryLabel: l10n.categoryLabel,
            otherLabel: l10n.categoryOtherLabel,
            generalLabel: l10n.categoryGeneralLabel,
            customLabel: l10n.categoryCustomLabel,
            customHint: l10n.categoryCustomHint,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _unitsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.unitsLabel),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _unitCodePrefixController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: l10n.unitCodePrefixLabel,
              hintText: l10n.unitCodePrefixHint,
              helperText: l10n.unitCodePrefixHelper,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.pricingSectionTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<BillingMode>(
            key: ValueKey<String>('add-billing-$_billingMode'),
            initialValue: _billingMode,
            decoration: InputDecoration(labelText: l10n.billingModeLabel),
            items: BillingMode.values
                .map(
                  (BillingMode mode) => DropdownMenuItem<BillingMode>(
                    value: mode,
                    child: Text(localizedBillingMode(l10n, mode)),
                  ),
                )
                .toList(),
            onChanged: (BillingMode? mode) {
              if (mode != null) {
                setState(() => _billingMode = mode);
              }
            },
          ),
          const SizedBox(height: 8),
          MoneyAmountField(
            controller: _rateController,
            allowDecimal: true,
            labelText: l10n.rateAmountLabel,
            hintText: l10n.rateAmountHint,
          ),
          const SizedBox(height: 8),
          MoneyAmountField(
            controller: _lateFeeController,
            allowDecimal: true,
            labelText: l10n.lateFeePerDayLabel,
            hintText: l10n.lateFeePerDayHint,
          ),
          if (catalogSupportsSecurityDeposit(addKind)) ...<Widget>[
            const SizedBox(height: 8),
            MoneyAmountField(
              controller: _securityDepositController,
              allowDecimal: true,
              labelText: l10n.securityDepositLabel,
              hintText: l10n.securityDepositHint,
              helperText: l10n.securityDepositHelper,
            ),
          ],
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _dueDateOptional,
            title: Text(l10n.dueDateOptionalLabel),
            subtitle: Text(l10n.dueDateOptionalSubtitle),
            onChanged: (bool value) {
              setState(() => _dueDateOptional = value);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _requiresUnitIdentity,
            title: Text(l10n.requiresUnitIdentityLabel),
            subtitle: Text(l10n.requiresUnitIdentitySubtitle),
            onChanged: (bool value) {
              setState(() => _requiresUnitIdentity = value);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _allowsDynamicPricing,
            title: Text(l10n.allowsDynamicPricingLabel),
            subtitle: Text(l10n.allowsDynamicPricingSubtitle),
            onChanged: (bool value) {
              setState(() => _allowsDynamicPricing = value);
            },
          ),
          ...() {
            final List<ResourceType> enabled =
                ref.watch(enabledResourceTypesProvider);
            final bool showKindPicker =
                enabled.any(isSubscriptionCatalogType) ||
                    isSubscriptionCatalogType(addKind);
            final List<ResourceType> kindOptions = <ResourceType>{
              ...enabled,
              addKind,
            }.toList();
            return <Widget>[
              if (showKindPicker) ...<Widget>[
                const SizedBox(height: 8),
                DropdownButtonFormField<ResourceType>(
                  key: ValueKey<String>('add-kind-$addKind'),
                  initialValue: addKind,
                  decoration: InputDecoration(
                    labelText: l10n.catalogResourceTypeLabel,
                  ),
                  items: kindOptions
                      .map(
                        (ResourceType type) => DropdownMenuItem<ResourceType>(
                          value: type,
                          child: Text(localizedResourceTypeLabel(l10n, type)),
                        ),
                      )
                      .toList(),
                  onChanged: (ResourceType? value) {
                    if (value != null) {
                      setState(() => _kindOverride = value);
                    }
                  },
                ),
              ],
              SubscriptionCatalogFields(
                fieldKeyPrefix: 'add-sub',
                kind: addKind,
                skuTier: _skuTier,
                periodUnit: _periodUnit,
                periodCountController: _periodCountController,
                minTier: _minTier,
                onSkuTierChanged: (SubscriptionTier t) {
                  setState(() => _skuTier = t);
                },
                onPeriodUnitChanged: (SubscriptionPeriodUnit u) {
                  setState(() => _periodUnit = u);
                },
                onMinTierChanged: (SubscriptionTier t) {
                  setState(() => _minTier = t);
                },
              ),
            ];
          }(),
          ...() {
            final String category = resolveSelectedCategory(
              selected: selectedCategory,
              customText: _customCategoryController.text,
            );
            final ResourceType kind =
                _kindOverride ?? defaultKindForCategory(category);
            final List<String> templateFields = ref.watch(extraFieldIdsProvider);
            final List<FieldDef> fields = resolveExtraFields(
              type: kind,
              templateFieldIds: templateFields.isEmpty ? null : templateFields,
            );
            return buildDynamicFieldInputs(
              context: context,
              fields: fields,
              editors: _extraFields,
              onChanged: () => setState(() {}),
            );
          }(),
          const SizedBox(height: 8),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(l10n.advancedFields),
            subtitle: Text(l10n.advancedFieldsSubtitle),
            children: <Widget>[
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: l10n.notesLabel,
                  hintText: l10n.notesHint,
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: FilledButton(
          onPressed: _submitting
              ? null
              : () async {
                  final String category = resolveSelectedCategory(
                    selected: selectedCategory,
                    customText: _customCategoryController.text,
                  );
                  if (!meetsMinMeaningfulText(_nameController.text) ||
                      !meetsMinMeaningfulText(category)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.minMeaningfulTextError(kMinMeaningfulTextLength),
                        ),
                      ),
                    );
                    return;
                  }
                  if (!meetsMinMeaningfulText(
                    _notesController.text,
                    allowEmpty: true,
                  )) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.minMeaningfulTextError(kMinMeaningfulTextLength),
                        ),
                      ),
                    );
                    return;
                  }
                  final int units = int.tryParse(_unitsController.text.trim()) ?? 1;
                  final ResourceType kind =
                      _kindOverride ?? defaultKindForCategory(category);
                  final List<String> templateFields =
                      ref.read(extraFieldIdsProvider);
                  final List<FieldDef> fields = resolveExtraFields(
                    type: kind,
                    templateFieldIds:
                        templateFields.isEmpty ? null : templateFields,
                  );
                  setState(() => _submitting = true);
                  await ref.read(repositoryProvider).addInventory(
                    name: _nameController.text.trim(),
                    category: category,
                    units: units < 1 ? 1 : units,
                    notes: _notesController.text.trim(),
                    billingMode: _billingMode,
                    rateAmount: parseRupeesToPaise(_rateController.text),
                    lateFeePerDay: parseRupeesToPaise(_lateFeeController.text),
                    securityDepositPaise:
                        parseRupeesToPaise(_securityDepositController.text),
                    dueDateOptional: _dueDateOptional,
                    requiresUnitIdentity: _requiresUnitIdentity,
                    unitCodePrefix: _unitCodePrefixController.text,
                    allowsDynamicPricing: _allowsDynamicPricing,
                    defaultItemKind: kind,
                    metadata: applySubscriptionCatalogMetadata(
                      _extraFields.collect(fields),
                      skuTier:
                          isSubscriptionCatalogType(kind) ? _skuTier : null,
                      periodUnit: _periodUnit,
                      periodCount:
                          int.tryParse(_periodCountController.text.trim()),
                      minTier:
                          isSubscriptionCatalogType(kind) ? null : _minTier,
                    ),
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
          child: Text(l10n.saveItem),
        ),
      ),
    );
  }
}

class ScanEntryScreen extends ConsumerStatefulWidget {
  const ScanEntryScreen({super.key});

  @override
  ConsumerState<ScanEntryScreen> createState() => _ScanEntryScreenState();
}

class _ScanEntryScreenState extends ConsumerState<ScanEntryScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final List<String> quickCodes = <String>[
      'customer:1001',
      'rental:3001',
      'inventory:2001',
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.actionScan)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(l10n.scanIntro),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: l10n.qrContentLabel,
              hintText: l10n.qrContentHint,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickCodes
                .map(
                  (code) => ActionChip(
                    label: Text(code),
                    onPressed: () => setState(() => _controller.text = code),
                  ),
                )
                .toList(),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: FilledButton.icon(
          onPressed: () async {
            final QrDestination? destination =
                await ref.read(repositoryProvider).resolveQr(_controller.text);
            if (!context.mounted) {
              return;
            }
            if (destination == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.noEntityMatched)),
              );
              return;
            }
            if (destination is QrCustomer) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CustomerDetailScreen(customerId: destination.customerId),
                ),
              );
              return;
            }
            if (destination is QrRental) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RentalDetailScreen(rentalId: destination.rentalId),
                ),
              );
              return;
            }
            if (destination is QrInventory) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => InventoryDetailScreen(itemId: destination.itemId),
                ),
              );
            }
          },
          icon: const Icon(Icons.open_in_new),
          label: Text(l10n.openLinkedRecord),
        ),
      ),
    );
  }
}

class VoiceSearchStubScreen extends StatelessWidget {
  const VoiceSearchStubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return _StubScaffold(
      title: l10n.voiceSearchTitle,
      body: l10n.voiceSearchBody,
    );
  }
}

class _StubScaffold extends StatelessWidget {
  const _StubScaffold({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(body),
          ),
        ),
      ),
    );
  }
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

Widget _balanceLabeledRow(
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

Future<void> _showAddOrderNoteSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Rental rental,
}) async {
  final AppLocalizations l10n = context.l10n;
  final TextEditingController bodyController = TextEditingController();
  RentalNoteKind kind = RentalNoteKind.general;
  String? selectedLineId;

  final bool? saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
        ),
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    l10n.addOrderNoteAction,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<RentalNoteKind>(
                    key: ValueKey<RentalNoteKind>(kind),
                    initialValue: kind,
                    decoration: InputDecoration(
                      labelText: l10n.orderNoteKindLabel,
                    ),
                    items: RentalNoteKind.values
                        .map(
                          (RentalNoteKind value) =>
                              DropdownMenuItem<RentalNoteKind>(
                            value: value,
                            child: Text(localizedRentalNoteKind(l10n, value)),
                          ),
                        )
                        .toList(),
                    onChanged: (RentalNoteKind? value) {
                      if (value == null) {
                        return;
                      }
                      setSheetState(() => kind = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    key: ValueKey<String>('line-${selectedLineId ?? 'all'}'),
                    initialValue: selectedLineId,
                    decoration: InputDecoration(
                      labelText: l10n.orderNoteLineLabel,
                    ),
                    items: <DropdownMenuItem<String?>>[
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(l10n.orderNoteWholeOrder),
                      ),
                      ...rental.lines.map(
                        (RentalLine line) => DropdownMenuItem<String?>(
                          value: line.id,
                          child: Text(line.displayLabel),
                        ),
                      ),
                    ],
                    onChanged: (String? value) {
                      setSheetState(() => selectedLineId = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bodyController,
                    minLines: 3,
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText: l10n.orderNoteBodyLabel,
                      hintText: l10n.orderNoteBodyHint,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(true),
                    child: Text(l10n.addOrderNoteAction),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );

  final String body = bodyController.text;
  bodyController.dispose();
  if (saved != true || !context.mounted) {
    return;
  }
  if (!meetsMinMeaningfulText(body)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.minMeaningfulTextError(kMinMeaningfulTextLength)),
      ),
    );
    return;
  }

  try {
    await ref.read(repositoryProvider).addRentalNote(
          rentalId: rental.id,
          rentalItemId: selectedLineId,
          body: body,
          kind: kind.storageValue,
        );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.orderNoteAddedSnack)),
    );
  } on ArgumentError catch (error) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.message?.toString() ?? error.toString())),
    );
  }
}

String _returnSettlementSnack(AppLocalizations l10n, RentalReturnResult result) {
  if (result.depositApplied <= 0) {
    return l10n.depositReturnSnackNoDeposit(formatMoney(result.totalAmount));
  }
  if (result.amountDue > 0) {
    return l10n.depositReturnSnackDue(
      formatMoney(result.depositApplied),
      formatMoney(result.amountDue),
    );
  }
  return l10n.depositReturnSnackApplied(
    formatMoney(result.depositApplied),
    formatMoney(result.depositBalanceAfter),
  );
}

Future<bool> _confirmAndMarkLinesLost({
  required BuildContext context,
  required WidgetRef ref,
  required Rental rental,
  required List<String> lineIds,
}) async {
  final AppLocalizations l10n = context.l10n;
  final Set<String> wanted = lineIds.toSet();
  final List<RentalLine> targets = rental.openRentLines
      .where((RentalLine l) => wanted.contains(l.id))
      .toList();
  if (targets.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.noLinesSelected)),
    );
    return false;
  }

  final VerificationSettings verification =
      ref.read(verificationSettingsProvider);
  final ReturnConditionCapture? condition = await showReturnConditionSheet(
    context: context,
    ref: ref,
    rentalId: rental.id,
    mode: verification.conditionMode,
    checklistItems: verification.checklistItems,
    isLost: true,
  );
  if (!context.mounted || condition == null) {
    return false;
  }

  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(l10n.confirmMarkLostTitle),
        content: Text(l10n.confirmMarkLostBody(targets.length)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.confirmMarkLostAction),
          ),
        ],
      );
    },
  );
  if (confirmed != true || !context.mounted) {
    return false;
  }

  final RentalReturnResult? result = await ref
      .read(repositoryProvider)
      .markRentalLinesLost(
        rental.id,
        targets.map((RentalLine l) => l.id).toList(),
        conditionNote: condition.conditionNote,
        mediaIds: condition.mediaIds,
        checklist: condition.checklist,
      );
  if (!context.mounted) {
    return result != null;
  }
  if (result == null) {
    return false;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        '${l10n.unitsLostSnack(result.lostLineIds.length)} '
        '${_returnSettlementSnack(l10n, result)}',
      ),
    ),
  );
  return true;
}

Future<bool> _confirmAndCompleteJobs({
  required BuildContext context,
  required WidgetRef ref,
  required Rental rental,
  required List<String> lineIds,
}) async {
  final AppLocalizations l10n = context.l10n;
  final Set<String> wanted = lineIds.toSet();
  final List<RentalLine> targets = rental.openJobLines
      .where((RentalLine l) => wanted.contains(l.id))
      .toList();
  if (targets.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.noLinesSelected)),
    );
    return false;
  }

  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(l10n.confirmCompleteJobsTitle),
        content: Text(l10n.confirmCompleteJobsBody(targets.length)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.markCompleteSelectedAction),
          ),
        ],
      );
    },
  );
  if (confirmed != true || !context.mounted) {
    return false;
  }

  final RentalReturnResult? result = await ref
      .read(repositoryProvider)
      .completeJobLines(
        rental.id,
        targets.map((RentalLine l) => l.id).toList(),
      );
  if (!context.mounted) {
    return false;
  }
  if (result == null) {
    return false;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(l10n.jobsCompletedSnack)),
  );
  return true;
}

Future<void> _extendRentalDue({
  required BuildContext context,
  required WidgetRef ref,
  required Rental rental,
}) async {
  final AppLocalizations l10n = context.l10n;
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime currentDue = rental.dueAt == null
      ? today
      : DateTime(rental.dueAt!.year, rental.dueAt!.month, rental.dueAt!.day);
  final DateTime firstAllowed = currentDue.isBefore(today)
      ? today
      : currentDue.add(const Duration(days: 1));
  final DateTime? picked = await showDatePicker(
    context: context,
    locale: indiaDatePickerLocale(context),
    initialDate: firstAllowed,
    firstDate: firstAllowed,
    lastDate: today.add(const Duration(days: 365 * 5)),
    helpText: l10n.extendDueTitle,
  );
  if (picked == null || !context.mounted) {
    return;
  }
  try {
    final bool ok = await ref.read(repositoryProvider).extendRentalDue(
          rental.id,
          picked,
        );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? l10n.extendDueSuccess : l10n.extendDueInvalid),
      ),
    );
  } on ArgumentError {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.extendDueInvalid)),
    );
  }
}

Future<bool> _confirmAndReturnRental({
  required BuildContext context,
  required WidgetRef ref,
  required Rental rental,
  required Customer customer,
  List<String>? lineIds,
}) async {
  final AppLocalizations l10n = context.l10n;
  final DateTime now = DateTime.now();
  final List<RentalLine> targets;
  if (lineIds == null || lineIds.isEmpty) {
    targets = rental.openRentLines;
  } else {
    final Set<String> wanted = lineIds.toSet();
    targets =
        rental.openRentLines.where((RentalLine l) => wanted.contains(l.id)).toList();
  }
  if (targets.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.noLinesSelected)),
    );
    return false;
  }

  final VerificationSettings verification =
      ref.read(verificationSettingsProvider);
  final ReturnConditionCapture? condition = await showReturnConditionSheet(
    context: context,
    ref: ref,
    rentalId: rental.id,
    mode: verification.conditionMode,
    checklistItems: verification.checklistItems,
  );
  if (!context.mounted || condition == null) {
    return false;
  }

  int computedTotal = 0;
  for (final RentalLine line in targets) {
    computedTotal += line.totalAmountAsOf(rental.startedAt, rental.dueAt, now);
  }

  final TextEditingController finalAmountController = TextEditingController(
    text: paiseToRupeesField(computedTotal),
  );
  final TextEditingController noteController = TextEditingController();

  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          final int parsedFinal = parseRupeesToPaise(finalAmountController.text);
          final int finalAmount = parsedFinal.clamp(0, computedTotal);
          final int discount =
              (computedTotal - finalAmount).clamp(0, computedTotal);
          final int willApply = rental.depositRemaining < finalAmount
              ? rental.depositRemaining
              : finalAmount;
          final int remainingDue = finalAmount - willApply;
          final int leftover = rental.depositRemaining - willApply;

          return AlertDialog(
            title: Text(l10n.returnSettlementTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ...targets.map(
                    (RentalLine line) => Text(
                      l10n.lineChargePreview(
                        line.displayLabel,
                        formatMoney(
                          line.totalAmountAsOf(
                            rental.startedAt,
                            rental.dueAt,
                            now,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.chargeTotalLabel(formatMoney(computedTotal))),
                  const SizedBox(height: 8),
                  MoneyAmountField(
                    controller: finalAmountController,
                    allowDecimal: true,
                    labelText: l10n.returnFinalAmountLabel,
                    hintText: l10n.returnFinalAmountHint,
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 6),
                  Text(l10n.returnDiscountLabel(formatMoney(discount))),
                  Text(
                    l10n.depositAvailableLabel(
                      formatMoney(rental.depositRemaining),
                    ),
                  ),
                  Text(l10n.depositWillApplyLabel(formatMoney(willApply))),
                  if (remainingDue > 0)
                    Text(
                      l10n.depositRemainingDueLabel(formatMoney(remainingDue)),
                    )
                  else if (leftover > 0)
                    Text(l10n.depositLeftoverLabel(formatMoney(leftover))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteController,
                    maxLength: kMoneyNoteMaxLength,
                    decoration: InputDecoration(
                      labelText: l10n.returnNoteLabel,
                      hintText: l10n.returnNoteHint,
                      counterText: '',
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.confirmReturnAction),
              ),
            ],
          );
        },
      );
    },
  );

  final int chargedTotal =
      parseRupeesToPaise(finalAmountController.text).clamp(0, computedTotal);
  final String? note = optionalMoneyNote(noteController.text);
  finalAmountController.dispose();
  noteController.dispose();

  if (confirmed != true || !context.mounted) {
    return false;
  }

  final RentalReturnResult? result = await ref
      .read(repositoryProvider)
      .returnRentalLines(
        rental.id,
        targets.map((RentalLine l) => l.id).toList(),
        chargedTotalPaise: chargedTotal,
        note: note,
        conditionNote: condition.conditionNote,
        mediaIds: condition.mediaIds,
        checklist: condition.checklist,
      );
  if (!context.mounted) {
    return result != null;
  }
  if (result == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.rentalReturned(rental.id))),
    );
    return false;
  }
  final String snack = result.rentalClosed
      ? _returnSettlementSnack(l10n, result)
      : '${l10n.partialReturnSnack(result.returnedLineIds.length)} '
          '${_returnSettlementSnack(l10n, result)}';
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(snack)),
  );
  return true;
}

Future<bool> _confirmAndCancelOrder({
  required BuildContext context,
  required WidgetRef ref,
  required Rental rental,
  required Customer customer,
}) async {
  final AppLocalizations l10n = context.l10n;
  final TextEditingController keptController =
      TextEditingController(text: '0');
  final TextEditingController returnedController =
      TextEditingController(text: '0');
  final TextEditingController noteController = TextEditingController();

  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(l10n.deleteOrderTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.depositAvailableLabel(
                  formatMoney(rental.depositRemaining),
                ),
              ),
              const SizedBox(height: 8),
              MoneyAmountField(
                controller: keptController,
                allowDecimal: true,
                labelText: l10n.deleteOrderKeptLabel,
                hintText: l10n.depositAmountHint,
              ),
              const SizedBox(height: 8),
              MoneyAmountField(
                controller: returnedController,
                allowDecimal: true,
                labelText: l10n.deleteOrderReturnedLabel,
                hintText: l10n.depositAmountHint,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                maxLength: kMoneyNoteMaxLength,
                decoration: InputDecoration(
                  labelText: l10n.deleteOrderNoteLabel,
                  hintText: l10n.returnNoteHint,
                  counterText: '',
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.confirmDeleteOrderAction),
          ),
        ],
      );
    },
  );

  final int keptPaise = parseRupeesToPaise(keptController.text);
  final int returnedPaise = parseRupeesToPaise(returnedController.text);
  final String? note = optionalMoneyNote(noteController.text);
  keptController.dispose();
  returnedController.dispose();
  noteController.dispose();

  if (confirmed != true || !context.mounted) {
    return false;
  }
  if (keptPaise < 0 || returnedPaise < 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.deleteOrderInvalidSettlement)),
    );
    return false;
  }
  if (keptPaise + returnedPaise > rental.depositRemaining) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.deleteOrderInvalidSettlement)),
    );
    return false;
  }

  try {
    final OrderCancelResult? result =
        await ref.read(repositoryProvider).cancelOrder(
              rentalId: rental.id,
              amountKeptPaise: keptPaise,
              amountReturnedPaise: returnedPaise,
              note: note,
            );
    if (!context.mounted) {
      return result != null;
    }
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deleteOrderFailed)),
      );
      return false;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.deleteOrderSuccessSnack(
            formatMoney(result.depositBalanceAfter),
          ),
        ),
      ),
    );
    return true;
  } on StateError {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deleteOrderBlockedPartial)),
      );
    }
    return false;
  } on ArgumentError {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deleteOrderInvalidSettlement)),
      );
    }
    return false;
  }
}
