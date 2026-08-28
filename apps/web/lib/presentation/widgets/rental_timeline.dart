import 'package:flutter/material.dart';

import '../../infrastructure/l10n/india_date_format.dart';
import '../../infrastructure/l10n/l10n_ext.dart';
import '../../infrastructure/l10n/timeline_l10n.dart';
import '../../domain/models/entities.dart';

class RentalTimeline extends StatelessWidget {
  const RentalTimeline({
    required this.events,
    super.key,
  });

  final List<RentalEvent> events;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    if (events.isEmpty) {
      return Text(
        l10n.timelineEmpty,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (BuildContext context, int index) {
        final RentalEvent event = events[index];
        final bool isPaymentReceived =
            event.title == TimelineTitleKey.paymentReceived;
        final String? ref = event.referenceCode?.trim();
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    localizeTimelineTitle(l10n, event.title),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (isPaymentReceived &&
                      ref != null &&
                      ref.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      l10n.timelinePaymentRef(ref),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(localizeTimelineSubtitle(l10n, event.subtitle)),
                  Text(
                    formatIndiaDateTime(event.at),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemCount: events.length,
    );
  }

}
