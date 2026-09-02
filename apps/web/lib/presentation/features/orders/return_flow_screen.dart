import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/app_providers.dart';
import '../../../domain/models/entities.dart';
import '../../../domain/pricing/rental_pricing.dart';
import '../../../infrastructure/l10n/india_date_format.dart';
import '../../../infrastructure/l10n/l10n_ext.dart';
import '../../privacy/privacy_display.dart';
import '../../widgets/ui_primitives.dart';
import 'rental_detail_screen.dart';
import 'rental_labels.dart';

class ReturnFlowScreen extends ConsumerWidget {
  const ReturnFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<Rental>> rentalsAsync = ref.watch(rentalsProvider);
    return rentalsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (Object error, StackTrace _) => Scaffold(body: Center(child: Text('$error'))),
      data: (List<Rental> rentals) {
        final List<Rental> active = rentals
            .where(
              (Rental item) =>
                  item.isActive && item.openRentLines.isNotEmpty,
            )
            .toList();
        return Scaffold(
          appBar: AppBar(title: Text(l10n.actionReturnItem)),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: active.isEmpty
                ? EmptyStatePane(
                    title: l10n.noActiveRentalsTitle,
                    subtitle: l10n.noActiveRentalsSubtitle,
                    ctaLabel: l10n.backToHome,
                    onPressed: () => Navigator.of(context).pop(),
                  )
                : ListView.separated(
                    itemBuilder: (BuildContext context, int index) {
                      final Rental rental = active[index];
                      final DateTime now = DateTime.now();
                      final int total = rental.totalAmountAsOf(now);
                      final int willApply = rental.depositRemaining < total
                          ? rental.depositRemaining
                          : total;
                      final String openBit = rental.openRentLines.length <
                              rental.lines.length
                          ? l10n.linesOpenCount(
                              rental.openRentLines.length,
                              rental.lines.length,
                            )
                          : '';
                      return EntityCard(
                        title: rentalLinesLabel(rental),
                        subtitle: <String>[
                          rental.isOpenEnded
                              ? l10n.rentalAmountOpenEnded(
                                  displayMoney(context, ref, total),
                                )
                              : l10n.rentalAmountSubtitle(
                                  formatIndiaDate(rental.dueAt!),
                                  displayMoney(context, ref, total),
                                ),
                          if (rental.isOpenEnded) l10n.accruedAmountHint,
                          if (openBit.isNotEmpty) openBit,
                          if (rental.depositRemaining > 0)
                            l10n.depositWillApplyLabel(formatMoney(willApply)),
                        ].join('\n'),
                        leadingIcon: Icons.assignment_return_outlined,
                        status: rental.statusFor(now),
                        trailing: FilledButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    RentalDetailScreen(rentalId: rental.id),
                              ),
                            );
                          },
                          child: Text(l10n.actionReturn),
                        ),
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemCount: active.length,
                  ),
          ),
        );
      },
    );
  }
}
