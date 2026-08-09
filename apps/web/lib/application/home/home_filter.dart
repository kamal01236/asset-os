import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/entities.dart';

/// Status filter selected from Home KPI chips (optional in-place Home results).
/// Null means no Home filter.
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

/// Rentals tab list filter set from Home KPI taps.
enum RentalsListFilter {
  active,
  dueToday,
  overdue,
}

extension RentalsListFilterX on RentalsListFilter {
  AssetStatus get status {
    switch (this) {
      case RentalsListFilter.active:
        return AssetStatus.rented;
      case RentalsListFilter.dueToday:
        return AssetStatus.dueToday;
      case RentalsListFilter.overdue:
        return AssetStatus.overdue;
    }
  }
}

/// Inventory tab list filter set from Home KPI taps.
enum InventoryListFilter {
  available,
}

/// Optional Home in-place filter (Customize Home → Filter results module).
final homeFilterProvider = StateProvider<HomeFilter?>((ref) => null);

final rentalsListFilterProvider =
    StateProvider<RentalsListFilter?>((ref) => null);

final inventoryListFilterProvider =
    StateProvider<InventoryListFilter?>((ref) => null);
