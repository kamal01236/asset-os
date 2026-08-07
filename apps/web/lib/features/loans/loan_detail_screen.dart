import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/india_date_format.dart';
import '../../core/l10n/l10n_ext.dart';
import '../../core/models/entities.dart';
import '../../core/pricing/rental_pricing.dart';
import '../../core/providers/app_providers.dart';

/// Calculator surface: current scenario, timeline, payments, close/pending.
class LoanDetailScreen extends ConsumerStatefulWidget {
  const LoanDetailScreen({
    required this.loanId,
    super.key,
  });

  final String loanId;

  @override
  ConsumerState<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends ConsumerState<LoanDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<MoneyLoan>> loansAsync =
        ref.watch(moneyLoansProvider);
    final AsyncValue<List<Customer>> customersAsync =
        ref.watch(customersProvider);

    return loansAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (Object e, StackTrace _) => Scaffold(
        appBar: AppBar(title: Text(l10n.loanDetailTitle)),
        body: Center(child: Text('$e')),
      ),
      data: (List<MoneyLoan> loans) {
        MoneyLoan? loan;
        for (final MoneyLoan l in loans) {
          if (l.id == widget.loanId) {
            loan = l;
            break;
          }
        }
        if (loan == null) {
          // After create, the stream can briefly lag; prefer spinner over a
          // stuck not-found while the provider is still catching up.
          if (loansAsync.isLoading || loansAsync.isRefreshing) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return Scaffold(
            appBar: AppBar(title: Text(l10n.loanDetailTitle)),
            body: Center(child: Text(l10n.loanNotFound)),
          );
        }
        final List<Customer> customers =
            customersAsync.valueOrNull ?? const <Customer>[];
        Customer? customer;
        for (final Customer c in customers) {
          if (c.id == loan.customerId) {
            customer = c;
            break;
          }
        }
        final LoanScenario scenario =
            computeLoanScenario(loan: loan, now: DateTime.now());
        final bool pending = loan.status == MoneyLoanStatus.pending;

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.loanDetailTitle),
            actions: <Widget>[
              if (pending)
                IconButton(
                  tooltip: l10n.loanEditSetupTooltip,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editSetup(loan!),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _CurrentScenarioCard(
                loan: loan,
                scenario: scenario,
                customerName: customer?.name ?? loan.customerId,
              ),
              const SizedBox(height: 12),
              _SetupSummary(loan: loan),
              const SizedBox(height: 16),
              Text(
                l10n.loanTimelineHeading,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              ...scenario.timeline.map(
                (LoanTimelineEvent e) => _TimelineRow(event: e, loan: loan!),
              ),
              if (pending) ...<Widget>[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    FilledButton.tonalIcon(
                      onPressed: () => _addEntry(MoneyLoanEntryKind.payment),
                      icon: const Icon(Icons.payments_outlined),
                      label: Text(l10n.loanAddPayment),
                    ),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _addEntry(MoneyLoanEntryKind.adjustment),
                      icon: const Icon(Icons.tune),
                      label: Text(l10n.loanAddAdjustment),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.loanKeepPendingHint)),
                          );
                        },
                        child: Text(l10n.loanKeepPending),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _markClosed(loan!, scenario),
                        child: Text(l10n.loanMarkClosed),
                      ),
                    ),
                  ],
                ),
              ] else ...<Widget>[
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => _reopen(loan!),
                  child: Text(l10n.loanReopen),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _addEntry(MoneyLoanEntryKind kind) async {
    final AppLocalizations l10n = context.l10n;
    final TextEditingController amountCtrl = TextEditingController();
    final TextEditingController noteCtrl = TextEditingController();
    DateTime entryAt = DateTime.now();
    entryAt = DateTime(entryAt.year, entryAt.month, entryAt.day);
    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 16,
            top: 8,
          ),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    kind == MoneyLoanEntryKind.payment
                        ? l10n.loanAddPayment
                        : l10n.loanAddAdjustment,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.loanEntryDateLabel),
                    subtitle: Text(formatIndiaDate(entryAt)),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        locale: indiaDatePickerLocale(context),
                        initialDate: entryAt,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setModal(() => entryAt = picked);
                      }
                    },
                  ),
                  TextField(
                    controller: amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: InputDecoration(
                      labelText: kind == MoneyLoanEntryKind.payment
                          ? l10n.loanPaymentAmountLabel
                          : l10n.loanAdjustmentAmountLabel,
                      border: const OutlineInputBorder(),
                      prefixText: '₹ ',
                      helperText: kind == MoneyLoanEntryKind.adjustment
                          ? l10n.loanAdjustmentHint
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.loanNoteOptionalLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.pop(sheetContext, true),
                    child: Text(l10n.loanSaveEntry),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
    if (saved != true || !mounted) {
      amountCtrl.dispose();
      noteCtrl.dispose();
      return;
    }
    final int amount = parseRupeesToPaise(amountCtrl.text);
    amountCtrl.dispose();
    final String? note =
        noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim();
    noteCtrl.dispose();
    try {
      await ref.read(repositoryProvider).addMoneyLoanEntry(
            loanId: widget.loanId,
            entryAt: entryAt,
            amountPaise: amount,
            kind: kind,
            note: note,
          );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _editSetup(MoneyLoan loan) async {
    final AppLocalizations l10n = context.l10n;
    DateTime started = DateTime(
      loan.interestStartedAt.year,
      loan.interestStartedAt.month,
      loan.interestStartedAt.day,
    );
    DateTime? ended = loan.interestEndedAt == null
        ? null
        : DateTime(
            loan.interestEndedAt!.year,
            loan.interestEndedAt!.month,
            loan.interestEndedAt!.day,
          );
    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialog) {
            return AlertDialog(
              title: Text(l10n.loanEditSetupTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.loanMoneyGivenOnLabel),
                    subtitle: Text(formatIndiaDate(started)),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        locale: indiaDatePickerLocale(context),
                        initialDate: started,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialog(() => started = picked);
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.loanDueOptionalLabel),
                    subtitle: Text(
                      ended == null
                          ? l10n.loanDueNone
                          : formatIndiaDate(ended!),
                    ),
                    trailing: ended == null
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setDialog(() => ended = null),
                          ),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        locale: indiaDatePickerLocale(context),
                        initialDate: ended ?? started,
                        firstDate: started,
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDialog(() => ended = picked);
                      }
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(l10n.loanCancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(l10n.loanSaveEntry),
                ),
              ],
            );
          },
        );
      },
    );
    if (saved != true || !mounted) {
      return;
    }
    try {
      await ref.read(repositoryProvider).updateMoneyLoan(
            loanId: loan.id,
            interestStartedAt: started,
            interestEndedAt: ended,
            clearInterestEndedAt: ended == null,
          );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _markClosed(MoneyLoan loan, LoanScenario scenario) async {
    final AppLocalizations l10n = context.l10n;
    if (scenario.pendingPaise > 0) {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(l10n.loanCloseWithPendingTitle),
            content: Text(
              l10n.loanCloseWithPendingBody(
                formatMoney(
                  scenario.pendingPaise,
                  currencyCode: loan.currencyCode,
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.loanCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.loanMarkClosed),
              ),
            ],
          );
        },
      );
      if (confirm != true) {
        return;
      }
    }
    try {
      await ref.read(repositoryProvider).closeMoneyLoan(loan.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.loanClosedSnack)),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _reopen(MoneyLoan loan) async {
    try {
      await ref.read(repositoryProvider).reopenMoneyLoan(loan.id);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }
}

