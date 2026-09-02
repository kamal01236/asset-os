import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/local_repository.dart';
import '../../../application/providers/app_providers.dart';
import '../../../infrastructure/l10n/india_date_format.dart';
import '../../../infrastructure/l10n/l10n_ext.dart';
import '../../widgets/ui_primitives.dart';

String localizedAuditEventLabel(AppLocalizations l10n, String event) {
  switch (event) {
    case 'customer_upsert':
      return l10n.auditEventCustomerUpsert;
    case 'inventory_add':
      return l10n.auditEventInventoryAdd;
    case 'inventory_update':
      return l10n.auditEventInventoryUpdate;
    case 'inventory_delete':
      return l10n.auditEventInventoryDelete;
    case 'inventory_archive':
      return l10n.auditEventInventoryArchive;
    case 'inventory_restore':
      return l10n.auditEventInventoryRestore;
    case 'backup_restore':
      return l10n.auditEventBackupRestore;
    case 'settings_changed':
      return l10n.auditEventSettingsChanged;
    default:
      return l10n.auditEventUnknown(event);
  }
}

/// Read-only reverse-chronological audit feed (More → Activity log).
class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<AuditEvent>> eventsAsync =
        ref.watch(auditEventsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.activityLogTitle)),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace _) => Center(child: Text('$error')),
        data: (List<AuditEvent> events) {
          if (events.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      l10n.activityLogEmptyTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.activityLogEmptySubtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (BuildContext context, int index) {
              final AuditEvent event = events[index];
              final String title = localizedAuditEventLabel(l10n, event.event);
              final List<String> meta = <String>[
                event.entityType,
                if (event.entityId != null && event.entityId!.isNotEmpty)
                  event.entityId!,
                formatIndiaDateTime(event.createdAt),
              ];
              return ListEntityRow(
                title: title,
                secondary: meta.join(' · '),
                tertiary: event.details,
                leadingIcon: Icons.history,
              );
            },
          );
        },
      ),
    );
  }
}
