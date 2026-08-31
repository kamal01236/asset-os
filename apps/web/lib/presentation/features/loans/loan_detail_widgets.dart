import 'package:flutter/material.dart';

import '../../../infrastructure/l10n/india_date_format.dart';
import '../../../infrastructure/l10n/l10n_ext.dart';
import '../../../domain/loans/loan_balance.dart';
import '../../../domain/loans/loan_models.dart';
import '../../../domain/pricing/rental_pricing.dart';

/// Key-value row used on loan detail and share snapshot cards.
Widget loanDetailKv(BuildContext context, String label, String value) {
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

class CurrentScenarioCard extends StatelessWidget {
  const CurrentScenarioCard({
    required this.loan,
    required this.scenario,
    required this.customerName,
    super.key,
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
              scenario.pendingPaise < 0
                  ? l10n.loanOverpaidNowLabel
                  : l10n.loanPendingNowLabel,
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
            loanDetailKv(
              context,
              l10n.loanTotalPrincipalLabel,
              formatMoney(
                scenario.totalPrincipalPaise,
                currencyCode: loan.currencyCode,
              ),
            ),
            loanDetailKv(
              context,
              l10n.loanPendingPrincipalLabel,
              formatMoney(
                scenario.displayPendingPrincipalPaise,
                currencyCode: loan.currencyCode,
              ),
            ),
            if (scenario.positiveInterestAccruedPaise > 0)
              loanDetailKv(
                context,
                l10n.loanTotalInterestLabel,
                formatMoney(
                  scenario.positiveInterestAccruedPaise,
                  currencyCode: loan.currencyCode,
                ),
              ),
            if (scenario.reverseInterestAccruedPaise > 0)
              loanDetailKv(
                context,
                l10n.loanReverseInterestToDateLabel,
                formatMoney(
                  scenario.reverseInterestAccruedPaise,
                  currencyCode: loan.currencyCode,
                ),
              ),
            if (scenario.displayPendingInterestPaise > 0)
              loanDetailKv(
                context,
                l10n.loanPendingInterestLabel,
                formatMoney(
                  scenario.displayPendingInterestPaise,
                  currencyCode: loan.currencyCode,
                ),
              ),
            if (scenario.reversePendingInterestPaise > 0)
              loanDetailKv(
                context,
                l10n.loanReversePendingInterestLabel,
                formatMoney(
                  scenario.reversePendingInterestPaise,
                  currencyCode: loan.currencyCode,
                ),
              ),
            loanDetailKv(
              context,
              l10n.loanPaidLabel,
              formatMoney(scenario.totalPaidPaise, currencyCode: loan.currencyCode),
            ),
            loanDetailKv(
              context,
              l10n.loanAdjustmentsLabel,
              formatMoney(
                scenario.totalAdjustmentsPaise,
                currencyCode: loan.currencyCode,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SetupSummary extends StatelessWidget {
  const SetupSummary({required this.loan, super.key});

  final MoneyLoan loan;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final double ratePct = loan.rateBps / 100.0;
    final String periodBase = switch (loan.ratePeriod) {
      MoneyRatePeriod.monthly => l10n.loanRateMonthly,
      MoneyRatePeriod.quarterly => l10n.loanRateQuarterly,
      MoneyRatePeriod.halfYearly => l10n.loanRateHalfYearly,
      MoneyRatePeriod.yearly => l10n.loanRateYearly,
    };
    final String period =
        loan.interestAccrual == MoneyInterestAccrual.daily365
            ? '$periodBase · ${l10n.loanRateDaily}'
            : periodBase;
    final String policy = switch (loan.capitalizationPolicy) {
      MoneyCapitalizationPolicy.never => l10n.loanCapPolicyNever,
      MoneyCapitalizationPolicy.onPayment => l10n.loanCapPolicyOnPayment,
      MoneyCapitalizationPolicy.onScheduledCycle =>
        l10n.loanCapPolicyOnScheduledCycle,
      MoneyCapitalizationPolicy.onBalanceDirectionChange =>
        l10n.loanCapPolicyOnBalanceDirectionChange,
      MoneyCapitalizationPolicy.onLoanClosure => l10n.loanCapPolicyOnLoanClosure,
      MoneyCapitalizationPolicy.manual => l10n.loanCapPolicyManual,
    };
    final String prepaymentMode =
        loan.prepaymentAllocation == MoneyPrepaymentAllocation.principalOnly
            ? l10n.loanPrepaymentPrincipalOnly
            : l10n.loanPrepaymentInterestFirst;
    final String start = formatIndiaDate(loan.interestStartedAt);
    final String due = loan.interestEndedAt == null
        ? l10n.loanDueNone
        : formatIndiaDate(loan.interestEndedAt!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.loanSetupSummary(start, due, '$ratePct%', period, policy),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.loanPrepaymentSetupLabel(prepaymentMode),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          switch (loan.capitalizationPolicy) {
            MoneyCapitalizationPolicy.never => l10n.loanCapPolicyHintNever,
            MoneyCapitalizationPolicy.onPayment =>
              l10n.loanCapPolicyHintOnPayment,
            MoneyCapitalizationPolicy.onScheduledCycle =>
              l10n.loanCapPolicyHintOnScheduledCycle,
            MoneyCapitalizationPolicy.onBalanceDirectionChange =>
              l10n.loanCapPolicyHintOnBalanceDirectionChange,
            MoneyCapitalizationPolicy.onLoanClosure =>
              l10n.loanCapPolicyHintOnLoanClosure,
            MoneyCapitalizationPolicy.manual => l10n.loanCapPolicyHintManual,
          },
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

DateTime _loanLedgerDateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

const double _kLoanLedgerDateWidth = 72;
const double _kLoanLedgerMoneyWidth = 92;

const List<FontFeature> _kLoanLedgerTabular = <FontFeature>[
  FontFeature.tabularFigures(),
];

/// Signed money for ledger amount column (+ / − prefix).
String loanLedgerSignedAmount(int signedPaise, {String currencyCode = 'INR'}) {
  final String money = formatMoney(
    signedPaise.abs(),
    currencyCode: currencyCode,
  );
  if (signedPaise > 0) {
    return '+$money';
  }
  if (signedPaise < 0) {
    return '−$money';
  }
  return money;
}

/// Effect of [event] on outstanding for the amount column.
int loanLedgerSignedAmountPaise(LoanTimelineEvent event) {
  return switch (event.kind) {
    LoanTimelineKind.interestSegment => event.amountPaise,
    LoanTimelineKind.interestCapitalized => event.amountPaise,
    LoanTimelineKind.payment => -event.amountPaise,
    LoanTimelineKind.disbursement => event.amountPaise,
    LoanTimelineKind.adjustment => -event.amountPaise,
    LoanTimelineKind.pendingAsOf => event.amountPaise,
  };
}

/// Column hint + body rows + pending footer for loan timeline.
List<Widget> buildLoanLedgerTimeline({
  required MoneyLoan loan,
  required LoanScenario scenario,
  void Function(MoneyLoanEntry entry)? onEdit,
}) {
  final List<LoanTimelineEvent> body = <LoanTimelineEvent>[];
  LoanTimelineEvent? pending;
  for (final LoanTimelineEvent event in scenario.timeline) {
    if (event.kind == LoanTimelineKind.pendingAsOf) {
      pending = event;
    } else {
      body.add(event);
    }
  }

  final List<Widget> children = <Widget>[
    const LoanLedgerColumnHeader(),
  ];
  DateTime? previousDay;
  for (final LoanTimelineEvent event in body) {
    final DateTime day = _loanLedgerDateOnly(event.at);
    final bool showDate = previousDay == null || previousDay != day;
    previousDay = day;
    children.add(
      TimelineRow(
        event: event,
        loan: loan,
        dateText: showDate ? formatIndiaDate(day) : '',
        onEdit: onEdit,
      ),
    );
  }
  if (pending != null) {
    children.add(
      LoanLedgerPendingFooter(
        event: pending,
        loan: loan,
      ),
    );
  }
  return children;
}

class _LoanLedgerGridRow extends StatelessWidget {
  const _LoanLedgerGridRow({
    required this.dateText,
    required this.particulars,
    required this.amountText,
    required this.balText,
    this.dateStyle,
    this.amountStyle,
    this.balStyle,
    this.onTap,
    this.tapTooltip,
  });

  final String dateText;
  final Widget particulars;
  final String amountText;
  final String balText;
  final TextStyle? dateStyle;
  final TextStyle? amountStyle;
  final TextStyle? balStyle;
  final VoidCallback? onTap;
  final String? tapTooltip;

  Widget _fixedColumn({
    required double width,
    required String text,
    required TextStyle? style,
    required Alignment alignment,
  }) {
    if (text.isEmpty) {
      return SizedBox(width: width);
    }
    return SizedBox(
      width: width,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment,
        child: Text(text, style: style),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    Widget row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _fixedColumn(
            width: _kLoanLedgerDateWidth,
            text: dateText,
            style: dateStyle,
            alignment: Alignment.centerLeft,
          ),
          Expanded(child: particulars),
          _fixedColumn(
            width: _kLoanLedgerMoneyWidth,
            text: amountText,
            style: amountStyle,
            alignment: Alignment.centerRight,
          ),
          _fixedColumn(
            width: _kLoanLedgerMoneyWidth,
            text: balText,
            style: balStyle,
            alignment: Alignment.centerRight,
          ),
        ],
      ),
    );
    if (onTap != null) {
      row = Material(
        type: MaterialType.transparency,
        child: InkWell(onTap: onTap, child: row),
      );
    }
    if (tapTooltip != null) {
      row = Tooltip(message: tapTooltip!, child: row);
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant, width: 0.5),
        ),
      ),
      child: row,
    );
  }
}

class LoanLedgerColumnHeader extends StatelessWidget {
  const LoanLedgerColumnHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextStyle? style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          fontFeatures: _kLoanLedgerTabular,
        );
    return _LoanLedgerGridRow(
      dateText: l10n.loanLedgerHeaderDate,
      particulars: Text(l10n.loanLedgerHeaderParticulars, style: style),
      amountText: l10n.loanLedgerHeaderAmount,
      balText: l10n.loanLedgerHeaderBal,
      dateStyle: style,
      amountStyle: style,
      balStyle: style,
    );
  }
}

class LoanLedgerPendingFooter extends StatelessWidget {
  const LoanLedgerPendingFooter({
    required this.event,
    required this.loan,
    super.key,
  });

  final LoanTimelineEvent event;
  final MoneyLoan loan;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextStyle? emphasis = Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          fontFeatures: _kLoanLedgerTabular,
        );
    final String label = event.amountPaise < 0
        ? l10n.loanOverpaidNowLabel
        : l10n.loanPendingNowLabel;
    return _LoanLedgerGridRow(
      dateText: '',
      particulars: Text(label, style: emphasis),
      amountText: '',
      balText: formatMoney(
        event.amountPaise,
        currencyCode: loan.currencyCode,
      ),
      dateStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontFeatures: _kLoanLedgerTabular,
          ),
      amountStyle: emphasis,
      balStyle: emphasis,
    );
  }
}

