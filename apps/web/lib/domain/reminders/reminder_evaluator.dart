import '../loans/loan_due.dart';
import '../loans/loan_models.dart';
import '../models/entities.dart';
import 'reminder_models.dart';
import '../../l10n/app_localizations.dart';

bool _isDueTomorrow(Rental rental, DateTime now) {
  final DateTime? due = rental.dueAt;
  if (due == null) {
    return false;
  }
  final DateTime tomorrow = DateTime(now.year, now.month, now.day)
      .add(const Duration(days: 1));
  return due.year == tomorrow.year &&
      due.month == tomorrow.month &&
      due.day == tomorrow.day;
}

String _dateSubtitle(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _customerTitle(Customer? customer, Rental rental) {
  return customer?.name ?? rental.nickname ?? rental.customerId;
}

String _customerTitleForLoan(Customer? customer, MoneyLoan loan) {
  return customer?.name ?? loan.customerId;
}

/// Open orders due tomorrow, today, or overdue.
List<ReminderCandidate> evaluateOrderReminders(
  List<Rental> rentals,
  List<Customer> customers,
  DateTime now,
) {
  final Map<String, Customer> byId = <String, Customer>{
    for (final Customer c in customers) c.id: c,
  };
  final List<ReminderCandidate> out = <ReminderCandidate>[];
  for (final Rental rental in rentals) {
    if (rental.orderStatus != OrderStatus.open) {
      continue;
    }
    final Customer? customer = byId[rental.customerId];
    final String title = _customerTitle(customer, rental);
    if (_isDueTomorrow(rental, now)) {
      final DateTime due = rental.dueAt!;
      out.add(
        ReminderCandidate(
          kind: ReminderKind.dueTomorrow,
          entityId: rental.id,
          title: title,
          subtitle: _dateSubtitle(due),
        ),
      );
    }
    final AssetStatus status = rental.statusFor(now);
    if (status == AssetStatus.dueToday) {
      final DateTime due = rental.dueAt!;
      out.add(
        ReminderCandidate(
          kind: ReminderKind.dueToday,
          entityId: rental.id,
          title: title,
          subtitle: _dateSubtitle(due),
        ),
      );
    } else if (status == AssetStatus.overdue) {
      final DateTime? due = rental.dueAt;
      out.add(
        ReminderCandidate(
          kind: ReminderKind.overdue,
          entityId: rental.id,
          title: title,
          subtitle: due == null ? '' : _dateSubtitle(due),
        ),
      );
    }
  }
  return out;
}

/// Active catalog items at or below [threshold] available units.
List<ReminderCandidate> evaluateLowStock(
  List<InventoryItem> inventory,
  int threshold,
) {
  final List<ReminderCandidate> out = <ReminderCandidate>[];
  for (final InventoryItem item in inventory) {
    if (!item.catalogActive || item.totalUnits <= 0) {
      continue;
    }
    if (item.availableUnits <= threshold) {
      out.add(
        ReminderCandidate(
          kind: ReminderKind.lowStock,
          entityId: item.id,
          title: item.name,
          subtitle: '${item.availableUnits}/${item.totalUnits}',
        ),
      );
    }
  }
  return out;
}

/// Pending loans with interest end on or before [now].
List<ReminderCandidate> evaluateLoanReminders(
  List<MoneyLoan> loans,
  List<Customer> customers,
  DateTime now,
) {
  final Map<String, Customer> byId = <String, Customer>{
    for (final Customer c in customers) c.id: c,
  };
  final List<ReminderCandidate> out = <ReminderCandidate>[];
  for (final MoneyLoan loan in loans) {
    if (!isMoneyLoanDue(loan, now)) {
      continue;
    }
    final Customer? customer = byId[loan.customerId];
    final DateTime due = loan.interestEndedAt!;
    out.add(
      ReminderCandidate(
        kind: ReminderKind.loanDue,
        entityId: loan.id,
        title: _customerTitleForLoan(customer, loan),
        subtitle: _dateSubtitle(due),
      ),
    );
  }
  return out;
}

/// Keeps candidates whose kind is enabled in [settings].
List<ReminderCandidate> filterByReminderSettings(
  List<ReminderCandidate> candidates,
  ReminderSettingsFilter settings,
) {
  return candidates
      .where((ReminderCandidate c) => settings.isKindEnabled(c.kind))
      .toList();
}

/// Settings subset used by the domain filter (no infrastructure deps).
class ReminderSettingsFilter {
  const ReminderSettingsFilter({
    required this.dueTomorrow,
    required this.dueToday,
    required this.overdue,
    required this.lowStock,
    required this.loansDue,
  });

  final bool dueTomorrow;
  final bool dueToday;
  final bool overdue;
  final bool lowStock;
  final bool loansDue;

  bool isKindEnabled(ReminderKind kind) {
    switch (kind) {
      case ReminderKind.dueTomorrow:
        return dueTomorrow;
      case ReminderKind.dueToday:
        return dueToday;
      case ReminderKind.overdue:
        return overdue;
      case ReminderKind.lowStock:
        return lowStock;
      case ReminderKind.loanDue:
        return loansDue;
    }
  }
}

int _countForKind(List<ReminderCandidate> candidates, ReminderKind kind) {
  return candidates.where((ReminderCandidate c) => c.kind == kind).length;
}

List<String> _sampleNames(List<ReminderCandidate> candidates, ReminderKind kind) {
  return candidates
      .where((ReminderCandidate c) => c.kind == kind)
      .map((ReminderCandidate c) => c.title)
      .take(3)
      .toList();
}

String _joinNames(List<String> names) => names.join(', ');

/// Plain-text digest for notifications and the web banner.
String buildDigestSummary(
  List<ReminderCandidate> candidates,
  AppLocalizations l10n,
) {
  if (candidates.isEmpty) {
    return '';
  }
  final int dueTomorrow = _countForKind(candidates, ReminderKind.dueTomorrow);
  final int dueToday = _countForKind(candidates, ReminderKind.dueToday);
  final int overdue = _countForKind(candidates, ReminderKind.overdue);
  final int lowStock = _countForKind(candidates, ReminderKind.lowStock);
  final int loanDue = _countForKind(candidates, ReminderKind.loanDue);

  return l10n.reminderDigestBody(
    dueTomorrow,
    dueToday,
    overdue,
    lowStock,
    loanDue,
    _joinNames(
      _sampleNames(candidates, ReminderKind.dueTomorrow),
    ),
    _joinNames(
      _sampleNames(candidates, ReminderKind.dueToday),
    ),
    _joinNames(
      _sampleNames(candidates, ReminderKind.overdue),
    ),
    _joinNames(
      _sampleNames(candidates, ReminderKind.lowStock),
    ),
    _joinNames(
      _sampleNames(candidates, ReminderKind.loanDue),
    ),
  );
}
