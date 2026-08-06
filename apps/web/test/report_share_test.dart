@Tags(['unit', 'reports'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:asset_os/core/config/app_branding.dart';
import 'package:asset_os/core/models/entities.dart';
import 'package:asset_os/core/models/unknown_customer.dart';
import 'package:asset_os/core/reports/report_builder.dart';
import 'package:asset_os/core/reports/report_models.dart';
import 'package:asset_os/core/sharing/whatsapp_share.dart';
import 'package:asset_os/l10n/app_localizations.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  final DateTime now = DateTime(2026, 8, 2, 15, 30);

  final List<Customer> customers = <Customer>[
    const Customer(
      id: 'CUS-1',
      name: 'Priya Patel',
      phone: '6666666666',
      isTrusted: true,
      qrCode: 'customer:1',
    ),
    const Customer(
      id: 'CUS-2',
      name: 'Amit Shah',
      phone: '6666666667',
      isTrusted: false,
      qrCode: 'customer:2',
    ),
  ];

  final List<InventoryItem> inventory = <InventoryItem>[
    const InventoryItem(
      id: 'INV-1',
      name: 'DSLR',
      category: 'Camera',
      availableUnits: 1,
      totalUnits: 2,
      status: AssetStatus.available,
      qrCode: 'inv:1',
    ),
    const InventoryItem(
      id: 'INV-2',
      name: 'Tripod',
      category: 'Support',
      availableUnits: 0,
      totalUnits: 1,
      status: AssetStatus.rented,
      qrCode: 'inv:2',
    ),
  ];

  final List<Rental> rentals = <Rental>[
    Rental(
      id: 'REN-1',
      customerId: 'CUS-1',
      lines: const <RentalLine>[
        RentalLine(
          id: 'RLI-REN-1-INV-2',
          itemId: 'INV-2',
          catalogName: 'Tripod',
          instanceName: 'Floor stand',
          shortCode: 'TRP-001',
        ),
      ],
      startedAt: now.subtract(const Duration(days: 2)),
      dueAt: now,
      timeline: const <RentalEvent>[],
      qrCode: 'rental:1',
    ),
    Rental(
      id: 'REN-2',
      customerId: 'CUS-2',
      lines: const <RentalLine>[
        RentalLine(
          id: 'RLI-REN-2-INV-1',
          itemId: 'INV-1',
          catalogName: 'DSLR',
          instanceName: 'Body A',
          shortCode: 'CAM-100',
        ),
      ],
      startedAt: now.subtract(const Duration(days: 5)),
      dueAt: now.subtract(const Duration(days: 1)),
      timeline: const <RentalEvent>[],
      qrCode: 'rental:2',
    ),
    Rental(
      id: 'REN-3',
      customerId: 'CUS-1',
      lines: const <RentalLine>[
        RentalLine(
          id: 'RLI-REN-3-INV-1',
          itemId: 'INV-1',
          catalogName: 'DSLR',
          instanceName: 'Body B',
          shortCode: 'CAM-101',
        ),
      ],
      startedAt: now.subtract(const Duration(days: 10)),
      dueAt: now.subtract(const Duration(days: 8)),
      returnedAt: now.subtract(const Duration(days: 7)),
      orderStatus: OrderStatus.completed,
      timeline: const <RentalEvent>[],
      qrCode: 'rental:3',
    ),
  ];

  group('ReportDateRange', () {
    test('daily starts at local midnight', () {
      final ReportDateRange range = ReportDateRange.resolve(
        period: ReportPeriod.daily,
        now: now,
      );
      expect(range.start, DateTime(2026, 8, 2));
      expect(range.end, now);
    });

    test('weekly is last 7 days', () {
      final ReportDateRange range = ReportDateRange.resolve(
        period: ReportPeriod.weekly,
        now: now,
      );
      expect(range.start, now.subtract(const Duration(days: 7)));
      expect(range.end, now);
    });

    test('monthly is calendar month start to now', () {
      final ReportDateRange range = ReportDateRange.resolve(
        period: ReportPeriod.monthly,
        now: now,
      );
      expect(range.start, DateTime(2026, 8, 1));
      expect(range.end, now);
    });

    test('custom end is inclusive end-of-day', () {
      final ReportDateRange range = ReportDateRange.resolve(
        period: ReportPeriod.custom,
        now: now,
        customStart: DateTime(2026, 7, 1),
        customEnd: DateTime(2026, 7, 15),
      );
      expect(range.start, DateTime(2026, 7, 1));
      expect(range.end.day, 15);
      expect(range.end.hour, 23);
    });
  });

  group('ReportBuilder', () {
    const ReportBuilder builder = ReportBuilder();

    test('summary includes counts and brand header', () {
      final ReportDateRange range = ReportDateRange.resolve(
        period: ReportPeriod.weekly,
        now: now,
      );
      final String text = builder.build(
        l10n: l10n,
        type: ReportType.summary,
        range: range,
        customers: customers,
        inventory: inventory,
        rentals: rentals,
        now: now,
      );
      expect(text, contains(l10n.reportHeader(kAppDisplayName)));
      expect(text, contains('26/07/2026 → 02/08/2026'));
      expect(text, contains(l10n.reportTypeSummary));
      expect(text, contains(l10n.reportActiveCount(2)));
      expect(text, contains(l10n.reportOpenedCount(2)));
      expect(text, contains(l10n.reportReturnedCount(1)));
      expect(text, contains(l10n.reportOverdueCount(1)));
      expect(text, contains('Charges (opened in range):'));
      expect(text, contains('Charges (returned in range):'));
      expect(text, contains('Deposit applied (returned in range):'));
      expect(text, contains('Balance due after deposit (returned):'));
    });

    test('customer-wise lists customers and items', () {
      final ReportDateRange range = ReportDateRange.resolve(
        period: ReportPeriod.weekly,
        now: now,
      );
      final String text = builder.build(
        l10n: l10n,
        type: ReportType.customerWise,
        range: range,
        customers: customers,
        inventory: inventory,
        rentals: rentals,
        now: now,
      );
      expect(text, contains(l10n.reportTypeCustomerWise));
      expect(text, contains('Priya Patel'));
      expect(text, contains('Tripod · Floor stand (TRP-001)'));
      expect(text, contains('Amit Shah'));
    });

    test('customer-wise prefixes nickname on rental lines', () {
      final List<Customer> unknownCustomers = <Customer>[
        buildUnknownCustomer(),
      ];
      final List<Rental> unknownRentals = <Rental>[
        Rental(
          id: 'REN-UNK-1',
          customerId: kUnknownCustomerId,
          lines: const <RentalLine>[
            RentalLine(
              id: 'RLI-REN-UNK-1-INV-1',
              itemId: 'INV-1',
              catalogName: 'DSLR',
              instanceName: 'Body A',
              shortCode: 'CAM-100',
            ),
          ],
          startedAt: now.subtract(const Duration(days: 1)),
          dueAt: now.add(const Duration(days: 2)),
          timeline: const <RentalEvent>[],
          qrCode: 'rental:unk1',
          nickname: 'Raju',
        ),
      ];
      final ReportDateRange range = ReportDateRange.resolve(
        period: ReportPeriod.weekly,
        now: now,
      );
      final String text = builder.build(
        l10n: l10n,
        type: ReportType.customerWise,
        range: range,
        customers: unknownCustomers,
        inventory: inventory,
        rentals: unknownRentals,
        now: now,
      );
      expect(text, contains('$kUnknownCustomerName ($kUnknownCustomerPhone)'));
      expect(text, contains('Raju — REN-UNK-1'));
    });

    test('inventory-wise lists rent counts and availability', () {
      final ReportDateRange range = ReportDateRange.resolve(
        period: ReportPeriod.monthly,
        now: now,
      );
      final String text = builder.build(
        l10n: l10n,
        type: ReportType.inventoryWise,
        range: range,
        customers: customers,
        inventory: inventory,
        rentals: rentals,
        now: now,
      );
      expect(text, contains(l10n.reportTypeResourcesWise));
      expect(text, contains('DSLR'));
      expect(text, contains('Tripod'));
      expect(text, contains('Floor stand (TRP-001)'));
      expect(text, contains('avail'));
    });

    test('truncates long reports', () {
      final ReportBuilder short = ReportBuilder(maxChars: 80);
      final ReportDateRange range = ReportDateRange.resolve(
        period: ReportPeriod.monthly,
        now: now,
      );
      final String text = short.build(
        l10n: l10n,
        type: ReportType.customerWise,
        range: range,
        customers: customers,
        inventory: inventory,
        rentals: rentals,
        now: now,
      );
      expect(text.length, lessThanOrEqualTo(80));
      expect(text, contains('truncated'));
    });
  });

  group('whatsapp_share', () {
    test('normalizeWhatsAppPhone prefixes 91 for 10-digit', () {
      expect(normalizeWhatsAppPhone('6666-666-666'), '916666666666');
      expect(normalizeWhatsAppPhone('+91 66666 66666'), '916666666666');
      expect(normalizeWhatsAppPhone('916666666666'), '916666666666');
    });

    test('buildWhatsAppShareUri encodes text and strips phone', () {
      final Uri uri = buildWhatsAppShareUri(
        phoneDigits: '6666 666666',
        message: 'Hello\nWorld',
      );
      expect(uri.scheme, 'https');
      expect(uri.host, 'wa.me');
      expect(uri.path, '/916666666666');
      expect(uri.queryParameters['text'], 'Hello\nWorld');
    });

    test('shareReportToSelf launches when launcher succeeds', () async {
      Uri? launched;
      final WhatsAppShareOutcome outcome = await shareReportToSelf(
        phoneDigits: '6666666666',
        message: 'Report body',
        launch: (Uri uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
          launched = uri;
          expect(mode, LaunchMode.externalApplication);
          return true;
        },
      );
      expect(outcome, WhatsAppShareOutcome.launched);
      expect(launched?.path, '/916666666666');
    });

    test('shareReportToSelf copies on launch failure', () async {
      ClipboardData? copied;
      final WhatsAppShareOutcome outcome = await shareReportToSelf(
        phoneDigits: '6666666666',
        message: 'Fallback text',
        launch: (Uri uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
          return false;
        },
        setClipboard: (ClipboardData data) async {
          copied = data;
        },
      );
      expect(outcome, WhatsAppShareOutcome.copiedToClipboard);
      expect(copied?.text, 'Fallback text');
    });

    test('shareReportToSelf returns missingPhone when empty', () async {
      final WhatsAppShareOutcome outcome = await shareReportToSelf(
        phoneDigits: '',
        message: 'x',
      );
      expect(outcome, WhatsAppShareOutcome.missingPhone);
    });
  });
}
