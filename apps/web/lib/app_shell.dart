import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_branding.dart';
import 'core/l10n/l10n_ext.dart';
import 'core/models/entities.dart';
import 'core/providers/app_providers.dart';
import 'core/repositories/local_repository.dart';
import 'core/widgets/rental_timeline.dart';
import 'core/widgets/ui_primitives.dart';
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

  Future<void> _openNewRentalFlow(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const NewRentalFlowScreen(),
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
              title: rental.id,
              subtitle: l10n.rentalDueSubtitle(customer.name, _date(rental.dueAt)),
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
              subtitle: l10n.inventoryAvailableSubtitle(
                item.category,
                item.availableUnits,
                item.totalUnits,
              ),
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
              subtitle: l10n.customerSubtitle(customer.phone, tier),
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
    final AsyncValue<List<InventoryItem>> inventoryAsync = ref.watch(inventoryProvider);

    if (rentalsAsync.isLoading || customersAsync.isLoading || inventoryAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<Rental> rentals = rentalsAsync.valueOrNull ?? const <Rental>[];
    final List<Customer> customers = customersAsync.valueOrNull ?? const <Customer>[];
    final List<InventoryItem> inventory = inventoryAsync.valueOrNull ?? const <InventoryItem>[];

    final Rental rental = rentals.firstWhere((item) => item.id == rentalId);
    final Customer customer = customers.firstWhere((item) => item.id == rental.customerId);
    final List<InventoryItem> items =
        inventory.where((item) => rental.itemIds.contains(item.id)).toList();

    return Scaffold(
      appBar: AppBar(title: Text(rental.id)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          EntityCard(
            title: customer.name,
            subtitle: l10n.phoneLabel(customer.phone),
            leadingIcon: Icons.person_outline,
            status: rental.statusFor(DateTime.now()),
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
                  ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• ${item.name}'),
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
                        await ref.read(repositoryProvider).returnRental(rental.id);
                        if (context.mounted) {
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

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _unitsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _beginEdit(InventoryItem item) {
    _nameController.text = item.name;
    _categoryController.text = item.category;
    _unitsController.text = '${item.totalUnits}';
    _notesController.text = item.notes ?? '';
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

    if (customersAsync.isLoading || rentalsAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<Customer> customers = customersAsync.valueOrNull ?? const <Customer>[];
    final List<Rental> rentals = rentalsAsync.valueOrNull ?? const <Rental>[];
    final Customer customer = customers.firstWhere((entry) => entry.id == customerId);
    final List<Rental> customerRentals =
        rentals.where((entry) => entry.customerId == customer.id).toList();

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
            l10n.recentRentals,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...customerRentals.map(
            (rental) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: EntityCard(
                title: rental.id,
                subtitle: l10n.dueDate(_date(rental.dueAt)),
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
              title: rental.id,
              subtitle: l10n.dueDate(_date(rental.dueAt)),
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
              title: rental.id,
              subtitle: l10n.returnedDate(_date(rental.returnedAt ?? rental.dueAt)),
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

class NewRentalFlowScreen extends ConsumerStatefulWidget {
  const NewRentalFlowScreen({super.key});

  @override
  ConsumerState<NewRentalFlowScreen> createState() => _NewRentalFlowScreenState();
}

class _NewRentalFlowScreenState extends ConsumerState<NewRentalFlowScreen> {
  int _step = 0;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final Set<String> _selectedInventoryIds = <String>{};
  Customer? _resolvedCustomer;
  bool _submitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final List<InventoryItem> inventory =
        ref.watch(inventoryProvider).valueOrNull ?? const <InventoryItem>[];
    final List<InventoryItem> availableItems =
        inventory.where((item) => item.availableUnits > 0).toList();
    final List<InventoryItem> selectedItems = availableItems
        .where((item) => _selectedInventoryIds.contains(item.id))
        .toList();
    final bool canContinue = switch (_step) {
      0 => _phoneController.text.trim().length >= 10,
      1 => _selectedInventoryIds.isNotEmpty,
      _ => true,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.actionNewRental)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            l10n.stepOf(_step + 1, 3),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          if (_step == 0) ...<Widget>[
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l10n.phoneNumberLabel,
                hintText: l10n.phoneNumberHint,
              ),
              onChanged: (value) async {
                final Customer? matched =
                    await ref.read(repositoryProvider).customerByPhone(value);
                if (!mounted) {
                  return;
                }
                setState(() => _resolvedCustomer = matched);
              },
            ),
            const SizedBox(height: 8),
            if (_resolvedCustomer != null)
              EntityCard(
                title: _resolvedCustomer!.name,
                subtitle: l10n.existingCustomerSubtitle(_resolvedCustomer!.phone),
                leadingIcon: Icons.verified_user_outlined,
                status: AssetStatus.available,
              )
            else
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.customerNameNewLabel,
                  hintText: l10n.customerNameNewHint,
                ),
              ),
          ],
          if (_step == 1) ...<Widget>[
            Text(
              l10n.selectItems,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ...availableItems.map(
              (item) => CheckboxListTile(
                value: _selectedInventoryIds.contains(item.id),
                title: Text(item.name),
                subtitle: Text(
                  l10n.itemAvailableCount(item.category, item.availableUnits),
                ),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selectedInventoryIds.add(item.id);
                    } else {
                      _selectedInventoryIds.remove(item.id);
                    }
                  });
                },
              ),
            ),
          ],
          if (_step == 2) ...<Widget>[
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
                    Text(l10n.reviewPhone(_phoneController.text.trim())),
                    Text(
                      l10n.reviewName(
                        _resolvedCustomer?.name ?? _nameController.text.trim(),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(l10n.reviewItemsLabel),
                    ...selectedItems.map((item) => Text('• ${item.name}')),
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
            if (_step > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting
                      ? null
                      : () => setState(() {
                          _step -= 1;
                        }),
                  child: Text(l10n.back),
                ),
              ),
            if (_step > 0) const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: (!canContinue || _submitting)
                    ? null
                    : () async {
                        if (_step < 2) {
                          setState(() {
                            _step += 1;
                          });
                          return;
                        }
                        setState(() => _submitting = true);
                        final LocalRepository repository = ref.read(repositoryProvider);
                        final Customer customer = _resolvedCustomer ??
                            await repository.upsertCustomerByPhone(
                              phone: _phoneController.text.trim(),
                              fallbackName: _nameController.text.trim(),
                            );
                        await repository.createRental(
                          customer: customer,
                          selectedItems: selectedItems,
                        );
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                child: Text(_step < 2 ? l10n.continueAction : l10n.confirmRental),
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
    return rentalsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (Object error, StackTrace _) => Scaffold(body: Center(child: Text('$error'))),
      data: (List<Rental> rentals) {
        final List<Rental> active = rentals.where((item) => item.isActive).toList();
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
                      return EntityCard(
                        title: rental.id,
                        subtitle: l10n.dueDate(_date(rental.dueAt)),
                        leadingIcon: Icons.assignment_return_outlined,
                        status: rental.statusFor(DateTime.now()),
                        trailing: FilledButton(
                          onPressed: () async {
                            await ref.read(repositoryProvider).returnRental(rental.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.rentalReturned(rental.id))),
                              );
                            }
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
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _unitsController.dispose();
    _notesController.dispose();
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
