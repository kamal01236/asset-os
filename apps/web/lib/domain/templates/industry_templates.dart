import 'package:flutter/widgets.dart';

import '../home/home_modules.dart';
import '../models/entities.dart';
import '../reports/report_widgets.dart';
import 'field_defs.dart';
import 'workflows.dart';

bool _isHindi(Locale locale) => locale.languageCode == 'hi';

/// Static industry packs for onboarding and Business Templates (single active pack).
class TemplateInventoryItem {
  const TemplateInventoryItem({
    required this.name,
    required this.category,
    required this.defaultUnits,
    this.nameHi = '',
    this.categoryHi = '',
    this.notes,
    this.billingMode = BillingMode.weekly,
    this.rateAmount = 0,
    this.lateFeePerDay = 0,
    this.currencyCode = 'INR',
    this.defaultItemKind = ResourceType.rental,
    this.requiresUnitIdentity = false,
    this.unitCodePrefix,
    this.dueDateOptional = false,
  });

  final String name;
  final String nameHi;
  final String category;
  final String categoryHi;
  final int defaultUnits;
  final String? notes;
  final BillingMode billingMode;
  /// Rate in paise.
  final int rateAmount;
  final int lateFeePerDay;
  final String currencyCode;
  final ResourceType defaultItemKind;
  final bool requiresUnitIdentity;
  /// Optional short-code pool prefix seeded into catalog.
  final String? unitCodePrefix;
  final bool dueDateOptional;

  String localizedName(Locale locale) =>
      _isHindi(locale) && nameHi.isNotEmpty ? nameHi : name;

  String localizedCategory(Locale locale) =>
      _isHindi(locale) && categoryHi.isNotEmpty ? categoryHi : category;

  /// Copy with [name]/[category] resolved for [locale] (for DB insert).
  TemplateInventoryItem resolvedForLocale(Locale locale) {
    if (!_isHindi(locale)) {
      return this;
    }
    return TemplateInventoryItem(
      name: localizedName(locale),
      nameHi: nameHi,
      category: localizedCategory(locale),
      categoryHi: categoryHi,
      defaultUnits: defaultUnits,
      notes: notes,
      billingMode: billingMode,
      rateAmount: rateAmount,
      lateFeePerDay: lateFeePerDay,
      currencyCode: currencyCode,
      defaultItemKind: defaultItemKind,
      requiresUnitIdentity: requiresUnitIdentity,
      unitCodePrefix: unitCodePrefix,
      dueDateOptional: dueDateOptional,
    );
  }
}

/// Prefs key for comma-separated [ResourceType.name] values.
const String kEnabledResourceTypesPrefsKey = 'asset_os_enabled_resource_types';

/// Fallback when prefs are empty and inventory has no typed kinds yet.
const List<ResourceType> kFallbackEnabledResourceTypes = <ResourceType>[
  ResourceType.rental,
  ResourceType.sale,
  ResourceType.job,
];

/// Distinct [ResourceType]s from template / inventory item kinds (stable order).
List<ResourceType> resourceTypesFromItems(
  Iterable<ResourceType> kinds,
) {
  final Set<ResourceType> seen = <ResourceType>{};
  final List<ResourceType> ordered = <ResourceType>[];
  for (final ResourceType kind in kinds) {
    if (seen.add(kind)) {
      ordered.add(kind);
    }
  }
  return ordered;
}

List<ResourceType> resourceTypesFromTemplateItems(
  Iterable<TemplateInventoryItem> items,
) {
  return resourceTypesFromItems(
    items.map((TemplateInventoryItem i) => i.defaultItemKind),
  );
}

List<ResourceType> parseEnabledResourceTypes(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return List<ResourceType>.from(kFallbackEnabledResourceTypes);
  }
  final List<ResourceType> parsed = <ResourceType>[];
  final Set<ResourceType> seen = <ResourceType>{};
  for (final String part in raw.split(',')) {
    final String id = part.trim();
    if (id.isEmpty) {
      continue;
    }
    final ResourceType type = ResourceType.parse(id);
    // Reject unknown tokens that parse() maps to rental by default when the
    // raw string was not a known enum name (except explicit "rental").
    final bool known = ResourceType.values.any((ResourceType t) => t.name == id) ||
        id == 'general';
    if (!known) {
      continue;
    }
    if (seen.add(type)) {
      parsed.add(type);
    }
  }
  return parsed.isEmpty
      ? List<ResourceType>.from(kFallbackEnabledResourceTypes)
      : parsed;
}

String encodeEnabledResourceTypes(Iterable<ResourceType> types) {
  final Set<ResourceType> seen = <ResourceType>{};
  final List<ResourceType> ordered = <ResourceType>[];
  for (final ResourceType type in types) {
    if (seen.add(type)) {
      ordered.add(type);
    }
  }
  return ordered.map((ResourceType t) => t.name).join(',');
}

/// Resolve enabled types: prefs → inventory kinds → fallback.
///
/// When prefs are missing and inventory derivation would leave New Order
/// without Sell/Job (e.g. demo seed or legacy rental-only catalog), union
/// with [kFallbackEnabledResourceTypes] so Sell/Job are not silently hidden.
/// Explicit prefs (onboarding / owner UI / template apply) win as-is.
List<ResourceType> resolveEnabledResourceTypes({
  required String? prefsRaw,
  Iterable<ResourceType> inventoryKinds = const <ResourceType>[],
}) {
  if (prefsRaw != null && prefsRaw.trim().isNotEmpty) {
    return parseEnabledResourceTypes(prefsRaw);
  }
  final List<ResourceType> fromInventory =
      resourceTypesFromItems(inventoryKinds);
  if (fromInventory.isNotEmpty) {
    final List<LineFulfillment> options =
        fulfillmentOptionsForEnabledTypes(fromInventory);
    final bool hasSellOrJob = options.contains(LineFulfillment.sell) ||
        options.contains(LineFulfillment.job);
    if (!hasSellOrJob) {
      return resourceTypesFromItems(<ResourceType>[
        ...fromInventory,
        ...kFallbackEnabledResourceTypes,
      ]);
    }
    return fromInventory;
  }
  return List<ResourceType>.from(kFallbackEnabledResourceTypes);
}

