import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n_ext.dart';
import '../../core/providers/app_providers.dart';
import '../../core/repositories/local_repository.dart';
import '../../core/templates/industry_templates.dart';
import '../../core/widgets/ui_primitives.dart';

/// Pick an industry pack, multi-select starter items, merge into inventory.
class BusinessTemplatesScreen extends ConsumerWidget {
  const BusinessTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.businessTemplatesTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            l10n.templatesIntro,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 14),
          ...kIndustryTemplates.map(
            (IndustryTemplate template) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: EntityCard(
                title: template.name,
                subtitle: l10n.templateCardSubtitle(
                  template.description,
                  template.items.length,
                ),
                leadingIcon: Icons.dashboard_customize_outlined,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TemplateItemPickerScreen(template: template),
                    ),
                  );
                },
              ),
            ),
          ),
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

class _TemplateItemPickerScreenState extends ConsumerState<TemplateItemPickerScreen> {
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
        ..addAll(List<int>.generate(widget.template.items.length, (int i) => i));
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
    final List<TemplateInventoryItem> selected = _selected
        .map((int index) => widget.template.items[index])
        .toList();
    setState(() => _submitting = true);
    final TemplateImportResult result =
        await ref.read(repositoryProvider).importTemplateInventory(selected);
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
      ref.read(currentTabIndexProvider.notifier).state = 2; // Inventory
      Navigator.of(context).popUntil((Route<void> route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final IndustryTemplate template = widget.template;
    return Scaffold(
      appBar: AppBar(title: Text(template.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            template.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade700,
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
              title: Text(item.name),
              subtitle: Text(
                l10n.templateItemSubtitle(item.category, unitsLabel),
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
            _submitting ? l10n.adding : l10n.addSelectedToInventory,
          ),
        ),
      ),
    );
  }
}
