import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../infrastructure/l10n/india_date_format.dart';
import '../../../infrastructure/l10n/l10n_ext.dart';
import '../../../domain/models/entities.dart';
import '../../../domain/pricing/rental_pricing.dart';
import '../../../domain/payments/payment_reference.dart';
import '../../../application/providers/app_providers.dart';
import '../../../infrastructure/sharing/loan_timeline_share.dart';
import '../../validation/input_formatters.dart';
import 'loan_create_screen.dart';
import 'loan_detail_widgets.dart';
import 'loan_timeline_share_snapshot.dart';

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
  bool _sharingTimeline = false;

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
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => LoanCreateScreen(loanId: loan!.id),
                      ),
                    );
                  },
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              CurrentScenarioCard(
                loan: loan,
                scenario: scenario,
                customerName: customer?.name ?? loan.customerId,
              ),
              const SizedBox(height: 12),
              SetupSummary(loan: loan),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      l10n.loanTimelineHeading,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.loanShareTimelineTooltip,
                    icon: _sharingTimeline
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.share_outlined),
                    onPressed: _sharingTimeline
                        ? null
                        : () => _shareTimeline(
                              loan: loan!,
                              scenario: scenario,
                              customerName: customer?.name ?? loan.customerId,
                            ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...scenario.timeline.map(
                (LoanTimelineEvent e) => TimelineRow(
                  event: e,
                  loan: loan!,
                  onEdit: pending
                      ? (MoneyLoanEntry entry) => _showCashEntrySheet(
                            loan: loan!,
                            existing: entry,
                          )
                      : null,
                ),
              ),
              if (pending) ...<Widget>[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    FilledButton.tonalIcon(
                      onPressed: () => _showCashEntrySheet(
                        loan: loan!,
                        initialKind: MoneyLoanEntryKind.repayment,
                      ),
                      icon: const Icon(Icons.payments_outlined),
                      label: Text(l10n.loanAddPayment),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => _showCashEntrySheet(
                        loan: loan!,
                        initialKind: MoneyLoanEntryKind.disbursement,
                      ),
                      icon: const Icon(Icons.add_card_outlined),
                      label: Text(l10n.loanAddPrincipal),
                    ),
                    OutlinedButton.icon(
                      onPressed: _addAdjustment,
                      icon: const Icon(Icons.tune),
                      label: Text(l10n.loanAddAdjustment),
                    ),
                    if (loan.capitalizationPolicy ==
                        MoneyCapitalizationPolicy.manual)
                      FilledButton.icon(
                        onPressed: scenario.unpaidInterestPaise == 0
                            ? null
                            : () => _capitalizeInterest(loan!),
                        icon: const Icon(Icons.merge_type),
                        label: Text(l10n.loanCapitalizeInterestAction),
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

  Future<void> _shareTimeline({
    required MoneyLoan loan,
    required LoanScenario scenario,
    required String customerName,
  }) async {
    final AppLocalizations l10n = context.l10n;
    final DateTime generatedAt = DateTime.now();
    setState(() => _sharingTimeline = true);
    try {
      final bool ok = await shareLoanTimelinePng(
        context: context,
        filename: loanTimelineShareFilename(loan.id, generatedAt),
        snapshot: LoanTimelineShareSnapshot(
          loan: loan,
          scenario: scenario,
          customerName: customerName,
          generatedAt: generatedAt,
        ),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? l10n.loanShareTimelineSuccess : l10n.loanShareTimelineFailed,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _sharingTimeline = false);
      }
    }
  }

  Future<void> _capitalizeInterest(MoneyLoan loan) async {
    final AppLocalizations l10n = context.l10n;
    try {
      await ref.read(repositoryProvider).capitalizeMoneyLoanInterest(loan.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.loanCapitalizeInterestSnack)),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      final String message = e is StateError &&
              e.message.contains('No unpaid interest')
          ? l10n.loanCapitalizeNothingSnack
          : '$e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _showCashEntrySheet({
    required MoneyLoan loan,
    MoneyLoanEntry? existing,
    MoneyLoanEntryKind? initialKind,
  }) async {
    final bool isEdit = existing != null;
    assert(
      (existing?.kind ?? initialKind) == MoneyLoanEntryKind.repayment ||
          (existing?.kind ?? initialKind) == MoneyLoanEntryKind.disbursement,
    );
    final AppLocalizations l10n = context.l10n;
    final TextEditingController amountCtrl = TextEditingController(
      text: existing != null ? paiseToRupeesField(existing.amountPaise) : null,
    );
    final TextEditingController noteCtrl = TextEditingController(
      text: existing?.note,
    );
    DateTime entryAt = existing?.entryAt ?? DateTime.now();
    entryAt = DateTime(entryAt.year, entryAt.month, entryAt.day);
    MoneyLoanEntryKind flow = existing?.kind ?? initialKind!;
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
              final String flowHint = switch (flow) {
                MoneyLoanEntryKind.repayment =>
                  loan.direction == MoneyLoanDirection.given
                      ? l10n.loanFlowRepaymentGiven
                      : l10n.loanFlowRepaymentTaken,
                MoneyLoanEntryKind.disbursement =>
                  loan.direction == MoneyLoanDirection.given
                      ? l10n.loanFlowDisbursementGiven
                      : l10n.loanFlowDisbursementTaken,
                MoneyLoanEntryKind.adjustment ||
                MoneyLoanEntryKind.capitalization =>
                  '',
              };
              final bool refReady = () {
                try {
                  validatePaymentReference(noteCtrl.text);
                  return true;
                } on ArgumentError {
                  return false;
                }
              }();
              final bool amountReady =
                  parseRupeesToPaise(amountCtrl.text) > 0;
              final String title = isEdit
                  ? (flow == MoneyLoanEntryKind.disbursement
                      ? l10n.loanEditDisbursement
                      : l10n.loanEditPayment)
                  : (flow == MoneyLoanEntryKind.disbursement
                      ? l10n.loanAddPrincipal
                      : l10n.loanAddPayment);
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (!isEdit)
                    SegmentedButton<MoneyLoanEntryKind>(
                      segments: <ButtonSegment<MoneyLoanEntryKind>>[
                        ButtonSegment<MoneyLoanEntryKind>(
                          value: MoneyLoanEntryKind.repayment,
                          label: Text(l10n.loanFlowRepayment),
                          icon: const Icon(Icons.south_west),
                        ),
                        ButtonSegment<MoneyLoanEntryKind>(
                          value: MoneyLoanEntryKind.disbursement,
                          label: Text(l10n.loanFlowAddPrincipal),
                          icon: const Icon(Icons.north_east),
                        ),
                      ],
                      selected: <MoneyLoanEntryKind>{flow},
                      onSelectionChanged: (Set<MoneyLoanEntryKind> next) {
                        setModal(() => flow = next.first);
                      },
                    )
                  else
                    Text(
                      flowHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  if (!isEdit) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      flowHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
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
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      kDigitsOnlyInputFormatter,
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.loanPaymentAmountLabel,
                      border: const OutlineInputBorder(),
                      prefixText: '₹ ',
                    ),
                    onChanged: (_) => setModal(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteCtrl,
                    maxLength: kPaymentReferenceMaxLength,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[A-Za-z0-9_-]'),
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.loanPaymentReferenceLabel,
                      hintText: l10n.paymentReferenceHint,
                      border: const OutlineInputBorder(),
                      counterText: '',
                    ),
                    onChanged: (_) => setModal(() {}),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: refReady && amountReady
                        ? () => Navigator.pop(sheetContext, true)
                        : null,
                    child: Text(l10n.loanSaveEntry),
                  ),
                  if (isEdit) ...<Widget>[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () async {
                        final bool? confirm = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext dialogContext) {
                            return AlertDialog(
                              title: Text(l10n.loanDeleteEntry),
                              content: Text(l10n.loanDeleteEntryConfirm),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                  child: Text(l10n.loanCancel),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, true),
                                  child: Text(l10n.loanDeleteEntry),
                                ),
                              ],
                            );
                          },
                        );
                        if (confirm == true && context.mounted) {
                          Navigator.pop(sheetContext, false);
                          await _deleteCashEntry(existing);
                        }
                      },
                      child: Text(l10n.loanDeleteEntry),
                    ),
                  ],
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
    final String note = requirePaymentReference(noteCtrl.text);
    noteCtrl.dispose();
    try {
      if (isEdit) {
        await ref.read(repositoryProvider).updateMoneyLoanEntry(
              entryId: existing.id,
              entryAt: entryAt,
              amountPaise: amount,
              note: note,
            );
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.loanEntryUpdated)),
        );
      } else if (flow == MoneyLoanEntryKind.disbursement) {
        await ref.read(repositoryProvider).addMoneyLoanPrincipal(
              loanId: widget.loanId,
              entryAt: entryAt,
              amountPaise: amount,
              note: note,
            );
      } else {
        await ref.read(repositoryProvider).addMoneyLoanEntry(
              loanId: widget.loanId,
              entryAt: entryAt,
              amountPaise: amount,
              kind: MoneyLoanEntryKind.repayment,
              note: note,
            );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _deleteCashEntry(MoneyLoanEntry entry) async {
    final AppLocalizations l10n = context.l10n;
    try {
      await ref.read(repositoryProvider).deleteMoneyLoanEntry(entry.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.loanEntryDeleted)),
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

  Future<void> _addAdjustment() async {
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
                    l10n.loanAddAdjustment,
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
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true,
                    ),
                    inputFormatters: <TextInputFormatter>[
                      kSignedDigitsInputFormatter,
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.loanAdjustmentAmountLabel,
                      border: const OutlineInputBorder(),
                      prefixText: '₹ ',
                      helperText: l10n.loanAdjustmentHint,
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
            kind: MoneyLoanEntryKind.adjustment,
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
