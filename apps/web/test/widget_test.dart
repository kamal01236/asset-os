@Tags(['integration', 'shell'])
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:asset_os/app_shell.dart';
import 'package:asset_os/core/config/app_branding.dart';
import 'package:asset_os/core/db/app_database.dart';
import 'package:asset_os/core/l10n/l10n_ext.dart';
import 'package:asset_os/core/l10n/timeline_l10n.dart';
import 'package:asset_os/core/models/entities.dart';
import 'package:asset_os/core/providers/app_providers.dart';
import 'package:asset_os/core/repositories/local_repository.dart';
import 'package:asset_os/core/templates/industry_templates.dart';
import 'package:asset_os/core/theme/app_theme.dart';
import 'package:asset_os/core/widgets/scoped_search_field.dart';

import 'support/test_harness.dart';

Widget _localizedApp({
  required ProviderContainer container,
  Locale? locale,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: _TestMaterialApp(localeOverride: locale),
  );
}

class _TestMaterialApp extends ConsumerWidget {
  const _TestMaterialApp({this.localeOverride});

  final Locale? localeOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      locale: localeOverride ?? ref.watch(localeProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const AppShell(),
    );
  }
}

Future<ProviderContainer> _pumpAppShell(
  WidgetTester tester, {
  Map<String, Object> prefs = const <String, Object>{},
  Locale? locale,
}) async {
  // Tall surface so Home modules below the KPI grid are built (ListView lazy).
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final ProviderContainer container = await bootContainer(
    seedDemo: true,
    prefs: prefs,
  );
  await tester.pumpWidget(_localizedApp(container: container, locale: locale));
  await pumpFrames(tester);
  return container;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('app loads smoke test with Drift seed', (WidgetTester tester) async {
    await _pumpAppShell(tester);

    expect(find.text(kAppDisplayName), findsOneWidget);
    expect(find.text('Search Anything'), findsOneWidget);
    expect(find.text('Today at a glance'), findsOneWidget);
    expect(find.text('Needs attention'), findsOneWidget);
    expect(find.text('AI suggestions (beta)'), findsNothing);
  });

  testWidgets('Home Due Today KPI navigates to Rentals with filter', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await _pumpAppShell(tester);

    expect(find.text('Needs attention'), findsOneWidget);
    expect(find.textContaining('Workshop set A'), findsOneWidget);

    await tester.tap(find.text('Due Today').first);
    await pumpFrames(tester);

    expect(container.read(currentTabIndexProvider), kTabIndexRentals);
    expect(
      container.read(rentalsListFilterProvider),
      RentalsListFilter.dueToday,
    );
    expect(find.text('Showing: Due Today'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
    expect(find.textContaining('Workshop set A'), findsOneWidget);

    await tester.tap(find.text('Clear'));
    await pumpFrames(tester);

    expect(find.text('Showing: Due Today'), findsNothing);
    expect(container.read(rentalsListFilterProvider), isNull);
  });

  testWidgets('Home Available KPI navigates to Inventory with filter', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await _pumpAppShell(tester);

    await tester.tap(find.text('Available').first);
    await pumpFrames(tester);

    expect(container.read(currentTabIndexProvider), kTabIndexInventory);
    expect(
      container.read(inventoryListFilterProvider),
      InventoryListFilter.available,
    );
    expect(find.text('Showing: Available'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
    expect(find.text('DSLR'), findsOneWidget);

    await tester.tap(find.text('Clear'));
    await pumpFrames(tester);

    expect(find.text('Showing: Available'), findsNothing);
    expect(container.read(inventoryListFilterProvider), isNull);
  });

  testWidgets('Home Overdue KPI navigates to Rentals overdue filter', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await _pumpAppShell(tester);

    await tester.tap(find.text('Overdue').first);
    await pumpFrames(tester);

    expect(container.read(currentTabIndexProvider), kTabIndexRentals);
    expect(
      container.read(rentalsListFilterProvider),
      RentalsListFilter.overdue,
    );
    expect(find.text('Showing: Overdue'), findsOneWidget);
  });

  testWidgets('default Home modules omit filterResults under KPIs', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await _pumpAppShell(tester);

    expect(
      container.read(homeModulesProvider).contains(HomeModuleId.filterResults),
      isFalse,
    );
    expect(find.text('Needs attention'), findsOneWidget);
    // KPI tap leaves Home; no in-place Showing: banner on Home.
    await tester.tap(find.text('Active').first);
    await pumpFrames(tester);
    expect(container.read(currentTabIndexProvider), kTabIndexRentals);
    expect(container.read(homeFilterProvider), isNull);
  });

  testWidgets('disabled Home module stays hidden until enabled via provider', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await _pumpAppShell(tester);

    expect(find.text('AI suggestions (beta)'), findsNothing);

    await container.read(homeModulesProvider.notifier).setEnabled(
          HomeModuleId.suggestions,
          true,
        );
    await pumpFrames(tester);

    expect(find.text('AI suggestions (beta)'), findsOneWidget);
  });

  testWidgets('primary tabs show seeded rentals, resources, and customers', (
    WidgetTester tester,
  ) async {
    await _pumpAppShell(tester);

    await tester.tap(find.text('Transactions'));
    await pumpFrames(tester);
    expect(find.text('Order'), findsWidgets);
    expect(find.textContaining('Priya'), findsWidgets);

    await tester.tap(find.text('Resources'));
    await pumpFrames(tester);
    expect(find.text('DSLR'), findsOneWidget);
    expect(find.text('Tripod'), findsOneWidget);

    await tester.tap(find.text('Customers'));
    await pumpFrames(tester);
    expect(find.text('Priya Patel'), findsWidgets);
    expect(find.textContaining('6666666666'), findsOneWidget);

    await tester.tap(find.text('More'));
    await pumpFrames(tester);
    expect(find.text('Offline simulation'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Customize Home'), findsOneWidget);
    expect(find.text('Enabled resource types'), findsOneWidget);
  });

  testWidgets('Transactions tab shows open and completed orders', (
    WidgetTester tester,
  ) async {
    await _pumpAppShell(tester);

    await tester.tap(find.text('Transactions'));
    await pumpFrames(tester);

    expect(find.textContaining('Priya'), findsWidgets);
    expect(find.text('Order'), findsWidgets);
  });

  testWidgets('open order detail cancel is bottom last action, not app bar', (
    WidgetTester tester,
  ) async {
    await _pumpAppShell(tester);

    await tester.tap(find.text('Transactions'));
    await pumpFrames(tester);
    await tester.tap(find.text('Order').first);
    await pumpFrames(tester);

    expect(find.widgetWithText(AppBar, '#3001'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Cancel order'), findsOneWidget);
    expect(find.text('Return all'), findsOneWidget);
    expect(find.text('Return selected'), findsOneWidget);

    final Finder cancelFinder =
        find.widgetWithText(OutlinedButton, 'Cancel order');
    final Finder returnAllFinder =
        find.widgetWithText(OutlinedButton, 'Return all');
    expect(
      tester.getTopLeft(cancelFinder).dy,
      greaterThan(tester.getTopLeft(returnAllFinder).dy),
    );
  });

  testWidgets('Home search is inline typeahead without a search route', (
    WidgetTester tester,
  ) async {
    await _pumpAppShell(tester);

    expect(find.text('Search Anything'), findsOneWidget);
    expect(find.text('Type at least 3 characters'), findsNothing);
    expect(find.widgetWithText(AppBar, 'Search'), findsNothing);
    expect(find.widgetWithText(AppBar, kAppDisplayName), findsOneWidget);

    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    expect(find.text('Type at least 3 characters'), findsOneWidget);
  });

  testWidgets('FAB Search opens typeahead bottom sheet', (
    WidgetTester tester,
  ) async {
    await _pumpAppShell(tester);

    await tester.tap(find.text('Actions'));
    await pumpFrames(tester);
    await tester.tap(find.text('Search').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Find customer, order, or resource'), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Search'), findsNothing);
  });

  testWidgets('ScopedSearchField shows suggestions once query meets min length', (
    WidgetTester tester,
  ) async {
    String query = '';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              final List<SearchSuggestion> suggestions =
                  query.trim().length >= 3
                      ? const <SearchSuggestion>[
                          SearchSuggestion(
                            id: 'INV-1',
                            title: 'DSLR',
                            subtitle: 'Camera',
                            leadingIcon: Icons.inventory_2_outlined,
                          ),
                        ]
                      : const <SearchSuggestion>[];
              return ScopedSearchField(
                hintText: 'Search inventory',
                minLengthHint: 'Type at least 3 characters',
                noResultsText: 'No matches',
                suggestions: suggestions,
                onQueryChanged: (String value) {
                  setState(() => query = value);
                },
                onSelected: (_) {},
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Type at least 3 characters'), findsNothing);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(find.text('Type at least 3 characters'), findsOneWidget);

    final TextField field = tester.widget(find.byType(TextField));
    field.controller!.value = const TextEditingValue(text: 'ds');
    field.onChanged!('ds');
    await tester.pump();
    expect(find.text('Type at least 3 characters'), findsOneWidget);
    expect(find.text('DSLR'), findsNothing);

    field.controller!.value = const TextEditingValue(text: 'dsl');
    field.onChanged!('dsl');
    await tester.pump();
    expect(find.text('Type at least 3 characters'), findsNothing);
    expect(find.text('DSLR'), findsOneWidget);
  });

  testWidgets('starts New Order flow from Actions sheet', (WidgetTester tester) async {
    await _pumpAppShell(tester);

    await tester.tap(find.text('Actions'));
    await pumpFrames(tester);
    // Home Quick Actions also shows "New Order"; prefer the sheet ListTile.
    await tester.tap(find.widgetWithText(ListTile, 'New Order'));
    await pumpFrames(tester);

    expect(find.widgetWithText(AppBar, 'New Order'), findsOneWidget);
    expect(find.text('Step 1 of 3'), findsOneWidget);
    expect(find.text('Line 1'), findsOneWidget);
    expect(find.text('Phone number'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);
  });

  testWidgets('Hindi locale shows localized chrome', (WidgetTester tester) async {
    await _pumpAppShell(tester, locale: const Locale('hi'));

    expect(find.text(kAppDisplayName), findsOneWidget);
    expect(find.text('कुछ भी खोजें'), findsOneWidget);
    expect(find.text('आज एक नज़र में'), findsOneWidget);
    expect(find.text('होम'), findsOneWidget);
    expect(find.text('संसाधन'), findsOneWidget);
  });

  test('localeProvider persists Hindi preference', () async {
    final ProviderContainer container = await bootContainer(seedDemo: true);
    expect(container.read(localeProvider).languageCode, 'en');

    await container.read(localeProvider.notifier).setLocale(const Locale('hi'));
    expect(container.read(localeProvider).languageCode, 'hi');
    expect(
      container.read(sharedPreferencesProvider).getString(kLocalePrefsKey),
      'hi',
    );

    final ProviderContainer reloaded = await bootContainer(
      seedDemo: false,
      prefs: <String, Object>{kLocalePrefsKey: 'hi'},
    );
    expect(reloaded.read(localeProvider).languageCode, 'hi');
  });

  test('themeModeProvider defaults to dark and persists light', () async {
    final ProviderContainer container = await bootContainer(seedDemo: true);
    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(
      container.read(sharedPreferencesProvider).getString(kThemeModePrefsKey),
      isNull,
    );

    await container
        .read(themeModeProvider.notifier)
        .setThemeMode(ThemeMode.light);
    expect(container.read(themeModeProvider), ThemeMode.light);
    expect(
      container.read(sharedPreferencesProvider).getString(kThemeModePrefsKey),
      'light',
    );

    final ProviderContainer reloaded = await bootContainer(
      seedDemo: false,
      prefs: <String, Object>{kThemeModePrefsKey: 'light'},
    );
    expect(reloaded.read(themeModeProvider), ThemeMode.light);

    final ProviderContainer invalid = await bootContainer(
      seedDemo: false,
      prefs: <String, Object>{kThemeModePrefsKey: 'system'},
    );
    expect(invalid.read(themeModeProvider), ThemeMode.dark);
  });

  testWidgets('More theme toggle switches themeMode and brightness', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await _pumpAppShell(tester);

    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
        Brightness.dark);

    await tester.tap(find.text('More'));
    await pumpFrames(tester);

    expect(find.text('Theme'), findsOneWidget);
    await tester.tap(find.text('Light'));
    await pumpFrames(tester);

    expect(container.read(themeModeProvider), ThemeMode.light);
    expect(
      container.read(sharedPreferencesProvider).getString(kThemeModePrefsKey),
      'light',
    );
    expect(Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
        Brightness.light);

    await tester.tap(find.text('Dark'));
    await pumpFrames(tester);

    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
        Brightness.dark);
  });

  test('seeds demo data when DB empty and no snapshot', () async {
    final ProviderContainer container = await bootContainer(seedDemo: true);

    final LocalRepository repo = container.read(repositoryProvider);
    final List<Customer> customers = await repo.listCustomers();
    final List<InventoryItem> inventory = await repo.listInventory();
    final List<Rental> rentals = await repo.listRentals();

    expect(customers, hasLength(4));
    expect(inventory, hasLength(3));
    expect(rentals, hasLength(2));
    expect(customers.any((c) => c.phone == '6666666666'), isTrue);
    expect(customers.any((c) => c.id == 'CUS-UNKNOWN'), isTrue);
  });

  test('migrates SharedPreferences snapshot once', () async {
    final DateTime now = DateTime(2026, 8, 2, 12);
    final AppDataSnapshot snapshot = AppDataSnapshot(
      customers: <Customer>[
        const Customer(
          id: 'CUS-M1',
          name: 'Migrated User',
          phone: '9000000001',
          isTrusted: true,
          qrCode: 'customer:m1',
        ),
      ],
      inventory: <InventoryItem>[
        const InventoryItem(
          id: 'INV-M1',
          name: 'Migrated Camera',
          category: 'Camera',
          availableUnits: 1,
          totalUnits: 1,
          status: AssetStatus.available,
          qrCode: 'inventory:m1',
        ),
      ],
      rentals: <Rental>[
        Rental(
          id: 'REN-M1',
          customerId: 'CUS-M1',
          lines: const <RentalLine>[
            RentalLine(
              id: 'RLI-REN-M1-INV-M1',
              itemId: 'INV-M1',
              catalogName: 'Migrated Camera',
              instanceName: 'Migrated Camera',
              shortCode: 'MIG-001',
            ),
          ],
          startedAt: now.subtract(const Duration(days: 1)),
          dueAt: now.add(const Duration(days: 2)),
          timeline: <RentalEvent>[
            RentalEvent(
              title: 'Rental opened',
              subtitle: 'From prefs snapshot',
              at: now.subtract(const Duration(days: 1)),
            ),
          ],
          qrCode: 'rental:m1',
        ),
      ],
    );

    final ProviderContainer container = await bootContainer(
      seedDemo: false,
      prefs: <String, Object>{
        LocalRepository.snapshotKey: snapshot.encode(),
      },
    );

    final LocalRepository repo = container.read(repositoryProvider);
    final SharedPreferences prefs = container.read(sharedPreferencesProvider);

    expect(await repo.listCustomers(), hasLength(2));
    expect(
      (await repo.listCustomers()).any((c) => c.name == 'Migrated User'),
      isTrue,
    );
    expect(
      (await repo.listCustomers()).any((c) => c.id == 'CUS-UNKNOWN'),
      isTrue,
    );
    expect(await repo.listInventory(), hasLength(1));
    expect(await repo.listRentals(), hasLength(1));
    expect(prefs.getString(LocalRepository.snapshotKey), isNull);

    // Re-initialize against same DB must not duplicate.
    await repo.initialize();
    expect(await repo.listCustomers(), hasLength(2));
  });

  test('create rental, return, phone lookup, search, and QR resolve', () async {
    final AppDatabase db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final LocalRepository repo = LocalRepository(db, preferences);
    await repo.initialize(seedDemo: true);

    final Customer existing = (await repo.customerByPhone('6666666666'))!;
    expect(existing.name, 'Priya Patel');

    final InventoryItem camera = (await repo.listInventory())
        .firstWhere((item) => item.id == 'INV-2001');
    expect(camera.availableUnits, 2);

    await repo.createRental(
      customer: existing,
      lines: <RentalLineInput>[
        RentalLineInput(
          itemId: camera.id,
          instanceName: 'Body unit 2',
          shortCode: 'CAM-002',
        ),
      ],
    );
    final List<Rental> afterCreate = await repo.listRentals();
    expect(afterCreate.length, greaterThanOrEqualTo(3));
    final Rental created = afterCreate.first;
    expect(created.customerId, existing.id);
    expect(created.isActive, isTrue);

    final InventoryItem afterRent = (await repo.listInventory())
        .firstWhere((item) => item.id == 'INV-2001');
    expect(afterRent.availableUnits, 1);

    final SearchResults results = await repo.search('priya');
    expect(results.customers, isNotEmpty);
    expect(results.customers.first.phone, '6666666666');

    final QrDestination? destination = await repo.resolveQr('customer:1001');
    expect(destination, isA<QrCustomer>());
    expect((destination! as QrCustomer).customerId, 'CUS-1001');

    await repo.returnRental(created.id);
    final Rental returned =
        (await repo.listRentals()).firstWhere((item) => item.id == created.id);
    expect(returned.isActive, isFalse);
    expect(
      returned.timeline.map((e) => e.title),
      contains(TimelineTitleKey.returned),
    );

    final InventoryItem afterReturn = (await repo.listInventory())
        .firstWhere((item) => item.id == 'INV-2001');
    expect(afterReturn.availableUnits, 2);
  });

  test('importTemplateInventory merges and skips duplicates', () async {
    final ProviderContainer container = await bootContainer(seedDemo: true);
    final LocalRepository repo = container.read(repositoryProvider);

    final TemplateImportResult first = await repo.importTemplateInventory(
      const <TemplateInventoryItem>[
        TemplateInventoryItem(name: 'DSLR', category: 'Camera', defaultUnits: 3),
        TemplateInventoryItem(name: 'Lens', category: 'Camera', defaultUnits: 4),
      ],
    );
    expect(first.added, 1);
    expect(first.skipped, 1);

    final TemplateImportResult second = await repo.importTemplateInventory(
      const <TemplateInventoryItem>[
        TemplateInventoryItem(name: 'Lens', category: 'Camera', defaultUnits: 4),
      ],
    );
    expect(second.added, 0);
    expect(second.skipped, 1);

    final List<InventoryItem> inventory = await repo.listInventory();
    expect(inventory.where((item) => item.name == 'Lens'), hasLength(1));
    expect(inventory.where((item) => item.name.toLowerCase() == 'dslr'), hasLength(1));
  });

  test('updateInventory adjusts units without exceeding total', () async {
    final ProviderContainer container = await bootContainer(seedDemo: true);
    final LocalRepository repo = container.read(repositoryProvider);

    await repo.updateInventory(
      id: 'INV-2001',
      name: 'DSLR Pro',
      category: 'Camera',
      units: 5,
      notes: 'Updated body',
    );
    InventoryItem updated =
        (await repo.listInventory()).firstWhere((item) => item.id == 'INV-2001');
    expect(updated.name, 'DSLR Pro');
    expect(updated.totalUnits, 5);
    expect(updated.availableUnits, 4); // was 2/3; +2 total → +2 available
    expect(updated.notes, 'Updated body');

    await repo.updateInventory(
      id: 'INV-2001',
      name: 'DSLR Pro',
      category: 'Camera',
      units: 3,
    );
    updated = (await repo.listInventory()).firstWhere((item) => item.id == 'INV-2001');
    expect(updated.totalUnits, 3);
    expect(updated.availableUnits, 2); // 4 + (-2) clamped
  });
}
