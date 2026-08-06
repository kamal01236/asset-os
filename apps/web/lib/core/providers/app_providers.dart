import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/app_database.dart';
import '../home/home_modules.dart';
import '../models/entities.dart';
import '../repositories/local_repository.dart';
import '../sharing/whatsapp_share.dart';
import '../templates/field_defs.dart';
import '../templates/industry_templates.dart';
import '../templates/workflows.dart';
import '../reports/report_widgets.dart';

export '../home/home_modules.dart';
export '../home/home_filter.dart';
export '../loans/loan_models.dart';
export '../loans/loan_balance.dart'
    show computeLoanScenario, LoanScenario, LoanTimelineEvent, LoanTimelineKind;
export '../templates/industry_templates.dart'
    show
        kEnabledResourceTypesPrefsKey,
        encodeEnabledResourceTypes,
        parseEnabledResourceTypes,
        resolveEnabledResourceTypes,
        fulfillmentOptionsForEnabledTypes;
export '../templates/workflows.dart'
    show
        kActiveWorkflowIdPrefsKey,
        kDefaultWorkflowId,
        resolveWorkflow,
        WorkflowDefinition,
        WorkflowStatus;
export '../templates/field_defs.dart'
    show
        kExtraFieldIdsPrefsKey,
        FieldDef,
        FieldValueType,
        resolveExtraFields,
        parseExtraFieldIds,
        encodeExtraFieldIds;
export '../reports/report_widgets.dart'
    show
        kReportWidgetsPrefsKey,
        ReportWidgetId,
        resolveReportWidgets,
        parseReportWidgets,
        encodeReportWidgets,
        kDefaultReportWidgets;

const String kLocalePrefsKey = 'asset_os_locale';
const String kThemeModePrefsKey = 'asset_os_theme_mode';
const String kPreferredModePrefsKey = 'asset_os_preferred_mode';
const String kOwnerWhatsAppPhoneKey = 'owner_whatsapp_phone';
const String kOwnerWhatsAppCountryCodeKey = 'owner_whatsapp_country_code';
const String kDefaultWhatsAppCountryCode = '91';

/// First-load / preferred working mode (local-first vs cloud-ready path).
enum PreferredWorkingMode {
  offline,
  online;

  String get prefsValue => name;

  static PreferredWorkingMode fromPrefsValue(String? raw) {
    if (raw == PreferredWorkingMode.online.prefsValue) {
      return PreferredWorkingMode.online;
    }
    // Missing or unknown → offline (product offline-first default).
    return PreferredWorkingMode.offline;
  }
}

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

final moneyLoansProvider = StreamProvider<List<MoneyLoan>>((ref) {
  return ref.watch(repositoryProvider).watchMoneyLoans();
});

final moneyLoansForCustomerProvider =
    StreamProvider.family<List<MoneyLoan>, String>((ref, customerId) {
  return ref.watch(repositoryProvider).watchMoneyLoans(customerId: customerId);
});

final depositLedgerProvider =
    StreamProvider.family<List<DepositLedgerEntry>, String>((ref, customerId) {
  return ref.watch(repositoryProvider).watchDepositLedger(customerId);
});

/// Bottom-nav tab indices for [currentTabIndexProvider].
const int kTabIndexHome = 0;
const int kTabIndexRentals = 1;
/// Alias: tab 1 is the unified Transactions surface (orders + loans).
const int kTabIndexTransactions = kTabIndexRentals;
const int kTabIndexInventory = 2;
const int kTabIndexCustomers = 3;
const int kTabIndexMore = 4;

/// Type filter on the Transactions tab (More → Loans deep-links to [loans]).
enum TransactionsTypeFilter { all, orders, loans }

final transactionsTypeFilterProvider =
    StateProvider<TransactionsTypeFilter>((ref) => TransactionsTypeFilter.all);

final currentTabIndexProvider = StateProvider<int>((ref) => 0);

final offlineModeProvider = StateProvider<bool>((ref) => false);

/// Persisted Offline / Online preference from first-load onboarding.
/// Maps to [offlineModeProvider] when set (offline → true, online → false).
final preferredModeProvider =
    StateNotifierProvider<PreferredModeNotifier, PreferredWorkingMode>((ref) {
  return PreferredModeNotifier(ref.watch(sharedPreferencesProvider), ref);
});

class PreferredModeNotifier extends StateNotifier<PreferredWorkingMode> {
  PreferredModeNotifier(this._preferences, this._ref)
      : super(
          PreferredWorkingMode.fromPrefsValue(
            _preferences.getString(kPreferredModePrefsKey),
          ),
        ) {
    if (_preferences.containsKey(kPreferredModePrefsKey)) {
      // Defer so sibling providers finish constructing.
      Future.microtask(() => _syncOfflineFlag(state));
    }
  }

  final SharedPreferences _preferences;
  final Ref _ref;

