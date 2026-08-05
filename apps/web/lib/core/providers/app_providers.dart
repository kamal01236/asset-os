import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/app_database.dart';
import '../home/home_modules.dart';
import '../models/entities.dart';
import '../repositories/local_repository.dart';
import '../sharing/whatsapp_share.dart';

export '../home/home_modules.dart';
export '../home/home_filter.dart';

const String kLocalePrefsKey = 'asset_os_locale';
const String kThemeModePrefsKey = 'asset_os_theme_mode';
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

final depositLedgerProvider =
    StreamProvider.family<List<DepositLedgerEntry>, String>((ref, customerId) {
  return ref.watch(repositoryProvider).watchDepositLedger(customerId);
});

/// Bottom-nav tab indices for [currentTabIndexProvider].
const int kTabIndexHome = 0;
const int kTabIndexRentals = 1;
const int kTabIndexInventory = 2;
const int kTabIndexCustomers = 3;
const int kTabIndexMore = 4;

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

/// Persisted theme mode. Defaults to dark when missing or unsupported.
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.watch(sharedPreferencesProvider));
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._preferences)
      : super(_themeModeFromPrefs(_preferences));

  final SharedPreferences _preferences;

  static const Set<String> _supported = <String>{'dark', 'light'};

  static ThemeMode _themeModeFromPrefs(SharedPreferences preferences) {
    final String? raw = preferences.getString(kThemeModePrefsKey);
    if (raw == 'light') {
      return ThemeMode.light;
    }
    // Missing, invalid, or explicit "dark" → dark (app default).
    if (raw != null && !_supported.contains(raw)) {
      return ThemeMode.dark;
    }
    return ThemeMode.dark;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode != ThemeMode.dark && mode != ThemeMode.light) {
      return;
    }
    state = mode;
    await _preferences.setString(
      kThemeModePrefsKey,
      mode == ThemeMode.light ? 'light' : 'dark',
    );
  }
}

final homeModulesProvider =
    StateNotifierProvider<HomeModulesNotifier, List<HomeModuleId>>((ref) {
  return HomeModulesNotifier(ref.watch(sharedPreferencesProvider));
});

class HomeModulesNotifier extends StateNotifier<List<HomeModuleId>> {
  HomeModulesNotifier(this._preferences)
      : super(parseHomeModules(_preferences.getString(kHomeModulesPrefsKey)));

  final SharedPreferences _preferences;

  bool get isCustomized =>
      _preferences.getBool(kHomeModulesCustomizedKey) ?? false;

  Future<void> setModules(
    List<HomeModuleId> modules, {
    bool markCustomized = true,
  }) async {
    state = parseHomeModules(encodeHomeModules(modules));
    await _preferences.setString(kHomeModulesPrefsKey, encodeHomeModules(state));
    if (markCustomized) {
      await _preferences.setBool(kHomeModulesCustomizedKey, true);
    }
  }

  Future<void> setEnabled(HomeModuleId id, bool enabled) async {
    if (id == HomeModuleId.search) {
      return;
    }
    final List<HomeModuleId> next = List<HomeModuleId>.from(state);
    if (enabled) {
      if (!next.contains(id)) {
        next.add(id);
      }
    } else {
      next.remove(id);
    }
    await setModules(next);
  }

  Future<void> applyTemplateDefaults(List<HomeModuleId> defaults) async {
    await setModules(defaults, markCustomized: false);
    await _preferences.setBool(kHomeModulesCustomizedKey, false);
  }

  bool isEnabled(HomeModuleId id) => state.contains(id);
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

/// Whether first-load industry template onboarding is still required.
/// Bootstrapped in [main] / [bootContainer]; flipped false after template pick.
final needsIndustryOnboardingProvider = StateProvider<bool>((ref) => false);

/// App bootstrap: no legacy demo snapshot. Tests that need Priya/DSLR pass
/// [seedDemo] true via [bootContainer] / [bootRepo].
Future<LocalRepository> bootstrapRepository({
  AppDatabase? database,
  SharedPreferences? preferences,
  bool seedDemo = false,
}) async {
  final SharedPreferences prefs = preferences ?? await SharedPreferences.getInstance();
  final AppDatabase db = database ?? AppDatabase();
  final LocalRepository repository = LocalRepository(db, prefs);
  await repository.initialize(seedDemo: seedDemo);
  return repository;
}
