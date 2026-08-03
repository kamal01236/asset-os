import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_branding.dart';
import 'core/inventory/inventory_categories.dart';
import 'core/l10n/l10n_ext.dart';
import 'core/models/customer_activity.dart';
import 'core/models/customer_balance.dart';
import 'core/models/entities.dart';
import 'core/models/unknown_customer.dart';
import 'core/pricing/rental_pricing.dart';
import 'core/providers/app_providers.dart';
import 'core/repositories/local_repository.dart';
import 'core/search/search_scope.dart';
import 'core/theme/app_theme.dart';
import 'core/validation/text_rules.dart';
import 'core/widgets/category_picker_field.dart';
import 'core/widgets/global_search_typeahead.dart';
import 'core/widgets/rental_timeline.dart';
import 'core/widgets/scoped_search_field.dart';
import 'core/widgets/ui_primitives.dart';
import 'features/home/customize_home_screen.dart';
import 'features/home/home_screen.dart';
import 'features/orders/new_order_flow_screen.dart';
import 'features/reports/share_reports_screen.dart';
import 'features/templates/business_templates_screen.dart';

export 'features/home/home_screen.dart' show HomeScreen;
export 'features/orders/new_order_flow_screen.dart'
    show NewOrderFlowScreen, NewRentalFlowScreen;

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      RentalsScreen(
        onOpenRental: (Rental rental) => _openRentalDetail(context, rental),
      ),
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
          NavigationDestination(icon: const Icon(Icons.assignment_outlined), label: l10n.navRentals),
          NavigationDestination(icon: const Icon(Icons.inventory_2_outlined), label: l10n.navInventory),
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

class RentalsScreen extends ConsumerWidget {
  const RentalsScreen({
    required this.onOpenRental,
    super.key,
  });

  final ValueChanged<Rental> onOpenRental;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<Rental>> rentalsAsync = ref.watch(rentalsProvider);
    final AsyncValue<List<Customer>> customersAsync = ref.watch(customersProvider);
    final RentalsListFilter? listFilter = ref.watch(rentalsListFilterProvider);

