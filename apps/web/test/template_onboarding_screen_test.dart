@Tags(['integration', 'shell'])
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/app_shell.dart';
import 'package:asset_os/core/config/app_branding.dart';
import 'package:asset_os/core/l10n/l10n_ext.dart';
import 'package:asset_os/core/providers/app_providers.dart';
import 'package:asset_os/core/theme/app_theme.dart';
import 'package:asset_os/features/onboarding/template_onboarding_screen.dart';
import 'package:asset_os/main.dart';

import 'support/test_harness.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('TemplateOnboardingScreen lists industry packs', (
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
          home: const TemplateOnboardingScreen(),
        ),
      ),
    );
    await pumpFrames(tester);

    expect(find.text(kAppDisplayName), findsOneWidget);
    expect(find.text('Choose your business type'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Camera Rental'), findsOneWidget);
  });

  testWidgets('MainApp shows onboarding when empty; AppShell when seeded', (
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
    expect(find.byType(TemplateOnboardingScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);

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
    expect(find.byType(TemplateOnboardingScreen), findsNothing);
  });
}
