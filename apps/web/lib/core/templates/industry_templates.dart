import '../home/home_modules.dart';
import '../models/entities.dart';

/// Static industry inventory packs for Business Templates (merge-into inventory).
class TemplateInventoryItem {
  const TemplateInventoryItem({
    required this.name,
    required this.category,
    required this.defaultUnits,
    this.notes,
    this.billingMode = BillingMode.weekly,
    this.rateAmount = 0,
    this.lateFeePerDay = 0,
    this.currencyCode = 'INR',
    this.defaultItemKind = InventoryItemKind.rental,
    this.requiresUnitIdentity = true,
    this.dueDateOptional = false,
  });

  final String name;
  final String category;
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
}

class IndustryTemplate {
  const IndustryTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.items,
    this.defaultHomeModules = kDefaultHomeModules,
  });

  final String id;
  final String name;
  final String description;
  final List<TemplateInventoryItem> items;

  /// Home layout defaults applied when the user accepts the template layout.
  final List<HomeModuleId> defaultHomeModules;
}

const List<IndustryTemplate> kIndustryTemplates = <IndustryTemplate>[
  IndustryTemplate(
    id: 'library',
    name: 'Library',
    description: 'Books and study materials for lending counters.',
    defaultHomeModules: kLibraryHomeModules,
    items: <TemplateInventoryItem>[
      TemplateInventoryItem(
        name: 'Novel',
        category: 'Library',
        defaultUnits: 20,
        billingMode: BillingMode.weekly,
        rateAmount: 5000, // ₹50/week
        lateFeePerDay: 500, // ₹5/day
      ),
      TemplateInventoryItem(
        name: 'Book',
        category: 'Library',
        defaultUnits: 10,
        billingMode: BillingMode.weekly,
        rateAmount: 3000,
      ),
      TemplateInventoryItem(
        name: 'Journal',
        category: 'Library',
        defaultUnits: 5,
        billingMode: BillingMode.weekly,
        rateAmount: 2000,
      ),
      TemplateInventoryItem(
        name: 'Magazine',
        category: 'Library',
        defaultUnits: 8,
        billingMode: BillingMode.weekly,
        rateAmount: 1500,
      ),
      TemplateInventoryItem(
        name: 'Calculator',
        category: 'Library',
        defaultUnits: 4,
        billingMode: BillingMode.daily,
        rateAmount: 1000,
      ),
    ],
  ),
  IndustryTemplate(
    id: 'camera',
    name: 'Camera Rental',
    description: 'Photography gear for shoot-day rentals.',
    items: <TemplateInventoryItem>[
      TemplateInventoryItem(
        name: 'DSLR',
        category: 'Camera',
        defaultUnits: 3,
        billingMode: BillingMode.daily,
        rateAmount: 150000,
        lateFeePerDay: 20000,
      ),
      TemplateInventoryItem(
        name: 'Lens',
        category: 'Camera',
        defaultUnits: 4,
        billingMode: BillingMode.daily,
        rateAmount: 80000,
      ),
      TemplateInventoryItem(
        name: 'Battery',
        category: 'Camera',
        defaultUnits: 6,
        billingMode: BillingMode.daily,
        rateAmount: 5000,
      ),
      TemplateInventoryItem(
        name: 'Memory Card',
        category: 'Camera',
        defaultUnits: 8,
        billingMode: BillingMode.daily,
        rateAmount: 3000,
      ),
      TemplateInventoryItem(
        name: 'Tripod',
        category: 'Camera',
        defaultUnits: 3,
        billingMode: BillingMode.daily,
        rateAmount: 20000,
      ),
    ],
  ),
  IndustryTemplate(
    id: 'farm',
    name: 'Farm Equipment',
    description: 'Field machinery and irrigation gear.',
    items: <TemplateInventoryItem>[
      TemplateInventoryItem(
        name: 'Tractor',
        category: 'Farm',
        defaultUnits: 1,
        billingMode: BillingMode.daily,
        rateAmount: 500000,
        lateFeePerDay: 50000,
      ),
      TemplateInventoryItem(
        name: 'Seeder',
        category: 'Farm',
        defaultUnits: 2,
        billingMode: BillingMode.daily,
        rateAmount: 150000,
      ),
      TemplateInventoryItem(
        name: 'Rotavator',
        category: 'Farm',
        defaultUnits: 2,
        billingMode: BillingMode.daily,
        rateAmount: 200000,
      ),
      TemplateInventoryItem(
        name: 'Water Pump',
        category: 'Farm',
        defaultUnits: 3,
        billingMode: BillingMode.daily,
        rateAmount: 80000,
      ),
    ],
  ),
  IndustryTemplate(
    id: 'event',
    name: 'Event Rental',
    description: 'Seating, staging, and AV for events.',
    items: <TemplateInventoryItem>[
      TemplateInventoryItem(
        name: 'Chair',
        category: 'Event',
        defaultUnits: 50,
        billingMode: BillingMode.fixed,
        rateAmount: 2000,
      ),
      TemplateInventoryItem(
        name: 'Table',
        category: 'Event',
        defaultUnits: 20,
        billingMode: BillingMode.fixed,
        rateAmount: 10000,
      ),
      TemplateInventoryItem(
        name: 'Stage Panel',
        category: 'Event',
        defaultUnits: 8,
        billingMode: BillingMode.daily,
        rateAmount: 50000,
      ),
      TemplateInventoryItem(
        name: 'Speaker',
        category: 'Event',
        defaultUnits: 4,
        billingMode: BillingMode.daily,
        rateAmount: 100000,
      ),
      TemplateInventoryItem(
        name: 'LED Light',
        category: 'Event',
        defaultUnits: 6,
        billingMode: BillingMode.daily,
        rateAmount: 40000,
      ),
    ],
  ),
  IndustryTemplate(
    id: 'construction',
    name: 'Construction / Tools',
    description: 'Jobsite tools and safety kits.',
    items: <TemplateInventoryItem>[
      TemplateInventoryItem(
        name: 'Drill Kit',
        category: 'Tools',
        defaultUnits: 4,
        billingMode: BillingMode.daily,
        rateAmount: 25000,
        lateFeePerDay: 5000,
      ),
      TemplateInventoryItem(
        name: 'Angle Grinder',
        category: 'Tools',
        defaultUnits: 3,
        billingMode: BillingMode.daily,
        rateAmount: 30000,
      ),
      TemplateInventoryItem(
        name: 'Ladder',
        category: 'Tools',
        defaultUnits: 3,
        billingMode: BillingMode.daily,
        rateAmount: 15000,
      ),
      TemplateInventoryItem(
        name: 'Safety Kit',
        category: 'Tools',
        defaultUnits: 5,
        billingMode: BillingMode.fixed,
        rateAmount: 10000,
      ),
    ],
  ),
  IndustryTemplate(
    id: 'office',
    name: 'Office Assets',
    description: 'Shared office hardware and access gear.',
    items: <TemplateInventoryItem>[
      TemplateInventoryItem(
        name: 'Laptop',
        category: 'Office',
        defaultUnits: 5,
        billingMode: BillingMode.weekly,
        rateAmount: 200000,
        lateFeePerDay: 10000,
      ),
      TemplateInventoryItem(
        name: 'Monitor',
        category: 'Office',
        defaultUnits: 6,
        billingMode: BillingMode.weekly,
        rateAmount: 50000,
      ),
      TemplateInventoryItem(
        name: 'Projector',
        category: 'Office',
        defaultUnits: 2,
        billingMode: BillingMode.daily,
        rateAmount: 100000,
      ),
      TemplateInventoryItem(
        name: 'Access Card',
        category: 'Office',
        defaultUnits: 20,
        billingMode: BillingMode.fixed,
        rateAmount: 5000,
      ),
    ],
  ),
  IndustryTemplate(
    id: 'parlour',
    name: 'Beauty Parlour',
    description: 'Service packages plus chair and kit rentals.',
    defaultHomeModules: kLibraryHomeModules,
    items: <TemplateInventoryItem>[
      TemplateInventoryItem(
        name: 'Haircut',
        category: 'Parlour',
        defaultUnits: 1,
        billingMode: BillingMode.fixed,
        rateAmount: 30000, // ₹300
        defaultItemKind: InventoryItemKind.general,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'Facial',
        category: 'Parlour',
        defaultUnits: 1,
        billingMode: BillingMode.fixed,
        rateAmount: 80000, // ₹800
        defaultItemKind: InventoryItemKind.general,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'Manicure',
        category: 'Parlour',
        defaultUnits: 1,
        billingMode: BillingMode.fixed,
        rateAmount: 40000, // ₹400
        defaultItemKind: InventoryItemKind.general,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'Bridal Package',
        category: 'Parlour',
        defaultUnits: 1,
        billingMode: BillingMode.fixed,
        rateAmount: 1500000, // ₹15,000
        defaultItemKind: InventoryItemKind.general,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'Steamer Kit',
        category: 'Parlour',
        defaultUnits: 2,
        billingMode: BillingMode.daily,
        rateAmount: 20000, // ₹200/day
        lateFeePerDay: 5000,
      ),
      TemplateInventoryItem(
        name: 'Chair',
        category: 'Parlour',
        defaultUnits: 4,
        billingMode: BillingMode.daily,
        rateAmount: 50000, // ₹500/day
      ),
    ],
  ),
  IndustryTemplate(
    id: 'boutique',
    name: 'Boutique',
    description: 'Garment and accessory rental for occasions.',
    defaultHomeModules: kLibraryHomeModules,
    items: <TemplateInventoryItem>[
      TemplateInventoryItem(
        name: 'Lehenga',
        category: 'Boutique',
        defaultUnits: 8,
        billingMode: BillingMode.weekly,
        rateAmount: 200000, // ₹2,000/week
        lateFeePerDay: 20000,
        requiresUnitIdentity: true,
      ),
      TemplateInventoryItem(
        name: 'Saree',
        category: 'Boutique',
        defaultUnits: 12,
        billingMode: BillingMode.weekly,
        rateAmount: 80000, // ₹800/week
        lateFeePerDay: 10000,
        requiresUnitIdentity: true,
      ),
      TemplateInventoryItem(
        name: 'Suit Set',
        category: 'Boutique',
        defaultUnits: 10,
        billingMode: BillingMode.weekly,
        rateAmount: 100000, // ₹1,000/week
        requiresUnitIdentity: true,
      ),
      TemplateInventoryItem(
        name: 'Dupatta',
        category: 'Boutique',
        defaultUnits: 15,
        billingMode: BillingMode.daily,
        rateAmount: 10000, // ₹100/day
        requiresUnitIdentity: true,
      ),
      TemplateInventoryItem(
        name: 'Jewellery Set',
        category: 'Boutique',
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
    description: 'Membership fee products and locker rentals.',
    defaultHomeModules: kLibraryHomeModules,
    items: <TemplateInventoryItem>[
      TemplateInventoryItem(
        name: 'Monthly Membership',
        category: 'Gym',
        defaultUnits: 50,
        billingMode: BillingMode.monthly,
        rateAmount: 150000, // ₹1,500/month
        defaultItemKind: InventoryItemKind.general,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'Quarterly Membership',
        category: 'Gym',
        defaultUnits: 30,
        billingMode: BillingMode.fixed,
        rateAmount: 400000, // ₹4,000
        defaultItemKind: InventoryItemKind.general,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'Annual Membership',
        category: 'Gym',
        defaultUnits: 20,
        billingMode: BillingMode.fixed,
        rateAmount: 1200000, // ₹12,000
        defaultItemKind: InventoryItemKind.general,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'Day Pass',
        category: 'Gym',
        defaultUnits: 100,
        billingMode: BillingMode.fixed,
        rateAmount: 30000, // ₹300
        defaultItemKind: InventoryItemKind.general,
        requiresUnitIdentity: false,
      ),
      TemplateInventoryItem(
        name: 'Locker',
        category: 'Gym',
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
