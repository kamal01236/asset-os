import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/app_database.dart';
import '../models/entities.dart';
import '../repositories/local_repository.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in ProviderScope.');
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final AppDatabase db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final repositoryProvider = Provider<LocalRepository>((ref) {
  throw UnimplementedError('LocalRepository must be overridden after bootstrap.');
});

final customersProvider = StreamProvider<List<Customer>>((ref) {
  return ref.watch(repositoryProvider).watchCustomers();
});

final inventoryProvider = StreamProvider<List<InventoryItem>>((ref) {
  return ref.watch(repositoryProvider).watchInventory();
});

final rentalsProvider = StreamProvider<List<Rental>>((ref) {
  return ref.watch(repositoryProvider).watchRentals();
});

final currentTabIndexProvider = StateProvider<int>((ref) => 0);

final offlineModeProvider = StateProvider<bool>((ref) => false);

int summaryCount({
  required AssetStatus status,
  required List<InventoryItem> inventory,
  required List<Rental> rentals,
  DateTime? now,
}) {
  final DateTime clock = now ?? DateTime.now();
  switch (status) {
    case AssetStatus.available:
      return inventory.where((item) => item.availableUnits > 0).length;
    case AssetStatus.rented:
      return rentals.where((rental) => rental.statusFor(clock) == AssetStatus.rented).length;
    case AssetStatus.dueToday:
      return rentals.where((rental) => rental.statusFor(clock) == AssetStatus.dueToday).length;
    case AssetStatus.overdue:
      return rentals.where((rental) => rental.statusFor(clock) == AssetStatus.overdue).length;
    case AssetStatus.archived:
      return rentals.where((rental) => !rental.isActive).length;
  }
}

Future<LocalRepository> bootstrapRepository({
  AppDatabase? database,
  SharedPreferences? preferences,
}) async {
  final SharedPreferences prefs = preferences ?? await SharedPreferences.getInstance();
  final AppDatabase db = database ?? AppDatabase();
  final LocalRepository repository = LocalRepository(db, prefs);
  await repository.initialize();
  return repository;
}
