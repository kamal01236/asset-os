import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_branding.dart';
import 'core/l10n/l10n_ext.dart';
import 'core/models/entities.dart';
import 'core/models/self_customer.dart';
import 'core/pricing/rental_pricing.dart';
import 'core/providers/app_providers.dart';
import 'core/repositories/local_repository.dart';
import 'core/widgets/rental_timeline.dart';
import 'core/widgets/ui_primitives.dart';
import 'features/reports/share_reports_screen.dart';
import 'features/templates/business_templates_screen.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final int tabIndex = ref.watch(currentTabIndexProvider);
    final bool offlineMode = ref.watch(offlineModeProvider);
    final List<Widget> pages = <Widget>[
      HomeScreen(
        onOpenSearch: () => _openSearch(context),
        onNewRental: () => _openNewRentalFlow(context),
        onReturnItem: () => _openReturnFlow(context),
        onAddInventory: () => _openAddInventoryFlow(context),
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
        actions: <Widget>[
          IconButton(
            tooltip: l10n.actionSearch,
            icon: const Icon(Icons.search),
            onPressed: () => _openSearch(context),
          ),
        ],
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
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const UniversalSearchScreen(),
      ),
    );
  }

  Future<void> _openNewRentalFlow(
    BuildContext context, {
    String? customerId,
    List<String> itemIds = const <String>[],
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NewRentalFlowScreen(
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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    required this.onOpenSearch,
    required this.onNewRental,
    required this.onReturnItem,
    required this.onAddInventory,
    super.key,
  });

  final VoidCallback onOpenSearch;
  final VoidCallback onNewRental;
  final VoidCallback onReturnItem;
  final VoidCallback onAddInventory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<InventoryItem>> inventoryAsync = ref.watch(inventoryProvider);
    final AsyncValue<List<Rental>> rentalsAsync = ref.watch(rentalsProvider);

    if (inventoryAsync.isLoading || rentalsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<InventoryItem> inventory = inventoryAsync.valueOrNull ?? const <InventoryItem>[];
    final List<Rental> rentals = rentalsAsync.valueOrNull ?? const <Rental>[];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        LargeSearchBar(onTap: onOpenSearch, hintText: l10n.searchAnything),
        const SizedBox(height: 14),
        Text(
          l10n.todayAtAGlance,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.8,
          children: <Widget>[
            KpiCard(
              label: l10n.kpiActive,
              value: summaryCount(
                status: AssetStatus.rented,
                inventory: inventory,
                rentals: rentals,
              ),
              status: AssetStatus.rented,
            ),
            KpiCard(
              label: l10n.statusDueToday,
              value: summaryCount(
                status: AssetStatus.dueToday,
                inventory: inventory,
                rentals: rentals,
              ),
              status: AssetStatus.dueToday,
            ),
            KpiCard(
              label: l10n.statusOverdue,
              value: summaryCount(
                status: AssetStatus.overdue,
                inventory: inventory,
                rentals: rentals,
              ),
              status: AssetStatus.overdue,
            ),
            KpiCard(
              label: l10n.statusAvailable,
              value: summaryCount(
                status: AssetStatus.available,
                inventory: inventory,
                rentals: rentals,
              ),
              status: AssetStatus.available,
            ),
          ],
        ),
        const SizedBox(height: 14),
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
              label: Text(l10n.actionAddInventory),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Card(
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
        ),
      ],
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
                    builder: (_) => const NewRentalFlowScreen(),
                  ),
                );
              },
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (BuildContext context, int index) {
            final Rental rental = rentals[index];
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
              title: rental.lines.isNotEmpty
                  ? rental.lines.map((RentalLine line) => line.displayLabel).join(', ')
                  : rental.id,
              subtitle:
                  '${rentalPartyLabel(customer, rental)} · ${_rentalAmountSubtitle(l10n, rental)}',
              leadingIcon: Icons.assignment_outlined,
              status: rental.statusFor(now),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onOpenRental(rental),
            );
          },
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemCount: rentals.length,
        );
      },
    );
  }
}

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({
    required this.onOpenInventory,
    super.key,
  });

  final ValueChanged<InventoryItem> onOpenInventory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<InventoryItem>> inventoryAsync = ref.watch(inventoryProvider);
    return inventoryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace _) => Center(child: Text('$error')),
      data: (List<InventoryItem> inventory) {
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (BuildContext context, int index) {
            final InventoryItem item = inventory[index];
            final AssetStatus status =
                item.availableUnits > 0 ? AssetStatus.available : AssetStatus.rented;
            return EntityCard(
              title: item.name,
              subtitle:
                  '${l10n.inventoryAvailableSubtitle(
                    item.category,
                    item.availableUnits,
                    item.totalUnits,
                  )} · ${l10n.inventoryRateSubtitle(
                    localizedBillingMode(l10n, item.billingMode),
                    formatMoney(item.rateAmount, currencyCode: item.currencyCode),
                  )}',
              leadingIcon: Icons.inventory_2_outlined,
              status: status,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onOpenInventory(item),
            );
          },
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemCount: inventory.length,
        );
      },
    );
  }
}

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({
    required this.onOpenCustomer,
    super.key,
  });

  final ValueChanged<Customer> onOpenCustomer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<Customer>> customersAsync = ref.watch(customersProvider);
    return customersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace _) => Center(child: Text('$error')),
      data: (List<Customer> customers) {
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (BuildContext context, int index) {
            final Customer customer = customers[index];
            final String tier =
                customer.isTrusted ? l10n.customerTrusted : l10n.customerStandard;
            return EntityCard(
              title: customer.name,
              subtitle: customer.depositBalance > 0
                  ? l10n.customerSubtitleWithDeposit(
                      customer.phone,
                      tier,
                      formatMoney(customer.depositBalance),
                    )
                  : l10n.customerSubtitle(customer.phone, tier),
              leadingIcon: Icons.person_outline,
              status: customer.isTrusted ? AssetStatus.available : AssetStatus.archived,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onOpenCustomer(customer),
            );
          },
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemCount: customers.length,
        );
      },
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

