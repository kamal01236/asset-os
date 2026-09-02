import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/config/app_branding.dart';
import '../../../infrastructure/l10n/l10n_ext.dart';
import '../../../application/providers/app_providers.dart';
import 'template_onboarding_screen.dart';

enum _WizardStep { language, mode, whatsapp, template }

/// First-load gate: Language → Mode → WhatsApp (online only) → Template.
class OnboardingWizardScreen extends ConsumerStatefulWidget {
  const OnboardingWizardScreen({super.key});

  @override
  ConsumerState<OnboardingWizardScreen> createState() =>
      _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState
    extends ConsumerState<OnboardingWizardScreen> {
  _WizardStep _step = _WizardStep.language;
  PreferredWorkingMode _selectedMode = PreferredWorkingMode.offline;
  late final TextEditingController _whatsAppController;
  String? _whatsAppError;

  @override
  void initState() {
    super.initState();
    final OwnerWhatsAppSettings settings = ref.read(ownerWhatsAppProvider);
    _whatsAppController = TextEditingController(text: settings.phoneDigits);
    _selectedMode = ref.read(preferredModeProvider);
  }

  @override
  void dispose() {
    _whatsAppController.dispose();
    super.dispose();
  }

  bool get _isOnline => _selectedMode == PreferredWorkingMode.online;

  int get _totalSteps => _isOnline ? 4 : 3;

  int get _currentStepNumber {
    switch (_step) {
      case _WizardStep.language:
        return 1;
      case _WizardStep.mode:
        return 2;
      case _WizardStep.whatsapp:
        return 3;
      case _WizardStep.template:
        return _isOnline ? 4 : 3;
    }
  }

  Future<void> _continueFromLanguage() async {
    final Locale locale = ref.read(localeProvider);
    await ref.read(localeProvider.notifier).setLocale(locale);
    setState(() => _step = _WizardStep.mode);
  }

  Future<void> _continueFromMode() async {
    await ref.read(preferredModeProvider.notifier).setMode(_selectedMode);
    setState(() {
      _step = _isOnline ? _WizardStep.whatsapp : _WizardStep.template;
    });
  }

  Future<void> _continueFromWhatsApp() async {
    final AppLocalizations l10n = context.l10n;
    final String digits =
        _whatsAppController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      setState(() => _whatsAppError = l10n.myWhatsAppInvalid);
      return;
    }
    setState(() => _whatsAppError = null);
    await ref.read(ownerWhatsAppProvider.notifier).setPhone(digits);
    if (!mounted) {
      return;
    }
    setState(() => _step = _WizardStep.template);
  }

  void _goBack() {
    setState(() {
      switch (_step) {
        case _WizardStep.language:
          break;
        case _WizardStep.mode:
          _step = _WizardStep.language;
        case _WizardStep.whatsapp:
          _step = _WizardStep.mode;
        case _WizardStep.template:
          _step = _isOnline ? _WizardStep.whatsapp : _WizardStep.mode;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final bool showBack = _step != _WizardStep.language;
    final bool showContinue = _step != _WizardStep.template;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    kAppDisplayName,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.onboardingStepProgress(
                      _currentStepNumber,
                      _totalSteps,
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildStepBody()),
            if (showContinue || showBack)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: <Widget>[
                    if (showBack)
                      TextButton(
                        onPressed: _goBack,
                        child: Text(l10n.onboardingTemplateCancel),
                      ),
                    const Spacer(),
                    if (showContinue)
                      FilledButton(
                        onPressed: () {
                          switch (_step) {
                            case _WizardStep.language:
                              _continueFromLanguage();
                            case _WizardStep.mode:
                              _continueFromMode();
                            case _WizardStep.whatsapp:
                              _continueFromWhatsApp();
                            case _WizardStep.template:
                              break;
                          }
                        },
                        child: Text(l10n.continueAction),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBody() {
    switch (_step) {
      case _WizardStep.language:
        return const _LanguageStep();
      case _WizardStep.mode:
        return _ModeStep(
          selected: _selectedMode,
          onChanged: (PreferredWorkingMode mode) {
            setState(() => _selectedMode = mode);
          },
        );
      case _WizardStep.whatsapp:
        return _WhatsAppStep(
          controller: _whatsAppController,
          errorText: _whatsAppError,
          onChanged: (_) {
            if (_whatsAppError != null) {
              setState(() => _whatsAppError = null);
            }
          },
        );
      case _WizardStep.template:
        return const TemplateOnboardingBody(
          showBrandHeader: false,
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
        );
    }
  }
}

class _LanguageStep extends ConsumerWidget {
  const _LanguageStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final Locale locale = ref.watch(localeProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      children: <Widget>[
        Text(
          l10n.onboardingLanguageTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.onboardingLanguageSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
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
            ref.read(localeProvider.notifier).setLocale(Locale(selection.first));
          },
        ),
      ],
    );
  }
}

class _ModeStep extends StatelessWidget {
  const _ModeStep({
    required this.selected,
    required this.onChanged,
  });

  final PreferredWorkingMode selected;
  final ValueChanged<PreferredWorkingMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      children: <Widget>[
        Text(
          l10n.onboardingModeTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.onboardingModeSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        _ModeChoiceTile(
          selected: selected == PreferredWorkingMode.offline,
          title: l10n.onboardingModeOfflineTitle,
          subtitle: l10n.onboardingModeOfflineSubtitle,
          icon: Icons.cloud_off_outlined,
          onTap: () => onChanged(PreferredWorkingMode.offline),
        ),
        const SizedBox(height: 10),
        _ModeChoiceTile(
          selected: selected == PreferredWorkingMode.online,
          title: l10n.onboardingModeOnlineTitle,
          subtitle: l10n.onboardingModeOnlineSubtitle,
          icon: Icons.cloud_outlined,
          onTap: () => onChanged(PreferredWorkingMode.online),
        ),
      ],
    );
  }
}

class _ModeChoiceTile extends StatelessWidget {
  const _ModeChoiceTile({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    return Material(
      color: selected
          ? colors.primaryContainer.withValues(alpha: 0.45)
          : colors.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhatsAppStep extends StatelessWidget {
  const _WhatsAppStep({
    required this.controller,
    required this.errorText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      children: <Widget>[
        Text(
          l10n.onboardingWhatsAppTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.onboardingWhatsAppSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.myWhatsAppTitle,
            hintText: l10n.myWhatsAppHint,
            errorText: errorText,
            border: const OutlineInputBorder(),
          ),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[\d+\s\-]')),
          ],
          onChanged: onChanged,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.onboardingVerificationCopy,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.onboardingVerificationSettingsHint(kAppDisplayName),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