  Future<void> setMode(PreferredWorkingMode mode) async {
    state = mode;
    await _preferences.setString(kPreferredModePrefsKey, mode.prefsValue);
    _syncOfflineFlag(mode);
  }

  void _syncOfflineFlag(PreferredWorkingMode mode) {
    _ref.read(offlineModeProvider.notifier).state =
        mode == PreferredWorkingMode.offline;
  }
}

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

final enabledResourceTypesProvider =
    StateNotifierProvider<EnabledResourceTypesNotifier, List<ResourceType>>(
  (ref) {
    return EnabledResourceTypesNotifier(
      ref.watch(sharedPreferencesProvider),
    );
  },
);

class EnabledResourceTypesNotifier extends StateNotifier<List<ResourceType>> {
  EnabledResourceTypesNotifier(this._preferences)
      : super(
          resolveEnabledResourceTypes(
            prefsRaw: _preferences.getString(kEnabledResourceTypesPrefsKey),
          ),
        );

  final SharedPreferences _preferences;

  Future<void> setTypes(List<ResourceType> types) async {
    state = resourceTypesFromItems(types);
    await _preferences.setString(
      kEnabledResourceTypesPrefsKey,
      encodeEnabledResourceTypes(state),
    );
  }

  /// Replace with a template pack's enabled set (full apply / onboarding).
  Future<void> applyTemplateTypes(List<ResourceType> types) async {
    await setTypes(types);
  }

  /// Union without shrinking (partial Business Templates merge).
  Future<void> unionTypes(Iterable<ResourceType> extra) async {
    await setTypes(resourceTypesFromItems(<ResourceType>[...state, ...extra]));
  }

  /// Toggle one type from More → Enabled resource types. Keeps at least one.
  Future<void> setTypeEnabled(ResourceType type, bool enabled) async {
    if (enabled) {
      if (state.contains(type)) {
        return;
      }
      await setTypes(<ResourceType>[...state, type]);
      return;
    }
    if (!state.contains(type) || state.length <= 1) {
      return;
    }
    await setTypes(
      state.where((ResourceType t) => t != type).toList(),
    );
  }

  bool isTypeEnabled(ResourceType type) => state.contains(type);
}

final activeWorkflowProvider =
    StateNotifierProvider<ActiveWorkflowNotifier, WorkflowDefinition>((ref) {
  return ActiveWorkflowNotifier(ref.watch(sharedPreferencesProvider));
});

class ActiveWorkflowNotifier extends StateNotifier<WorkflowDefinition> {
  ActiveWorkflowNotifier(this._preferences)
      : super(
          resolveWorkflow(
            prefsId: _preferences.getString(kActiveWorkflowIdPrefsKey),
          ),
        );

  final SharedPreferences _preferences;

  Future<void> setWorkflowId(String workflowId) async {
    final WorkflowDefinition workflow = resolveWorkflow(prefsId: workflowId);
    state = workflow;
    await _preferences.setString(kActiveWorkflowIdPrefsKey, workflow.id);
  }

  Future<void> applyTemplateWorkflow(String workflowId) async {
    await setWorkflowId(workflowId);
  }
}

final extraFieldIdsProvider =
    StateNotifierProvider<ExtraFieldIdsNotifier, List<String>>((ref) {
  return ExtraFieldIdsNotifier(ref.watch(sharedPreferencesProvider));
});

class ExtraFieldIdsNotifier extends StateNotifier<List<String>> {
  ExtraFieldIdsNotifier(this._preferences)
      : super(parseExtraFieldIds(_preferences.getString(kExtraFieldIdsPrefsKey)));

  final SharedPreferences _preferences;

  Future<void> setIds(List<String> ids) async {
    final List<String> next = parseExtraFieldIds(encodeExtraFieldIds(ids));
    state = next;
    await _preferences.setString(kExtraFieldIdsPrefsKey, encodeExtraFieldIds(next));
  }

  Future<void> applyTemplateFields(List<String> ids) async {
    await setIds(ids);
  }
}

final reportWidgetsProvider =
    StateNotifierProvider<ReportWidgetsNotifier, List<ReportWidgetId>>((ref) {
  return ReportWidgetsNotifier(ref.watch(sharedPreferencesProvider));
});

class ReportWidgetsNotifier extends StateNotifier<List<ReportWidgetId>> {
  ReportWidgetsNotifier(this._preferences)
      : super(
          resolveReportWidgets(
            prefsRaw: _preferences.getString(kReportWidgetsPrefsKey),
          ),
        );

  final SharedPreferences _preferences;

  Future<void> setWidgets(List<ReportWidgetId> widgets) async {
    final List<ReportWidgetId> next = parseReportWidgets(
      encodeReportWidgets(widgets),
    );
    state = next;
    await _preferences.setString(
      kReportWidgetsPrefsKey,
      encodeReportWidgets(next),
    );
  }

  Future<void> applyTemplateWidgets(List<ReportWidgetId> widgets) async {
    await setWidgets(widgets);
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