class RentalDetailScreen extends ConsumerWidget {
  const RentalDetailScreen({
    required this.rentalId,
    super.key,
  });

  final String rentalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<Rental>> rentalsAsync = ref.watch(rentalsProvider);
    final AsyncValue<List<Customer>> customersAsync = ref.watch(customersProvider);

    if (rentalsAsync.isLoading || customersAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<Rental> rentals = rentalsAsync.valueOrNull ?? const <Rental>[];
    final List<Customer> customers = customersAsync.valueOrNull ?? const <Customer>[];

    final Rental rental = rentals.firstWhere((item) => item.id == rentalId);
    final Customer customer = customers.firstWhere((item) => item.id == rental.customerId);
    final DateTime now = DateTime.now();
    final int lateShown = rental.lateAmountAsOf(now);
    final int totalShown = rental.totalAmountAsOf(now);

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
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(l10n.itemsHeading, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 6),
                  ...rental.lines.map((RentalLine line) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• ${line.displayLabel}'),
                  )),
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
                  Text(l10n.reviewDueLabel(_date(rental.dueAt))),
                  Text(
                    l10n.inventoryRateSubtitle(
                      localizedBillingMode(l10n, rental.billingMode),
                      formatMoney(rental.rateAmount),
                    ),
                  ),
                  Text(l10n.chargeBaseLabel(formatMoney(rental.baseAmount))),
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
                        final int willApply = customer.depositBalance < totalShown
                            ? customer.depositBalance
                            : totalShown;
                        final int remainingDue = totalShown - willApply;
                        final int leftover =
                            customer.depositBalance - willApply;
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
                    if (!rental.isActive)
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
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.extendPlaceholder)),
                  );
                },
                child: Text(l10n.extendAction),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.sharePlaceholder)),
                  );
                },
                child: Text(l10n.shareAction),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: rental.isActive
                    ? () async {
                        final bool done = await _confirmAndReturnRental(
                          context: context,
                          ref: ref,
                          rental: rental,
                          customer: customer,
                        );
                        if (done && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      }
                    : null,
                child: Text(l10n.actionReturn),
              ),
            ),
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
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _unitsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _lateFeeController = TextEditingController();
  BillingMode _billingMode = BillingMode.weekly;

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _unitsController.dispose();
    _notesController.dispose();
    _rateController.dispose();
    _lateFeeController.dispose();
    super.dispose();
  }

  void _beginEdit(InventoryItem item) {
    _nameController.text = item.name;
    _categoryController.text = item.category;
    _unitsController.text = '${item.totalUnits}';
    _notesController.text = item.notes ?? '';
    _rateController.text = paiseToRupeesField(item.rateAmount);
    _lateFeeController.text = paiseToRupeesField(item.lateFeePerDay);
    _billingMode = item.billingMode;
    setState(() => _editing = true);
  }

  Future<void> _saveEdit() async {
    if (_saving) {
      return;
    }
    final AppLocalizations l10n = context.l10n;
    final String name = _nameController.text.trim();
    final String category = _categoryController.text.trim();
    if (name.isEmpty || category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.nameCategoryRequired)),
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
      notes: _notesController.text.trim(),
      billingMode: _billingMode,
      rateAmount: parseRupeesToPaise(_rateController.text),
      lateFeePerDay: parseRupeesToPaise(_lateFeeController.text),
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
                  onPressed: () => _beginEdit(item),
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
                    TextField(
                      controller: _categoryController,
                      decoration: InputDecoration(labelText: l10n.categoryLabel),
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
                        item.category,
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
                          '${item.lateFeePerDay > 0 ? ' · ${formatMoney(item.lateFeePerDay)}/day late' : ''}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.label_outline),
                        title: Text(l10n.inventoryInstancesNote),
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
                              builder: (_) => NewRentalFlowScreen(
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
            l10n.recentRentals,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...customerRentals.map(
            (rental) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: EntityCard(
                title: rental.lines.isNotEmpty
                    ? rental.lines.map((RentalLine line) => line.displayLabel).join(', ')
                    : rental.id,
                subtitle: _rentalAmountSubtitle(l10n, rental),
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
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: FilledButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => NewRentalFlowScreen(
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
}

class UniversalSearchScreen extends ConsumerStatefulWidget {
  const UniversalSearchScreen({super.key});

  @override
  ConsumerState<UniversalSearchScreen> createState() => _UniversalSearchScreenState();
}

class _UniversalSearchScreenState extends ConsumerState<UniversalSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  SearchResults _results = const SearchResults(
    customers: <Customer>[],
    currentRentals: <Rental>[],
    previousRentals: <Rental>[],
    inventory: <InventoryItem>[],
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String query) async {
    final SearchResults results = await ref.read(repositoryProvider).search(query);
    if (!mounted) {
      return;
    }
    setState(() => _results = results);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.actionSearch)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.searchHint,
            ),
            onChanged: _runSearch,
          ),
          const SizedBox(height: 12),
          _SearchSection<Customer>(
            title: l10n.searchSectionCustomers,
            items: _results.customers,
            itemBuilder: (customer) => EntityCard(
              title: customer.name,
              subtitle: customer.phone,
              leadingIcon: Icons.person_outline,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CustomerDetailScreen(customerId: customer.id),
                  ),
                );
              },
            ),
          ),
          _SearchSection<Rental>(
            title: l10n.searchSectionCurrentRentals,
            items: _results.currentRentals,
            itemBuilder: (rental) => EntityCard(
              title: rental.lines.isNotEmpty
                  ? rental.lines.map((RentalLine line) => line.displayLabel).join(', ')
                  : rental.id,
              subtitle: _rentalAmountSubtitle(l10n, rental),
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
          ),
          _SearchSection<Rental>(
            title: l10n.searchSectionPreviousRentals,
            items: _results.previousRentals,
            itemBuilder: (rental) => EntityCard(
              title: rental.lines.isNotEmpty
                  ? rental.lines.map((RentalLine line) => line.displayLabel).join(', ')
                  : rental.id,
              subtitle: <String>[
                l10n.returnedDate(_date(rental.returnedAt ?? rental.dueAt)),
                if (rental.depositApplied > 0)
                  l10n.depositAppliedLabel(formatMoney(rental.depositApplied)),
              ].join(' · '),
              leadingIcon: Icons.history,
              status: AssetStatus.archived,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RentalDetailScreen(rentalId: rental.id),
                  ),
                );
              },
            ),
          ),
          _SearchSection<InventoryItem>(
            title: l10n.searchSectionInventory,
            items: _results.inventory,
            itemBuilder: (item) => EntityCard(
              title: item.name,
              subtitle: l10n.inventoryUnitsSubtitle(
                item.category,
                item.availableUnits,
                item.totalUnits,
              ),
              leadingIcon: Icons.inventory_2_outlined,
              status: item.availableUnits > 0 ? AssetStatus.available : AssetStatus.rented,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => InventoryDetailScreen(itemId: item.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchSection<T> extends StatelessWidget {
  const _SearchSection({
    required this.title,
    required this.items,
    required this.itemBuilder,
  });

  final String title;
  final List<T> items;
  final Widget Function(T item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l10n.noMatchingSection(title),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: itemBuilder(item),
            ),
          ),
        const SizedBox(height: 6),
      ],
    );
  }
}