/// Passbook-style ledger row: Date | Particulars | Amount | Bal.
class TimelineRow extends StatelessWidget {
  const TimelineRow({
    required this.event,
    required this.loan,
    required this.dateText,
    this.onEdit,
    super.key,
  });

  final LoanTimelineEvent event;
  final MoneyLoan loan;
  final String dateText;
  final void Function(MoneyLoanEntry entry)? onEdit;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final String title = switch (event.kind) {
      LoanTimelineKind.interestSegment => event.amountPaise < 0
          ? l10n.loanLedgerReverseInterest
          : l10n.loanLedgerInterest,
      LoanTimelineKind.interestCapitalized => l10n.loanLedgerCapitalized,
      LoanTimelineKind.payment => l10n.loanLedgerPayment,
      LoanTimelineKind.disbursement => l10n.loanLedgerPrincipal,
      LoanTimelineKind.adjustment => l10n.loanLedgerAdjustment,
      LoanTimelineKind.pendingAsOf => event.amountPaise < 0
          ? l10n.loanOverpaidNowLabel
          : l10n.loanPendingNowLabel,
    };

    final List<String> metaParts = <String>[];
    if (event.kind == LoanTimelineKind.interestSegment) {
      final DateTime interestFrom = event.from ?? event.at;
      final DateTime interestThrough = event.through ?? event.at;
      metaParts.add(
        l10n.loanLedgerMetaOnPrincipal(
          formatMoney(
            (event.principalBasisPaise ?? 0).abs(),
            currencyCode: loan.currencyCode,
          ),
          formatIndiaDate(interestFrom),
          formatIndiaDate(interestThrough),
          calendarDaysBetween(interestFrom, interestThrough),
        ),
      );
    } else if (event.kind == LoanTimelineKind.payment) {
      final String? ref = event.note?.trim();
      if (ref != null && ref.isNotEmpty) {
        metaParts.add(l10n.timelinePaymentRef(ref));
      }
      if (event.toInterestPaise > 0) {
        metaParts.add(
          l10n.loanLedgerMetaToInterestPrincipal(
            formatMoney(
              event.toInterestPaise,
              currencyCode: loan.currencyCode,
            ),
            formatMoney(
              event.toPrincipalPaise,
              currencyCode: loan.currencyCode,
            ),
          ),
        );
      }
    } else {
      final String? note = event.note?.trim();
      if (note != null &&
          note.isNotEmpty &&
          (event.kind == LoanTimelineKind.disbursement ||
              event.kind == LoanTimelineKind.adjustment)) {
        metaParts.add(
          event.kind == LoanTimelineKind.disbursement
              ? l10n.timelinePaymentRef(note)
              : note,
        );
      }
    }
    final String? meta = metaParts.isEmpty ? null : metaParts.join(' · ');

