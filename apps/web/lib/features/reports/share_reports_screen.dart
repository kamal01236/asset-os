import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n_ext.dart';
import '../../core/models/entities.dart';
import '../../core/providers/app_providers.dart';
import '../../core/reports/report_builder.dart';
import '../../core/reports/report_models.dart';
import '../../core/sharing/whatsapp_share.dart';

/// Generate a text report and share it to the owner's WhatsApp (share-to-self).
class ShareReportsScreen extends ConsumerStatefulWidget {
  const ShareReportsScreen({super.key});

  @override
  ConsumerState<ShareReportsScreen> createState() => _ShareReportsScreenState();
}

class _ShareReportsScreenState extends ConsumerState<ShareReportsScreen> {
  ReportType _type = ReportType.summary;
  ReportPeriod _period = ReportPeriod.daily;
  DateTime? _customStart;
  DateTime? _customEnd;
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final OwnerWhatsAppSettings whatsApp = ref.watch(ownerWhatsAppProvider);
    final AsyncValue<List<Customer>> customersAsync = ref.watch(customersProvider);
    final AsyncValue<List<InventoryItem>> inventoryAsync =
        ref.watch(inventoryProvider);
    final AsyncValue<List<Rental>> rentalsAsync = ref.watch(rentalsProvider);

    final bool loading = customersAsync.isLoading ||
        inventoryAsync.isLoading ||
        rentalsAsync.isLoading;

    final List<Customer> customers =
        customersAsync.valueOrNull ?? const <Customer>[];
    final List<InventoryItem> inventory =
        inventoryAsync.valueOrNull ?? const <InventoryItem>[];
    final List<Rental> rentals = rentalsAsync.valueOrNull ?? const <Rental>[];

    final DateTime now = DateTime.now();
    final ReportDateRange range = ReportDateRange.resolve(
      period: _period,
      now: now,
      customStart: _customStart,
      customEnd: _customEnd,
    );

    final String preview = loading
        ? '…'
        : const ReportBuilder().build(
            type: _type,
            range: range,
            customers: customers,
            inventory: inventory,
            rentals: rentals,
            now: now,
          );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.shareReportsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            l10n.shareReportsSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.reportTypeLabel,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ChoiceChip(
                label: Text(l10n.reportTypeSummary),
                selected: _type == ReportType.summary,
                onSelected: (_) => setState(() => _type = ReportType.summary),
              ),
              ChoiceChip(
                label: Text(l10n.reportTypeCustomerWise),
                selected: _type == ReportType.customerWise,
                onSelected: (_) =>
                    setState(() => _type = ReportType.customerWise),
              ),
              ChoiceChip(
                label: Text(l10n.reportTypeInventoryWise),
                selected: _type == ReportType.inventoryWise,
                onSelected: (_) =>
                    setState(() => _type = ReportType.inventoryWise),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.reportPeriodLabel,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ChoiceChip(
                label: Text(l10n.reportPeriodDaily),
                selected: _period == ReportPeriod.daily,
                onSelected: (_) => setState(() => _period = ReportPeriod.daily),
              ),
              ChoiceChip(
                label: Text(l10n.reportPeriodWeekly),
                selected: _period == ReportPeriod.weekly,
                onSelected: (_) => setState(() => _period = ReportPeriod.weekly),
              ),
              ChoiceChip(
                label: Text(l10n.reportPeriodMonthly),
                selected: _period == ReportPeriod.monthly,
                onSelected: (_) =>
                    setState(() => _period = ReportPeriod.monthly),
              ),
              ChoiceChip(
                label: Text(l10n.reportPeriodCustom),
                selected: _period == ReportPeriod.custom,
                onSelected: (_) {
                  final DateTime now = DateTime.now();
                  setState(() {
                    _period = ReportPeriod.custom;
                    _customStart ??= DateTime(now.year, now.month, now.day);
                    _customEnd ??= DateTime(now.year, now.month, now.day);
                  });
                },
              ),
            ],
          ),
          if (_period == ReportPeriod.custom) ...<Widget>[
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(isStart: true),
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(
                      '${l10n.reportStartDate}: ${_formatShort(_customStart ?? now)}',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(isStart: false),
                    icon: const Icon(Icons.event_outlined, size: 18),
                    label: Text(
                      '${l10n.reportEndDate}: ${_formatShort(_customEnd ?? now)}',
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text(
            l10n.reportPreviewLabel,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Card(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: SelectableText(
                  preview,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!whatsApp.isConfigured)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                l10n.reportMissingPhone,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          FilledButton.icon(
            onPressed: loading || _sharing
                ? null
                : () => _share(preview, whatsApp),
            icon: const Icon(Icons.share_outlined),
            label: Text(l10n.shareToMyWhatsApp),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: loading
                ? null
                : () async {
                    await Clipboard.setData(ClipboardData(text: preview));
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.reportCopied)),
                    );
                  },
            icon: const Icon(Icons.copy_outlined),
            label: Text(l10n.copyReportText),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final DateTime now = DateTime.now();
    final DateTime initial = isStart
        ? (_customStart ?? now)
        : (_customEnd ?? now);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      if (isStart) {
        _customStart = picked;
      } else {
        _customEnd = picked;
      }
    });
  }

  Future<void> _share(String preview, OwnerWhatsAppSettings whatsApp) async {
    final AppLocalizations l10n = context.l10n;
    if (!whatsApp.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.reportMissingPhone),
          action: SnackBarAction(
            label: l10n.setWhatsAppAction,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      );
      return;
    }

    setState(() => _sharing = true);
    try {
      final WhatsAppShareOutcome outcome = await shareReportToSelf(
        phoneDigits: whatsApp.phoneDigits,
        countryCode: whatsApp.countryCode,
        message: preview,
      );
      if (!mounted) {
        return;
      }
      final String message;
      switch (outcome) {
        case WhatsAppShareOutcome.launched:
          message = l10n.reportWhatsAppOpened;
        case WhatsAppShareOutcome.copiedToClipboard:
          message = l10n.reportWhatsAppFallback;
        case WhatsAppShareOutcome.missingPhone:
          message = l10n.reportMissingPhone;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() => _sharing = false);
      }
    }
  }

  String _formatShort(DateTime value) {
    final String y = value.year.toString().padLeft(4, '0');
    final String m = value.month.toString().padLeft(2, '0');
    final String d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

/// Settings card + entry for owner WhatsApp on More.
class MyWhatsAppSettingsCard extends ConsumerStatefulWidget {
  const MyWhatsAppSettingsCard({super.key});

  @override
  ConsumerState<MyWhatsAppSettingsCard> createState() =>
      _MyWhatsAppSettingsCardState();
}

class _MyWhatsAppSettingsCardState
    extends ConsumerState<MyWhatsAppSettingsCard> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    final OwnerWhatsAppSettings settings = ref.read(ownerWhatsAppProvider);
    _controller = TextEditingController(text: settings.phoneDigits);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.myWhatsAppTitle),
              subtitle: Text(l10n.myWhatsAppSubtitle),
              leading: const Icon(Icons.chat_outlined),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: l10n.myWhatsAppHint,
                errorText: _error,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[\d+\s\-]')),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _save,
                child: Text(l10n.saveAction),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final AppLocalizations l10n = context.l10n;
    final String digits = _controller.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      setState(() => _error = l10n.myWhatsAppInvalid);
      return;
    }
    setState(() => _error = null);
    await ref.read(ownerWhatsAppProvider.notifier).setPhone(digits);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.myWhatsAppSaved)),
    );
  }
}