/// New Order More-options fulfillment segments for the enabled type set.
///
/// [current] keeps Sell/Job visible when already selected on the line even if
/// the type is not in the enabled set. Catalog items are never hidden by type.
/// Membership / subscription enable Sell; loan enables Rent.
List<LineFulfillment> fulfillmentOptionsForEnabledTypes(
  Iterable<ResourceType> enabled, {
  LineFulfillment? current,
}) {
  final Set<ResourceType> set = enabled.toSet();
  final bool showSell = set.contains(ResourceType.sale) ||
      set.contains(ResourceType.subscription) ||
      set.contains(ResourceType.membership) ||
      current == LineFulfillment.sell;
  final bool showJob = set.contains(ResourceType.job) ||
      set.contains(ResourceType.service) ||
      current == LineFulfillment.job;
  final bool rentLike = set.contains(ResourceType.rental) ||
      set.contains(ResourceType.loan) ||
      set.contains(ResourceType.financial) ||
      set.contains(ResourceType.custom) ||
      current == LineFulfillment.rent;
  final bool showRent = rentLike || (!showSell && !showJob);

  final List<LineFulfillment> options = <LineFulfillment>[];
  if (showRent) {
    options.add(LineFulfillment.rent);
  }
  if (showSell) {
    options.add(LineFulfillment.sell);
  }
  if (showJob) {
    options.add(LineFulfillment.job);
  }
  return options;
}

class IndustryTemplate {
  const IndustryTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.items,
    this.nameHi = '',
    this.descriptionHi = '',
    this.defaultHomeModules = kDefaultHomeModules,
    this.enabledResourceTypesOverride,
    this.workflowId = kDefaultWorkflowId,
    this.extraFieldIds = const <String>[],
    this.defaultReportWidgets = kDefaultReportWidgets,
  });

  final String id;
  final String name;
  final String nameHi;
  final String description;
  final String descriptionHi;
  final List<TemplateInventoryItem> items;

  /// Home layout defaults applied when the user accepts the template layout.
  final List<HomeModuleId> defaultHomeModules;

  /// Explicit enabled types; when null, derived from [items].
  final List<ResourceType>? enabledResourceTypesOverride;

  /// Status pipeline preset applied at onboarding / full Home layout apply.
  final String workflowId;

  /// Dynamic catalog field ids from [kFieldDefs] for this pack.
  final List<String> extraFieldIds;

  /// Default Share Reports widget composition for this pack.
  final List<ReportWidgetId> defaultReportWidgets;

  /// Resource types this pack enables for New Order fulfillment chrome.
  /// Defaults to the union of [items] `.defaultItemKind` when override omitted.
  List<ResourceType> get enabledResourceTypes =>
      enabledResourceTypesOverride ?? resourceTypesFromTemplateItems(items);

  WorkflowDefinition get workflow => resolveWorkflow(prefsId: workflowId);

  /// Resolved [FieldDef]s declared by this pack (unknown ids skipped).
  List<FieldDef> get extraFields {
    final List<FieldDef> out = <FieldDef>[];
    for (final String id in extraFieldIds) {
      final FieldDef? def = fieldDefById(id);
      if (def != null) {
        out.add(def);
      }
    }
    return out;
  }

  String localizedName(Locale locale) =>
      _isHindi(locale) && nameHi.isNotEmpty ? nameHi : name;

  String localizedDescription(Locale locale) =>
      _isHindi(locale) && descriptionHi.isNotEmpty ? descriptionHi : description;
}

