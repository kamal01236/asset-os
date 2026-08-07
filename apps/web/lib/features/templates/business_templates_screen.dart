import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n_ext.dart';
import '../../core/models/entities.dart';
import '../../core/providers/app_providers.dart';
import '../../core/repositories/local_repository.dart';
import '../../core/templates/industry_templates.dart';

/// Switch the single active industry pack; optionally import starter inventory.
class BusinessTemplatesScreen extends ConsumerStatefulWidget {
  const BusinessTemplatesScreen({super.key});

  @override
  ConsumerState<BusinessTemplatesScreen> createState() =>
      _BusinessTemplatesScreenState();
}

class _BusinessTemplatesScreenState
    extends ConsumerState<BusinessTemplatesScreen> {
  String? _activeId;
  bool _loading = true;
  bool _switching = false;
  /// Bumped when a switch is cancelled so the dropdown reverts its selection.
  int _dropdownEpoch = 0;

  @override
  void initState() {
    super.initState();
    _loadActive();
  }

  Future<void> _loadActive() async {
    final String? id =
        await ref.read(repositoryProvider).selectedIndustryTemplateId();
    if (!mounted) {
      return;
    }
    setState(() {
      _activeId = id;
      _loading = false;
    });
  }

  Future<void> _syncProviders(IndustryTemplate template) async {
    await ref
        .read(homeModulesProvider.notifier)
        .applyTemplateDefaults(template.defaultHomeModules);
    await ref
        .read(enabledResourceTypesProvider.notifier)
        .applyTemplateTypes(template.enabledResourceTypes);
    await ref
        .read(activeWorkflowProvider.notifier)
        .applyTemplateWorkflow(template.workflowId);
    await ref
        .read(extraFieldIdsProvider.notifier)
        .applyTemplateFields(template.extraFieldIds);
    await ref
        .read(reportWidgetsProvider.notifier)
        .applyTemplateWidgets(template.defaultReportWidgets);
  }

  Future<void> _onTemplateSelected(String? nextId) async {
    if (nextId == null || nextId == _activeId || _switching) {
      return;
    }
    final IndustryTemplate? template = industryTemplateById(nextId);
    if (template == null) {
      return;
    }

    final AppLocalizations l10n = context.l10n;
    final Locale locale = Localizations.localeOf(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.switchTemplateTitle),
          content: Text(
            l10n.switchTemplateBody(template.localizedName(locale)),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.switchTemplateCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.switchTemplateConfirm),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      setState(() => _dropdownEpoch++);
      return;
    }

    setState(() => _switching = true);
    await ref.read(repositoryProvider).activateIndustryTemplate(template);
    await _syncProviders(template);
    if (!mounted) {
      return;
    }
    setState(() {
      _activeId = template.id;
      _switching = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.switchTemplateDone)),
    );

    if (template.items.isEmpty) {
      return;
    }
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TemplateItemPickerScreen(template: template),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final Locale locale = Localizations.localeOf(context);
    final String? dropdownValue = industryTemplateById(_activeId ?? '') == null
        ? null
        : _activeId;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.businessTemplatesTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            l10n.templatesIntro,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.activeTemplateLabel,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            DropdownButtonFormField<String>(
              key: ValueKey<String>('$_activeId-$_dropdownEpoch'),
              initialValue: dropdownValue,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              hint: Text(l10n.activeTemplateHint),
              items: <DropdownMenuItem<String>>[
                for (final IndustryTemplate template in kIndustryTemplates)
                  DropdownMenuItem<String>(
                    value: template.id,
                    child: Text(template.localizedName(locale)),
                  ),
              ],
              onChanged: _switching ? null : _onTemplateSelected,
            ),
          if (_switching) ...<Widget>[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}

class TemplateItemPickerScreen extends ConsumerStatefulWidget {
  const TemplateItemPickerScreen({
    required this.template,
    super.key,
  });

  final IndustryTemplate template;

  @override
  ConsumerState<TemplateItemPickerScreen> createState() =>
      _TemplateItemPickerScreenState();
}

class _TemplateItemPickerScreenState
    extends ConsumerState<TemplateItemPickerScreen> {
  late final Set<int> _selected;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selected = Set<int>.from(
      List<int>.generate(widget.template.items.length, (int i) => i),
    );
  }

  void _selectAll() {
    setState(() {
      _selected
        ..clear()
        ..addAll(
          List<int>.generate(widget.template.items.length, (int i) => i),
        );
    });
  }

  void _clear() {
    setState(() => _selected.clear());
  }

  Future<void> _importSelected() async {
    if (_selected.isEmpty || _submitting) {
      return;
    }
    final AppLocalizations l10n = context.l10n;
    final Locale locale = Localizations.localeOf(context);
    final List<TemplateInventoryItem> selected = _selected
        .map((int index) => widget.template.items[index])
        .toList();
    setState(() => _submitting = true);
    final TemplateImportResult result = await ref
        .read(repositoryProvider)
        .importTemplateInventory(selected, locale: locale);
    if (result.added > 0) {
      final List<ResourceType> importedKinds = resourceTypesFromTemplateItems(
        selected,
      );
      await ref
          .read(enabledResourceTypesProvider.notifier)
          .unionTypes(importedKinds);
    }
    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.templateImportResult(result.added, result.skipped),
        ),
      ),
    );
    if (result.added > 0) {
      ref.read(currentTabIndexProvider.notifier).state = kTabIndexInventory;
      Navigator.of(context).popUntil((Route<void> route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final Locale locale = Localizations.localeOf(context);
    final IndustryTemplate template = widget.template;
    return Scaffold(
      appBar: AppBar(title: Text(template.localizedName(locale))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            template.localizedDescription(locale),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              TextButton(onPressed: _selectAll, child: Text(l10n.selectAll)),
              TextButton(onPressed: _clear, child: Text(l10n.clearSelection)),
              const Spacer(),
              Text(
                l10n.selectedCount(_selected.length),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...List<Widget>.generate(template.items.length, (int index) {
            final TemplateInventoryItem item = template.items[index];
            final bool checked = _selected.contains(index);
            final String unitsLabel = item.defaultUnits == 1
                ? l10n.unitSingular(item.defaultUnits)
                : l10n.unitPlural(item.defaultUnits);
            return CheckboxListTile(
              value: checked,
              contentPadding: EdgeInsets.zero,
              title: Text(item.localizedName(locale)),
              subtitle: Text(
                l10n.templateItemSubtitle(
                  item.localizedCategory(locale),
                  unitsLabel,
                ),
              ),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selected.add(index);
                  } else {
                    _selected.remove(index);
                  }
                });
              },
            );
          }),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: FilledButton(
          onPressed: _selected.isEmpty || _submitting ? null : _importSelected,
          child: Text(
            _submitting ? l10n.adding : l10n.addSelectedToResources,
          ),
        ),
      ),
    );
  }
}
