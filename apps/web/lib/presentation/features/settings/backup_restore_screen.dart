import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/local_repository.dart';
import '../../../application/providers/app_providers.dart';
import '../../../application/reminders/reminder_scheduler.dart';
import '../../../application/reminders/reminder_settings.dart';
import '../../../domain/config/app_branding.dart';
import '../../../infrastructure/l10n/india_date_format.dart';
import '../../../infrastructure/l10n/l10n_ext.dart';
import '../../../infrastructure/sharing/backup_file.dart';

/// Local backup / restore surface (More → Backup & Restore).
///
/// Export writes the full local database + known settings to a JSON file;
/// restore replaces everything on this device after a destructive-confirm.
class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() =>
      _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  bool _exporting = false;
  bool _restoring = false;
  DateTime? _lastExportedAt;

  @override
  void initState() {
    super.initState();
    _loadLastExported();
  }

  Future<void> _loadLastExported() async {
    final DateTime? at =
        await ref.read(repositoryProvider).lastBackupExportedAt();
    if (!mounted) {
      return;
    }
    setState(() => _lastExportedAt = at);
  }

  Future<void> _export() async {
    if (_exporting || _restoring) {
      return;
    }
    setState(() => _exporting = true);
    final AppLocalizations l10n = context.l10n;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final LocalRepository repo = ref.read(repositoryProvider);
      final String json = await repo.exportBackupJson();
      final String stamp = _fileStamp(DateTime.now());
      final String filename =
          '${kAppDisplayName.toLowerCase()}-backup-$stamp.json';
      await saveBackupFile(json, filename);
      if (!mounted) {
        return;
      }
      await _loadLastExported();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.backupExportSuccess)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.backupExportError)),
      );
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  Future<void> _restore() async {
    if (_exporting || _restoring) {
      return;
    }
    final AppLocalizations l10n = context.l10n;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    final String? content = await pickBackupFile();
    if (!mounted) {
      return;
    }
    if (content == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.backupRestoreNoFile)),
      );
      return;
    }

    final bool confirmed = await _confirmReplace(l10n);
    if (!confirmed || !mounted) {
      return;
    }

    setState(() => _restoring = true);
    try {
      await ref
          .read(repositoryProvider)
          .importBackupJson(content, replaceExisting: true);
      if (!mounted) {
        return;
      }
      ref.read(localeProvider.notifier).reloadFromPreferences();
      ref.read(themeModeProvider.notifier).reloadFromPreferences();
      final ReminderSettings reminderSettings =
          ref.read(reminderSettingsProvider.notifier).reloadFromPreferences();
      ref.read(verificationSettingsProvider.notifier).reloadFromPreferences();
      await ReminderScheduler(ref.read(repositoryProvider))
          .refreshScheduledReminders(settings: reminderSettings, l10n: l10n);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.backupRestoreSuccess)),
      );
    } on BackupRestoreException catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(_restoreErrorMessage(l10n, error))),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(_restoreErrorMessage(
            l10n,
            const BackupRestoreException(BackupRestoreError.invalidFormat),
          )),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _restoring = false);
      }
    }
  }

  Future<bool> _confirmReplace(AppLocalizations l10n) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.backupRestoreConfirmTitle),
          content: Text(l10n.backupRestoreConfirmBody(kAppDisplayName)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.backupRestoreConfirmAction),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  String _restoreErrorMessage(
    AppLocalizations l10n,
    BackupRestoreException error,
  ) {
    switch (error.error) {
      case BackupRestoreError.unsupportedFormatVersion:
        return l10n.backupRestoreErrorFormatVersion(kAppDisplayName);
      case BackupRestoreError.schemaTooNew:
        return l10n.backupRestoreErrorSchemaTooNew(kAppDisplayName);
      case BackupRestoreError.invalidFormat:
        return l10n.backupRestoreErrorInvalid(kAppDisplayName);
    }
  }

  static String _fileStamp(DateTime now) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}'
        '-${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool busy = _exporting || _restoring;
    final String lastExportLabel = _lastExportedAt == null
        ? l10n.backupNeverExported
        : l10n.backupLastExported(formatIndiaDateTime(_lastExportedAt!));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupRestoreTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            l10n.backupRestoreSubtitle,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.backupExportSectionTitle,
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.backupExportSectionBody,
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.backupMediaNote,
                    style: textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lastExportLabel,
                    style: textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FilledButton.icon(
                      onPressed: busy ? null : _export,
                      icon: _exporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_outlined),
                      label: Text(
                        _exporting
                            ? l10n.backupExporting
                            : l10n.backupExportAction,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.backupRestoreSectionTitle,
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.backupRestoreSectionBody,
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : _restore,
                      icon: _restoring
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.restore_outlined),
                      label: Text(
                        _restoring
                            ? l10n.backupRestoring
                            : l10n.backupRestoreAction,
                      ),
                    ),
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
