import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/entities.dart';

/// Status filter selected from Home KPI cards. Null means no filter.
enum HomeFilter {
  active,
  dueToday,
  overdue,
  available,
}

extension HomeFilterX on HomeFilter {
  AssetStatus get status {
    switch (this) {
      case HomeFilter.active:
        return AssetStatus.rented;
      case HomeFilter.dueToday:
        return AssetStatus.dueToday;
      case HomeFilter.overdue:
        return AssetStatus.overdue;
      case HomeFilter.available:
        return AssetStatus.available;
    }
  }
}

final homeFilterProvider = StateProvider<HomeFilter?>((ref) => null);
