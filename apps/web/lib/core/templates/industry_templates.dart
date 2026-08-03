import '../pricing/rental_pricing.dart';

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
}

class IndustryTemplate {
  const IndustryTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.items,
  });

  final String id;
  final String name;
  final String description;
  final List<TemplateInventoryItem> items;
}

const List<IndustryTemplate> kIndustryTemplates = <IndustryTemplate>[
  IndustryTemplate(
    id: 'library',
    name: 'Library',
    description: 'Books and study materials for lending counters.',
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
];

IndustryTemplate? industryTemplateById(String id) {
  for (final IndustryTemplate template in kIndustryTemplates) {
    if (template.id == id) {
      return template;
    }
  }
  return null;
}
