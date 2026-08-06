@Tags(['widget', 'loans'])
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/core/l10n/l10n_ext.dart';
import 'package:asset_os/core/models/entities.dart';
import 'package:asset_os/core/providers/app_providers.dart';
import 'package:asset_os/core/repositories/local_repository.dart';
import 'package:asset_os/core/theme/app_theme.dart';
import 'package:asset_os/features/loans/loan_create_screen.dart';

import 'support/test_harness.dart';

Future<void> _pumpCreate(
  WidgetTester tester, {
  required ProviderContainer container,
  String? initialCustomerId,
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: container.read(themeModeProvider),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: LoanCreateScreen(initialCustomerId: initialCustomerId),
      ),
    ),
  );
  await pumpFrames(tester);
}

Future<void> _settle(WidgetTester tester, {int ticks = 20}) async {
  for (int i = 0; i < ticks; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

/// Phone, name, principal, rate, note — in form order.
Finder get _fields => find.byType(TextField);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('new name+phone creates customer and loan', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await bootContainer();
    final LocalRepository repo = container.read(repositoryProvider);

    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpCreate(tester, container: container);

    expect(_fields.evaluate().length >= 4, isTrue);
    await tester.enterText(_fields.at(0), '9876543210');
    await tester.enterText(_fields.at(1), 'Neha Verma');
    await tester.enterText(_fields.at(2), '5000');
    await tester.pump();
    await _settle(tester, ticks: 8);

    await tester.tap(find.widgetWithText(FilledButton, 'New loan'));
    await _settle(tester, ticks: 25);

    final Customer? customer = await repo.customerByPhone('9876543210');
    expect(customer, isNotNull);
    expect(customer!.name, 'Neha Verma');

    final List<MoneyLoan> loans = await repo.listMoneyLoans();
    expect(loans, hasLength(1));
    expect(loans.first.customerId, customer.id);
    expect(loans.first.principalPaise, 500000);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('initialCustomerId prefills and save keeps same id', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await bootContainer();
    final LocalRepository repo = container.read(repositoryProvider);
    final Customer existing = await ensureCustomer(
      repo,
      phone: '8888888888',
      name: 'Kiran Mehta',
    );

    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpCreate(
      tester,
      container: container,
      initialCustomerId: existing.id,
    );
    // Prefill is post-frame + async customerById.
    await _settle(tester, ticks: 20);

    final TextField phoneField = tester.widget<TextField>(_fields.at(0));
    final TextField nameField = tester.widget<TextField>(_fields.at(1));
    expect(phoneField.controller?.text, '8888888888');
    expect(nameField.controller?.text, 'Kiran Mehta');
    expect(find.textContaining('Existing customer'), findsOneWidget);

    await tester.enterText(_fields.at(2), '2500');
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'New loan'));
    await _settle(tester, ticks: 25);

    final List<MoneyLoan> loans =
        await repo.listMoneyLoans(customerId: existing.id);
    expect(loans, isNotEmpty);
    expect(loans.first.customerId, existing.id);
    expect(loans.first.principalPaise, 250000);

    // Same phone still maps to the prefilled customer (no duplicate upsert).
    final Customer? after = await repo.customerByPhone('8888888888');
    expect(after?.id, existing.id);

    // Flush Drift stream-cancel timers after LoanDetailScreen is torn down.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
