import 'package:flutter/widgets.dart';

import '../home/home_modules.dart';
import '../models/entities.dart';

bool _isHindi(Locale locale) => locale.languageCode == 'hi';

/// Static industry inventory packs for Business Templates (merge-into inventory).
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
    this.defaultItemKind = InventoryItemKind.rental,
    this.requiresUnitIdentity = false,
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
  final InventoryItemKind defaultItemKind;
  final bool requiresUnitIdentity;
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
      dueDateOptional: dueDateOptional,
    );
  }
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
  });

  final String id;
  final String name;
  final String nameHi;
  final String description;
  final String descriptionHi;
  final List<TemplateInventoryItem> items;

  /// Home layout defaults applied when the user accepts the template layout.
  final List<HomeModuleId> defaultHomeModules;

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
    description: 'Books and study materials for lending counters.',
    descriptionHi: 'उधार काउंटर के लिए किताबें और अध्ययन सामग्री।',
    defaultHomeModules: kLibraryHomeModules,
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
    ],
  ),
  IndustryTemplate(
    id: 'camera',
    name: 'Camera Rental',
    nameHi: 'कैमरा किराया',
    description: 'Photography gear for shoot-day rentals.',
    descriptionHi: 'शूट के दिन किराए के लिए फोटोग्राफी गियर।',
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
    description: 'Field machinery and irrigation gear.',
    descriptionHi: 'खेत की मशीनरी और सिंचाई का सामान।',
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
    id: 'construction',
    name: 'Construction / Tools',
    nameHi: 'निर्माण / औजार',
    description: 'Jobsite tools and safety kits.',
    descriptionHi: 'साइट के औजार और सुरक्षा किट।',
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
    description: 'Service packages plus chair and kit rentals.',
    descriptionHi: 'सेवा पैकेज तथा कुर्सी और किट किराया।',
    defaultHomeModules: kLibraryHomeModules,
    items: <TemplateInventoryItem>[
      TemplateInventoryItem(
        name: 'Haircut',
        nameHi: 'हेयरकट',
        category: 'Parlour',
        categoryHi: 'पार्लर',
        defaultUnits: 1,
        billingMode: BillingMode.fixed,
        rateAmount: 30000, // ₹300
        defaultItemKind: InventoryItemKind.job,
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
        defaultItemKind: InventoryItemKind.job,
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
        defaultItemKind: InventoryItemKind.job,
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
        defaultItemKind: InventoryItemKind.job,
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
    defaultHomeModules: kLibraryHomeModules,
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
    defaultHomeModules: kLibraryHomeModules,
    items: <TemplateInventoryItem>[
      TemplateInventoryItem(
        name: 'Monthly Membership',
        nameHi: 'मासिक सदस्यता',
        category: 'Gym',
        categoryHi: 'जिम',
        defaultUnits: 50,
        billingMode: BillingMode.monthly,
        rateAmount: 150000, // ₹1,500/month
        defaultItemKind: InventoryItemKind.general,
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
        defaultItemKind: InventoryItemKind.general,
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
        defaultItemKind: InventoryItemKind.general,
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
        defaultItemKind: InventoryItemKind.general,
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
];

IndustryTemplate? industryTemplateById(String id) {
  for (final IndustryTemplate template in kIndustryTemplates) {
    if (template.id == id) {
      return template;
    }
  }
  return null;
}
