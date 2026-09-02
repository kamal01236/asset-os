import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/local_repository.dart';
import '../../../application/providers/app_providers.dart';
import '../../../domain/models/customer_balance.dart';
import '../../../domain/models/entities.dart';
import '../../../domain/search/search_scope.dart';
import '../../../domain/subscriptions/subscription_coverage.dart';
import '../../../domain/subscriptions/subscription_models.dart';
import '../../../domain/validation/text_rules.dart';
import '../../../infrastructure/l10n/india_date_format.dart';
import '../../../infrastructure/l10n/l10n_ext.dart';
import '../../privacy/privacy_display.dart';
import '../../theme/app_theme.dart';
import '../../widgets/scoped_search_field.dart';
import '../../widgets/ui_primitives.dart';

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
              subtitle: displayPhone(context, ref, customer.phone),
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
              secondary: displayPhone(context, ref, customer.phone),
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
                        displayMoney(context, ref, balance.netPaise),
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
