import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/app_providers.dart';
import '../../../domain/config/app_branding.dart';
import '../../../infrastructure/l10n/l10n_ext.dart';
import '../../widgets/ui_primitives.dart';
import '../home/customize_home_screen.dart';
import '../reports/share_reports_screen.dart';
import '../settings/backup_restore_screen.dart';
import '../settings/privacy_settings_screen.dart';
import '../settings/reminders_screen.dart';
import '../settings/verification_settings_screen.dart';
import '../templates/business_templates_screen.dart';
import '../templates/enabled_resource_types_screen.dart';
import 'audit_log_screen.dart';
import 'voice_search_stub_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool offlineMode = ref.watch(offlineModeProvider);
    final Locale locale = ref.watch(localeProvider);
    final ThemeMode themeMode = ref.watch(themeModeProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Card(
          child: SwitchListTile(
            value: offlineMode,
            title: Text(l10n.offlineSimulationTitle),
            subtitle: Text(l10n.offlineSimulationSubtitle),
            onChanged: (bool value) {
              ref.read(offlineModeProvider.notifier).state = value;
            },
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.languageTitle),
                  subtitle: Text(l10n.languageSubtitle),
                  leading: const Icon(Icons.language),
                ),
                const SizedBox(height: 4),
                SegmentedButton<String>(
                  segments: <ButtonSegment<String>>[
                    ButtonSegment<String>(
                      value: 'en',
                      label: Text(l10n.languageEnglish),
                    ),
                    ButtonSegment<String>(
                      value: 'hi',
                      label: Text(l10n.languageHindi),
                    ),
                  ],
                  selected: <String>{locale.languageCode},
                  onSelectionChanged: (Set<String> selection) {
                    final String code = selection.first;
                    ref.read(localeProvider.notifier).setLocale(Locale(code));
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.themeTitle),
                  subtitle: Text(l10n.themeSubtitle),
                  leading: const Icon(Icons.dark_mode_outlined),
                ),
                const SizedBox(height: 4),
                SegmentedButton<ThemeMode>(
                  segments: <ButtonSegment<ThemeMode>>[
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      label: Text(l10n.themeDark),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      label: Text(l10n.themeLight),
                    ),
                  ],
                  selected: <ThemeMode>{themeMode},
                  onSelectionChanged: (Set<ThemeMode> selection) {
                    ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(selection.first);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const MyWhatsAppSettingsCard(),
        const SizedBox(height: 10),
        EntityCard(
          title: l10n.shareReportsTitle,
          subtitle: l10n.shareReportsSubtitle,
          leadingIcon: Icons.share_outlined,
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ShareReportsScreen()),
            );
          },
        ),
        const SizedBox(height: 10),
        EntityCard(
          title: l10n.remindersTitle,
          subtitle: l10n.remindersSubtitle(kAppDisplayName),
          leadingIcon: Icons.notifications_outlined,
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const RemindersScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        EntityCard(
          title: l10n.verificationSettingsTitle,
          subtitle: l10n.verificationSettingsCardSubtitle,
          leadingIcon: Icons.verified_user_outlined,
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const VerificationSettingsScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        EntityCard(
          title: l10n.privacySettingsTitle,
          subtitle: l10n.privacySettingsCardSubtitle,
          leadingIcon: Icons.privacy_tip_outlined,
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PrivacySettingsScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        EntityCard(
          title: l10n.backupRestoreTitle,
          subtitle: l10n.backupRestoreSubtitle,
          leadingIcon: Icons.backup_outlined,
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const BackupRestoreScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        EntityCard(
          title: l10n.activityLogTitle,
          subtitle: l10n.activityLogSubtitle,
          leadingIcon: Icons.history,
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AuditLogScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        EntityCard(
          title: l10n.customizeHomeTitle,
          subtitle: l10n.customizeHomeSubtitle,
          leadingIcon: Icons.view_quilt_outlined,
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CustomizeHomeScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        EntityCard(
          title: l10n.enabledResourceTypesTitle,
          subtitle: l10n.enabledResourceTypesSubtitle,
          leadingIcon: Icons.category_outlined,
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const EnabledResourceTypesScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        EntityCard(
          title: l10n.voiceSearchStubTitle,
          subtitle: l10n.voiceSearchStubSubtitle,
          leadingIcon: Icons.keyboard_voice_outlined,
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const VoiceSearchStubScreen()),
            );
          },
        ),
        const SizedBox(height: 10),
        EntityCard(
          title: l10n.businessTemplatesTitle,
          subtitle: l10n.businessTemplatesSubtitle,
          leadingIcon: Icons.dashboard_customize_outlined,
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const BusinessTemplatesScreen()),
            );
          },
        ),
      ],
    );
  }
}
