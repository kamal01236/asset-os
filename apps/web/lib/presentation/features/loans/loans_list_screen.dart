import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../infrastructure/l10n/l10n_ext.dart';
import '../../../domain/models/entities.dart';
import '../../../domain/pricing/rental_pricing.dart';
import '../../../application/providers/app_providers.dart';
import '../../widgets/ui_primitives.dart';
import 'loan_create_screen.dart';
import 'loan_detail_screen.dart';

/// Lists pending and closed cash loans.
class LoansListScreen extends ConsumerStatefulWidget {
  const LoansListScreen({
    this.initialCustomerId,
    super.key,
  });

  final String? initialCustomerId;

  @override
  ConsumerState<LoansListScreen> createState() => _LoansListScreenState();
}

class _LoansListScreenState extends ConsumerState<LoansListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<MoneyLoan>> loansAsync =
        ref.watch(moneyLoansProvider);
    final AsyncValue<List<Customer>> customersAsync =
        ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.loansTitle),
        bottom: TabBar(
          controller: _tabs,
          tabs: <Widget>[
            Tab(text: l10n.loanStatusPending),
            Tab(text: l10n.loanStatusClosed),
          ],
        ),
      ),
      body: loansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace _) => Center(child: Text('$e')),
        data: (List<MoneyLoan> loans) {
          final List<Customer> customers =
              customersAsync.valueOrNull ?? const <Customer>[];
          final Map<String, Customer> byId = <String, Customer>{
            for (final Customer c in customers) c.id: c,
          };
          List<MoneyLoan> filtered = loans;
          final String? onlyCustomer = widget.initialCustomerId;
          if (onlyCustomer != null) {
            filtered = filtered
                .where((MoneyLoan l) => l.customerId == onlyCustomer)
                .toList();
          }
          final List<MoneyLoan> pending = filtered
              .where((MoneyLoan l) => l.status == MoneyLoanStatus.pending)
              .toList();
          final List<MoneyLoan> closed = filtered
              .where((MoneyLoan l) => l.status == MoneyLoanStatus.closed)
              .toList();
          return TabBarView(
            controller: _tabs,
            children: <Widget>[
              _LoanListBody(
                loans: pending,
                customersById: byId,
                emptyMessage: l10n.loansPendingEmpty,
                onOpen: _openLoan,
              ),
              _LoanListBody(
                loans: closed,
                customersById: byId,
                emptyMessage: l10n.loansClosedEmpty,
                onOpen: _openLoan,
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => LoanCreateScreen(
                initialCustomerId: widget.initialCustomerId,
              ),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.loanCreateAction),
      ),
    );
  }

  void _openLoan(MoneyLoan loan) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LoanDetailScreen(loanId: loan.id),
      ),
    );
  }
}

class _LoanListBody extends StatelessWidget {
  const _LoanListBody({
    required this.loans,
    required this.customersById,
    required this.emptyMessage,
    required this.onOpen,
  });

  final List<MoneyLoan> loans;
  final Map<String, Customer> customersById;
  final String emptyMessage;
  final ValueChanged<MoneyLoan> onOpen;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final DateTime now = DateTime.now();
    if (loans.isEmpty) {
      return Center(child: CompactEmptyState(message: emptyMessage));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
      itemCount: loans.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) {
        final MoneyLoan loan = loans[index];
        final Customer? customer = customersById[loan.customerId];
        final LoanScenario scenario =
            computeLoanScenario(loan: loan, now: now);
        final String directionLabel = loan.direction == MoneyLoanDirection.given
            ? l10n.loanDirectionGiven
            : l10n.loanDirectionTaken;
        return EntityCard(
          title: customer?.name ?? loan.customerId,
          subtitle:
              '$directionLabel · ${formatMoney(scenario.pendingPaise, currencyCode: loan.currencyCode)}',
          leadingIcon: loan.direction == MoneyLoanDirection.given
              ? Icons.call_made
              : Icons.call_received,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onOpen(loan),
        );
      },
    );
  }
}