const List<IndustryTemplate> kIndustryTemplates = <IndustryTemplate>[
  IndustryTemplate(
    id: 'library',
    name: 'Library',
    nameHi: 'पुस्तकालय',
    description: 'Books and reading seats for lending counters.',
    descriptionHi: 'उधार काउंटर के लिए किताबें और बैठने की सीटें।',
    defaultHomeModules: kLibraryHomeModules,
    workflowId: kRentalWorkflowId,
    defaultReportWidgets: kLibraryReportWidgets,
    extraFieldIds: <String>[kFieldBarcode],
    enabledResourceTypesOverride: <ResourceType>[
      ResourceType.rental,
      ResourceType.loan,
    ],
    items: <TemplateInventoryItem>[
      TemplateInventoryItem(
        name: 'Novel',
        nameHi: 'उपन्यास',
        category: 'Library',
        categoryHi: 'पुस्तकालय',
        defaultUnits: 20,
        billingMode: BillingMode.weekly,
        rateAmount: 5000, // ₹50/week
        lateFeePerDay: 500, // ₹5/day
      ),
      TemplateInventoryItem(
        name: 'Book',
        nameHi: 'किताब',
        category: 'Library',
        categoryHi: 'पुस्तकालय',
        defaultUnits: 10,
        billingMode: BillingMode.weekly,
        rateAmount: 3000,
      ),
      TemplateInventoryItem(
        name: 'Journal',
        nameHi: 'जर्नल',
        category: 'Library',
        categoryHi: 'पुस्तकालय',
        defaultUnits: 5,
        billingMode: BillingMode.weekly,
        rateAmount: 2000,
      ),
      TemplateInventoryItem(
        name: 'Magazine',
        nameHi: 'पत्रिका',
        category: 'Library',
        categoryHi: 'पुस्तकालय',
        defaultUnits: 8,
        billingMode: BillingMode.weekly,
        rateAmount: 1500,
      ),
      TemplateInventoryItem(
        name: 'Calculator',
        nameHi: 'कैलकुलेटर',
        category: 'Library',
        categoryHi: 'पुस्तकालय',
        defaultUnits: 4,
        billingMode: BillingMode.daily,
        rateAmount: 1000,
      ),
      TemplateInventoryItem(
        name: 'Reading seat',
        nameHi: 'पढ़ने की सीट',
        category: 'Library',
        categoryHi: 'पुस्तकालय',
        defaultUnits: 40,
        billingMode: BillingMode.monthly,
        rateAmount: 50000, // ₹500/month
        lateFeePerDay: 1000, // ₹10/day
        requiresUnitIdentity: true,
        unitCodePrefix: 'SEAT',
      ),
    ],
  ),
  IndustryTemplate(
    id: 'camera',
    name: 'Camera Rental',
    nameHi: 'कैमरा किराया',
    description: 'Photography gear for shoot-day rentals.',
    descriptionHi: 'शूट के दिन किराए के लिए फोटोग्राफी गियर।',
    defaultHomeModules: kRentalHomeModules,
    workflowId: kRentalWorkflowId,
    defaultReportWidgets: kRentalReportWidgets,
    extraFieldIds: <String>[kFieldBarcode],
    enabledResourceTypesOverride: <ResourceType>[ResourceType.rental],
    items: <TemplateInventoryItem>[
      TemplateInventoryItem(
        name: 'DSLR',
        nameHi: 'DSLR',
        category: 'Camera',
        categoryHi: 'कैमरा',
        defaultUnits: 3,
        billingMode: BillingMode.daily,
        rateAmount: 150000,
        lateFeePerDay: 20000,
      ),
      TemplateInventoryItem(
        name: 'Lens',
        nameHi: 'लेंस',
        category: 'Camera',
        categoryHi: 'कैमरा',
        defaultUnits: 4,
        billingMode: BillingMode.daily,
        rateAmount: 80000,
      ),
      TemplateInventoryItem(
        name: 'Battery',
        nameHi: 'बैटरी',
        category: 'Camera',
        categoryHi: 'कैमरा',
        defaultUnits: 6,
        billingMode: BillingMode.daily,
        rateAmount: 5000,
      ),
      TemplateInventoryItem(
        name: 'Memory Card',
        nameHi: 'मेमोरी कार्ड',
        category: 'Camera',
        categoryHi: 'कैमरा',
        defaultUnits: 8,
        billingMode: BillingMode.daily,
        rateAmount: 3000,
      ),
      TemplateInventoryItem(
        name: 'Tripod',
        nameHi: 'ट्राइपॉड',
        category: 'Camera',
        categoryHi: 'कैमरा',
        defaultUnits: 3,
        billingMode: BillingMode.daily,
        rateAmount: 20000,
      ),
    ],
  ),
  IndustryTemplate(
    id: 'farm',
    name: 'Farm Equipment',
    nameHi: 'कृषि उपकरण',
    description:
        'Tractor, harvest, and tanker rentals with driver and acre fields.',
    descriptionHi:
        'ट्रैक्टर, कटाई और टैंकर किराया — ड्राइवर और एकड़ फ़ील्ड सहित।',
    defaultHomeModules: kRentalHomeModules,
    workflowId: kRentalWorkflowId,
    defaultReportWidgets: kRentalReportWidgets,
    extraFieldIds: <String>[
      kFieldBarcode,
      kFieldDriverName,
      kFieldVillage,
      kFieldHoursRun,
      kFieldAcres,
    ],
    enabledResourceTypesOverride: <ResourceType>[ResourceType.rental],
    items: <TemplateInventoryItem>[
      TemplateInventoryItem(
        name: 'Tractor',
        nameHi: 'ट्रैक्टर',
        category: 'Farm',
        categoryHi: 'कृषि',
        defaultUnits: 1,
        billingMode: BillingMode.daily,
        rateAmount: 500000,
        lateFeePerDay: 50000,
      ),
      TemplateInventoryItem(
        name: 'Harvester',
        nameHi: 'हार्वेस्टर',
        category: 'Farm',
        categoryHi: 'कृषि',
        defaultUnits: 1,
        billingMode: BillingMode.daily,
        rateAmount: 800000,
        lateFeePerDay: 80000,
      ),
      TemplateInventoryItem(
        name: 'Water Tanker',
        nameHi: 'पानी टैंकर',
        category: 'Farm',
        categoryHi: 'कृषि',
        defaultUnits: 2,
        billingMode: BillingMode.daily,
        rateAmount: 300000,
        lateFeePerDay: 30000,
      ),
      TemplateInventoryItem(
        name: 'Seeder',
        nameHi: 'सीडर',
        category: 'Farm',
        categoryHi: 'कृषि',
        defaultUnits: 2,
        billingMode: BillingMode.daily,
        rateAmount: 150000,
      ),
      TemplateInventoryItem(
        name: 'Rotavator',
        nameHi: 'रोटावेटर',
        category: 'Farm',
        categoryHi: 'कृषि',
        defaultUnits: 2,
        billingMode: BillingMode.daily,
        rateAmount: 200000,
      ),
      TemplateInventoryItem(
        name: 'Water Pump',
        nameHi: 'पानी का पंप',
        category: 'Farm',
        categoryHi: 'कृषि',
        defaultUnits: 3,
        billingMode: BillingMode.daily,
        rateAmount: 80000,
      ),
    ],
  ),
  IndustryTemplate(
    id: 'event',
    name: 'Event Rental',
    nameHi: 'इवेंट किराया',
    description: 'Seating, staging, and AV for events.',
    descriptionHi: 'इवेंट के लिए बैठक, स्टेजिंग और AV।',
    defaultHomeModules: kRentalHomeModules,
    workflowId: kRentalWorkflowId,
    defaultReportWidgets: kRentalReportWidgets,
    extraFieldIds: <String>[kFieldBarcode],
    enabledResourceTypesOverride: <ResourceType>[ResourceType.rental],
    items: <TemplateInventoryItem>[
      TemplateInventoryItem(
        name: 'Chair',
        nameHi: 'कुर्सी',
        category: 'Event',
        categoryHi: 'इवेंट',
        defaultUnits: 50,
        billingMode: BillingMode.fixed,
        rateAmount: 2000,
      ),
      TemplateInventoryItem(
        name: 'Table',
        nameHi: 'टेबल',
        category: 'Event',
        categoryHi: 'इवेंट',
        defaultUnits: 20,
        billingMode: BillingMode.fixed,
        rateAmount: 10000,
      ),
      TemplateInventoryItem(
        name: 'Stage Panel',
        nameHi: 'स्टेज पैनल',
        category: 'Event',
        categoryHi: 'इवेंट',
        defaultUnits: 8,
        billingMode: BillingMode.daily,
        rateAmount: 50000,
      ),
      TemplateInventoryItem(
        name: 'Speaker',
        nameHi: 'स्पीकर',
        category: 'Event',
        categoryHi: 'इवेंट',
        defaultUnits: 4,
        billingMode: BillingMode.daily,
        rateAmount: 100000,
      ),
      TemplateInventoryItem(
        name: 'LED Light',
        nameHi: 'LED लाइट',
        category: 'Event',
        categoryHi: 'इवेंट',
        defaultUnits: 6,
        billingMode: BillingMode.daily,
        rateAmount: 40000,
      ),
    ],
  ),
  IndustryTemplate(
    id: 'marriage_decor',
    name: 'Marriage Decorations',
    nameHi: 'शादी डेकोरेशन',
    description: 'Wedding seating, stage, flowers, lights, and power gear.',
    descriptionHi: 'शादी के लिए बैठक, स्टेज, फूल, लाइट और पावर गियर।',
    defaultHomeModules: kRentalHomeModules,
    workflowId: kRentalWorkflowId,
    defaultReportWidgets: kRentalReportWidgets,
    extraFieldIds: <String>[kFieldBarcode],
    enabledResourceTypesOverride: <ResourceType>[ResourceType.rental],
    items: <TemplateInventoryItem>[
      TemplateInventoryItem(
        name: 'Chair',
        nameHi: 'कुर्सी',
        category: 'Marriage Decor',
        categoryHi: 'शादी डेकोर',
        defaultUnits: 100,
        billingMode: BillingMode.fixed,
        rateAmount: 1500,
      ),
      TemplateInventoryItem(
        name: 'Stage',
        nameHi: 'स्टेज',
        category: 'Marriage Decor',
        categoryHi: 'शादी डेकोर',
        defaultUnits: 2,
        billingMode: BillingMode.daily,
        rateAmount: 500000,
        lateFeePerDay: 50000,
      ),
      TemplateInventoryItem(
        name: 'Flower Decoration',
        nameHi: 'फूल डेकोरेशन',
        category: 'Marriage Decor',
        categoryHi: 'शादी डेकोर',
        defaultUnits: 10,
        billingMode: BillingMode.fixed,
        rateAmount: 200000,
      ),
      TemplateInventoryItem(
        name: 'String Lights',
        nameHi: 'झालर लाइट',
        category: 'Marriage Decor',
        categoryHi: 'शादी डेकोर',
        defaultUnits: 20,
        billingMode: BillingMode.daily,
        rateAmount: 30000,
      ),
      TemplateInventoryItem(
        name: 'Pedestal Fan',
        nameHi: 'पेडस्टल पंखा',
        category: 'Marriage Decor',
        categoryHi: 'शादी डेकोर',
        defaultUnits: 15,
        billingMode: BillingMode.daily,
        rateAmount: 15000,
      ),
      TemplateInventoryItem(
        name: 'Generator',
        nameHi: 'जनरेटर',
        category: 'Marriage Decor',
        categoryHi: 'शादी डेकोर',
        defaultUnits: 2,
        billingMode: BillingMode.daily,
        rateAmount: 250000,
        lateFeePerDay: 25000,
      ),
    ],
  ),
  IndustryTemplate(
    id: 'birthday_decor',
    name: 'Birthday Decorations',
    nameHi: 'बर्थडे डेकोरेशन',
    description: 'Balloon gear, photo frames, and LED numbers for parties.',
    descriptionHi: 'पार्टी के लिए बैलून गियर, फ्रेम और LED नंबर।',
    defaultHomeModules: kRentalHomeModules,
    workflowId: kRentalWorkflowId,
    defaultReportWidgets: kRentalReportWidgets,
    extraFieldIds: <String>[kFieldBarcode],
    enabledResourceTypesOverride: <ResourceType>[ResourceType.rental],
    items: <TemplateInventoryItem>[
      TemplateInventoryItem(
        name: 'Balloon Pump',
        nameHi: 'बैलून पंप',
        category: 'Birthday Decor',
        categoryHi: 'बर्थडे डेकोर',
        defaultUnits: 4,
        billingMode: BillingMode.fixed,
        rateAmount: 20000,
      ),
      TemplateInventoryItem(
        name: 'Balloon Stand',
        nameHi: 'बैलून स्टैंड',
        category: 'Birthday Decor',
        categoryHi: 'बर्थडे डेकोर',
        defaultUnits: 8,
        billingMode: BillingMode.fixed,
        rateAmount: 15000,
      ),
      TemplateInventoryItem(
        name: 'Photo Frame',
        nameHi: 'फोटो फ्रेम',
        category: 'Birthday Decor',
        categoryHi: 'बर्थडे डेकोर',
        defaultUnits: 6,
        billingMode: BillingMode.fixed,
        rateAmount: 25000,
      ),
      TemplateInventoryItem(
        name: 'LED Number Set',
        nameHi: 'LED नंबर सेट',
        category: 'Birthday Decor',
        categoryHi: 'बर्थडे डेकोर',
        defaultUnits: 5,
        billingMode: BillingMode.fixed,
        rateAmount: 40000,
      ),
      TemplateInventoryItem(
        name: 'Backdrop Stand',
        nameHi: 'बैकड्रॉप स्टैंड',
        category: 'Birthday Decor',
        categoryHi: 'बर्थडे डेकोर',
        defaultUnits: 3,
        billingMode: BillingMode.daily,
        rateAmount: 50000,
      ),
    ],
  ),
  IndustryTemplate(
    id: 'temple',
    name: 'Temple',
    nameHi: 'मंदिर',
    description: 'Hall booking, chairs, sound, and optional donation lines.',
    descriptionHi: 'हॉल बुकिंग, कुर्सी, साउंड और वैकल्पिक दान लाइन।',
    defaultHomeModules: kRentalHomeModules,
    workflowId: kRentalWorkflowId,
    defaultReportWidgets: kRentalReportWidgets,
    extraFieldIds: <String>[kFieldBarcode],
    enabledResourceTypesOverride: <ResourceType>[
      ResourceType.rental,
      ResourceType.sale,
    ],
    items: <TemplateInventoryItem>[
      TemplateInventoryItem(
        name: 'Hall Booking',
        nameHi: 'हॉल बुकिंग',
        category: 'Temple',
        categoryHi: 'मंदिर',
        defaultUnits: 1,
        billingMode: BillingMode.daily,
        rateAmount: 500000,
        lateFeePerDay: 50000,
      ),
      TemplateInventoryItem(
        name: 'Chair',
        nameHi: 'कुर्सी',
        category: 'Temple',
        categoryHi: 'मंदिर',
        defaultUnits: 80,
        billingMode: BillingMode.fixed,
        rateAmount: 1000,
      ),
      TemplateInventoryItem(
        name: 'Sound System',
        nameHi: 'साउंड सिस्टम',
        category: 'Temple',
        categoryHi: 'मंदिर',
        defaultUnits: 2,
        billingMode: BillingMode.daily,
        rateAmount: 150000,
        lateFeePerDay: 15000,
      ),
      TemplateInventoryItem(
        name: 'Donation Receipt',
        nameHi: 'दान रसीद',
        category: 'Temple',
        categoryHi: 'मंदिर',
        defaultUnits: 100,
        billingMode: BillingMode.fixed,
        rateAmount: 1100, // ₹11 placeholder SKU
        defaultItemKind: ResourceType.sale,
        requiresUnitIdentity: false,
      ),
    ],
  ),
  IndustryTemplate(
    id: 'construction',
    name: 'Construction / Tools',
    nameHi: 'निर्माण / औजार',
    description: 'Jobsite tools and safety kits.',
    descriptionHi: 'साइट के औजार और सुरक्षा किट।',
    defaultHomeModules: kRentalHomeModules,
    defaultReportWidgets: kRentalReportWidgets,
    extraFieldIds: <String>[kFieldBarcode],
    enabledResourceTypesOverride: <ResourceType>[ResourceType.rental],
    items: <TemplateInventoryItem>[
      TemplateInventoryItem(
        name: 'Drill Kit',
        nameHi: 'ड्रिल किट',
        category: 'Tools',
        categoryHi: 'औजार',
        defaultUnits: 4,
        billingMode: BillingMode.daily,
        rateAmount: 25000,
        lateFeePerDay: 5000,
      ),
      TemplateInventoryItem(
        name: 'Angle Grinder',
        nameHi: 'एंगल ग्राइंडर',
        category: 'Tools',
        categoryHi: 'औजार',
        defaultUnits: 3,
        billingMode: BillingMode.daily,
        rateAmount: 30000,
      ),
      TemplateInventoryItem(
        name: 'Ladder',
        nameHi: 'सीढ़ी',
        category: 'Tools',
        categoryHi: 'औजार',
        defaultUnits: 3,
        billingMode: BillingMode.daily,
        rateAmount: 15000,
      ),
      TemplateInventoryItem(
        name: 'Safety Kit',
        nameHi: 'सुरक्षा किट',
        category: 'Tools',
        categoryHi: 'औजार',
        defaultUnits: 5,
        billingMode: BillingMode.fixed,
        rateAmount: 10000,
      ),
    ],
  ),
  IndustryTemplate(
    id: 'office',
    name: 'Office Assets',
    nameHi: 'ऑफिस संपत्ति',
    description: 'Shared office hardware and access gear.',
    descriptionHi: 'साझा ऑफिस हार्डवेयर और एक्सेस गियर।',
    defaultHomeModules: kRentalHomeModules,
    defaultReportWidgets: kRentalReportWidgets,
    extraFieldIds: <String>[kFieldBarcode],
    enabledResourceTypesOverride: <ResourceType>[ResourceType.rental],
    items: <TemplateInventoryItem>[
      TemplateInventoryItem(
        name: 'Laptop',
        nameHi: 'लैपटॉप',
        category: 'Office',
        categoryHi: 'ऑफिस',
        defaultUnits: 5,
        billingMode: BillingMode.weekly,
        rateAmount: 200000,
        lateFeePerDay: 10000,
      ),
      TemplateInventoryItem(
        name: 'Monitor',
        nameHi: 'मॉनिटर',
        category: 'Office',
        categoryHi: 'ऑफिस',
        defaultUnits: 6,
        billingMode: BillingMode.weekly,
        rateAmount: 50000,
      ),
      TemplateInventoryItem(
        name: 'Projector',
        nameHi: 'प्रोजेक्टर',
        category: 'Office',
        categoryHi: 'ऑफिस',
        defaultUnits: 2,
        billingMode: BillingMode.daily,
        rateAmount: 100000,
      ),
      TemplateInventoryItem(
        name: 'Access Card',
        nameHi: 'एक्सेस कार्ड',
        category: 'Office',
        categoryHi: 'ऑफिस',
        defaultUnits: 20,
        billingMode: BillingMode.fixed,
        rateAmount: 5000,
      ),
    ],
  ),
  IndustryTemplate(
    id: 'parlour',
    name: 'Beauty Parlour',
    nameHi: 'ब्यूटी पार्लर',
    description:
        'Service packages, retail products, membership, and kit rentals.',
    descriptionHi:
        'सेवा पैकेज, रिटेल उत्पाद, सदस्यता और किट किराया।',
    defaultHomeModules: kJobHomeModules,
    workflowId: kJobWorkflowId,
    defaultReportWidgets: kJobReportWidgets,
    extraFieldIds: <String>[kFieldEstimatedDuration, kFieldBarcode, kFieldMaxVisits],
    enabledResourceTypesOverride: <ResourceType>[
      ResourceType.service,
      ResourceType.job,
      ResourceType.membership,
      ResourceType.sale,
      ResourceType.rental,
    ],
    items: <TemplateInventoryItem>[
      TemplateInventoryItem(
        name: 'Haircut',
        nameHi: 'हेयरकट',
        category: 'Parlour',
        categoryHi: 'पार्लर',
        defaultUnits: 1,
        billingMode: BillingMode.fixed,
        rateAmount: 30000, // ₹300
        defaultItemKind: ResourceType.service,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'Facial',
        nameHi: 'फेशियल',
        category: 'Parlour',
        categoryHi: 'पार्लर',
        defaultUnits: 1,
        billingMode: BillingMode.fixed,
        rateAmount: 80000, // ₹800
        defaultItemKind: ResourceType.service,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'Manicure',
        nameHi: 'मैनीक्योर',
        category: 'Parlour',
        categoryHi: 'पार्लर',
        defaultUnits: 1,
        billingMode: BillingMode.fixed,
        rateAmount: 40000, // ₹400
        defaultItemKind: ResourceType.service,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'Bridal Package',
        nameHi: 'ब्राइडल पैकेज',
        category: 'Parlour',
        categoryHi: 'पार्लर',
        defaultUnits: 1,
        billingMode: BillingMode.fixed,
        rateAmount: 1500000, // ₹15,000
        defaultItemKind: ResourceType.service,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'Party Makeup Package',
        nameHi: 'पार्टी मेकअप पैकेज',
        category: 'Parlour',
        categoryHi: 'पार्लर',
        defaultUnits: 1,
        billingMode: BillingMode.fixed,
        rateAmount: 500000, // ₹5,000
        defaultItemKind: ResourceType.service,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'Hair Oil',
        nameHi: 'हेयर ऑयल',
        category: 'Parlour',
        categoryHi: 'पार्लर',
        defaultUnits: 20,
        billingMode: BillingMode.fixed,
        rateAmount: 15000, // ₹150
        defaultItemKind: ResourceType.sale,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'Face Cream',
        nameHi: 'फेस क्रीम',
        category: 'Parlour',
        categoryHi: 'पार्लर',
        defaultUnits: 15,
        billingMode: BillingMode.fixed,
        rateAmount: 25000, // ₹250
        defaultItemKind: ResourceType.sale,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'Monthly Membership',
        nameHi: 'मासिक सदस्यता',
        category: 'Parlour',
        categoryHi: 'पार्लर',
        defaultUnits: 30,
        billingMode: BillingMode.monthly,
        rateAmount: 200000, // ₹2,000/month
        defaultItemKind: ResourceType.membership,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'Steamer Kit',
        nameHi: 'स्टीमर किट',
        category: 'Parlour',
        categoryHi: 'पार्लर',
        defaultUnits: 2,
        billingMode: BillingMode.daily,
        rateAmount: 20000, // ₹200/day
        lateFeePerDay: 5000,
      ),
      TemplateInventoryItem(
        name: 'Chair',
        nameHi: 'कुर्सी',
        category: 'Parlour',
        categoryHi: 'पार्लर',
        defaultUnits: 4,
        billingMode: BillingMode.daily,
        rateAmount: 50000, // ₹500/day
      ),
    ],
  ),
  IndustryTemplate(
    id: 'boutique',
    name: 'Boutique',
    nameHi: 'बुटीक',
    description: 'Garment and accessory rental for occasions.',
    descriptionHi: 'अवसरों के लिए कपड़े और एक्सेसरी किराया।',
    defaultHomeModules: kJobHomeModules,
    workflowId: kBoutiqueWorkflowId,
    defaultReportWidgets: kBoutiqueReportWidgets,
    extraFieldIds: <String>[kFieldBarcode],
    enabledResourceTypesOverride: <ResourceType>[
      ResourceType.rental,
      ResourceType.sale,
      ResourceType.job,
    ],
    items: <TemplateInventoryItem>[
      TemplateInventoryItem(
        name: 'Lehenga',
        nameHi: 'लहंगा',
        category: 'Boutique',
        categoryHi: 'बुटीक',
        defaultUnits: 8,
        billingMode: BillingMode.weekly,
        rateAmount: 200000, // ₹2,000/week
        lateFeePerDay: 20000,
        requiresUnitIdentity: true,
      ),
      TemplateInventoryItem(
        name: 'Saree',
        nameHi: 'साड़ी',
        category: 'Boutique',
        categoryHi: 'बुटीक',
        defaultUnits: 12,
        billingMode: BillingMode.weekly,
        rateAmount: 80000, // ₹800/week
        lateFeePerDay: 10000,
        requiresUnitIdentity: true,
      ),
      TemplateInventoryItem(
        name: 'Suit Set',
        nameHi: 'सूट सेट',
        category: 'Boutique',
        categoryHi: 'बुटीक',
        defaultUnits: 10,
        billingMode: BillingMode.weekly,
        rateAmount: 100000, // ₹1,000/week
        requiresUnitIdentity: true,
      ),
      TemplateInventoryItem(
        name: 'Dupatta',
        nameHi: 'दुपट्टा',
        category: 'Boutique',
        categoryHi: 'बुटीक',
        defaultUnits: 15,
        billingMode: BillingMode.daily,
        rateAmount: 10000, // ₹100/day
        requiresUnitIdentity: true,
      ),
      TemplateInventoryItem(
        name: 'Jewellery Set',
        nameHi: 'ज्वेलरी सेट',
        category: 'Boutique',
        categoryHi: 'बुटीक',
        defaultUnits: 6,
        billingMode: BillingMode.weekly,
        rateAmount: 150000, // ₹1,500/week
        lateFeePerDay: 15000,
        requiresUnitIdentity: true,
      ),
    ],
  ),
  IndustryTemplate(
    id: 'gym',
    name: 'Gym Membership',
    nameHi: 'जिम सदस्यता',
    description: 'Membership fee products and locker rentals.',
    descriptionHi: 'सदस्यता शुल्क उत्पाद और लॉकर किराया।',
    defaultHomeModules: kMembershipHomeModules,
    workflowId: kRentalWorkflowId,
    defaultReportWidgets: kMembershipReportWidgets,
    extraFieldIds: <String>[kFieldMaxVisits, kFieldBarcode],
    enabledResourceTypesOverride: <ResourceType>[
      ResourceType.membership,
      ResourceType.sale,
      ResourceType.rental,
    ],
    items: <TemplateInventoryItem>[
      TemplateInventoryItem(
        name: 'Monthly Membership',
        nameHi: 'मासिक सदस्यता',
        category: 'Gym',
        categoryHi: 'जिम',
        defaultUnits: 50,
        billingMode: BillingMode.monthly,
        rateAmount: 150000, // ₹1,500/month
        defaultItemKind: ResourceType.membership,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'Quarterly Membership',
        nameHi: 'तिमाही सदस्यता',
        category: 'Gym',
        categoryHi: 'जिम',
        defaultUnits: 30,
        billingMode: BillingMode.fixed,
        rateAmount: 400000, // ₹4,000
        defaultItemKind: ResourceType.membership,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'Annual Membership',
        nameHi: 'वार्षिक सदस्यता',
        category: 'Gym',
        categoryHi: 'जिम',
        defaultUnits: 20,
        billingMode: BillingMode.fixed,
        rateAmount: 1200000, // ₹12,000
        defaultItemKind: ResourceType.membership,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'Day Pass',
        nameHi: 'डे पास',
        category: 'Gym',
        categoryHi: 'जिम',
        defaultUnits: 100,
        billingMode: BillingMode.fixed,
        rateAmount: 30000, // ₹300
        defaultItemKind: ResourceType.sale,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'Locker',
        nameHi: 'लॉकर',
        category: 'Gym',
        categoryHi: 'जिम',
        defaultUnits: 20,
        billingMode: BillingMode.monthly,
        rateAmount: 30000, // ₹300/month
        requiresUnitIdentity: false,
      ),
    ],
  ),
  IndustryTemplate(
    id: 'salon',
    name: 'Salon',
    nameHi: 'सैलून',
    description:
        'Walk-in services, retail products, and simple membership plans.',
    descriptionHi:
        'वॉक-इन सेवाएँ, रिटेल उत्पाद और सरल सदस्यता योजनाएँ।',
    defaultHomeModules: kJobHomeModules,
    workflowId: kSalonWorkflowId,
    defaultReportWidgets: kJobReportWidgets,
    extraFieldIds: <String>[kFieldEstimatedDuration, kFieldMaxVisits],
    enabledResourceTypesOverride: <ResourceType>[
      ResourceType.service,
      ResourceType.job,
      ResourceType.membership,
      ResourceType.sale,
    ],
    items: <TemplateInventoryItem>[
      TemplateInventoryItem(
        name: 'Haircut',
        nameHi: 'हेयरकट',
        category: 'Salon',
        categoryHi: 'सैलून',
        defaultUnits: 1,
        billingMode: BillingMode.fixed,
        rateAmount: 25000,
        defaultItemKind: ResourceType.service,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'Beard Trim',
        nameHi: 'दाढ़ी ट्रिम',
        category: 'Salon',
        categoryHi: 'सैलून',
        defaultUnits: 1,
        billingMode: BillingMode.fixed,
        rateAmount: 15000,
        defaultItemKind: ResourceType.service,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'Hair Color',
        nameHi: 'हेयर कलर',
        category: 'Salon',
        categoryHi: 'सैलून',
        defaultUnits: 1,
        billingMode: BillingMode.fixed,
        rateAmount: 80000,
        defaultItemKind: ResourceType.service,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'Spa Package',
        nameHi: 'स्पा पैकेज',
        category: 'Salon',
        categoryHi: 'सैलून',
        defaultUnits: 1,
        billingMode: BillingMode.fixed,
        rateAmount: 120000,
        defaultItemKind: ResourceType.service,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'Shampoo',
        nameHi: 'शैम्पू',
        category: 'Salon',
        categoryHi: 'सैलून',
        defaultUnits: 25,
        billingMode: BillingMode.fixed,
        rateAmount: 20000,
        defaultItemKind: ResourceType.sale,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'Monthly Membership',
        nameHi: 'मासिक सदस्यता',
        category: 'Salon',
        categoryHi: 'सैलून',
        defaultUnits: 20,
        billingMode: BillingMode.monthly,
        rateAmount: 150000,
        defaultItemKind: ResourceType.membership,
        requiresUnitIdentity: false,
      ),
    ],
  ),
  IndustryTemplate(
    id: 'mobile_repair',
    name: 'Mobile Repair',
    nameHi: 'मोबाइल मरम्मत',
    description: 'Phone repair jobs with parts counter and IMEI fields.',
    descriptionHi: 'फ़ोन मरम्मत जॉब, पार्ट्स काउंटर और IMEI फ़ील्ड।',
    defaultHomeModules: kJobHomeModules,
    workflowId: kJobWorkflowId,
    defaultReportWidgets: kJobReportWidgets,
    extraFieldIds: <String>[
      kFieldEstimatedDuration,
      kFieldImei,
      kFieldBarcode,
    ],
    enabledResourceTypesOverride: <ResourceType>[
      ResourceType.job,
      ResourceType.sale,
    ],
    items: <TemplateInventoryItem>[
      TemplateInventoryItem(
        name: 'Screen Replacement',
        nameHi: 'स्क्रीन रिप्लेसमेंट',
        category: 'Mobile Repair',
        categoryHi: 'मोबाइल मरम्मत',
        defaultUnits: 1,
        billingMode: BillingMode.fixed,
        rateAmount: 150000,
        defaultItemKind: ResourceType.job,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'Battery Replacement',
        nameHi: 'बैटरी रिप्लेसमेंट',
        category: 'Mobile Repair',
        categoryHi: 'मोबाइल मरम्मत',
        defaultUnits: 1,
        billingMode: BillingMode.fixed,
        rateAmount: 80000,
        defaultItemKind: ResourceType.job,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'Software Fix',
        nameHi: 'सॉफ़्टवेयर फिक्स',
        category: 'Mobile Repair',
        categoryHi: 'मोबाइल मरम्मत',
        defaultUnits: 1,
        billingMode: BillingMode.fixed,
        rateAmount: 40000,
        defaultItemKind: ResourceType.job,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'Tempered Glass',
        nameHi: 'टेम्पर्ड ग्लास',
        category: 'Mobile Repair',
        categoryHi: 'मोबाइल मरम्मत',
        defaultUnits: 30,
        billingMode: BillingMode.fixed,
        rateAmount: 20000,
        defaultItemKind: ResourceType.sale,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'Charging Port',
        nameHi: 'चार्जिंग पोर्ट',
        category: 'Mobile Repair',
        categoryHi: 'मोबाइल मरम्मत',
        defaultUnits: 15,
        billingMode: BillingMode.fixed,
        rateAmount: 35000,
        defaultItemKind: ResourceType.sale,
        requiresUnitIdentity: false,
      ),
    ],
  ),
  IndustryTemplate(
    id: 'laptop_repair',
    name: 'Laptop Repair',
    nameHi: 'लैपटॉप मरम्मत',
    description: 'Laptop repair jobs with accessories and password notes.',
    descriptionHi: 'लैपटॉप मरम्मत जॉब, एक्सेसरी और पासवर्ड नोट।',
    defaultHomeModules: kJobHomeModules,
    workflowId: kJobWorkflowId,
    defaultReportWidgets: kJobReportWidgets,
    extraFieldIds: <String>[
      kFieldEstimatedDuration,
      kFieldDevicePasswordNote,
      kFieldBarcode,
    ],
    enabledResourceTypesOverride: <ResourceType>[
      ResourceType.job,
      ResourceType.sale,
    ],
    items: <TemplateInventoryItem>[
      TemplateInventoryItem(
        name: 'OS Reinstall',
        nameHi: 'OS रीइंस्टॉल',
        category: 'Laptop Repair',
        categoryHi: 'लैपटॉप मरम्मत',
        defaultUnits: 1,
        billingMode: BillingMode.fixed,
        rateAmount: 100000,
        defaultItemKind: ResourceType.job,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'Keyboard Repair',
        nameHi: 'कीबोर्ड मरम्मत',
        category: 'Laptop Repair',
        categoryHi: 'लैपटॉप मरम्मत',
        defaultUnits: 1,
        billingMode: BillingMode.fixed,
        rateAmount: 120000,
        defaultItemKind: ResourceType.job,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'Data Recovery',
        nameHi: 'डेटा रिकवरी',
        category: 'Laptop Repair',
        categoryHi: 'लैपटॉप मरम्मत',
        defaultUnits: 1,
        billingMode: BillingMode.fixed,
        rateAmount: 200000,
        defaultItemKind: ResourceType.job,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'Laptop Charger',
        nameHi: 'लैपटॉप चार्जर',
        category: 'Laptop Repair',
        categoryHi: 'लैपटॉप मरम्मत',
        defaultUnits: 10,
        billingMode: BillingMode.fixed,
        rateAmount: 150000,
        defaultItemKind: ResourceType.sale,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'RAM Upgrade',
        nameHi: 'RAM अपग्रेड',
        category: 'Laptop Repair',
        categoryHi: 'लैपटॉप मरम्मत',
        defaultUnits: 8,
        billingMode: BillingMode.fixed,
        rateAmount: 250000,
        defaultItemKind: ResourceType.sale,
        requiresUnitIdentity: false,
      ),
    ],
  ),
  IndustryTemplate(
    id: 'tailor',
    name: 'Tailor',
    nameHi: 'दर्जी',
    description:
        'Stitching jobs with measurements, trial and delivery dates.',
    descriptionHi: 'सिलाई जॉब — नाप, ट्रायल और डिलीवरी तारीख सहित।',
    defaultHomeModules: kJobHomeModules,
    workflowId: kJobWorkflowId,
    defaultReportWidgets: kJobReportWidgets,
    extraFieldIds: <String>[
      kFieldEstimatedDuration,
      kFieldMeasurements,
      kFieldTrialDate,
      kFieldDeliveryDate,
    ],
    enabledResourceTypesOverride: <ResourceType>[
      ResourceType.job,
      ResourceType.sale,
    ],
    items: <TemplateInventoryItem>[
      TemplateInventoryItem(
        name: 'Blouse Stitching',
        nameHi: 'ब्लाउज सिलाई',
        category: 'Tailor',
        categoryHi: 'दर्जी',
        defaultUnits: 1,
        billingMode: BillingMode.fixed,
        rateAmount: 40000,
        defaultItemKind: ResourceType.job,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'Suit Stitching',
        nameHi: 'सूट सिलाई',
        category: 'Tailor',
        categoryHi: 'दर्जी',
        defaultUnits: 1,
        billingMode: BillingMode.fixed,
        rateAmount: 120000,
        defaultItemKind: ResourceType.job,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'Alteration',
        nameHi: 'अल्टरेशन',
        category: 'Tailor',
        categoryHi: 'दर्जी',
        defaultUnits: 1,
        billingMode: BillingMode.fixed,
        rateAmount: 20000,
        defaultItemKind: ResourceType.job,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'Buttons Pack',
        nameHi: 'बटन पैक',
        category: 'Tailor',
        categoryHi: 'दर्जी',
        defaultUnits: 50,
        billingMode: BillingMode.fixed,
        rateAmount: 5000,
        defaultItemKind: ResourceType.sale,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'Zipper',
        nameHi: 'जिपर',
        category: 'Tailor',
        categoryHi: 'दर्जी',
        defaultUnits: 40,
        billingMode: BillingMode.fixed,
        rateAmount: 3000,
        defaultItemKind: ResourceType.sale,
        requiresUnitIdentity: false,
      ),
    ],
  ),
  IndustryTemplate(
    id: 'mechanic',
    name: 'Mechanic',
    nameHi: 'मैकेनिक',
    description: 'Repair job tickets and parts counter.',
    descriptionHi: 'मरम्मत जॉब टिकट और पार्ट्स काउंटर।',
    defaultHomeModules: kJobHomeModules,
    workflowId: kJobWorkflowId,
    defaultReportWidgets: kJobReportWidgets,
    extraFieldIds: <String>[kFieldEstimatedDuration, kFieldBarcode],
    enabledResourceTypesOverride: <ResourceType>[
      ResourceType.job,
      ResourceType.sale,
      ResourceType.service,
    ],
    items: <TemplateInventoryItem>[
      TemplateInventoryItem(
        name: 'Oil Change',
        nameHi: 'ऑयल चेंज',
        category: 'Mechanic',
        categoryHi: 'मैकेनिक',
        defaultUnits: 1,
        billingMode: BillingMode.fixed,
        rateAmount: 50000,
        defaultItemKind: ResourceType.job,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'Brake Service',
        nameHi: 'ब्रेक सेवा',
        category: 'Mechanic',
        categoryHi: 'मैकेनिक',
        defaultUnits: 1,
        billingMode: BillingMode.fixed,
        rateAmount: 120000,
        defaultItemKind: ResourceType.job,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'Spare Part',
        nameHi: 'स्पेयर पार्ट',
        category: 'Mechanic',
        categoryHi: 'मैकेनिक',
        defaultUnits: 20,
        billingMode: BillingMode.fixed,
        rateAmount: 20000,
        defaultItemKind: ResourceType.sale,
        requiresUnitIdentity: false,
      ),
    ],
  ),
  IndustryTemplate(
    id: 'money_lending',
    name: 'Money Lending',
    nameHi: 'कर्ज / उधार',
    description:
        'Cash loans given and taken with interest calculator and dated payments.',
    descriptionHi:
        'दिए और लिए गए नकद कर्ज, ब्याज कैलकुलेटर और दिनांकित भुगतान।',
    defaultHomeModules: kMoneyLendingHomeModules,
    defaultReportWidgets: kMoneyLendingReportWidgets,
    enabledResourceTypesOverride: <ResourceType>[
      ResourceType.financial,
    ],
    items: <TemplateInventoryItem>[],
  ),
];

IndustryTemplate? industryTemplateById(String id) {
  for (final IndustryTemplate template in kIndustryTemplates) {
    if (template.id == id) {
      return template;
    }
  }
  return null;
}