    return rentalsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace _) => Center(child: Text('$error')),
      data: (List<Rental> rentals) {
        final List<Customer> customers = customersAsync.valueOrNull ?? const <Customer>[];
        final DateTime now = DateTime.now();
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

        final List<Rental> visible = listFilter == null
            ? rentals
            : rentals
                .where(
                  (Rental rental) =>
                      rental.statusFor(now) == listFilter.status,
                )
                .toList();
        final String? filterLabel = listFilter == null
            ? null
            : _rentalsListFilterLabel(l10n, listFilter);

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (BuildContext context, int index) {
            if (filterLabel != null && index == 0) {
              return ActiveFilterBar(
                label: filterLabel,
                onClear: () =>
                    ref.read(rentalsListFilterProvider.notifier).state = null,
              );
            }
            final int rentalIndex = filterLabel == null ? index : index - 1;
            if (visible.isEmpty) {
              return EmptyStatePane(
                title: l10n.homeFilterEmptyTitle,
                subtitle: l10n.homeFilterEmptyRentalsSubtitle(filterLabel!),
                ctaLabel: l10n.actionNewRental,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const NewOrderFlowScreen(),
                    ),
                  );
                },
              );
            }
            final Rental rental = visible[rentalIndex];
            final Customer customer = customers.firstWhere(
              (item) => item.id == rental.customerId,
              orElse: () => Customer(
                id: 'unknown',
                name: l10n.unknownCustomer,
                phone: '--',
                isTrusted: false,
                qrCode: 'unknown',
              ),
            );
            return EntityCard(
              title: _rentalLinesLabel(rental),
              subtitle:
                  '${rentalPartyLabel(customer, rental)} · ${_rentalAmountSubtitle(l10n, rental)}',
              leadingIcon: Icons.assignment_outlined,
              status: rental.statusFor(now),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onOpenRental(rental),
            );
          },
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemCount: filterLabel == null
              ? visible.length
              : (visible.isEmpty ? 2 : visible.length + 1),
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
              minLengthHint: l10n.searchTypeMinChars,
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
                subtitle: l10n.homeFilterEmptyInventorySubtitle,
                ctaLabel: l10n.actionAddInventory,
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
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: EntityCard(
                    title: item.name,
                    subtitle:
                        '${l10n.inventoryAvailableSubtitle(
                          item.isGeneral
                              ? '${item.category} · ${l10n.itemKindGeneralBadge}'
                              : item.category,
                          item.availableUnits,
                          item.totalUnits,
                        )} · ${l10n.inventoryRateSubtitle(
                          localizedBillingMode(l10n, item.billingMode),
                          formatMoney(
                            item.rateAmount,
                            currencyCode: item.currencyCode,
                          ),
                        )}',
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
    final DateTime now = DateTime.now();
    final List<Customer> visible = _visibleCustomers(customers);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        ScopedSearchField(
          controller: _searchController,
          hintText: l10n.searchCustomersHint,
          minLengthHint: l10n.searchTypeMinChars,
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
          final String tier =
              customer.isTrusted ? l10n.customerTrusted : l10n.customerStandard;
          final CustomerBalanceAsOf balance =
              customerBalanceAsOf(customer, rentals, now);
          final String subtitle = balance.hasActivity
              ? l10n.customerSubtitleWithBalances(
                  customer.phone,
                  tier,
                  formatMoney(balance.advancePaise),
                  formatMoney(balance.pendingPaise),
                  formatMoney(balance.duePaise),
                )
              : l10n.customerSubtitle(customer.phone, tier);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: EntityCard(
              title: customer.name,
              subtitle: subtitle,
              leadingIcon: Icons.person_outline,
              status: customer.isTrusted
                  ? AssetStatus.available
                  : AssetStatus.archived,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (balance.duePaise > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        formatMoney(balance.duePaise),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.overdue,
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
                    title: Text(sheetL10n.actionAddInventory),
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
  final Set<String> _selectedLineIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<Rental>> rentalsAsync = ref.watch(rentalsProvider);
    final AsyncValue<List<Customer>> customersAsync = ref.watch(customersProvider);

    if (rentalsAsync.isLoading || customersAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<Rental> rentals = rentalsAsync.valueOrNull ?? const <Rental>[];
    final List<Customer> customers = customersAsync.valueOrNull ?? const <Customer>[];

    final Rental rental = rentals.firstWhere((item) => item.id == widget.rentalId);
    final Customer customer = customers.firstWhere((item) => item.id == rental.customerId);
    final DateTime now = DateTime.now();
    final int lateShown = rental.lateAmountAsOf(now);
    final int totalShown = rental.totalAmountAsOf(now);
    final List<RentalLine> openLines = rental.openLines;
    final List<RentalLine> closedLines = rental.returnedLines;
    final Set<String> openIds =
        openLines.map((RentalLine l) => l.id).toSet();
    final Set<String> selectedIds =
        _selectedLineIds.where(openIds.contains).toSet();

    return Scaffold(
      appBar: AppBar(title: Text(rental.id)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          EntityCard(
            title: rentalPartyLabel(customer, rental),
            subtitle: rental.nickname?.trim().isNotEmpty == true
                ? l10n.rentalNicknameSubtitle(customer.name, customer.phone)
                : l10n.phoneLabel(customer.phone),
            leadingIcon: Icons.person_outline,
            status: rental.statusFor(now),
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
                    l10n.orderStatusHeading,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.orderIssuedSummary(rental.lines.length),
                  ),
                  Text(
                    l10n.orderPendingSummary(openLines.length),
                  ),
                  Text(
                    l10n.orderReturnedSummary(closedLines.length),
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
                  Text(l10n.itemsHeading, style: Theme.of(context).textTheme.titleSmall),
                  if (rental.isActive && openLines.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      l10n.linesOpenCount(openLines.length, rental.lines.length),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.selectLinesToReturn),
                    ...openLines.map((RentalLine line) {
                      final bool selected = selectedIds.contains(line.id);
                      final int lineTotal = line.totalAmountAsOf(rental.startedAt, rental.dueAt, now);
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        value: selected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedLineIds.add(line.id);
                            } else {
                              _selectedLineIds.remove(line.id);
                            }
                          });
                        },
                        title: Text(line.displayLabel),
                        subtitle: Text(
                          '${l10n.lineOpenLabel} · ${formatMoney(lineTotal)}',
                        ),
                        secondary: TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ReplaceLineFlowScreen(
                                  rentalId: rental.id,
                                  lineId: line.id,
                                ),
                              ),
                            );
                          },
                          child: Text(l10n.replaceLineAction),
                        ),
                      );
                    }),
                  ],
                  if (closedLines.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      l10n.returnedLinesHeading,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    ...closedLines.map(
                      (RentalLine line) => Padding(
                        padding: const EdgeInsets.only(bottom: 4, top: 4),
                        child: Text(
                          '• ${line.displayLabel} — '
                          '${line.isSell ? l10n.soldLineBadge : l10n.lineReturnedLabel} · '
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
                        : l10n.reviewDueLabel(_date(rental.dueAt!)),
                  ),
                  if (rental.isOpenEnded && rental.isActive)
                    Text(l10n.accruedAmountHint),
                  Text(
                    l10n.inventoryRateSubtitle(
                      localizedBillingMode(l10n, rental.billingMode),
                      formatMoney(rental.rateAmount),
                    ),
                  ),
                  Text(
                    l10n.chargeBaseLabel(
                      formatMoney(
                        rental.isOpenEnded && rental.isActive
                            ? totalShown
                            : rental.baseAmount,
                      ),
                    ),
                  ),
                  if (lateShown > 0)
                    Text(l10n.chargeLateLabel(formatMoney(lateShown))),
                  Text(
                    l10n.chargeTotalLabel(formatMoney(totalShown)),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (rental.isActive) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      l10n.depositAvailableLabel(
                        formatMoney(customer.depositBalance),
                      ),
                    ),
                    Builder(
                      builder: (BuildContext context) {
                        final List<RentalLine> settleLines = selectedIds.isEmpty
                            ? openLines
                            : openLines
                                .where((RentalLine l) => selectedIds.contains(l.id))
                                .toList();
                        int previewTotal = 0;
                        for (final RentalLine line in settleLines) {
                          previewTotal += line.totalAmountAsOf(rental.startedAt, rental.dueAt, now);
                        }
                        final int willApply = customer.depositBalance < previewTotal
                            ? customer.depositBalance
                            : previewTotal;
                        final int remainingDue = previewTotal - willApply;
                        final int leftover = customer.depositBalance - willApply;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              l10n.depositWillApplyLabel(
                                formatMoney(willApply),
                              ),
                            ),
                            if (remainingDue > 0)
                              Text(
                                l10n.depositRemainingDueLabel(
                                  formatMoney(remainingDue),
                                ),
                              )
                            else if (leftover > 0)
                              Text(
                                l10n.depositLeftoverLabel(
                                  formatMoney(leftover),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ] else ...<Widget>[
                    if (rental.depositApplied > 0)
                      Text(
                        l10n.depositAppliedLabel(
                          formatMoney(rental.depositApplied),
                        ),
                      ),
                    Text(
                      l10n.depositNetDueLabel(
                        formatMoney(rental.amountDueAfterDeposit),
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
                  Text(l10n.timelineHeading, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  RentalTimeline(events: rental.timeline),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: rental.isActive
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: openLines.isEmpty
                          ? null
                          : () async {
                              final bool done = await _confirmAndReturnRental(
                                context: context,
                                ref: ref,
                                rental: rental,
                                customer: customer,
                                lineIds: openLines
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
                      onPressed: selectedIds.isEmpty
                          ? null
                          : () async {
                              final bool done = await _confirmAndReturnRental(
                                context: context,
                                ref: ref,
                                rental: rental,
                                customer: customer,
                                lineIds: selectedIds.toList(),
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
                                setState(() => _selectedLineIds.clear());
                              }
                            },
                      child: Text(l10n.returnSelectedAction),
                    ),
                  ),
                ],
              ),
            )
          : null,
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
  String? _selectedCategory;
  BillingMode _billingMode = BillingMode.weekly;
  bool _dueDateOptional = false;
  bool _requiresUnitIdentity = true;
  InventoryItemKind _defaultItemKind = InventoryItemKind.rental;

  @override
  void dispose() {
    _nameController.dispose();
    _customCategoryController.dispose();
    _unitsController.dispose();
    _notesController.dispose();
    _rateController.dispose();
    _lateFeeController.dispose();
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
    _billingMode = item.billingMode;
    _dueDateOptional = item.dueDateOptional;
    _requiresUnitIdentity = item.requiresUnitIdentity;
    _defaultItemKind = item.defaultItemKind;
    setState(() => _editing = true);
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
    final int units = int.tryParse(_unitsController.text.trim()) ?? 1;
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
      dueDateOptional: _dueDateOptional,
      requiresUnitIdentity: _requiresUnitIdentity,
      defaultItemKind: _selectedCategory == kCategoryGeneral
          ? InventoryItemKind.general
          : _defaultItemKind,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _saving = false;
      _editing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.inventoryUpdated)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<InventoryItem>> inventoryAsync = ref.watch(inventoryProvider);
    return inventoryAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (Object error, StackTrace _) => Scaffold(body: Center(child: Text('$error'))),
      data: (List<InventoryItem> inventory) {
        final InventoryItem item =
            inventory.firstWhere((entry) => entry.id == widget.itemId);
        final List<String> categoryOptions = buildCategoryOptions(inventory);
        final AssetStatus status =
            item.availableUnits > 0 ? AssetStatus.available : AssetStatus.rented;
        return Scaffold(
          appBar: AppBar(
            title: Text(_editing ? l10n.editInventoryTitle : l10n.inventoryDetailTitle),
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
                        setState(() {
                          _selectedCategory = value;
                          if (value == kCategoryGeneral) {
                            _defaultItemKind = InventoryItemKind.general;
                          }
                        });
                      },
                      categoryLabel: l10n.categoryLabel,
                      otherLabel: l10n.categoryOtherLabel,
                      generalLabel: l10n.categoryGeneralLabel,
                      customLabel: l10n.categoryCustomLabel,
                      customHint: l10n.categoryCustomHint,
                    ),
                    const SizedBox(height: 8),
                    if (_selectedCategory != kCategoryGeneral) ...<Widget>[
                      Text(
                        l10n.itemKindDefaultLabel,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<InventoryItemKind>(
                        segments: <ButtonSegment<InventoryItemKind>>[
                          ButtonSegment<InventoryItemKind>(
                            value: InventoryItemKind.rental,
                            label: Text(l10n.itemKindRentalLabel),
                          ),
                          ButtonSegment<InventoryItemKind>(
                            value: InventoryItemKind.general,
                            label: Text(l10n.itemKindGeneralLabel),
                          ),
                        ],
                        selected: <InventoryItemKind>{_defaultItemKind},
                        onSelectionChanged: (Set<InventoryItemKind> selection) {
                          setState(() => _defaultItemKind = selection.first);
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                    TextField(
                      controller: _unitsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.totalUnitsLabel,
                        helperText: l10n.totalUnitsHelper,
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
                    TextField(
                      controller: _rateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: l10n.rateAmountLabel,
                        hintText: l10n.rateAmountHint,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _lateFeeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: l10n.lateFeePerDayLabel,
                        hintText: l10n.lateFeePerDayHint,
                      ),
                    ),
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
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: l10n.notesLabel,
                        hintText: l10n.notesHint,
                      ),
                    ),
                  ]
                : <Widget>[
                    EntityCard(
                      title: item.name,
                      subtitle: l10n.inventoryAvailableSubtitle(
                        item.isGeneral
                            ? '${item.category} · ${l10n.itemKindGeneralBadge}'
                            : item.category,
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
                        subtitle: item.requiresUnitIdentity
                            ? Text(l10n.inventoryInstancesNote)
                            : null,
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
    final AsyncValue<List<DepositLedgerEntry>> ledgerAsync =
        ref.watch(depositLedgerProvider(customerId));

    if (customersAsync.isLoading || rentalsAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<Customer> customers = customersAsync.valueOrNull ?? const <Customer>[];
    final List<Rental> rentals = rentalsAsync.valueOrNull ?? const <Rental>[];
    final Customer customer = customers.firstWhere((entry) => entry.id == customerId);
    final List<Rental> customerRentals =
        rentals.where((entry) => entry.customerId == customer.id).toList();
    final List<DepositLedgerEntry> ledger =
        (ledgerAsync.valueOrNull ?? const <DepositLedgerEntry>[]).take(10).toList();
    final CustomerBalanceAsOf balance =
        customerBalanceAsOf(customer, rentals, DateTime.now());

    return Scaffold(
      appBar: AppBar(title: Text(l10n.customerProfileTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          EntityCard(
            title: customer.name,
            subtitle: customer.phone,
            leadingIcon: Icons.person_outline,
            status: customer.isTrusted ? AssetStatus.available : AssetStatus.archived,
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
                    label: l10n.balanceDueLabel,
                    amount: formatMoney(balance.duePaise),
                    emphasize: balance.duePaise > 0,
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
                    l10n.depositBalanceLabel,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatMoney(customer.depositBalance),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: FilledButton(
                          onPressed: () => _showDepositAmountDialog(
                            context: context,
                            ref: ref,
                            customer: customer,
                            isTopUp: true,
                          ),
                          child: Text(l10n.depositAddAction),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: customer.depositBalance > 0
                              ? () => _showDepositAmountDialog(
                                    context: context,
                                    ref: ref,
                                    customer: customer,
                                    isTopUp: false,
                                  )
                              : null,
                          child: Text(l10n.depositRefundAction),
                        ),
                      ),
                    ],
                  ),
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
          const SizedBox(height: 10),
          Text(
            l10n.depositLedgerHeading,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (ledger.isEmpty)
            Text(l10n.depositLedgerEmpty)
          else
            ...ledger.map(
              (DepositLedgerEntry entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    title: Text(_depositLedgerTitle(l10n, entry)),
                    subtitle: Text(
                      <String>[
                        l10n.depositLedgerBalanceAfter(
                          formatMoney(entry.balanceAfter),
                        ),
                        if (entry.note != null && entry.note!.isNotEmpty)
                          entry.note!,
                        _date(entry.at),
                      ].join(' · '),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 10),
          Text(
            l10n.activityTimelineHeading,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (customerRentals.isEmpty)
            Text(l10n.activityEmpty)
          else ..._customerActivitySection(context, l10n, customerRentals),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: FilledButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => NewOrderFlowScreen(
                  initialCustomerId: customer.id,
                ),
              ),
            );
          },
          child: Text(l10n.issueToCustomerAction),
        ),
      ),
    );
  }

  List<Widget> _customerActivitySection(
    BuildContext context,
    AppLocalizations l10n,
    List<Rental> customerRentals,
  ) {
    final List<Rental> ordered = List<Rental>.from(customerRentals)
      ..sort((Rental a, Rental b) => b.startedAt.compareTo(a.startedAt));
    final List<CustomerActivityEntry> activity =
        buildCustomerActivity(customerRentals);
    return <Widget>[
      ...ordered.map((Rental rental) {
        final RentalOrderStatusSummary summary =
            RentalOrderStatusSummary.fromRental(rental);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: EntityCard(
            title: _rentalLinesLabel(rental),
            subtitle: l10n.rentalOrderStatusChips(
              summary.issued,
              summary.pending,
              summary.returned,
            ),
            leadingIcon: Icons.assignment_outlined,
            status: rental.statusFor(DateTime.now()),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RentalDetailScreen(rentalId: rental.id),
                ),
              );
            },
          ),
        );
      }),
      const SizedBox(height: 4),
      if (activity.isEmpty)
        Text(l10n.activityEmpty)
      else
        ...activity.map((CustomerActivityEntry entry) {
          final String title = switch (entry.kind) {
            CustomerActivityKind.issued => l10n.activityIssued(entry.subtitle),
            CustomerActivityKind.returned =>
              l10n.activityReturned(entry.subtitle),
            CustomerActivityKind.event => entry.title,
          };
          final String? subtitle = entry.kind == CustomerActivityKind.event
              ? entry.subtitle
              : entry.rentalId;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: ListTile(
                leading: Icon(
                  switch (entry.kind) {
                    CustomerActivityKind.issued => Icons.output_outlined,
                    CustomerActivityKind.returned => Icons.input_outlined,
                    CustomerActivityKind.event => Icons.history,
                  },
                ),
                title: Text(title),
                subtitle: Text(
                  <String>[
                    if (subtitle != null && subtitle.isNotEmpty) subtitle,
                    _date(entry.at),
                  ].join(' · '),
                ),
                onTap: entry.rentalId == null
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => RentalDetailScreen(
                              rentalId: entry.rentalId!,
                            ),
                          ),
                        );
                      },
              ),
            ),
          );
        }),
    ];
  }
}