enum _RentalFlowStep { party, items, labels, duration, review }

class NewRentalFlowScreen extends ConsumerStatefulWidget {
  const NewRentalFlowScreen({
    super.key,
    this.initialCustomerId,
    this.initialInventoryItemIds = const <String>[],
  });

  final String? initialCustomerId;
  final List<String> initialInventoryItemIds;

  @override
  ConsumerState<NewRentalFlowScreen> createState() => _NewRentalFlowScreenState();
}

class _NewRentalFlowScreenState extends ConsumerState<NewRentalFlowScreen> {
  int _stepIndex = 0;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _durationController = TextEditingController(text: '1');
  final TextEditingController _inventorySearchController = TextEditingController();
  final Set<String> _selectedInventoryIds = <String>{};
  final Map<String, TextEditingController> _instanceNameControllers =
      <String, TextEditingController>{};
  final Map<String, TextEditingController> _shortCodeControllers =
      <String, TextEditingController>{};
  Customer? _resolvedCustomer;
  DateTime? _customEnd;
  bool _submitting = false;
  bool _prefillApplied = false;
  String _inventoryQuery = '';

  bool get _isSelfSelected =>
      (widget.initialCustomerId != null &&
          isSelfCustomerId(widget.initialCustomerId!)) ||
      (_resolvedCustomer != null && isSelfCustomer(_resolvedCustomer!));