class _CurrentScenarioCard extends StatelessWidget {
  const _CurrentScenarioCard({
    required this.loan,
    required this.scenario,
    required this.customerName,
  });

  final MoneyLoan loan;
  final LoanScenario scenario;
  final String customerName;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String statusLabel = switch (loan.status) {
      MoneyLoanStatus.pending => l10n.loanStatusPending,
      MoneyLoanStatus.closed => l10n.loanStatusClosed,
      MoneyLoanStatus.cancelled => l10n.loanStatusCancelled,
    };
    final String direction = loan.direction == MoneyLoanDirection.given
        ? l10n.loanDirectionGiven
        : l10n.loanDirectionTaken;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    customerName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (loan.status == MoneyLoanStatus.pending
                            ? Theme.of(context).colorScheme.tertiary
                            : Theme.of(context).colorScheme.outline)
                        .withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              direction,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.loanPendingNowLabel,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Text(
              formatMoney(
                scenario.pendingPaise,
                currencyCode: loan.currencyCode,
              ),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            _kv(context, l10n.loanPrincipalLabel,
                formatMoney(scenario.principalPaise, currencyCode: loan.currencyCode)),
            _kv(context, l10n.loanInterestToDateLabel,
                formatMoney(scenario.interestAccruedPaise, currencyCode: loan.currencyCode)),
            _kv(context, l10n.loanPaidLabel,
                formatMoney(scenario.totalPaidPaise, currencyCode: loan.currencyCode)),
            _kv(context, l10n.loanAdjustmentsLabel,
                formatMoney(scenario.totalAdjustmentsPaise, currencyCode: loan.currencyCode)),
          ],
        ),
      ),
    );
  }

  Widget _kv(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SetupSummary extends StatelessWidget {
  const _SetupSummary({required this.loan});

  final MoneyLoan loan;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final double ratePct = loan.rateBps / 100.0;
    final String period = loan.ratePeriod == MoneyRatePeriod.monthly
        ? l10n.loanRateMonthly
        : l10n.loanRateYearly;
    final String kind = loan.interestKind == MoneyInterestKind.simple
        ? l10n.loanInterestSimple
        : l10n.loanInterestCompound;
    final String start = formatIndiaDate(loan.interestStartedAt);
    final String due = loan.interestEndedAt == null
        ? l10n.loanDueNone
        : formatIndiaDate(loan.interestEndedAt!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.loanSetupSummary(start, due, '$ratePct%', period, kind),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.loanPeriodEndInterestHint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.event, required this.loan});

  final LoanTimelineEvent event;
  final MoneyLoan loan;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String money = formatMoney(
      event.amountPaise,
      currencyCode: loan.currencyCode,
    );
    final String text = switch (event.kind) {
      LoanTimelineKind.start =>
        l10n.loanTimelineStart(formatIndiaDate(event.at), money),
      LoanTimelineKind.interestSegment => l10n.loanTimelineInterest(
          formatIndiaDate(event.at),
          formatMoney(
            event.principalBasisPaise ?? 0,
            currencyCode: loan.currencyCode,
          ),
          money,
        ),
      LoanTimelineKind.deferredSliceInterest =>
        l10n.loanTimelineDeferredSlice(
          formatMoney(
            event.principalBasisPaise ?? 0,
            currencyCode: loan.currencyCode,
          ),
          formatIndiaDate(event.at),
          money,
        ),
      LoanTimelineKind.periodEndSliceInterest =>
        l10n.loanTimelinePeriodEndSlice(
          formatMoney(
            event.principalBasisPaise ?? 0,
            currencyCode: loan.currencyCode,
          ),
          formatIndiaDate(event.from ?? event.at),
          formatIndiaDate(event.through ?? event.at),
          money,
        ),
      LoanTimelineKind.remainingPeriodInterest =>
        l10n.loanTimelineRemainingPeriodInterest(
          formatMoney(
            event.principalBasisPaise ?? 0,
            currencyCode: loan.currencyCode,
          ),
          money,
        ),
      LoanTimelineKind.principalAfterCapitalize =>
        l10n.loanTimelinePrincipalNow(formatIndiaDate(event.at), money),
      LoanTimelineKind.payment => l10n.loanTimelinePayment(
          formatIndiaDate(event.at),
          money,
          formatMoney(event.toPrincipalPaise, currencyCode: loan.currencyCode),
        ),
      LoanTimelineKind.adjustment => l10n.loanTimelineAdjustment(
          formatIndiaDate(event.at),
          money,
        ),
      LoanTimelineKind.pendingAsOf =>
        l10n.loanTimelinePending(formatIndiaDate(event.at), money),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            switch (event.kind) {
              LoanTimelineKind.start => Icons.flag_outlined,
              LoanTimelineKind.interestSegment => Icons.trending_up,
              LoanTimelineKind.deferredSliceInterest => Icons.timelapse,
              LoanTimelineKind.periodEndSliceInterest => Icons.trending_up,
              LoanTimelineKind.remainingPeriodInterest => Icons.trending_up,
              LoanTimelineKind.principalAfterCapitalize => Icons.account_balance_wallet_outlined,
              LoanTimelineKind.payment => Icons.payments_outlined,
              LoanTimelineKind.adjustment => Icons.tune,
              LoanTimelineKind.pendingAsOf => Icons.pending_actions_outlined,
            },
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: event.kind == LoanTimelineKind.pendingAsOf ||
                      event.kind == LoanTimelineKind.principalAfterCapitalize
                  ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      )
                  : Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