class ReplaceLineFlowScreen extends ConsumerStatefulWidget {
  const ReplaceLineFlowScreen({
    required this.rentalId,
    required this.lineId,
    super.key,
  });

  final String rentalId;
  final String lineId;

  @override
  ConsumerState<ReplaceLineFlowScreen> createState() =>
      _ReplaceLineFlowScreenState();
}

class _ReplaceLineFlowScreenState extends ConsumerState<ReplaceLineFlowScreen> {
  final TextEditingController _instanceNameController = TextEditingController();
  final TextEditingController _shortCodeController = TextEditingController();
  final TextEditingController _durationController =
      TextEditingController(text: '1');
  String? _selectedItemId;
  DateTime? _customEnd;
  bool _submitting = false;

  @override
  void dispose() {
    _instanceNameController.dispose();
    _shortCodeController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<Rental>> rentalsAsync = ref.watch(rentalsProvider);
    final AsyncValue<List<InventoryItem>> inventoryAsync =
        ref.watch(inventoryProvider);
    final AsyncValue<List<Customer>> customersAsync =
        ref.watch(customersProvider);

    if (rentalsAsync.isLoading ||
        inventoryAsync.isLoading ||
        customersAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final Rental rental = (rentalsAsync.valueOrNull ?? const <Rental>[])
        .firstWhere((Rental r) => r.id == widget.rentalId);
    final RentalLine line = rental.lines.firstWhere(
      (RentalLine l) => l.id == widget.lineId,
    );
    final Customer customer = (customersAsync.valueOrNull ?? const <Customer>[])
        .firstWhere((Customer c) => c.id == rental.customerId);
    final List<InventoryItem> available = (inventoryAsync.valueOrNull ??
            const <InventoryItem>[])
        .where((InventoryItem i) => i.availableUnits > 0)
        .toList();
    final InventoryItem? selected = _selectedItemId == null
        ? null
        : available.cast<InventoryItem?>().firstWhere(
              (InventoryItem? i) => i?.id == _selectedItemId,
              orElse: () => null,
            );
    final DateTime now = DateTime.now();
    final int oldCharge = line.totalAmountAsOf(rental.startedAt, rental.dueAt, now);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.replaceFlowTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(l10n.replaceSettlementIntro),
          const SizedBox(height: 8),
          Text(
            l10n.lineChargePreview(line.displayLabel, formatMoney(oldCharge)),
          ),
          Text(
            l10n.depositAvailableLabel(formatMoney(customer.depositBalance)),
          ),
          const SizedBox(height: 16),
          Text(l10n.reviewItemsLabel),
          const SizedBox(height: 8),
          ...available.map(
            (InventoryItem item) => ListTile(
              leading: Icon(
                _selectedItemId == item.id
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
              ),
              title: Text(item.name),
              subtitle: Text(
                l10n.inventoryAvailableSubtitle(
                  item.category,
                  item.availableUnits,
                  item.totalUnits,
                ),
              ),
              onTap: () => setState(() => _selectedItemId = item.id),
            ),
          ),
          if (selected != null) ...<Widget>[
            const SizedBox(height: 8),
            TextField(
              controller: _instanceNameController,
              decoration: InputDecoration(
                labelText: l10n.instanceNameLabel,
                hintText: l10n.instanceNameHint,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _shortCodeController,
              decoration: InputDecoration(
                labelText: l10n.shortCodeLabel,
                hintText: l10n.shortCodeHint,
              ),
            ),
            const SizedBox(height: 8),
            if (selected.billingMode == BillingMode.custom)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.customEndDateLabel),
                subtitle: Text(
                  _customEnd == null ? '—' : _date(_customEnd!),
                ),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: () async {
                  final DateTime today = DateTime.now();
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _customEnd ?? today,
                    firstDate: today,
                    lastDate: today.add(const Duration(days: 365 * 2)),
                  );
                  if (picked != null) {
                    setState(() => _customEnd = picked);
                  }
                },
              )
            else
              TextField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: switch (selected.billingMode) {
                    BillingMode.daily => l10n.durationUnitsDaily,
                    BillingMode.weekly => l10n.durationUnitsWeekly,
                    BillingMode.monthly => l10n.durationUnitsMonthly,
                    BillingMode.fixed => l10n.durationUnitsFixed,
                    BillingMode.custom => l10n.durationUnitsLabel,
                  },
                ),
              ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: FilledButton(
          onPressed: _submitting || selected == null
              ? null
              : () async {
                  final String instanceName =
                      _instanceNameController.text.trim();
                  final String shortCode =
                      LocalRepository.normalizeShortCode(
                    _shortCodeController.text,
                  );
                  if (instanceName.isEmpty || shortCode.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.instanceLabelsRequired)),
                    );
                    return;
                  }
                  if (selected.billingMode == BillingMode.custom &&
                      _customEnd == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.customEndRequired)),
                    );
                    return;
                  }
                  final int units =
                      int.tryParse(_durationController.text.trim()) ?? 1;
                  setState(() => _submitting = true);
                  try {
                    final String? nick = isUnknownCustomer(customer)
                        ? rental.nickname
                        : null;
                    final RentalReplaceResult? result = await ref
                        .read(repositoryProvider)
                        .replaceRentalLine(
                          rentalId: rental.id,
                          lineId: line.id,
                          newLine: RentalLineInput(
                            itemId: selected.id,
                            instanceName: instanceName,
                            shortCode: shortCode,
                          ),
                          nickname: nick,
                          durationUnits: units < 1 ? 1 : units,
                          customEnd: selected.billingMode == BillingMode.custom
                              ? _customEnd
                              : null,
                          billingModeOverride: selected.billingMode,
                        );
                    if (!context.mounted) {
                      return;
                    }
                    if (result == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.rentalReturned(rental.id))),
                      );
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.replaceSuccessSnack(
                            result.newRentalId,
                            formatMoney(
                              result.returnResult.depositBalanceAfter,
                            ),
                          ),
                        ),
                      ),
                    );
                    Navigator.of(context).pop();
                  } on DuplicateActiveShortCodeException catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.duplicateShortCode(error.shortCode),
                          ),
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _submitting = false);
                    }
                  }
                },
          child: Text(l10n.replaceConfirmAction),
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
    final AsyncValue<List<Customer>> customersAsync = ref.watch(customersProvider);
    return rentalsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (Object error, StackTrace _) => Scaffold(body: Center(child: Text('$error'))),
      data: (List<Rental> rentals) {
        final List<Rental> active = rentals.where((item) => item.isActive).toList();
        final List<Customer> customers =
            customersAsync.valueOrNull ?? const <Customer>[];
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
                      final Customer customer = customers.firstWhere(
                        (Customer c) => c.id == rental.customerId,
                        orElse: () => Customer(
                          id: rental.customerId,
                          name: l10n.unknownCustomer,
                          phone: '',
                          isTrusted: false,
                          qrCode: '',
                        ),
                      );
                      final int total = rental.totalAmountAsOf(now);
                      final int willApply = customer.depositBalance < total
                          ? customer.depositBalance
                          : total;
                      final String openBit = rental.openLines.length < rental.lines.length
                          ? l10n.linesOpenCount(
                              rental.openLines.length,
                              rental.lines.length,
                            )
                          : '';
                      return EntityCard(
                        title: _rentalLinesLabel(rental),
                        subtitle: <String>[
                          rental.isOpenEnded
                              ? l10n.rentalAmountOpenEnded(formatMoney(total))
                              : l10n.rentalAmountSubtitle(
                                  _date(rental.dueAt!),
                                  formatMoney(total),
                                ),
                          if (rental.isOpenEnded) l10n.accruedAmountHint,
                          if (openBit.isNotEmpty) openBit,
                          if (customer.depositBalance > 0)
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
  late String _selectedCategory;
  BillingMode _billingMode = BillingMode.weekly;
  bool _dueDateOptional = false;
  bool _requiresUnitIdentity = true;
  InventoryItemKind _defaultItemKind = InventoryItemKind.rental;
  bool _submitting = false;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final List<InventoryItem> inventory =
        ref.watch(inventoryProvider).asData?.value ?? const <InventoryItem>[];
    final List<String> categoryOptions = buildCategoryOptions(inventory);
    final String selectedCategory = categoryOptions.contains(_selectedCategory)
        ? _selectedCategory
        : (categoryOptions.isNotEmpty
            ? categoryOptions.first
            : kCategoryOther);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.actionAddInventory)),
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
                setState(() {
                  _selectedCategory = value;
                  if (value == kCategoryGeneral) {
                    _defaultItemKind = InventoryItemKind.general;
                  }
                });
              }
            },
            categoryLabel: l10n.categoryLabel,
            otherLabel: l10n.categoryOtherLabel,
            generalLabel: l10n.categoryGeneralLabel,
            customLabel: l10n.categoryCustomLabel,
            customHint: l10n.categoryCustomHint,
          ),
          const SizedBox(height: 8),
          if (selectedCategory != kCategoryGeneral) ...<Widget>[
            Text(
              l10n.itemKindDefaultLabel,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<InventoryItemKind>(
              segments: <ButtonSegment<InventoryItemKind>>[
                ButtonSegment<InventoryItemKind>(
                  value: InventoryItemKind.rental,
                  label: Text(l10n.itemKindRentalLabel),
                ),
                ButtonSegment<InventoryItemKind>(
                  value: InventoryItemKind.general,
                  label: Text(l10n.itemKindGeneralLabel),
                ),
              ],
              selected: <InventoryItemKind>{_defaultItemKind},
              onSelectionChanged: (Set<InventoryItemKind> selection) {
                setState(() => _defaultItemKind = selection.first);
              },
            ),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: _unitsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.unitsLabel),
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
          TextField(
            controller: _rateController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.rateAmountLabel,
              hintText: l10n.rateAmountHint,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _lateFeeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.lateFeePerDayLabel,
              hintText: l10n.lateFeePerDayHint,
            ),
          ),
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
                  setState(() => _submitting = true);
                  await ref.read(repositoryProvider).addInventory(
                    name: _nameController.text.trim(),
                    category: category,
                    units: units < 1 ? 1 : units,
                    notes: _notesController.text.trim(),
                    billingMode: _billingMode,
                    rateAmount: parseRupeesToPaise(_rateController.text),
                    lateFeePerDay: parseRupeesToPaise(_lateFeeController.text),
                    dueDateOptional: _dueDateOptional,
                    requiresUnitIdentity: _requiresUnitIdentity,
                    defaultItemKind: selectedCategory == kCategoryGeneral
                        ? InventoryItemKind.general
                        : _defaultItemKind,
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

String _date(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

String _rentalAmountSubtitle(AppLocalizations l10n, Rental rental) {
  final DateTime now = DateTime.now();
  final String amount = formatMoney(rental.totalAmountAsOf(now));
  final String base = rental.isOpenEnded
      ? l10n.rentalAmountOpenEnded(amount)
      : l10n.rentalAmountSubtitle(_date(rental.dueAt!), amount);
  if (!rental.isActive && rental.depositApplied > 0) {
    return '$base · ${l10n.depositAppliedLabel(formatMoney(rental.depositApplied))}';
  }
  return base;
}

String _depositLedgerTitle(AppLocalizations l10n, DepositLedgerEntry entry) {
  final String amount = formatMoney(entry.amount.abs());
  switch (entry.type) {
    case DepositLedgerType.topUp:
      return l10n.depositLedgerTopUp(amount);
    case DepositLedgerType.apply:
      return l10n.depositLedgerApply(amount);
    case DepositLedgerType.refund:
      return l10n.depositLedgerRefund(amount);
    case DepositLedgerType.adjust:
      return l10n.depositLedgerAdjust(amount);
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
    targets = rental.openLines;
  } else {
    final Set<String> wanted = lineIds.toSet();
    targets =
        rental.openLines.where((RentalLine l) => wanted.contains(l.id)).toList();
  }
  if (targets.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.noLinesSelected)),
    );
    return false;
  }

  int total = 0;
  for (final RentalLine line in targets) {
    total += line.totalAmountAsOf(rental.startedAt, rental.dueAt, now);
  }
  final int willApply =
      customer.depositBalance < total ? customer.depositBalance : total;
  final int remainingDue = total - willApply;
  final int leftover = customer.depositBalance - willApply;

  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
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
                    formatMoney(line.totalAmountAsOf(rental.startedAt, rental.dueAt, now)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(l10n.chargeTotalLabel(formatMoney(total))),
              Text(
                l10n.depositAvailableLabel(formatMoney(customer.depositBalance)),
              ),
              Text(l10n.depositWillApplyLabel(formatMoney(willApply))),
              if (remainingDue > 0)
                Text(l10n.depositRemainingDueLabel(formatMoney(remainingDue)))
              else if (leftover > 0)
                Text(l10n.depositLeftoverLabel(formatMoney(leftover))),
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
  if (confirmed != true || !context.mounted) {
    return false;
  }

  final RentalReturnResult? result = await ref
      .read(repositoryProvider)
      .returnRentalLines(
        rental.id,
        targets.map((RentalLine l) => l.id).toList(),
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

Future<void> _showDepositAmountDialog({
  required BuildContext context,
  required WidgetRef ref,
  required Customer customer,
  required bool isTopUp,
}) async {
  final AppLocalizations l10n = context.l10n;
  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(isTopUp ? l10n.depositTopUpTitle : l10n.depositRefundTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.depositAmountLabel,
                hintText: l10n.depositAmountHint,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: l10n.depositNoteLabel,
                hintText: l10n.depositNoteHint,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              isTopUp ? l10n.depositConfirmTopUp : l10n.depositConfirmRefund,
            ),
          ),
        ],
      );
    },
  );

  final int amountPaise = parseRupeesToPaise(amountController.text);
  amountController.dispose();
  final String note = noteController.text.trim();
  noteController.dispose();

  if (confirmed != true || !context.mounted) {
    return;
  }
  if (amountPaise <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.depositInvalidAmount)),
    );
    return;
  }
  if (!isTopUp && amountPaise > customer.depositBalance) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.depositRefundExceeds)),
    );
    return;
  }

  try {
    final Customer updated = isTopUp
        ? await ref.read(repositoryProvider).topUpDeposit(
              customer.id,
              amountPaise,
              note: note.isEmpty ? null : note,
            )
        : await ref.read(repositoryProvider).refundDeposit(
              customer.id,
              amountPaise,
              note: note.isEmpty ? null : note,
            );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isTopUp
              ? l10n.depositTopUpSuccess(formatMoney(updated.depositBalance))
              : l10n.depositRefundSuccess(formatMoney(updated.depositBalance)),
        ),
      ),
    );
  } on ArgumentError catch (error) {
    if (!context.mounted) {
      return;
    }
    final String message = error.message == 'Refund cannot exceed deposit balance'
        ? l10n.depositRefundExceeds
        : '$error';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
