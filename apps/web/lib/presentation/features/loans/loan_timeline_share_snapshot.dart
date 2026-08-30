import 'package:flutter/material.dart';

import '../../../domain/config/app_branding.dart';
import '../../../domain/loans/loan_balance.dart';
import '../../../domain/loans/loan_models.dart';
import '../../../infrastructure/l10n/india_date_format.dart';
import '../../../infrastructure/l10n/l10n_ext.dart';
import 'loan_detail_widgets.dart';

/// Fixed width for loan timeline PNG share (matches report preview compact width).
const double kLoanTimelineShareWidth = 360;

/// Full vertical snapshot: header, scenario, setup, and entire timeline (no ListView).
class LoanTimelineShareSnapshot extends StatelessWidget {
  const LoanTimelineShareSnapshot({
    required this.loan,
    required this.scenario,
    required this.customerName,
    required this.generatedAt,
    super.key,
  });

  final MoneyLoan loan;
  final LoanScenario scenario;
  final String customerName;
  final DateTime generatedAt;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final String statusLabel = switch (loan.status) {
      MoneyLoanStatus.pending => l10n.loanStatusPending,
      MoneyLoanStatus.closed => l10n.loanStatusClosed,
      MoneyLoanStatus.cancelled => l10n.loanStatusCancelled,
    };
    final String direction = loan.direction == MoneyLoanDirection.given
        ? l10n.loanDirectionGiven
        : l10n.loanDirectionTaken;

    return SizedBox(
      width: kLoanTimelineShareWidth,
      child: Material(
        color: theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                kAppDisplayName,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                customerName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$direction · $statusLabel',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatIndiaDateTime(generatedAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              CurrentScenarioCard(
                loan: loan,
                scenario: scenario,
                customerName: customerName,
              ),
              const SizedBox(height: 12),
              SetupSummary(loan: loan),
              const SizedBox(height: 16),
              Text(
                l10n.loanTimelineHeading,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...buildLoanLedgerTimeline(
                loan: loan,
                scenario: scenario,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
