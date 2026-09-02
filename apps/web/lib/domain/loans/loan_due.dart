import 'loan_models.dart';

/// True when a pending loan has a due date on or before [asOf].
bool isMoneyLoanDue(MoneyLoan loan, DateTime asOf) {
  if (loan.status != MoneyLoanStatus.pending) {
    return false;
  }
  final DateTime? ended = loan.interestEndedAt;
  if (ended == null) {
    return false;
  }
  final DateTime due = DateTime(ended.year, ended.month, ended.day);
  final DateTime today = DateTime(asOf.year, asOf.month, asOf.day);
  return !due.isAfter(today);
}
