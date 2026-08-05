@Tags(['widget', 'shell'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/core/l10n/l10n_ext.dart';
import 'package:asset_os/core/models/entities.dart';
import 'package:asset_os/core/providers/app_providers.dart';
import 'package:asset_os/core/theme/app_theme.dart';
import 'package:asset_os/core/widgets/scoped_search_field.dart';
import 'package:asset_os/core/widgets/ui_primitives.dart';
import 'package:asset_os/features/reports/share_reports_screen.dart';

import 'support/test_harness.dart';

Widget _wrap(Widget child, {ProviderContainer? container}) {
  final bool ownsContainer = container == null;
  final ProviderContainer c = container ?? ProviderContainer();
  if (ownsContainer) {
    addTearDown(c.dispose);
  }
  return UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: child,
    ),
  );
}

void main() {
  testWidgets('OrderBillCard shows party as title and separate amounts', (
    WidgetTester tester,
  ) async {
    final Rental rental = Rental(
      id: 'REN-9001',
      customerId: 'CUS-1',
      lines: const <RentalLine>[
        RentalLine(
          id: 'RLI-1',
          itemId: 'INV-1',
          catalogName: 'DSLR',
          instanceName: 'Body A',
          shortCode: 'CAM-100',
        ),
      ],
      startedAt: DateTime(2026, 8, 1),
      dueAt: DateTime(2026, 8, 4),
      timeline: const <RentalEvent>[],
      qrCode: 'rental:9001',
      depositAmount: 50000,
      baseAmount: 120000,
    );

    await tester.pumpWidget(
      _wrap(
        Scaffold(
          body: OrderBillCard(
            rental: rental,
            partyLabel: 'Priya Patel',
            linesLabel: 'DSLR · Body A (CAM-100)',
          ),
        ),
      ),
    );

    expect(find.text('Priya Patel'), findsOneWidget);
    expect(find.text('DSLR · Body A (CAM-100)'), findsOneWidget);
    expect(find.text('#9001'), findsOneWidget);
    expect(find.text('REN-9001'), findsNothing);
    expect(find.text('Bill'), findsOneWidget);
    expect(find.text('Advance'), findsOneWidget);
  });

  testWidgets('customer list uses TierPill not Available/Archived for tier', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const Scaffold(
          body: Column(
            children: <Widget>[
              ListEntityRow(
                title: 'Priya Patel',
                secondary: '6666666666',
                leadingIcon: Icons.person_outline,
                pill: TierPill(trusted: true),
              ),
              ListEntityRow(
                title: 'Amit Shah',
                secondary: '6666666667',
                leadingIcon: Icons.person_outline,
                pill: TierPill(trusted: false),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Trusted'), findsOneWidget);
    expect(find.text('Standard'), findsOneWidget);
    expect(find.text('Available'), findsNothing);
    expect(find.text('Archived'), findsNothing);
  });

  testWidgets('Share to WhatsApp disabled without configured number', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await bootContainer(
      prefs: const <String, Object>{
        'owner_whatsapp_phone': '',
      },
    );
    await tester.pumpWidget(
      _wrap(const ShareReportsScreen(), container: container),
    );
    await pumpFrames(tester, frames: 24);

    expect(container.read(ownerWhatsAppProvider).isConfigured, isFalse);

    final Finder shareButton = find.widgetWithText(
      FilledButton,
      'Share to my WhatsApp',
    );
    expect(shareButton, findsOneWidget);
    expect(tester.widget<FilledButton>(shareButton).onPressed, isNull);

    await tester.ensureVisible(find.text('Set WhatsApp'));
    expect(find.textContaining('WhatsApp number'), findsWidgets);
  });

  testWidgets('Home empty attention has no New Order CTA', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return CompactEmptyState(
                message: context.l10n.needsAttentionEmptySubtitle,
              );
            },
          ),
        ),
      ),
    );

    expect(
      find.text('Due today and overdue orders will show up here.'),
      findsOneWidget,
    );
    expect(find.text('New Order'), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('search min-length hint shows only on focus or short query', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        Scaffold(
          body: ScopedSearchField(
            hintText: 'Search',
            minLengthHint: 'Type at least 3 characters',
            noResultsText: 'No matches',
            suggestions: const <SearchSuggestion>[],
            onQueryChanged: (_) {},
            onSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Type at least 3 characters'), findsNothing);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(find.text('Type at least 3 characters'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ab');
    await tester.pump();
    expect(find.text('Type at least 3 characters'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'abc');
    await tester.pump();
    expect(find.text('Type at least 3 characters'), findsNothing);
  });

  test('shortOrderId uses last segment', () {
    expect(shortOrderId('REN-9001'), '#9001');
    expect(shortOrderId('REN-UNK-12'), '#12');
  });
}
