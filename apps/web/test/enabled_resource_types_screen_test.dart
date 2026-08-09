@Tags(['unit', 'shell'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:asset_os/domain/models/entities.dart';
import 'package:asset_os/application/providers/app_providers.dart';
import 'package:asset_os/presentation/features/templates/enabled_resource_types_screen.dart';
import 'package:asset_os/l10n/app_localizations.dart';

import 'support/test_harness.dart';

void main() {
  testWidgets('More enabled-types screen toggles prefs via provider', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await bootContainer(
      seedDemo: true,
      prefs: <String, Object>{
        kEnabledResourceTypesPrefsKey: 'rental,sale,job',
      },
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: EnabledResourceTypesScreen(),
        ),
      ),
    );
    await pumpFrames(tester);

    expect(find.text('Enabled resource types'), findsOneWidget);
    expect(
      container.read(enabledResourceTypesProvider),
      <ResourceType>[
        ResourceType.rental,
        ResourceType.sale,
        ResourceType.job,
      ],
    );

    await tester.tap(find.widgetWithText(SwitchListTile, 'Job'));
    await tester.pump();

    expect(
      container.read(enabledResourceTypesProvider),
      <ResourceType>[ResourceType.rental, ResourceType.sale],
    );

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(kEnabledResourceTypesPrefsKey), 'rental,sale');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  test('setTypeEnabled keeps at least one type', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      kEnabledResourceTypesPrefsKey: 'rental',
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final EnabledResourceTypesNotifier notifier =
        EnabledResourceTypesNotifier(prefs);

    await notifier.setTypeEnabled(ResourceType.rental, false);
    expect(notifier.state, <ResourceType>[ResourceType.rental]);

    await notifier.setTypeEnabled(ResourceType.sale, true);
    expect(
      notifier.state,
      <ResourceType>[ResourceType.rental, ResourceType.sale],
    );
  });
}
