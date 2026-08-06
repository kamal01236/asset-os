import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_branding.dart';
import '../../core/l10n/l10n_ext.dart';
import '../../core/providers/app_providers.dart';
import '../../core/templates/industry_templates.dart';
import '../../core/widgets/ui_primitives.dart';

/// First-load gate: require an industry template before entering the shell.
class TemplateOnboardingScreen extends ConsumerStatefulWidget {
  const TemplateOnboardingScreen({super.key});

  @override
  ConsumerState<TemplateOnboardingScreen> createState() =>
      _TemplateOnboardingScreenState();
}

class _TemplateOnboardingScreenState
    extends ConsumerState<TemplateOnboardingScreen> {
  bool _submitting = false;

  Future<void> _chooseTemplate(IndustryTemplate template) async {
    if (_submitting) {
      return;
    }
    final AppLocalizations l10n = context.l10n;
    final Locale locale = Localizations.localeOf(context);
    final String templateName = template.localizedName(locale);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(templateName),
          content: Text(
            l10n.onboardingTemplateConfirmBody(
              template.items.length,
              templateName,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.onboardingTemplateCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.onboardingTemplateConfirm),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(repositoryProvider).completeIndustryOnboarding(
            template,
            locale: locale,
          );
      await ref
          .read(homeModulesProvider.notifier)
          .applyTemplateDefaults(template.defaultHomeModules);
      await ref
          .read(enabledResourceTypesProvider.notifier)
          .applyTemplateTypes(template.enabledResourceTypes);
      ref.read(needsIndustryOnboardingProvider.notifier).state = false;
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final Locale locale = Localizations.localeOf(context);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
              children: <Widget>[
                Text(
                  kAppDisplayName,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.onboardingTemplateTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.onboardingTemplateSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                ...kIndustryTemplates.map(
                  (IndustryTemplate template) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: EntityCard(
                      title: template.localizedName(locale),
                      subtitle: l10n.templateCardSubtitle(
                        template.localizedDescription(locale),
                        template.items.length,
                      ),
                      leadingIcon: Icons.storefront_outlined,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _submitting
                          ? null
                          : () => _chooseTemplate(template),
                    ),
                  ),
                ),
              ],
            ),
            if (_submitting)
              const ColoredBox(
                color: Color(0x66000000),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
