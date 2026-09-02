@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/domain/loans/loan_models.dart';
import 'package:asset_os/domain/models/entities.dart';
import 'package:asset_os/domain/reminders/reminder_evaluator.dart';
import 'package:asset_os/domain/reminders/reminder_models.dart';
import 'package:asset_os/l10n/app_localizations_en.dart';

Customer _customer({String id = 'C1', String name = 'Priya Patel'}) {
  return Customer(
    id: id,
    name: name,
    phone: '9999999999',
    isTrusted: false,
    qrCode: 'cust:$id',
  );
}

Rental _openRental({
  required String id,
  required DateTime dueAt,
  String customerId = 'C1',
}) {
  return Rental(
    id: id,
    customerId: customerId,
    lines: const <RentalLine>[],
    startedAt: dueAt.subtract(const Duration(days: 2)),
    dueAt: dueAt,
    timeline: const <RentalEvent>[],
    qrCode: 'rental:$id',
    orderStatus: OrderStatus.open,
  );
}

InventoryItem _inventory({
  required String id,
  required int available,
  required int total,
  bool active = true,
}) {
  return InventoryItem(
    id: id,
    name: 'Widget $id',
    category: 'General',
    availableUnits: available,
    totalUnits: total,
    status: AssetStatus.available,
    qrCode: 'inv:$id',
    catalogActive: active,
  );
}

MoneyLoan _loan({required DateTime interestEndedAt, MoneyLoanStatus status = MoneyLoanStatus.pending}) {
  return MoneyLoan(
    id: 'L1',
    customerId: 'C1',
    direction: MoneyLoanDirection.given,
    principalPaise: 100000,
    currencyCode: 'INR',
    interestKind: MoneyInterestKind.simple,
    rateBps: 200,
    ratePeriod: MoneyRatePeriod.monthly,
    interestStartedAt: interestEndedAt.subtract(const Duration(days: 30)),
    interestEndedAt: interestEndedAt,
    status: status,
    createdAt: interestEndedAt.subtract(const Duration(days: 30)),
    entries: const <MoneyLoanEntry>[],
  );
}

void main() {
  final AppLocalizationsEn l10n = AppLocalizationsEn();
  final List<Customer> customers = <Customer>[_customer()];

  group('evaluateOrderReminders', () {
    test('due tomorrow matches next calendar day', () {
      final DateTime now = DateTime(2026, 3, 10, 15);
      final List<Rental> rentals = <Rental>[
        _openRental(id: 'R1', dueAt: DateTime(2026, 3, 11, 8)),
      ];
      final List<ReminderCandidate> out =
          evaluateOrderReminders(rentals, customers, now);
      expect(out, hasLength(1));
      expect(out.first.kind, ReminderKind.dueTomorrow);
      expect(out.first.entityId, 'R1');
    });

    test('due today and overdue respect calendar-day boundaries', () {
      final DateTime now = DateTime(2026, 3, 10, 9);
      final List<Rental> rentals = <Rental>[
        _openRental(id: 'today', dueAt: DateTime(2026, 3, 10, 23, 59)),
        _openRental(id: 'overdue', dueAt: DateTime(2026, 3, 9, 18)),
      ];
      final List<ReminderCandidate> out =
          evaluateOrderReminders(rentals, customers, now);
      expect(out.where((ReminderCandidate c) => c.kind == ReminderKind.dueToday), hasLength(1));
      expect(out.where((ReminderCandidate c) => c.kind == ReminderKind.overdue), hasLength(1));
    });
  });

  group('evaluateLowStock', () {
    test('threshold zero flags out of stock', () {
      final List<ReminderCandidate> out = evaluateLowStock(
        <InventoryItem>[_inventory(id: 'I1', available: 0, total: 4)],
        0,
      );
      expect(out, hasLength(1));
      expect(out.first.kind, ReminderKind.lowStock);
    });

    test('threshold one excludes two available units', () {
      final List<ReminderCandidate> out = evaluateLowStock(
        <InventoryItem>[_inventory(id: 'I1', available: 2, total: 5)],
        1,
      );
      expect(out, isEmpty);
    });
  });

  group('evaluateLoanReminders', () {
    test('pending loan due on or before today is included', () {
      final DateTime now = DateTime(2026, 3, 10, 12);
      final List<ReminderCandidate> out = evaluateLoanReminders(
        <MoneyLoan>[_loan(interestEndedAt: DateTime(2026, 3, 10))],
        customers,
        now,
      );
      expect(out, hasLength(1));
      expect(out.first.kind, ReminderKind.loanDue);
    });
  });

  group('filterByReminderSettings', () {
    test('disabled kind removes candidates', () {
      const ReminderSettingsFilter settings = ReminderSettingsFilter(
        dueTomorrow: true,
        dueToday: false,
        overdue: true,
        lowStock: true,
        loansDue: true,
      );
      final List<ReminderCandidate> filtered = filterByReminderSettings(
        <ReminderCandidate>[
          const ReminderCandidate(
            kind: ReminderKind.dueToday,
            entityId: 'x',
            title: 'A',
            subtitle: '',
          ),
          const ReminderCandidate(
            kind: ReminderKind.overdue,
            entityId: 'y',
            title: 'B',
            subtitle: '',
          ),
        ],
        settings,
      );
      expect(filtered, hasLength(1));
      expect(filtered.first.kind, ReminderKind.overdue);
    });
  });

  group('buildDigestSummary', () {
    test('includes counts in localized string', () {
      final String summary = buildDigestSummary(
        <ReminderCandidate>[
          const ReminderCandidate(
            kind: ReminderKind.dueToday,
            entityId: 'R1',
            title: 'Priya',
            subtitle: '',
          ),
          const ReminderCandidate(
            kind: ReminderKind.overdue,
            entityId: 'R2',
            title: 'Ravi',
            subtitle: '',
          ),
        ],
        l10n,
      );
      expect(summary, contains('Due today: 1'));
      expect(summary, contains('Overdue: 1'));
      expect(summary, contains('Priya'));
      expect(summary, contains('Ravi'));
    });
  });
}
