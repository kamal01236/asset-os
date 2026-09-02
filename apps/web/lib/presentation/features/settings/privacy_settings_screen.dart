import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../application/privacy/media_retention_service.dart';
import '../../../application/privacy/privacy_settings.dart';
import '../../../application/providers/app_providers.dart';
import '../../../domain/config/app_branding.dart';
import '../../../infrastructure/l10n/l10n_ext.dart';

/// More → Privacy & Data (app lock, display masking, retention, about).
class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() =>
      _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  String? _pinError;
  PackageInfo? _packageInfo;
  bool _purging = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPackageInfo());
  }

  Future<void> _loadPackageInfo() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    if (!mounted) {
      return;
    }
    setState(() => _packageInfo = info);
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _persist(PrivacySettings settings, {bool snack = false}) async {
    await ref.read(privacySettingsProvider.notifier).update(settings);
    if (!mounted || !snack) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.privacySettingsSaved)),
    );
  }

  Future<void> _savePin(PrivacySettings settings) async {
    final AppLocalizations l10n = context.l10n;
    final String pin = _pinController.text.trim();
    final String confirm = _confirmPinController.text.trim();
    if (pin.length < 4 || pin.length > 6) {
      setState(() => _pinError = l10n.appLockPinInvalid);
      return;
    }
    if (pin != confirm) {
      setState(() => _pinError = l10n.appLockPinMismatch);
      return;
    }
    setState(() => _pinError = null);
    await _persist(settings.copyWith(appLockPin: pin), snack: true);
  }

  Future<void> _runCleanup(PrivacySettings settings) async {
    if (_purging || settings.mediaRetentionDays == 0) {
      return;
    }
    final AppLocalizations l10n = context.l10n;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.mediaRetentionConfirmTitle),
          content: Text(
            l10n.mediaRetentionConfirmBody(settings.mediaRetentionDays),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.mediaRetentionConfirmAction),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() => _purging = true);
    try {
      final int count = await MediaRetentionService(ref.read(repositoryProvider))
          .purgeExpired(retentionDays: settings.mediaRetentionDays);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.mediaRetentionPurgeSuccess(count))),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.mediaRetentionPurgeError)),
      );
    } finally {
      if (mounted) {
        setState(() => _purging = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final PrivacySettings settings = ref.watch(privacySettingsProvider);
    final int schemaVersion = ref.watch(repositoryProvider).appSchemaVersion;

    if (_pinController.text != (settings.appLockPin ?? '')) {
      _pinController.text = settings.appLockPin ?? '';
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacySettingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            l10n.privacySettingsSubtitle(kAppDisplayName),
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: <Widget>[
                SwitchListTile(
                  title: Text(l10n.appLockEnabledTitle),
                  subtitle: Text(l10n.appLockEnabledSubtitle),
                  value: settings.appLockEnabled,
                  onChanged: (bool value) {
                    if (value && !settings.hasValidAppLockPin) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.appLockSetPinFirst)),
                      );
                      return;
                    }
                    _persist(settings.copyWith(appLockEnabled: value));
                  },
                ),
                if (settings.appLockEnabled) ...<Widget>[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(l10n.appLockPinSectionTitle,
                            style: textTheme.titleSmall),
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
                            labelText: l10n.appLockPinLabel,
                            helperText: l10n.appLockPinHelper,
                            errorText: _pinError,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _confirmPinController,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          decoration: InputDecoration(
                            labelText: l10n.appLockPinConfirmLabel,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            onPressed: () => _savePin(settings),
                            child: Text(l10n.saveAction),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!kIsWeb) ...<Widget>[
                    const Divider(height: 1),
                    SwitchListTile(
                      title: Text(l10n.appLockBiometricTitle),
                      subtitle: Text(l10n.appLockBiometricSubtitle),
                      value: settings.biometricEnabled,
                      onChanged: (bool value) async {
                        if (value) {
                          final ScaffoldMessengerState messenger =
                              ScaffoldMessenger.of(context);
                          final LocalAuthentication auth = LocalAuthentication();
                          final bool can = await auth.canCheckBiometrics;
                          if (!can) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(l10n.appLockBiometricUnavailable),
                              ),
                            );
                            return;
                          }
                        }
                        _persist(settings.copyWith(biometricEnabled: value));
                      },
                    ),
                  ] else ...<Widget>[
                    const Divider(height: 1),
                    ListTile(
                      title: Text(l10n.appLockBiometricTitle),
                      subtitle: Text(l10n.appLockBiometricWebNote),
                      leading: const Icon(Icons.fingerprint_outlined),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: <Widget>[
                SwitchListTile(
                  title: Text(l10n.hidePricesTitle),
                  subtitle: Text(l10n.hidePricesSubtitle),
                  value: settings.hidePrices,
                  onChanged: (bool value) =>
                      _persist(settings.copyWith(hidePrices: value)),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text(l10n.hidePhoneNumbersTitle),
                  subtitle: Text(l10n.hidePhoneNumbersSubtitle),
                  value: settings.hidePhoneNumbers,
                  onChanged: (bool value) =>
                      _persist(settings.copyWith(hidePhoneNumbers: value)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(l10n.mediaRetentionTitle, style: textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    l10n.mediaRetentionSubtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      IconButton(
                        onPressed: settings.mediaRetentionDays > 0
                            ? () => _persist(
                                  settings.copyWith(
                                    mediaRetentionDays:
                                        settings.mediaRetentionDays - 1,
                                  ),
                                )
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Expanded(
                        child: Text(
                          settings.mediaRetentionDays == 0
                              ? l10n.mediaRetentionForever
                              : l10n.mediaRetentionDaysLabel(
                                  settings.mediaRetentionDays,
                                ),
                          textAlign: TextAlign.center,
                          style: textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: settings.mediaRetentionDays < 365
                            ? () => _persist(
                                  settings.copyWith(
                                    mediaRetentionDays:
                                        settings.mediaRetentionDays + 1,
                                  ),
                                )
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  Slider(
                    value: settings.mediaRetentionDays.toDouble(),
                    min: 0,
                    max: 365,
                    divisions: 365,
                    label: settings.mediaRetentionDays == 0
                        ? l10n.mediaRetentionForever
                        : l10n.mediaRetentionDaysLabel(
                            settings.mediaRetentionDays,
                          ),
                    onChanged: (double value) => _persist(
                      settings.copyWith(mediaRetentionDays: value.round()),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _purging || settings.mediaRetentionDays == 0
                          ? null
                          : () => _runCleanup(settings),
                      icon: _purging
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cleaning_services_outlined),
                      label: Text(l10n.mediaRetentionCleanupAction),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              title: Text(l10n.analyticsDisabledTitle),
              subtitle: Text(l10n.analyticsDisabledSubtitle(kAppDisplayName)),
              value: settings.analyticsDisabled,
              onChanged: (bool value) =>
                  _persist(settings.copyWith(analyticsDisabled: value)),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(l10n.aboutSectionTitle, style: textTheme.titleSmall),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.info_outline),
                    title: Text(l10n.aboutAppVersionLabel),
                    subtitle: Text(
                      _packageInfo == null
                          ? '…'
                          : '${_packageInfo!.version}+${_packageInfo!.buildNumber}',
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.storage_outlined),
                    title: Text(l10n.aboutDbSchemaLabel),
                    subtitle: Text('$schemaVersion'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.apps_outlined),
                    title: Text(l10n.aboutAppNameLabel),
                    subtitle: Text(kAppDisplayName),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}