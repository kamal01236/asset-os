import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/app_database.dart';
import '../models/entities.dart';
import '../repositories/local_repository.dart';
import '../sharing/whatsapp_share.dart';

const String kLocalePrefsKey = 'asset_os_locale';
const String kOwnerWhatsAppPhoneKey = 'owner_whatsapp_phone';
const String kOwnerWhatsAppCountryCodeKey = 'owner_whatsapp_country_code';
const String kDefaultWhatsAppCountryCode = '91';

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

/// Persisted app locale. Defaults to English when missing or unsupported.
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier(ref.watch(sharedPreferencesProvider));
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(this._preferences) : super(_localeFromPrefs(_preferences));

  final SharedPreferences _preferences;

  static const List<String> supportedLanguageCodes = <String>['en', 'hi'];

  static Locale _localeFromPrefs(SharedPreferences preferences) {
    final String? code = preferences.getString(kLocalePrefsKey);
    if (code != null && supportedLanguageCodes.contains(code)) {
      return Locale(code);
    }
    return const Locale('en');
  }

  Future<void> setLocale(Locale locale) async {
    final String code = locale.languageCode;
    if (!supportedLanguageCodes.contains(code)) {
      return;
    }
    state = Locale(code);
    await _preferences.setString(kLocalePrefsKey, code);
  }
}

/// Owner WhatsApp number for share-to-self reports (digits + country code).
class OwnerWhatsAppSettings {
  const OwnerWhatsAppSettings({
    required this.phoneDigits,
    required this.countryCode,
  });

  /// Stored digits as entered (typically 10-digit local, or full E.164 digits).
  final String phoneDigits;

  /// Default country calling code without `+` (e.g. `91`).
  final String countryCode;

  /// Digits suitable for `wa.me` (10-digit local numbers get [countryCode] prefix).
  String get e164Digits => normalizeWhatsAppPhone(
        phoneDigits,
        countryCode: countryCode,
      );

  bool get isConfigured {
    final String local = phoneDigits.replaceAll(RegExp(r'\D'), '');
    return local.length >= 10;
  }
}

final ownerWhatsAppProvider =
    StateNotifierProvider<OwnerWhatsAppNotifier, OwnerWhatsAppSettings>((ref) {
  return OwnerWhatsAppNotifier(ref.watch(sharedPreferencesProvider));
});

class OwnerWhatsAppNotifier extends StateNotifier<OwnerWhatsAppSettings> {
  OwnerWhatsAppNotifier(this._preferences) : super(_fromPrefs(_preferences));

  final SharedPreferences _preferences;

  static OwnerWhatsAppSettings _fromPrefs(SharedPreferences preferences) {
    final String phone =
        preferences.getString(kOwnerWhatsAppPhoneKey) ?? '';
    final String country =
        preferences.getString(kOwnerWhatsAppCountryCodeKey) ??
            kDefaultWhatsAppCountryCode;
    return OwnerWhatsAppSettings(
      phoneDigits: phone.replaceAll(RegExp(r'\D'), ''),
      countryCode: country.replaceAll(RegExp(r'\D'), '').isEmpty
          ? kDefaultWhatsAppCountryCode
          : country.replaceAll(RegExp(r'\D'), ''),
    );
  }

  Future<void> setPhone(String rawPhone, {String? countryCode}) async {
    final String digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    final String cc = (countryCode ?? state.countryCode)
        .replaceAll(RegExp(r'\D'), '');
    final String resolvedCc =
        cc.isEmpty ? kDefaultWhatsAppCountryCode : cc;
    state = OwnerWhatsAppSettings(
      phoneDigits: digits,
      countryCode: resolvedCc,
    );
    await _preferences.setString(kOwnerWhatsAppPhoneKey, digits);
    await _preferences.setString(kOwnerWhatsAppCountryCodeKey, resolvedCc);
  }
}

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
