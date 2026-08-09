import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n_ext.dart';
import '../../core/models/entities.dart';
import '../../core/providers/app_providers.dart';

/// More → toggle which [ResourceType]s gate New Order fulfillment chrome.
class EnabledResourceTypesScreen extends ConsumerWidget {
  const EnabledResourceTypesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final List<ResourceType> enabled = ref.watch(enabledResourceTypesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.enabledResourceTypesTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            l10n.enabledResourceTypesIntro,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ...ResourceType.values.map((ResourceType type) {
            final bool isOn = enabled.contains(type);
            final bool lastOn = isOn && enabled.length <= 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: SwitchListTile(
                  value: isOn,
                  title: Text(localizedResourceTypeLabel(l10n, type)),
                  subtitle: lastOn
                      ? Text(l10n.enabledResourceTypesKeepOne)
                      : null,
                  onChanged: lastOn
                      ? null
                      : (bool value) {
                          ref
                              .read(enabledResourceTypesProvider.notifier)
                              .setTypeEnabled(type, value);
                        },
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
