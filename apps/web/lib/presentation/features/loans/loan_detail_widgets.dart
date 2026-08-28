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
              l10n.loanPrincipalLabel,
              formatMoney(
                scenario.remainingPrincipalPaise,
                currencyCode: loan.currencyCode,
              ),
            ),
            if (scenario.remainingPrincipalPaise != scenario.principalPaise)
              loanDetailKv(
                context,
                l10n.loanOriginalPrincipalLabel,
                formatMoney(
                  scenario.principalPaise,
                  currencyCode: loan.currencyCode,
                ),
              ),
            loanDetailKv(
              context,
              scenario.interestAccruedPaise < 0
                  ? l10n.loanReverseInterestToDateLabel
                  : l10n.loanInterestToDateLabel,
              formatMoney(
                scenario.interestAccruedPaise,
                currencyCode: loan.currencyCode,
              ),
            ),
            if (scenario.unpaidInterestPaise != 0)
              loanDetailKv(
                context,
                l10n.loanUnpaidInterestLabel,
                formatMoney(
                  scenario.unpaidInterestPaise,
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

class TimelineRow extends StatelessWidget {
  const TimelineRow({
    required this.event,
    required this.loan,
    this.onEdit,
    super.key,
  });

  final LoanTimelineEvent event;
  final MoneyLoan loan;
  final void Function(MoneyLoanEntry entry)? onEdit;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String money = formatMoney(
      event.amountPaise,
      currencyCode: loan.currencyCode,
    );
    final String text = switch (event.kind) {
      LoanTimelineKind.interestSegment => event.amountPaise < 0
          ? l10n.loanTimelineReverseInterestSegment(
              formatMoney(
                event.principalBasisPaise ?? 0,
                currencyCode: loan.currencyCode,
              ),
              formatIndiaDate(event.from ?? event.at),
              formatIndiaDate(event.through ?? event.at),
              money,
            )
          : l10n.loanTimelineInterestSegment(
              formatMoney(
                event.principalBasisPaise ?? 0,
                currencyCode: loan.currencyCode,
              ),
              formatIndiaDate(event.from ?? event.at),
              formatIndiaDate(event.through ?? event.at),
              money,
            ),
      LoanTimelineKind.interestCapitalized =>
        l10n.loanTimelineInterestCapitalized(
          formatIndiaDate(event.at),
          money,
        ),
      LoanTimelineKind.payment => event.toInterestPaise > 0
          ? l10n.loanTimelinePaymentSplit(
              formatIndiaDate(event.at),
              money,
              formatMoney(event.toInterestPaise, currencyCode: loan.currencyCode),
              formatMoney(event.toPrincipalPaise, currencyCode: loan.currencyCode),
            )
          : l10n.loanTimelinePayment(
              formatIndiaDate(event.at),
              money,
              formatMoney(event.toPrincipalPaise, currencyCode: loan.currencyCode),
            ),
      LoanTimelineKind.disbursement => l10n.loanTimelineDisbursement(
          formatIndiaDate(event.at),
          money,
        ),
      LoanTimelineKind.adjustment => l10n.loanTimelineAdjustment(
          formatIndiaDate(event.at),
          money,
        ),
      LoanTimelineKind.pendingAsOf => event.amountPaise < 0
          ? l10n.loanTimelinePendingOverpaid(
              formatIndiaDate(event.at),
              money,
            )
          : l10n.loanTimelinePending(formatIndiaDate(event.at), money),
    };
    final String? paymentRef = event.note?.trim();
    final bool showPaymentRef = paymentRef != null &&
        paymentRef.isNotEmpty &&
        (event.kind == LoanTimelineKind.payment ||
            event.kind == LoanTimelineKind.disbursement);
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            switch (event.kind) {
              LoanTimelineKind.interestSegment => event.amountPaise < 0
                  ? Icons.trending_down
                  : Icons.trending_up,
              LoanTimelineKind.interestCapitalized => Icons.merge_type,
              LoanTimelineKind.payment => Icons.payments_outlined,
              LoanTimelineKind.disbursement => Icons.add_card_outlined,
              LoanTimelineKind.adjustment => Icons.tune,
              LoanTimelineKind.pendingAsOf => Icons.pending_actions_outlined,
            },
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  text,
                  style: event.kind == LoanTimelineKind.pendingAsOf
                      ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          )
                      : Theme.of(context).textTheme.bodyMedium,
                ),
                if (showPaymentRef) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    l10n.timelinePaymentRef(paymentRef),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (editableEntry != null)
            IconButton(
              tooltip: l10n.loanEditEntryTooltip,
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => onEdit!(editableEntry!),
            ),
        ],
      ),
    );
  }
}
