import 'loan_models.dart';

/// Why the ledger is asking whether to capitalize unpaid interest.
enum LedgerHook {
  beforePayment,
  scheduledBoundary,
  beforeSignFlip,
  atClosure,
  manualEntry,
}

/// Mutable signed ledger snapshot during [computeLoanScenario].
class LedgerState {
  LedgerState({
    this.balance = 0,
    this.unpaidInterest = 0,
  });

  int balance;
  int unpaidInterest;

  int get outstanding => balance + unpaidInterest;
}

/// Pluggable rule for when unpaid interest merges into [LedgerState.balance].
abstract class InterestCapitalizationPolicy {
  const InterestCapitalizationPolicy();

  bool shouldCapitalize({
    required MoneyLoan loan,
    required LedgerState state,
    required LedgerHook hook,
  });
}

class NeverCapitalizePolicy extends InterestCapitalizationPolicy {
  const NeverCapitalizePolicy();

  @override
  bool shouldCapitalize({
    required MoneyLoan loan,
    required LedgerState state,
    required LedgerHook hook,
  }) =>
      false;
}

class OnPaymentCapitalizePolicy extends InterestCapitalizationPolicy {
  const OnPaymentCapitalizePolicy();

  @override
  bool shouldCapitalize({
    required MoneyLoan loan,
    required LedgerState state,
    required LedgerHook hook,
  }) =>
      hook == LedgerHook.beforePayment;
}

class OnScheduledCycleCapitalizePolicy extends InterestCapitalizationPolicy {
  const OnScheduledCycleCapitalizePolicy();

  @override
  bool shouldCapitalize({
    required MoneyLoan loan,
    required LedgerState state,
    required LedgerHook hook,
  }) =>
      hook == LedgerHook.scheduledBoundary;
}

class OnBalanceDirectionChangeCapitalizePolicy
    extends InterestCapitalizationPolicy {
  const OnBalanceDirectionChangeCapitalizePolicy();

  @override
  bool shouldCapitalize({
    required MoneyLoan loan,
    required LedgerState state,
    required LedgerHook hook,
  }) =>
      hook == LedgerHook.beforeSignFlip;
}

class OnLoanClosureCapitalizePolicy extends InterestCapitalizationPolicy {
  const OnLoanClosureCapitalizePolicy();

  @override
  bool shouldCapitalize({
    required MoneyLoan loan,
    required LedgerState state,
    required LedgerHook hook,
  }) =>
      hook == LedgerHook.atClosure;
}

class ManualCapitalizePolicy extends InterestCapitalizationPolicy {
  const ManualCapitalizePolicy();

  @override
  bool shouldCapitalize({
    required MoneyLoan loan,
    required LedgerState state,
    required LedgerHook hook,
  }) =>
      hook == LedgerHook.manualEntry;
}

InterestCapitalizationPolicy capitalizationPolicyFor(MoneyLoan loan) {
  return switch (loan.capitalizationPolicy) {
    MoneyCapitalizationPolicy.never => const NeverCapitalizePolicy(),
    MoneyCapitalizationPolicy.onPayment => const OnPaymentCapitalizePolicy(),
    MoneyCapitalizationPolicy.onScheduledCycle =>
      const OnScheduledCycleCapitalizePolicy(),
    MoneyCapitalizationPolicy.onBalanceDirectionChange =>
      const OnBalanceDirectionChangeCapitalizePolicy(),
    MoneyCapitalizationPolicy.onLoanClosure =>
      const OnLoanClosureCapitalizePolicy(),
    MoneyCapitalizationPolicy.manual => const ManualCapitalizePolicy(),
  };
}