    final int signedPaise = loanLedgerSignedAmountPaise(event);
    final String amountText = loanLedgerSignedAmount(
      signedPaise,
      currencyCode: loan.currencyCode,
    );
    final Color amountColor = signedPaise > 0
        ? scheme.tertiary
        : signedPaise < 0
            ? scheme.error
            : scheme.onSurface;

    final String balText = event.balanceAfterPaise == null
        ? ''
        : formatMoney(
            event.balanceAfterPaise!,
            currencyCode: loan.currencyCode,
          );

    MoneyLoanEntry? editableEntry;
    if (onEdit != null &&
        event.entryId != null &&
        (event.kind == LoanTimelineKind.payment ||
            event.kind == LoanTimelineKind.disbursement)) {
      for (final MoneyLoanEntry e in loan.entries) {
        if (e.id == event.entryId) {
          editableEntry = e;
          break;
        }
      }
    }

    final String particularsForSemantics =
        meta == null ? title : '$title. $meta';
    final String rowSemantics = l10n.loanLedgerRowSemantics(
      dateText,
      particularsForSemantics,
      amountText,
      balText,
    );
    final String semanticsLabel = editableEntry == null
        ? rowSemantics
        : '${l10n.loanEditEntryTooltip}. $rowSemantics';

    return Semantics(
      container: true,
      button: editableEntry != null,
      label: semanticsLabel,
      excludeSemantics: true,
      child: _LoanLedgerGridRow(
        dateText: dateText,
        particulars: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Flexible(
                  child: Text(
                    title,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (editableEntry != null) ...<Widget>[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ],
            ),
            if (meta != null) ...<Widget>[
              const SizedBox(height: 2),
              Text(
                meta,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        amountText: amountText,
        balText: balText,
        dateStyle: textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontFeatures: _kLoanLedgerTabular,
        ),
        amountStyle: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: amountColor,
          fontFeatures: _kLoanLedgerTabular,
        ),
        balStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          fontFeatures: _kLoanLedgerTabular,
        ),
        onTap: editableEntry == null ? null : () => onEdit!(editableEntry!),
        tapTooltip: editableEntry == null ? null : l10n.loanEditEntryTooltip,
      ),
    );
  }
}
