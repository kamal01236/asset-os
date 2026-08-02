/// Static industry inventory packs for Business Templates (merge-into inventory).
class TemplateInventoryItem {
  const TemplateInventoryItem({
    required this.name,
    required this.category,
    required this.defaultUnits,
    this.notes,
  });

  final String name;
  final String category;
  final int defaultUnits;
  final String? notes;
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
      TemplateInventoryItem(name: 'Book', category: 'Library', defaultUnits: 10),
      TemplateInventoryItem(name: 'Journal', category: 'Library', defaultUnits: 5),
      TemplateInventoryItem(name: 'Magazine', category: 'Library', defaultUnits: 8),
      TemplateInventoryItem(name: 'Calculator', category: 'Library', defaultUnits: 4),
    ],
  ),
  IndustryTemplate(
    id: 'camera',
    name: 'Camera Rental',
    description: 'Photography gear for shoot-day rentals.',
    items: <TemplateInventoryItem>[
      TemplateInventoryItem(name: 'DSLR', category: 'Camera', defaultUnits: 3),
      TemplateInventoryItem(name: 'Lens', category: 'Camera', defaultUnits: 4),
      TemplateInventoryItem(name: 'Battery', category: 'Camera', defaultUnits: 6),
      TemplateInventoryItem(name: 'Memory Card', category: 'Camera', defaultUnits: 8),
      TemplateInventoryItem(name: 'Tripod', category: 'Camera', defaultUnits: 3),
    ],
  ),
  IndustryTemplate(
    id: 'farm',
    name: 'Farm Equipment',
    description: 'Field machinery and irrigation gear.',
    items: <TemplateInventoryItem>[
      TemplateInventoryItem(name: 'Tractor', category: 'Farm', defaultUnits: 1),
      TemplateInventoryItem(name: 'Seeder', category: 'Farm', defaultUnits: 2),
      TemplateInventoryItem(name: 'Rotavator', category: 'Farm', defaultUnits: 2),
      TemplateInventoryItem(name: 'Water Pump', category: 'Farm', defaultUnits: 3),
    ],
  ),
  IndustryTemplate(
    id: 'event',
    name: 'Event Rental',
    description: 'Seating, staging, and AV for events.',
    items: <TemplateInventoryItem>[
      TemplateInventoryItem(name: 'Chair', category: 'Event', defaultUnits: 50),
      TemplateInventoryItem(name: 'Table', category: 'Event', defaultUnits: 20),
      TemplateInventoryItem(name: 'Stage Panel', category: 'Event', defaultUnits: 8),
      TemplateInventoryItem(name: 'Speaker', category: 'Event', defaultUnits: 4),
      TemplateInventoryItem(name: 'LED Light', category: 'Event', defaultUnits: 6),
    ],
  ),
  IndustryTemplate(
    id: 'construction',
    name: 'Construction / Tools',
    description: 'Jobsite tools and safety kits.',
    items: <TemplateInventoryItem>[
      TemplateInventoryItem(name: 'Drill Kit', category: 'Tools', defaultUnits: 4),
      TemplateInventoryItem(name: 'Angle Grinder', category: 'Tools', defaultUnits: 3),
      TemplateInventoryItem(name: 'Ladder', category: 'Tools', defaultUnits: 3),
      TemplateInventoryItem(name: 'Safety Kit', category: 'Tools', defaultUnits: 5),
    ],
  ),
  IndustryTemplate(
    id: 'office',
    name: 'Office Assets',
    description: 'Shared office hardware and access gear.',
    items: <TemplateInventoryItem>[
      TemplateInventoryItem(name: 'Laptop', category: 'Office', defaultUnits: 5),
      TemplateInventoryItem(name: 'Monitor', category: 'Office', defaultUnits: 6),
      TemplateInventoryItem(name: 'Projector', category: 'Office', defaultUnits: 2),
      TemplateInventoryItem(name: 'Access Card', category: 'Office', defaultUnits: 20),
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
