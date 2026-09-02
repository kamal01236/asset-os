import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/app_providers.dart';
import '../../../domain/config/app_branding.dart';
import '../../../domain/verification/verification_models.dart';
import '../../../infrastructure/l10n/l10n_ext.dart';

/// More → Verification settings (handover method, condition mode, checklist).
class VerificationSettingsScreen extends ConsumerStatefulWidget {
  const VerificationSettingsScreen({super.key});

  @override
  ConsumerState<VerificationSettingsScreen> createState() =>
      _VerificationSettingsScreenState();
}

class _VerificationSettingsScreenState
    extends ConsumerState<VerificationSettingsScreen> {
  final TextEditingController _pinController = TextEditingController();
  final List<TextEditingController> _checklistControllers =
      <TextEditingController>[];

  @override
  void dispose() {
    _pinController.dispose();
    for (final TextEditingController c in _checklistControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncChecklistControllers(List<String> items) {
    while (_checklistControllers.length < items.length) {
      _checklistControllers.add(TextEditingController());
    }
    while (_checklistControllers.length > items.length) {
      _checklistControllers.removeLast().dispose();
    }
    for (int i = 0; i < items.length; i++) {
      if (_checklistControllers[i].text != items[i]) {
        _checklistControllers[i].text = items[i];
      }
    }
  }

  Future<void> _persist(VerificationSettings settings, {bool snack = false}) async {
    await ref.read(verificationSettingsProvider.notifier).update(settings);
    if (!mounted || !snack) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.verificationSettingsSaved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final VerificationSettings settings = ref.watch(verificationSettingsProvider);

    if (_pinController.text != (settings.pin ?? '')) {
      _pinController.text = settings.pin ?? '';
    }
    _syncChecklistControllers(settings.checklistItems);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.verificationSettingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            l10n.verificationSettingsSubtitle(kAppDisplayName),
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.verificationSettingsOperatorNote,
            style: textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: SwitchListTile(
              title: Text(l10n.verificationHandoverEnabledTitle),
              subtitle: Text(l10n.verificationHandoverEnabledSubtitle),
              value: settings.handoverEnabled,
              onChanged: (bool value) {
                _persist(settings.copyWith(handoverEnabled: value));
              },
            ),
          ),
          if (settings.handoverEnabled) ...<Widget>[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.verificationHandoverMethodTitle,
                      style: textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    ...VerificationMethod.values.map(
                      (VerificationMethod method) {
                        final bool selected = settings.handoverMethod == method;
                        return ListTile(
                          title: Text(_methodLabel(l10n, method)),
                          trailing: selected
                              ? Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                          onTap: () =>
                              _persist(settings.copyWith(handoverMethod: method)),
                        );
                      },
                    ),
                    if (settings.handoverMethod == VerificationMethod.pin) ...<Widget>[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _pinController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: InputDecoration(
                          labelText: l10n.verificationPinLabel,
                          helperText: l10n.verificationPinHelper,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (String value) {
                          _persist(settings.copyWith(pin: value));
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.verificationConditionModeTitle,
                    style: textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<ConditionMode>(
                    segments: <ButtonSegment<ConditionMode>>[
                      ButtonSegment<ConditionMode>(
                        value: ConditionMode.basic,
                        label: Text(l10n.verificationConditionBasic),
                      ),
                      ButtonSegment<ConditionMode>(
                        value: ConditionMode.standard,
                        label: Text(l10n.verificationConditionStandard),
                      ),
                      ButtonSegment<ConditionMode>(
                        value: ConditionMode.advanced,
                        label: Text(l10n.verificationConditionAdvanced),
                      ),
                    ],
                    selected: <ConditionMode>{settings.conditionMode},
                    onSelectionChanged: (Set<ConditionMode> selected) {
                      _persist(settings.copyWith(conditionMode: selected.first));
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _conditionModeBody(l10n, settings.conditionMode),
                    style: textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (settings.handoverMethod == VerificationMethod.checklist ||
              settings.conditionMode == ConditionMode.advanced) ...<Widget>[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.verificationChecklistTitle,
                      style: textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    ...List<Widget>.generate(settings.checklistItems.length, (int i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: TextField(
                                controller: _checklistControllers[i],
                                decoration: InputDecoration(
                                  labelText: l10n.verificationChecklistItemLabel(i + 1),
                                  border: const OutlineInputBorder(),
                                ),
                                onChanged: (String value) {
                                  final List<String> next =
                                      List<String>.from(settings.checklistItems);
                                  next[i] = value;
                                  _persist(settings.copyWith(checklistItems: next));
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: settings.checklistItems.length <= 1
                                  ? null
                                  : () {
                                      final List<String> next =
                                          List<String>.from(settings.checklistItems)
                                            ..removeAt(i);
                                      _persist(
                                        settings.copyWith(checklistItems: next),
                                        snack: true,
                                      );
                                    },
                            ),
                          ],
                        ),
                      );
                    }),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: () {
                          final List<String> next =
                              List<String>.from(settings.checklistItems)
                                ..add('');
                          _persist(settings.copyWith(checklistItems: next));
                        },
                        icon: const Icon(Icons.add),
                        label: Text(l10n.verificationChecklistAdd),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _methodLabel(AppLocalizations l10n, VerificationMethod method) {
    switch (method) {
      case VerificationMethod.manual:
        return l10n.verificationMethodManual;
      case VerificationMethod.pin:
        return l10n.verificationMethodPin;
      case VerificationMethod.otpDisplay:
        return l10n.verificationMethodOtpDisplay;
      case VerificationMethod.photo:
        return l10n.verificationMethodPhoto;
      case VerificationMethod.checklist:
        return l10n.verificationMethodChecklist;
    }
  }

  String _conditionModeBody(AppLocalizations l10n, ConditionMode mode) {
    switch (mode) {
      case ConditionMode.basic:
        return l10n.verificationConditionBasicBody;
      case ConditionMode.standard:
        return l10n.verificationConditionStandardBody;
      case ConditionMode.advanced:
        return l10n.verificationConditionAdvancedBody;
    }
  }
}
