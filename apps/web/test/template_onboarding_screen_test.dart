@Tags(['integration', 'shell'])
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:asset_os/presentation/app_shell.dart';
import 'package:asset_os/domain/config/app_branding.dart';
import 'package:asset_os/infrastructure/l10n/l10n_ext.dart';
import 'package:asset_os/application/providers/app_providers.dart';
import 'package:asset_os/presentation/theme/app_theme.dart';
import 'package:asset_os/presentation/features/onboarding/onboarding_wizard_screen.dart';
import 'package:asset_os/presentation/features/onboarding/template_onboarding_screen.dart';
import 'package:asset_os/main.dart';

import 'support/test_harness.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('TemplateOnboardingBody lists industry packs', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final ProviderContainer container = await bootContainer(seedDemo: false);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.dark,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(
            body: TemplateOnboardingBody(showBrandHeader: true),
          ),
        ),
      ),
    );
    await pumpFrames(tester);

    expect(find.text(kAppDisplayName), findsOneWidget);
    expect(find.text('Choose your business type'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Camera Rental'), findsOneWidget);
  });

  testWidgets('MainApp shows wizard when empty; AppShell when seeded', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final ProviderContainer empty = await bootContainer(seedDemo: false);
    expect(empty.read(needsIndustryOnboardingProvider), isTrue);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: empty,
        child: const MainApp(),
      ),
    );
    await pumpFrames(tester);
    expect(find.byType(OnboardingWizardScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
    expect(find.text('Choose your language'), findsOneWidget);

    final ProviderContainer seeded = await bootContainer(seedDemo: true);
    expect(seeded.read(needsIndustryOnboardingProvider), isFalse);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: seeded,
        child: const MainApp(),
      ),
    );
    await pumpFrames(tester);
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(OnboardingWizardScreen), findsNothing);
  });

  testWidgets('Offline path skips WhatsApp and reaches templates', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final ProviderContainer container = await bootContainer(seedDemo: false);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MainApp(),
      ),
    );
    await pumpFrames(tester);

    expect(find.text('Step 1 of 3'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await pumpFrames(tester);

    expect(find.text('How do you want to work?'), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);
    // Offline is default — continue straight to templates.
    await tester.tap(find.text('Continue'));
    await pumpFrames(tester);

    expect(find.text('Choose your business type'), findsOneWidget);
    expect(find.text('Your WhatsApp number'), findsNothing);
    expect(find.text('Step 3 of 3'), findsOneWidget);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(kPreferredModePrefsKey), 'offline');
    expect(container.read(offlineModeProvider), isTrue);
  });

  testWidgets('Online path requires WhatsApp before templates', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final ProviderContainer container = await bootContainer(seedDemo: false);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MainApp(),
      ),
    );
    await pumpFrames(tester);

    await tester.tap(find.text('Continue'));
    await pumpFrames(tester);

    await tester.tap(find.text('Online'));
    await pumpFrames(tester);
    await tester.tap(find.text('Continue'));
    await pumpFrames(tester);

    expect(find.text('Your WhatsApp number'), findsOneWidget);
    expect(find.textContaining('OTP later'), findsOneWidget);
    expect(find.text('Step 3 of 4'), findsOneWidget);

    // Empty / invalid blocks continue.
    await tester.tap(find.text('Continue'));
    await pumpFrames(tester);
    expect(find.text('Enter a valid 10-digit (or full) mobile number.'), findsOneWidget);
    expect(find.text('Choose your business type'), findsNothing);

    await tester.enterText(find.byType(TextField).first, '9876543210');
    await tester.tap(find.text('Continue'));
    await pumpFrames(tester);

    expect(find.text('Choose your business type'), findsOneWidget);
    expect(find.text('Step 4 of 4'), findsOneWidget);
    expect(container.read(ownerWhatsAppProvider).phoneDigits, '9876543210');
    expect(container.read(preferredModeProvider), PreferredWorkingMode.online);
    expect(container.read(offlineModeProvider), isFalse);
  });

  test('needsIndustryOnboardingProvider override is mutable', () async {
    final ProviderContainer container = await bootContainer(seedDemo: false);
    expect(container.read(needsIndustryOnboardingProvider), isTrue);
    container.read(needsIndustryOnboardingProvider.notifier).state = false;
    expect(container.read(needsIndustryOnboardingProvider), isFalse);
  });

  testWidgets('TemplateOnboardingBody confirm clears gate', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final ProviderContainer container = await bootContainer(seedDemo: false);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.dark,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const TemplateOnboardingScreen(),
        ),
      ),
    );
    await pumpFrames(tester);

    await tester.tap(find.text('Library'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Use this template'));
    await tester.pump();
    // Drift writes need the real async zone; spinner would hang pumpAndSettle.
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await pumpFrames(tester, frames: 20);

    expect(container.read(needsIndustryOnboardingProvider), isFalse);
  });

  testWidgets('Completing wizard template clears onboarding gate', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final ProviderContainer container = await bootContainer(seedDemo: false);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MainApp(),
      ),
    );
    await pumpFrames(tester);

    await tester.tap(find.text('Continue'));
    await pumpFrames(tester);
    await tester.tap(find.text('Continue'));
    await pumpFrames(tester);

    expect(find.text('Library'), findsOneWidget);
    await tester.tap(find.text('Library'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(FilledButton, 'Use this template'));
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await pumpFrames(tester, frames: 20);

    expect(container.read(needsIndustryOnboardingProvider), isFalse);
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(OnboardingWizardScreen), findsNothing);
  });
}
