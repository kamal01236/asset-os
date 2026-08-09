@Tags(['unit', 'inventory', 'reports'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/domain/models/entities.dart';
import 'package:asset_os/application/reports/report_builder.dart';
import 'package:asset_os/domain/reports/report_models.dart';
import 'package:asset_os/domain/reports/report_widgets.dart';
import 'package:asset_os/domain/templates/field_defs.dart';
import 'package:asset_os/domain/templates/industry_templates.dart';
import 'package:asset_os/l10n/app_localizations.dart';

void main() {
  group('FieldDef registry', () {
    test('starter defs cover duration, visits, barcode, and household fields', () {
      expect(fieldDefById(kFieldEstimatedDuration)?.type, FieldValueType.number);
      expect(fieldDefById(kFieldMaxVisits)?.appliesTo(ResourceType.membership), isTrue);
      expect(fieldDefById(kFieldBarcode)?.appliesTo(ResourceType.rental), isTrue);
      expect(fieldDefById(kFieldBarcode)?.appliesTo(ResourceType.job), isFalse);
      expect(fieldDefById(kFieldImei)?.type, FieldValueType.text);
      expect(fieldDefById(kFieldImei)?.appliesTo(ResourceType.job), isTrue);
      expect(fieldDefById(kFieldMeasurements)?.labelHi, isNotEmpty);
      expect(fieldDefById(kFieldDriverName)?.appliesTo(ResourceType.rental), isTrue);
      expect(fieldDefById(kFieldVillage)?.type, FieldValueType.text);
      expect(fieldDefById(kFieldHoursRun)?.type, FieldValueType.number);
      expect(fieldDefById(kFieldAcres)?.type, FieldValueType.number);
      expect(fieldDefById(kFieldTrialDate)?.type, FieldValueType.date);
      expect(fieldDefById(kFieldDeliveryDate)?.type, FieldValueType.date);
      expect(
        fieldDefById(kFieldDevicePasswordNote)?.appliesTo(ResourceType.job),
        isTrue,
      );
    });

    test('resolveExtraFields filters by type and template ids', () {
      final List<FieldDef> membership = resolveExtraFields(
        type: ResourceType.membership,
        templateFieldIds: <String>[kFieldMaxVisits, kFieldBarcode],
      );
      expect(membership.map((FieldDef f) => f.id), <String>[kFieldMaxVisits]);

      final List<FieldDef> allForJob = resolveExtraFields(
        type: ResourceType.job,
      );
      expect(allForJob.map((FieldDef f) => f.id), contains(kFieldEstimatedDuration));
    });

    test('metadata encode/decode round-trips', () {
      final String? raw = encodeMetadata(<String, Object?>{
        kFieldMaxVisits: 12,
        kFieldBarcode: 'ABC-1',
        'empty': '',
      });
      expect(raw, isNotNull);
      final Map<String, Object?> decoded = decodeMetadata(raw);
      expect(decoded[kFieldMaxVisits], 12);
      expect(decoded[kFieldBarcode], 'ABC-1');
      expect(decoded.containsKey('empty'), isFalse);
      expect(encodeMetadata(const <String, Object?>{}), isNull);
    });
  });

  group('template packs phase 5', () {
    test('gym and boutique declare fields and report widgets', () {
      final IndustryTemplate gym = industryTemplateById('gym')!;
      expect(gym.extraFieldIds, contains(kFieldMaxVisits));
      expect(gym.defaultReportWidgets, kMembershipReportWidgets);

      final IndustryTemplate boutique = industryTemplateById('boutique')!;
      expect(boutique.extraFieldIds, contains(kFieldBarcode));
      expect(boutique.defaultReportWidgets, kBoutiqueReportWidgets);
    });
  });

  group('ReportBuilder widgets', () {
    late AppLocalizations l10n;

    setUpAll(() async {
      l10n = await AppLocalizations.delegate.load(const Locale('en'));
    });

    test('summary uses template widget pack (gym omits overdue)', () {
      final DateTime now = DateTime(2026, 8, 2, 15, 30);
      final ReportDateRange range = ReportDateRange.resolve(
        period: ReportPeriod.weekly,
        now: now,
      );
      final String text = const ReportBuilder().build(
        l10n: l10n,
        type: ReportType.summary,
        range: range,
        customers: const <Customer>[
          Customer(
            id: 'CUS-1',
            name: 'Priya',
            phone: '6666666666',
            isTrusted: true,
            qrCode: 'c:1',
          ),
        ],
        inventory: const <InventoryItem>[
          InventoryItem(
            id: 'INV-1',
            name: 'Pass',
            category: 'Gym',
            availableUnits: 1,
            totalUnits: 1,
            status: AssetStatus.available,
            qrCode: 'i:1',
            defaultItemKind: ResourceType.membership,
          ),
        ],
        rentals: <Rental>[
          Rental(
            id: 'REN-1',
            customerId: 'CUS-1',
            lines: const <RentalLine>[
              RentalLine(
                id: 'RLI-1',
                itemId: 'INV-1',
                catalogName: 'Pass',
                instanceName: '',
                shortCode: 'P-1',
              ),
            ],
            startedAt: now.subtract(const Duration(days: 1)),
            dueAt: now.add(const Duration(days: 2)),
            timeline: const <RentalEvent>[],
            qrCode: 'r:1',
            baseAmount: 150000,
          ),
        ],
        now: now,
        widgets: kMembershipReportWidgets,
      );
      expect(text, contains('Revenue'));
      expect(text, contains('Activity'));
      expect(text, contains('Top customers'));
      expect(text, isNot(contains(l10n.reportOverdueCount(0))));
    });
  });
}
