import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'presentation/app_shell.dart';
import 'domain/config/app_branding.dart';
import 'infrastructure/db/app_database.dart';
import 'l10n/app_localizations.dart';
import 'infrastructure/notifications/local_notifications.dart';
import 'application/providers/app_providers.dart';
import 'application/local_repository.dart';
import 'application/reminders/reminder_scheduler.dart';
import 'application/reminders/reminder_settings.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/features/onboarding/onboarding_wizard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initLocalNotifications();
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  final AppDatabase database = AppDatabase();
  final LocalRepository repository = await bootstrapRepository(
    database: database,
    preferences: preferences,
    seedDemo: false,
  );
  final bool needsOnboarding = await repository.needsIndustryOnboarding();

  if (!needsOnboarding) {
    final ReminderSettings settings =
        ReminderSettings.fromPreferences(preferences);
    final AppLocalizations l10n = lookupAppLocalizations(
      LocaleNotifier.supportedLanguageCodes.contains(
        preferences.getString(kLocalePrefsKey),
      )
          ? Locale(preferences.getString(kLocalePrefsKey)!)
          : const Locale('en'),
    );
    await ReminderScheduler(repository).refreshScheduledReminders(
      settings: settings,
      l10n: l10n,
    );
  }

  runApp(
    ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(preferences),
        databaseProvider.overrideWithValue(database),
        repositoryProvider.overrideWithValue(repository),
        needsIndustryOnboardingProvider.overrideWith((ref) => needsOnboarding),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Locale locale = ref.watch(localeProvider);
    final ThemeMode themeMode = ref.watch(themeModeProvider);
    final bool needsOnboarding = ref.watch(needsIndustryOnboardingProvider);
    return MaterialApp(
      title: kAppDisplayName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: needsOnboarding
          ? const OnboardingWizardScreen()
          : const AppShell(),
    );
  }
}
