import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/privacy/media_retention_service.dart';
import '../application/providers/app_providers.dart';
import '../application/reminders/reminder_scheduler.dart';
import '../domain/config/app_branding.dart';
import '../domain/models/entities.dart';
import '../infrastructure/l10n/l10n_ext.dart';
import 'features/customers/customer_detail_screen.dart';
import 'features/customers/customers_screen.dart';
import 'features/home/home_screen.dart';
import 'features/inventory/add_inventory_flow_screen.dart';
import 'features/inventory/inventory_detail_screen.dart';
import 'features/inventory/inventory_screen.dart';
import 'features/more/more_screen.dart';
import 'features/more/scan_entry_screen.dart';
import 'features/orders/new_order_flow_screen.dart';
import 'features/orders/rental_detail_nav.dart';
import 'features/orders/rental_detail_screen.dart';
import 'features/orders/return_flow_screen.dart';
import 'features/shell/global_actions_button.dart';
import 'features/transactions/transactions_screen.dart';
import 'widgets/global_search_typeahead.dart';
import 'widgets/reminder_digest_banner.dart';
import 'widgets/ui_primitives.dart';

export 'features/customers/customer_detail_screen.dart' show CustomerDetailScreen;
export 'features/home/home_screen.dart' show HomeScreen;
export 'features/inventory/inventory_detail_screen.dart' show InventoryDetailScreen;
export 'features/orders/new_order_flow_screen.dart' show NewOrderFlowScreen;
export 'features/orders/rental_detail_screen.dart' show RentalDetailScreen;

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

  static bool _shouldRunLifecycleSideEffects(WidgetsBinding binding) {
    return !binding.runtimeType.toString().contains('TestWidgets');
  }

  @override
  void initState() {
    super.initState();
    ensureRentalDetailNavRegistered();
    WidgetsBinding.instance.addObserver(this);
    if (_shouldRunLifecycleSideEffects(WidgetsBinding.instance)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_onAppResumed());
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _shouldRunLifecycleSideEffects(WidgetsBinding.instance)) {
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
      final int retentionDays =
          ref.read(privacySettingsProvider).mediaRetentionDays;
      if (retentionDays > 0) {
        await MediaRetentionService(ref.read(repositoryProvider))
            .purgeExpired(retentionDays: retentionDays);
      }
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
