/// Pluggable sections that compose the Home screen.
enum HomeModuleId {
  search,
  kpis,
  filterResults,
  needsAttention,
  pendingJobs,
  quickActions,
  recentActivity,
  suggestions,
}

const String kHomeModulesPrefsKey = 'asset_os_home_modules';
const String kHomeModulesCustomizedKey = 'asset_os_home_modules_customized';

/// Default enabled set for Generic / Camera-style templates.
/// KPIs navigate to filtered Rentals/Inventory tabs; in-place filterResults
/// stays optional via Customize Home. Quick actions and pending jobs stay
/// available via Customize Home (FAB covers New Order / Return).
const List<HomeModuleId> kDefaultHomeModules = <HomeModuleId>[
  HomeModuleId.search,
  HomeModuleId.kpis,
  HomeModuleId.needsAttention,
];

/// Library template adds recent activity for borrow/return tracking feel.
const List<HomeModuleId> kLibraryHomeModules = <HomeModuleId>[
  HomeModuleId.search,
  HomeModuleId.kpis,
  HomeModuleId.needsAttention,
  HomeModuleId.recentActivity,
];

/// Modules the user can toggle in Customize Home (search stays locked on).
const List<HomeModuleId> kRemovableHomeModules = <HomeModuleId>[
  HomeModuleId.kpis,
  HomeModuleId.filterResults,
  HomeModuleId.needsAttention,
  HomeModuleId.pendingJobs,
  HomeModuleId.quickActions,
  HomeModuleId.recentActivity,
  HomeModuleId.suggestions,
];

List<HomeModuleId> parseHomeModules(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return List<HomeModuleId>.from(kDefaultHomeModules);
  }
  final List<HomeModuleId> parsed = <HomeModuleId>[];
  for (final String part in raw.split(',')) {
    final String id = part.trim();
    for (final HomeModuleId module in HomeModuleId.values) {
      if (module.name == id) {
        parsed.add(module);
        break;
      }
    }
  }
  if (!parsed.contains(HomeModuleId.search)) {
    parsed.insert(0, HomeModuleId.search);
  }
  return parsed.isEmpty ? List<HomeModuleId>.from(kDefaultHomeModules) : parsed;
}

String encodeHomeModules(List<HomeModuleId> modules) {
  final Set<HomeModuleId> unique = <HomeModuleId>{};
  final List<HomeModuleId> ordered = <HomeModuleId>[];
  for (final HomeModuleId id in modules) {
    if (unique.add(id)) {
      ordered.add(id);
    }
  }
  if (!unique.contains(HomeModuleId.search)) {
    ordered.insert(0, HomeModuleId.search);
  }
  return ordered.map((HomeModuleId id) => id.name).join(',');
}
