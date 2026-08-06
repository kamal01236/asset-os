import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n_ext.dart';
import '../../core/providers/app_providers.dart';

/// Toggle removable Home modules; search stays locked on.
class CustomizeHomeScreen extends ConsumerWidget {
  const CustomizeHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final List<HomeModuleId> enabled = ref.watch(homeModulesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.customizeHomeTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            l10n.customizeHomeIntro,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              value: true,
              onChanged: null,
              title: Text(l10n.moduleSearch),
              subtitle: Text(l10n.moduleSearchLocked),
            ),
          ),
          const SizedBox(height: 10),
          ...kRemovableHomeModules.map((HomeModuleId id) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: SwitchListTile(
                  value: enabled.contains(id),
                  title: Text(_moduleTitle(l10n, id)),
                  subtitle: Text(_moduleSubtitle(l10n, id)),
                  onChanged: (bool value) {
                    ref.read(homeModulesProvider.notifier).setEnabled(id, value);
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

String _moduleTitle(AppLocalizations l10n, HomeModuleId id) {
  switch (id) {
    case HomeModuleId.search:
      return l10n.moduleSearch;
    case HomeModuleId.kpis:
      return l10n.moduleKpis;
    case HomeModuleId.filterResults:
      return l10n.moduleFilterResults;
    case HomeModuleId.needsAttention:
      return l10n.moduleNeedsAttention;
    case HomeModuleId.pendingJobs:
      return l10n.modulePendingJobs;
    case HomeModuleId.pendingLoans:
      return l10n.modulePendingLoans;
    case HomeModuleId.dueLoans:
      return l10n.moduleDueLoans;
    case HomeModuleId.quickActions:
      return l10n.moduleQuickActions;
    case HomeModuleId.recentActivity:
      return l10n.moduleRecentActivity;
    case HomeModuleId.suggestions:
      return l10n.moduleSuggestions;
  }
}

String _moduleSubtitle(AppLocalizations l10n, HomeModuleId id) {
  switch (id) {
    case HomeModuleId.search:
      return l10n.moduleSearchLocked;
    case HomeModuleId.kpis:
      return l10n.moduleKpisSubtitle;
    case HomeModuleId.filterResults:
      return l10n.moduleFilterResultsSubtitle;
    case HomeModuleId.needsAttention:
      return l10n.moduleNeedsAttentionSubtitle;
    case HomeModuleId.pendingJobs:
      return l10n.modulePendingJobsSubtitle;
    case HomeModuleId.pendingLoans:
      return l10n.modulePendingLoansSubtitle;
    case HomeModuleId.dueLoans:
      return l10n.moduleDueLoansSubtitle;
    case HomeModuleId.quickActions:
      return l10n.moduleQuickActionsSubtitle;
    case HomeModuleId.recentActivity:
      return l10n.moduleRecentActivitySubtitle;
    case HomeModuleId.suggestions:
      return l10n.moduleSuggestionsSubtitle;
  }
}
