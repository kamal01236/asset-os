import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/local_repository.dart';
import '../../../application/providers/app_providers.dart';
import '../../../domain/models/entities.dart';
import '../../../domain/search/search_scope.dart';
import '../../../domain/validation/text_rules.dart';
import '../../../infrastructure/l10n/l10n_ext.dart';
import '../../privacy/privacy_display.dart';
import '../../widgets/scoped_search_field.dart';
import '../../widgets/ui_primitives.dart';
import 'add_inventory_flow_screen.dart';

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
                      displayMoney(
                        context,
                        ref,
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