  bool get _skipPartyStep =>
      widget.initialCustomerId != null &&
      !isSelfCustomerId(widget.initialCustomerId!);

  bool get _nicknameOnlyParty =>
      widget.initialCustomerId != null &&
      isSelfCustomerId(widget.initialCustomerId!);

  bool get _showInventorySearch => widget.initialCustomerId != null;

  List<_RentalFlowStep> get _steps {
    final List<_RentalFlowStep> steps = <_RentalFlowStep>[];
    if (!_skipPartyStep) {
      steps.add(_RentalFlowStep.party);
    }
    steps.addAll(const <_RentalFlowStep>[
      _RentalFlowStep.items,
      _RentalFlowStep.labels,
      _RentalFlowStep.duration,
      _RentalFlowStep.review,
    ]);
    return steps;
  }

  _RentalFlowStep get _currentStep => _steps[_stepIndex];

  @override
  void initState() {
    super.initState();
    if (widget.initialInventoryItemIds.isNotEmpty) {
      _selectedInventoryIds.addAll(widget.initialInventoryItemIds);
      _syncLabelControllers(_selectedInventoryIds);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyPrefill();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _nicknameController.dispose();
    _durationController.dispose();
    _inventorySearchController.dispose();
    for (final TextEditingController c in _instanceNameControllers.values) {
      c.dispose();
    }
    for (final TextEditingController c in _shortCodeControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _applyPrefill() async {
    if (_prefillApplied || !mounted) {
      return;
    }
    _prefillApplied = true;
    if (widget.initialCustomerId == null) {
      return;
    }
    final LocalRepository repository = ref.read(repositoryProvider);
    Customer? customer;
    final List<Customer> customers = await repository.listCustomers();
    final Iterable<Customer> matches = customers.where(
      (Customer c) => c.id == widget.initialCustomerId,
    );
    if (matches.isNotEmpty) {
      customer = matches.first;
    } else if (isSelfCustomerId(widget.initialCustomerId!)) {
      customer = await repository.ensureSelfCustomer();
    }
    if (!mounted || customer == null) {
      return;
    }
    setState(() {
      _resolvedCustomer = customer;
      _phoneController.text = customer!.phone;
      if (!isSelfCustomer(customer)) {
        _nameController.text = customer.name;
      }
    });
  }

  void _pruneUnavailableSelection(List<InventoryItem> availableItems) {
    if (_selectedInventoryIds.isEmpty) {
      return;
    }
    final Set<String> availableIds =
        availableItems.map((InventoryItem item) => item.id).toSet();
    final List<String> stale = _selectedInventoryIds
        .where((String id) => !availableIds.contains(id))
        .toList();
    if (stale.isEmpty) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedInventoryIds.removeAll(stale);
        _syncLabelControllers(_selectedInventoryIds);
      });
    });
  }

  BillingMode _primaryMode(List<InventoryItem> selectedItems) {
    if (selectedItems.isEmpty) {
      return BillingMode.weekly;
    }
    return selectedItems.first.billingMode;
  }

  int _durationUnitsValue() {
    final int parsed = int.tryParse(_durationController.text.trim()) ?? 0;
    return parsed < 1 ? 0 : parsed;
  }

  bool _durationComplete(List<InventoryItem> selectedItems) {
    final BillingMode mode = _primaryMode(selectedItems);
    if (mode == BillingMode.custom) {
      if (_customEnd == null) {
        return false;
      }
      final DateTime today = DateTime.now();
      final DateTime startDay = DateTime(today.year, today.month, today.day);
      final DateTime endDay =
          DateTime(_customEnd!.year, _customEnd!.month, _customEnd!.day);
      return !endDay.isBefore(startDay);
    }
    return _durationUnitsValue() >= 1;
  }

  DateTime _previewDue(List<InventoryItem> selectedItems) {
    final DateTime now = DateTime.now();
    final BillingMode mode = _primaryMode(selectedItems);
    return computeDueAt(
      start: now,
      mode: mode,
      durationUnits: _durationUnitsValue() < 1 ? 1 : _durationUnitsValue(),
      customEnd: _customEnd,
    );
  }

  int _lineCharge(InventoryItem item, DateTime due) {
    return computeBaseAmount(
      mode: item.billingMode,
      rateAmount: item.rateAmount,
      start: DateTime.now(),
      due: due,
    );
  }

  int _previewBaseTotal(List<InventoryItem> selectedItems) {
    final DateTime due = _previewDue(selectedItems);
    int total = 0;
    for (final InventoryItem item in selectedItems) {
      total += _lineCharge(item, due);
    }
    return total;
  }

  void _syncLabelControllers(Iterable<String> selectedIds) {
    final Set<String> ids = selectedIds.toSet();
    for (final String id in ids) {
      _instanceNameControllers.putIfAbsent(id, TextEditingController.new);
      _shortCodeControllers.putIfAbsent(id, TextEditingController.new);
    }
    final List<String> stale = _instanceNameControllers.keys
        .where((String id) => !ids.contains(id))
        .toList();
    for (final String id in stale) {
      _instanceNameControllers.remove(id)?.dispose();
      _shortCodeControllers.remove(id)?.dispose();
    }
  }

  bool _labelsComplete(List<InventoryItem> selectedItems) {
    if (selectedItems.isEmpty) {
      return false;
    }
    final Set<String> codes = <String>{};
    for (final InventoryItem item in selectedItems) {
      final String name =
          _instanceNameControllers[item.id]?.text.trim() ?? '';
      final String code = LocalRepository.normalizeShortCode(
        _shortCodeControllers[item.id]?.text ?? '',
      );
      if (name.isEmpty || code.isEmpty) {
        return false;
      }
      if (!codes.add(code)) {
        return false;
      }
    }
    return true;
  }

  List<RentalLineInput> _buildLineInputs(List<InventoryItem> selectedItems) {
    return selectedItems
        .map(
          (InventoryItem item) => RentalLineInput(
            itemId: item.id,
            instanceName: _instanceNameControllers[item.id]!.text.trim(),
            shortCode: _shortCodeControllers[item.id]!.text.trim(),
          ),
        )
        .toList();
  }

  Future<void> _pickSelfCustomer() async {
    final Customer self = await ref.read(repositoryProvider).ensureSelfCustomer();
    if (!mounted) {
      return;
    }
    setState(() {
      _resolvedCustomer = self;
      _phoneController.text = kSelfCustomerPhone;
      _nameController.clear();
    });
  }

  Future<void> _onPhoneChanged(String value) async {
    final Customer? matched =
        await ref.read(repositoryProvider).customerByPhone(value);
    if (!mounted) {
      return;
    }
    setState(() => _resolvedCustomer = matched);
  }

  List<InventoryItem> _filteredAvailable(List<InventoryItem> availableItems) {
    final String query = _inventoryQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return availableItems;
    }
    return availableItems
        .where(
          (InventoryItem item) =>
              item.name.toLowerCase().contains(query) ||
              item.category.toLowerCase().contains(query),
        )
        .toList();
  }

  bool _canContinue(List<InventoryItem> selectedItems) {
    return switch (_currentStep) {
      _RentalFlowStep.party => _isSelfSelected
          ? _nicknameController.text.trim().isNotEmpty
          : _phoneController.text.trim().length >= 10,
      _RentalFlowStep.items => _selectedInventoryIds.isNotEmpty,
      _RentalFlowStep.labels => _labelsComplete(selectedItems),
      _RentalFlowStep.duration => _durationComplete(selectedItems),
      _RentalFlowStep.review => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<InventoryItem>> inventoryAsync =
        ref.watch(inventoryProvider);
    final List<InventoryItem> inventory =
        inventoryAsync.valueOrNull ?? const <InventoryItem>[];
    final List<InventoryItem> availableItems =
        inventory.where((item) => item.availableUnits > 0).toList();
    if (inventoryAsync.hasValue) {
      _pruneUnavailableSelection(availableItems);
    }
    final List<InventoryItem> selectedItems = availableItems
        .where((item) => _selectedInventoryIds.contains(item.id))
        .toList();
    final List<InventoryItem> visibleItems = _filteredAvailable(availableItems);
    final List<_RentalFlowStep> steps = _steps;
    final bool canContinue = _canContinue(selectedItems);
    final bool isLastStep = _stepIndex >= steps.length - 1;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.actionNewRental)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            l10n.stepOf(_stepIndex + 1, steps.length),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          if (_currentStep == _RentalFlowStep.party) ...<Widget>[
            if (!_nicknameOnlyParty) ...<Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: FilterChip(
                  selected: _isSelfSelected,
                  label: Text(l10n.selfKnownQuickPick),
                  onSelected: (_) => _pickSelfCustomer(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.phoneNumberLabel,
                  hintText: l10n.phoneNumberHint,
                ),
                onChanged: (value) async {
                  await _onPhoneChanged(value);
                },
              ),
              const SizedBox(height: 8),
            ],
            if (_isSelfSelected) ...<Widget>[
              EntityCard(
                title: kSelfCustomerName,
                subtitle: l10n.existingCustomerSubtitle(kSelfCustomerPhone),
                leadingIcon: Icons.verified_user_outlined,
                status: AssetStatus.available,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nicknameController,
                decoration: InputDecoration(
                  labelText: l10n.rentalNicknameLabel,
                  hintText: l10n.rentalNicknameHint,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ] else if (_resolvedCustomer != null)
              EntityCard(
                title: _resolvedCustomer!.name,
                subtitle: _resolvedCustomer!.depositBalance > 0
                    ? l10n.existingCustomerWithDeposit(
                        _resolvedCustomer!.phone,
                        formatMoney(_resolvedCustomer!.depositBalance),
                      )
                    : l10n.existingCustomerSubtitle(_resolvedCustomer!.phone),
                leadingIcon: Icons.verified_user_outlined,
                status: AssetStatus.available,
              )
            else if (!_nicknameOnlyParty)
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.customerNameNewLabel,
                  hintText: l10n.customerNameNewHint,
                ),
              ),
          ],
          if (_currentStep == _RentalFlowStep.items) ...<Widget>[
            Text(
              l10n.selectItems,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (_showInventorySearch) ...<Widget>[
              const SizedBox(height: 8),
              TextField(
                controller: _inventorySearchController,
                decoration: InputDecoration(
                  labelText: l10n.actionSearch,
                  hintText: l10n.searchInventoryHint,
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (String value) {
                  setState(() => _inventoryQuery = value);
                },
              ),
            ],
            const SizedBox(height: 8),
            ...visibleItems.map(
              (item) => CheckboxListTile(
                value: _selectedInventoryIds.contains(item.id),
                title: Text(item.name),
                subtitle: Text(
                  '${l10n.itemAvailableCount(item.category, item.availableUnits)} · '
                  '${l10n.inventoryRateSubtitle(
                    localizedBillingMode(l10n, item.billingMode),
                    formatMoney(item.rateAmount, currencyCode: item.currencyCode),
                  )}',
                ),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selectedInventoryIds.add(item.id);
                    } else {
                      _selectedInventoryIds.remove(item.id);
                    }
                    _syncLabelControllers(_selectedInventoryIds);
                  });
                },
              ),
            ),
          ],
          if (_currentStep == _RentalFlowStep.labels) ...<Widget>[
            Text(
              l10n.labelInstancesHeading,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.labelInstancesHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            ...selectedItems.map((InventoryItem item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _instanceNameControllers[item.id],
                      decoration: InputDecoration(
                        labelText: l10n.instanceNameLabel,
                        hintText: l10n.instanceNameHint,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _shortCodeControllers[item.id],
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: l10n.shortCodeLabel,
                        hintText: l10n.shortCodeHint,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              );
            }),
          ],
          if (_currentStep == _RentalFlowStep.duration) ...<Widget>[
            Text(
              l10n.durationHeading,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.durationHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              localizedBillingMode(l10n, _primaryMode(selectedItems)),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (_primaryMode(selectedItems) == BillingMode.custom) ...<Widget>[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.customEndDateLabel),
                subtitle: Text(
                  _customEnd == null ? '—' : _date(_customEnd!),
                ),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: () async {
                  final DateTime now = DateTime.now();
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _customEnd ?? now.add(const Duration(days: 1)),
                    firstDate: DateTime(now.year, now.month, now.day),
                    lastDate: now.add(const Duration(days: 365 * 2)),
                  );
                  if (picked != null) {
                    setState(() => _customEnd = picked);
                  }
                },
              ),
            ] else
              TextField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: switch (_primaryMode(selectedItems)) {
                    BillingMode.daily => l10n.durationUnitsDaily,
                    BillingMode.weekly => l10n.durationUnitsWeekly,
                    BillingMode.monthly => l10n.durationUnitsMonthly,
                    BillingMode.fixed => l10n.durationUnitsFixed,
                    BillingMode.custom => l10n.durationUnitsLabel,
                  },
                ),
                onChanged: (_) => setState(() {}),
              ),
            if (_durationComplete(selectedItems)) ...<Widget>[
              const SizedBox(height: 12),
              Text(l10n.chargePreviewDue(_date(_previewDue(selectedItems)))),
              const SizedBox(height: 6),
              ...selectedItems.map((InventoryItem item) {
                final int amount =
                    _lineCharge(item, _previewDue(selectedItems));
                return Text(
                  l10n.chargeLineAmount(
                    item.name,
                    formatMoney(amount, currencyCode: item.currencyCode),
                  ),
                );
              }),
              const SizedBox(height: 6),
              Text(
                l10n.chargeTotalLabel(
                  formatMoney(_previewBaseTotal(selectedItems)),
                ),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
          if (_currentStep == _RentalFlowStep.review) ...<Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.reviewHeading,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isSelfSelected) ...<Widget>[
                      Text(
                        l10n.reviewNickname(
                          _nicknameController.text.trim(),
                          kSelfCustomerName,
                        ),
                      ),
                      Text(l10n.reviewPhone(kSelfCustomerPhone)),
                    ] else ...<Widget>[
                      Text(l10n.reviewPhone(_phoneController.text.trim())),
                      Text(
                        l10n.reviewName(
                          _resolvedCustomer?.name ?? _nameController.text.trim(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(l10n.reviewDueLabel(_date(_previewDue(selectedItems)))),
                    const SizedBox(height: 6),
                    Text(l10n.reviewItemsLabel),
                    ...selectedItems.map((InventoryItem item) {
                      final String name =
                          _instanceNameControllers[item.id]?.text.trim() ?? '';
                      final String code = LocalRepository.normalizeShortCode(
                        _shortCodeControllers[item.id]?.text ?? '',
                      );
                      final int amount =
                          _lineCharge(item, _previewDue(selectedItems));
                      return Text(
                        '• ${RentalLine(
                          itemId: item.id,
                          catalogName: item.name,
                          instanceName: name,
                          shortCode: code,
                        ).displayLabel} — ${formatMoney(amount, currencyCode: item.currencyCode)}',
                      );
                    }),
                    const SizedBox(height: 6),
                    Text(l10n.reviewChargesLabel),
                    Text(
                      l10n.chargeTotalLabel(
                        formatMoney(_previewBaseTotal(selectedItems)),
                      ),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(
          children: <Widget>[
            if (_stepIndex > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting
                      ? null
                      : () => setState(() {
                          _stepIndex -= 1;
                        }),
                  child: Text(l10n.back),
                ),
              ),
            if (_stepIndex > 0) const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: (!canContinue || _submitting)
                    ? null
                    : () async {
                        if (_currentStep == _RentalFlowStep.party &&
                            _isSelfSelected &&
                            _nicknameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.rentalNicknameRequired)),
                          );
                          return;
                        }
                        if (_currentStep == _RentalFlowStep.items) {
                          _syncLabelControllers(_selectedInventoryIds);
                        }
                        if (_currentStep == _RentalFlowStep.labels &&
                            !_labelsComplete(selectedItems)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.instanceLabelsRequired)),
                          );
                          return;
                        }
                        if (_currentStep == _RentalFlowStep.duration &&
                            !_durationComplete(selectedItems)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _primaryMode(selectedItems) == BillingMode.custom
                                    ? l10n.customEndRequired
                                    : l10n.durationRequired,
                              ),
                            ),
                          );
                          return;
                        }
                        if (!isLastStep) {
                          setState(() {
                            _stepIndex += 1;
                          });
                          return;
                        }
                        setState(() => _submitting = true);
                        final LocalRepository repository = ref.read(repositoryProvider);
                        final Customer customer;
                        final String? nickname;
                        if (_isSelfSelected) {
                          customer = await repository.ensureSelfCustomer();
                          nickname = _nicknameController.text.trim();
                        } else {
                          customer = _resolvedCustomer ??
                              await repository.upsertCustomerByPhone(
                                phone: _phoneController.text.trim(),
                                fallbackName: _nameController.text.trim(),
                              );
                          nickname = null;
                        }
                        try {
                          await repository.createRental(
                            customer: customer,
                            lines: _buildLineInputs(selectedItems),
                            nickname: nickname,
                            durationUnits: _primaryMode(selectedItems) ==
                                    BillingMode.custom
                                ? 1
                                : _durationUnitsValue(),
                            customEnd: _primaryMode(selectedItems) ==
                                    BillingMode.custom
                                ? _customEnd
                                : null,
                            billingModeOverride: _primaryMode(selectedItems),
                          );
                        } catch (error) {
                          if (context.mounted) {
                            setState(() => _submitting = false);
                            final String message;
                            if (error is DuplicateActiveShortCodeException) {
                              message = l10n.duplicateShortCode(error.shortCode);
                            } else if (error is ArgumentError) {
                              final String raw = error.message?.toString() ?? '';
                              if (raw.toLowerCase().contains('nickname')) {
                                message = l10n.rentalNicknameRequired;
                              } else if (raw.toLowerCase().contains('instance') ||
                                  raw.toLowerCase().contains('short code')) {
                                message = l10n.instanceLabelsRequired;
                              } else {
                                message = raw.isEmpty ? '$error' : raw;
                              }
                            } else {
                              message = '$error';
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(message)),
                            );
                          }
                          return;
                        }
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                child: Text(
                  isLastStep ? l10n.confirmRental : l10n.continueAction,
                ),
              ),
            ),
          ],
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
                      return EntityCard(
                        title: rental.lines.isNotEmpty
                            ? rental.lines
                                .map((RentalLine line) => line.displayLabel)
                                .join(', ')
                            : rental.id,
                        subtitle: <String>[
                          l10n.rentalAmountSubtitle(
                            _date(rental.dueAt),
                            formatMoney(total),
                          ),
                          if (customer.depositBalance > 0)
                            l10n.depositWillApplyLabel(formatMoney(willApply)),
                        ].join('\n'),
                        leadingIcon: Icons.assignment_return_outlined,
                        status: rental.statusFor(now),
                        trailing: FilledButton(
                          onPressed: () async {
                            await _confirmAndReturnRental(
                              context: context,
                              ref: ref,
                              rental: rental,
                              customer: customer,
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
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _unitsController = TextEditingController(text: '1');
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _rateController = TextEditingController(text: '0');
  final TextEditingController _lateFeeController = TextEditingController(text: '0');
  BillingMode _billingMode = BillingMode.weekly;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _unitsController.dispose();
    _notesController.dispose();
    _rateController.dispose();
    _lateFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
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
          TextField(
            controller: _categoryController,
            decoration: InputDecoration(labelText: l10n.categoryLabel),
          ),
          const SizedBox(height: 8),
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
                  if (_nameController.text.trim().isEmpty ||
                      _categoryController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.nameCategoryRequired)),
                    );
                    return;
                  }
                  final int units = int.tryParse(_unitsController.text.trim()) ?? 1;
                  setState(() => _submitting = true);
                  await ref.read(repositoryProvider).addInventory(
                    name: _nameController.text.trim(),
                    category: _categoryController.text.trim(),
                    units: units < 1 ? 1 : units,
                    notes: _notesController.text.trim(),
                    billingMode: _billingMode,
                    rateAmount: parseRupeesToPaise(_rateController.text),
                    lateFeePerDay: parseRupeesToPaise(_lateFeeController.text),
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

String _date(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

String _rentalAmountSubtitle(AppLocalizations l10n, Rental rental) {
  final DateTime now = DateTime.now();
  final String base = l10n.rentalAmountSubtitle(
    _date(rental.dueAt),
    formatMoney(rental.totalAmountAsOf(now)),
  );
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
}) async {
  final AppLocalizations l10n = context.l10n;
  final DateTime now = DateTime.now();
  final int total = rental.totalAmountAsOf(now);
  final int willApply =
      customer.depositBalance < total ? customer.depositBalance : total;
  final int remainingDue = total - willApply;
  final int leftover = customer.depositBalance - willApply;

  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(l10n.returnSettlementTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
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

  final RentalReturnResult? result =
      await ref.read(repositoryProvider).returnRental(rental.id);
  if (!context.mounted) {
    return result != null;
  }
  if (result == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.rentalReturned(rental.id))),
    );
    return false;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(_returnSettlementSnack(l10n, result))),
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
