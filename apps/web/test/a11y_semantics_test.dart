@Tags(['widget', 'shell'])
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/application/providers/app_providers.dart';
import 'package:asset_os/domain/config/app_branding.dart';
import 'package:asset_os/domain/models/entities.dart';
import 'package:asset_os/infrastructure/l10n/l10n_ext.dart';
import 'package:asset_os/presentation/app_shell.dart';
import 'package:asset_os/presentation/theme/app_theme.dart';
import 'package:asset_os/presentation/widgets/scoped_search_field.dart';
import 'package:asset_os/presentation/widgets/ui_primitives.dart';

import 'support/test_harness.dart';

Widget _localizedShell({
  required ProviderContainer container,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MediaQuery(
      data: MediaQueryData(textScaler: textScaler),
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: container.read(themeModeProvider),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const AppShell(),
      ),
    ),
  );
}

Future<ProviderContainer> _pumpShell(
  WidgetTester tester, {
  TextScaler textScaler = TextScaler.noScaling,
  Map<String, Object> prefs = const <String, Object>{},
}) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final ProviderContainer container = await bootContainer(
    seedDemo: true,
    prefs: prefs,
  );
  await tester.pumpWidget(
    _localizedShell(container: container, textScaler: textScaler),
  );
  await pumpFrames(tester);
  return container;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('shell nav and Actions FAB expose semantics labels', (
    WidgetTester tester,
  ) async {
    await _pumpShell(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Transactions'), findsWidgets);
    expect(find.text('Resources'), findsWidgets);
    expect(find.text('Customers'), findsWidgets);
    expect(find.text('More'), findsWidgets);
    expect(find.byTooltip('Actions'), findsOneWidget);
    expect(find.text(kAppDisplayName), findsOneWidget);
  });

  testWidgets('offline banner is a live region when shown', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await _pumpShell(tester);
    container.read(offlineModeProvider.notifier).state = true;
    await pumpFrames(tester);

    expect(
      find.bySemanticsLabel('Working offline — changes will sync later.'),
      findsOneWidget,
    );
  });

  testWidgets('StatusPill and MoneyStack expose readable semantics', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const Scaffold(
          body: Column(
            children: <Widget>[
              StatusPill(status: AssetStatus.available),
              MoneyStack(label: 'Total due', amount: '₹100'),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('Available'), findsOneWidget);
    expect(find.bySemanticsLabel('Total due, ₹100'), findsOneWidget);
  });

  testWidgets('search clear control has l10n tooltip', (
    WidgetTester tester,
  ) async {
    final TextEditingController controller = TextEditingController(text: 'ab');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: ScopedSearchField(
            controller: controller,
            hintText: 'Search',
            noResultsText: 'None',
            suggestions: const <SearchSuggestion>[],
            onQueryChanged: (_) {},
            onSelected: (_) {},
            showSuggestionList: false,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byTooltip('Clear search'), findsOneWidget);
  });

  testWidgets('shell at 1.5× text scale does not overflow Home chrome', (
    WidgetTester tester,
  ) async {
    final List<Object> overflows = <Object>[];
    final void Function(FlutterErrorDetails)? oldOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final String text = details.toString();
      if (text.contains('overflowed') || text.contains('RenderFlex')) {
        overflows.add(details);
      }
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);

    await _pumpShell(tester, textScaler: const TextScaler.linear(1.5));

    expect(find.text(kAppDisplayName), findsOneWidget);
    expect(find.byTooltip('Actions'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(overflows, isEmpty);
  });
}
