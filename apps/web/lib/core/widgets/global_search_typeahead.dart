import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n_ext.dart';
import '../models/entities.dart';
import '../pricing/rental_pricing.dart';
import '../providers/app_providers.dart';
import '../repositories/local_repository.dart';
import '../search/search_scope.dart';
import '../validation/text_rules.dart';
import 'scoped_search_field.dart';

/// In-page global search typeahead (customers, rentals, inventory).
///
/// Used on Home and in the FAB Search bottom sheet. Selecting a hit navigates
/// via the provided open callbacks — no separate search route.
class GlobalSearchTypeahead extends ConsumerStatefulWidget {
  const GlobalSearchTypeahead({
    required this.onOpenCustomer,
    required this.onOpenRental,
    required this.onOpenInventory,
    this.hintText,
    this.autofocus = false,
    super.key,
  });

  final ValueChanged<Customer> onOpenCustomer;
  final ValueChanged<Rental> onOpenRental;
  final ValueChanged<InventoryItem> onOpenInventory;
  final String? hintText;
  final bool autofocus;

  @override
  ConsumerState<GlobalSearchTypeahead> createState() =>
      _GlobalSearchTypeaheadState();
}

class _GlobalSearchTypeaheadState extends ConsumerState<GlobalSearchTypeahead> {
  final TextEditingController _controller = TextEditingController();
  List<SearchSuggestion> _suggestions = const <SearchSuggestion>[];
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

  Future<void> _onQueryChanged(String value) async {
    final String trimmed = value.trim();
    if (trimmed.length < kMinMeaningfulTextLength) {
      setState(() {
        _suggestions = const <SearchSuggestion>[];
        _results = const SearchResults(
          customers: <Customer>[],
          currentRentals: <Rental>[],
          previousRentals: <Rental>[],
          inventory: <InventoryItem>[],
        );
      });
      return;
    }
    final SearchResults results;
    try {
      results = await ref.read(repositoryProvider).search(
            trimmed,
            scope: SearchScope.global,
          );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _suggestions = const <SearchSuggestion>[];
        _results = const SearchResults(
          customers: <Customer>[],
          currentRentals: <Rental>[],
          previousRentals: <Rental>[],
          inventory: <InventoryItem>[],
        );
      });
      return;
    }
    if (!mounted) {
      return;
    }
    final AppLocalizations l10n = context.l10n;
    setState(() {
      _results = results;
      _suggestions = _buildSuggestions(l10n, results);
    });
  }

  List<SearchSuggestion> _buildSuggestions(
    AppLocalizations l10n,
    SearchResults results,
  ) {
    final List<SearchSuggestion> out = <SearchSuggestion>[];
    for (final Customer customer in results.customers) {
      out.add(
        SearchSuggestion(
          id: customer.id,
          title: customer.name,
          subtitle: '${l10n.searchSectionCustomers} · ${customer.phone}',
          leadingIcon: Icons.person_outline,
          kind: SearchHitKind.customer,
        ),
      );
    }
    for (final Rental rental in results.currentRentals) {
      out.add(
        SearchSuggestion(
          id: rental.id,
          title: _rentalLinesLabel(rental),
          subtitle:
              '${l10n.searchSectionCurrentRentals} · ${_rentalAmountSubtitle(l10n, rental)}',
          leadingIcon: Icons.assignment_outlined,
          kind: SearchHitKind.rental,
        ),
      );
    }
    for (final Rental rental in results.previousRentals) {
      out.add(
        SearchSuggestion(
          id: rental.id,
          title: _rentalLinesLabel(rental),
          subtitle:
              '${l10n.searchSectionPreviousRentals} · ${_previousRentalSubtitle(l10n, rental)}',
          leadingIcon: Icons.history,
          kind: SearchHitKind.rental,
        ),
      );
    }
    for (final InventoryItem item in results.inventory) {
      out.add(
        SearchSuggestion(
          id: item.id,
          title: item.name,
          subtitle:
              '${l10n.searchSectionInventory} · ${l10n.inventoryUnitsSubtitle(
            item.category,
            item.availableUnits,
            item.totalUnits,
          )}',
          leadingIcon: Icons.inventory_2_outlined,
          kind: SearchHitKind.inventory,
        ),
      );
    }
    return out;
  }

  void _onSelected(SearchSuggestion suggestion) {
    switch (suggestion.kind) {
      case SearchHitKind.customer:
        final Customer customer = _results.customers.firstWhere(
          (Customer entry) => entry.id == suggestion.id,
        );
        widget.onOpenCustomer(customer);
      case SearchHitKind.rental:
        final Rental rental = <Rental>[
          ..._results.currentRentals,
          ..._results.previousRentals,
        ].firstWhere((Rental entry) => entry.id == suggestion.id);
        widget.onOpenRental(rental);
      case SearchHitKind.inventory:
        final InventoryItem item = _results.inventory.firstWhere(
          (InventoryItem entry) => entry.id == suggestion.id,
        );
        widget.onOpenInventory(item);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return ScopedSearchField(
      controller: _controller,
      autofocus: widget.autofocus,
      hintText: widget.hintText ?? l10n.searchAnything,
      minLengthHint: l10n.searchTypeMinChars,
      noResultsText: l10n.searchNoResults,
      suggestions: _suggestions,
      onQueryChanged: _onQueryChanged,
      onSelected: _onSelected,
      semanticLabel: l10n.actionSearch,
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

String _shortDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

String _rentalAmountSubtitle(AppLocalizations l10n, Rental rental) {
  final DateTime now = DateTime.now();
  final String amount = formatMoney(rental.totalAmountAsOf(now));
  if (rental.isOpenEnded) {
    return l10n.rentalAmountOpenEnded(amount);
  }
  return l10n.rentalAmountSubtitle(_shortDate(rental.dueAt!), amount);
}

String _previousRentalSubtitle(AppLocalizations l10n, Rental rental) {
  final String returned = l10n.returnedDate(
    _shortDate(rental.returnedAt ?? rental.dueAt ?? rental.startedAt),
  );
  if (rental.depositApplied > 0) {
    return '$returned · ${l10n.depositAppliedLabel(formatMoney(rental.depositApplied))}';
  }
  return returned;
}
