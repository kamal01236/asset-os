import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/app_providers.dart';
import '../../../domain/models/entities.dart';
import '../../../domain/payments/payment_reference.dart';
import '../../../domain/pricing/rental_pricing.dart';
import '../../../domain/validation/text_rules.dart';
import '../../../domain/verification/verification_models.dart';
import '../../../infrastructure/l10n/india_date_format.dart';
import '../../../infrastructure/l10n/l10n_ext.dart';
import '../../widgets/ui_primitives.dart';
import 'return_verification_sheet.dart';

Future<void> showAddOrderNoteSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Rental rental,
}) async {
  final AppLocalizations l10n = context.l10n;
  final TextEditingController bodyController = TextEditingController();
  RentalNoteKind kind = RentalNoteKind.general;
  String? selectedLineId;

  final bool? saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
        ),
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    l10n.addOrderNoteAction,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<RentalNoteKind>(
                    key: ValueKey<RentalNoteKind>(kind),
                    initialValue: kind,
                    decoration: InputDecoration(
                      labelText: l10n.orderNoteKindLabel,
                    ),
                    items: RentalNoteKind.values
                        .map(
                          (RentalNoteKind value) =>
                              DropdownMenuItem<RentalNoteKind>(
                            value: value,
                            child: Text(localizedRentalNoteKind(l10n, value)),
                          ),
                        )
                        .toList(),
                    onChanged: (RentalNoteKind? value) {
                      if (value == null) {
                        return;
                      }
                      setSheetState(() => kind = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    key: ValueKey<String>('line-${selectedLineId ?? 'all'}'),
                    initialValue: selectedLineId,
                    decoration: InputDecoration(
                      labelText: l10n.orderNoteLineLabel,
                    ),
                    items: <DropdownMenuItem<String?>>[
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(l10n.orderNoteWholeOrder),
                      ),
                      ...rental.lines.map(
                        (RentalLine line) => DropdownMenuItem<String?>(
                          value: line.id,
                          child: Text(line.displayLabel),
                        ),
                      ),
                    ],
                    onChanged: (String? value) {
                      setSheetState(() => selectedLineId = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bodyController,
                    minLines: 3,
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText: l10n.orderNoteBodyLabel,
                      hintText: l10n.orderNoteBodyHint,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(true),
                    child: Text(l10n.addOrderNoteAction),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );

  final String body = bodyController.text;
  bodyController.dispose();
  if (saved != true || !context.mounted) {
    return;
  }
  if (!meetsMinMeaningfulText(body)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.minMeaningfulTextError(kMinMeaningfulTextLength)),
      ),
    );
    return;
  }

  try {
    await ref.read(repositoryProvider).addRentalNote(
          rentalId: rental.id,
          rentalItemId: selectedLineId,
          body: body,
          kind: kind.storageValue,
        );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.orderNoteAddedSnack)),
    );
  } on ArgumentError catch (error) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.message?.toString() ?? error.toString())),
    );
  }
}

String returnSettlementSnack(AppLocalizations l10n, RentalReturnResult result) {
  if (result.depositApplied <= 0) {
    return l10n.depositReturnSnackNoDeposit(formatMoney(result.totalAmount));
  }
  if (result.amountDue > 0) {
    return l10n.depositReturnSnackDue(
      formatMoney(result.depositApplied),
      formatMoney(result.amountDue),
    );
  }
  return l10n.depositReturnSnackApplied(
    formatMoney(result.depositApplied),
    formatMoney(result.depositBalanceAfter),
  );
}

Future<bool> confirmAndMarkLinesLost({
  required BuildContext context,
  required WidgetRef ref,
  required Rental rental,
  required List<String> lineIds,
}) async {
  final AppLocalizations l10n = context.l10n;
  final Set<String> wanted = lineIds.toSet();
  final List<RentalLine> targets = rental.openRentLines
      .where((RentalLine l) => wanted.contains(l.id))
      .toList();
  if (targets.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.noLinesSelected)),
    );
    return false;
  }

  final VerificationSettings verification =
      ref.read(verificationSettingsProvider);
  final ReturnConditionCapture? condition = await showReturnConditionSheet(
    context: context,
    ref: ref,
    rentalId: rental.id,
    mode: verification.conditionMode,
    checklistItems: verification.checklistItems,
    isLost: true,
  );
  if (!context.mounted || condition == null) {
    return false;
  }

  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(l10n.confirmMarkLostTitle),
        content: Text(l10n.confirmMarkLostBody(targets.length)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.confirmMarkLostAction),
          ),
        ],
      );
    },
  );
  if (confirmed != true || !context.mounted) {
    return false;
  }

  final RentalReturnResult? result = await ref
      .read(repositoryProvider)
      .markRentalLinesLost(
        rental.id,
        targets.map((RentalLine l) => l.id).toList(),
        conditionNote: condition.conditionNote,
        mediaIds: condition.mediaIds,
        checklist: condition.checklist,
      );
  if (!context.mounted) {
    return result != null;
  }
  if (result == null) {
    return false;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        '${l10n.unitsLostSnack(result.lostLineIds.length)} '
        '${returnSettlementSnack(l10n, result)}',
      ),
    ),
  );
  return true;
}

Future<bool> confirmAndCompleteJobs({
  required BuildContext context,
  required WidgetRef ref,
  required Rental rental,
  required List<String> lineIds,
}) async {
  final AppLocalizations l10n = context.l10n;
  final Set<String> wanted = lineIds.toSet();
  final List<RentalLine> targets = rental.openJobLines
      .where((RentalLine l) => wanted.contains(l.id))
      .toList();
  if (targets.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.noLinesSelected)),
    );
    return false;
  }

  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(l10n.confirmCompleteJobsTitle),
        content: Text(l10n.confirmCompleteJobsBody(targets.length)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.markCompleteSelectedAction),
          ),
        ],
      );
    },
  );
  if (confirmed != true || !context.mounted) {
    return false;
  }

  final RentalReturnResult? result = await ref
      .read(repositoryProvider)
      .completeJobLines(
        rental.id,
        targets.map((RentalLine l) => l.id).toList(),
      );
  if (!context.mounted) {
    return false;
  }
  if (result == null) {
    return false;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(l10n.jobsCompletedSnack)),
  );
  return true;
}

Future<void> extendRentalDue({
  required BuildContext context,
  required WidgetRef ref,
  required Rental rental,
}) async {
  final AppLocalizations l10n = context.l10n;
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime currentDue = rental.dueAt == null
      ? today
      : DateTime(rental.dueAt!.year, rental.dueAt!.month, rental.dueAt!.day);
  final DateTime firstAllowed = currentDue.isBefore(today)
      ? today
      : currentDue.add(const Duration(days: 1));
  final DateTime? picked = await showDatePicker(
    context: context,
    locale: indiaDatePickerLocale(context),
    initialDate: firstAllowed,
    firstDate: firstAllowed,
    lastDate: today.add(const Duration(days: 365 * 5)),
    helpText: l10n.extendDueTitle,
  );
  if (picked == null || !context.mounted) {
    return;
  }
  try {
    final bool ok = await ref.read(repositoryProvider).extendRentalDue(
          rental.id,
          picked,
        );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? l10n.extendDueSuccess : l10n.extendDueInvalid),
      ),
    );
  } on ArgumentError {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.extendDueInvalid)),
    );
  }
}

Future<bool> confirmAndReturnRental({
  required BuildContext context,
  required WidgetRef ref,
  required Rental rental,
  required Customer customer,
  List<String>? lineIds,
}) async {
  final AppLocalizations l10n = context.l10n;
  final DateTime now = DateTime.now();
  final List<RentalLine> targets;
  if (lineIds == null || lineIds.isEmpty) {
    targets = rental.openRentLines;
  } else {
    final Set<String> wanted = lineIds.toSet();
    targets =
        rental.openRentLines.where((RentalLine l) => wanted.contains(l.id)).toList();
  }
  if (targets.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.noLinesSelected)),
    );
    return false;
  }

  final VerificationSettings verification =
      ref.read(verificationSettingsProvider);
  final ReturnConditionCapture? condition = await showReturnConditionSheet(
    context: context,
    ref: ref,
    rentalId: rental.id,
    mode: verification.conditionMode,
    checklistItems: verification.checklistItems,
  );
  if (!context.mounted || condition == null) {
    return false;
  }

  int computedTotal = 0;
  for (final RentalLine line in targets) {
    computedTotal += line.totalAmountAsOf(rental.startedAt, rental.dueAt, now);
  }

  final TextEditingController finalAmountController = TextEditingController(
    text: paiseToRupeesField(computedTotal),
  );
  final TextEditingController noteController = TextEditingController();

  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          final int parsedFinal = parseRupeesToPaise(finalAmountController.text);
          final int finalAmount = parsedFinal.clamp(0, computedTotal);
          final int discount =
              (computedTotal - finalAmount).clamp(0, computedTotal);
          final int willApply = rental.depositRemaining < finalAmount
              ? rental.depositRemaining
              : finalAmount;
          final int remainingDue = finalAmount - willApply;
          final int leftover = rental.depositRemaining - willApply;

          return AlertDialog(
            title: Text(l10n.returnSettlementTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ...targets.map(
                    (RentalLine line) => Text(
                      l10n.lineChargePreview(
                        line.displayLabel,
                        formatMoney(
                          line.totalAmountAsOf(
                            rental.startedAt,
                            rental.dueAt,
                            now,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.chargeTotalLabel(formatMoney(computedTotal))),
                  const SizedBox(height: 8),
                  MoneyAmountField(
                    controller: finalAmountController,
                    allowDecimal: true,
                    labelText: l10n.returnFinalAmountLabel,
                    hintText: l10n.returnFinalAmountHint,
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 6),
                  Text(l10n.returnDiscountLabel(formatMoney(discount))),
                  Text(
                    l10n.depositAvailableLabel(
                      formatMoney(rental.depositRemaining),
                    ),
                  ),
                  Text(l10n.depositWillApplyLabel(formatMoney(willApply))),
                  if (remainingDue > 0)
                    Text(
                      l10n.depositRemainingDueLabel(formatMoney(remainingDue)),
                    )
                  else if (leftover > 0)
                    Text(l10n.depositLeftoverLabel(formatMoney(leftover))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteController,
                    maxLength: kMoneyNoteMaxLength,
                    decoration: InputDecoration(
                      labelText: l10n.returnNoteLabel,
                      hintText: l10n.returnNoteHint,
                      counterText: '',
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.confirmReturnAction),
              ),
            ],
          );
        },
      );
    },
  );

  final int chargedTotal =
      parseRupeesToPaise(finalAmountController.text).clamp(0, computedTotal);
  final String? note = optionalMoneyNote(noteController.text);
  finalAmountController.dispose();
  noteController.dispose();

  if (confirmed != true || !context.mounted) {
    return false;
  }

  final RentalReturnResult? result = await ref
      .read(repositoryProvider)
      .returnRentalLines(
        rental.id,
        targets.map((RentalLine l) => l.id).toList(),
        chargedTotalPaise: chargedTotal,
        note: note,
        conditionNote: condition.conditionNote,
        mediaIds: condition.mediaIds,
        checklist: condition.checklist,
      );
  if (!context.mounted) {
    return result != null;
  }
  if (result == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.rentalReturned(rental.id))),
    );
    return false;
  }
  final String snack = result.rentalClosed
      ? returnSettlementSnack(l10n, result)
      : '${l10n.partialReturnSnack(result.returnedLineIds.length)} '
          '${returnSettlementSnack(l10n, result)}';
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(snack)),
  );
  return true;
}

Future<bool> confirmAndCancelOrder({
  required BuildContext context,
  required WidgetRef ref,
  required Rental rental,
  required Customer customer,
}) async {
  final AppLocalizations l10n = context.l10n;
  final TextEditingController keptController =
      TextEditingController(text: '0');
  final TextEditingController returnedController =
      TextEditingController(text: '0');
  final TextEditingController noteController = TextEditingController();

  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(l10n.deleteOrderTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.depositAvailableLabel(
                  formatMoney(rental.depositRemaining),
                ),
              ),
              const SizedBox(height: 8),
              MoneyAmountField(
                controller: keptController,
                allowDecimal: true,
                labelText: l10n.deleteOrderKeptLabel,
                hintText: l10n.depositAmountHint,
              ),
              const SizedBox(height: 8),
              MoneyAmountField(
                controller: returnedController,
                allowDecimal: true,
                labelText: l10n.deleteOrderReturnedLabel,
                hintText: l10n.depositAmountHint,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                maxLength: kMoneyNoteMaxLength,
                decoration: InputDecoration(
                  labelText: l10n.deleteOrderNoteLabel,
                  hintText: l10n.returnNoteHint,
                  counterText: '',
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.confirmDeleteOrderAction),
          ),
        ],
      );
    },
  );

  final int keptPaise = parseRupeesToPaise(keptController.text);
  final int returnedPaise = parseRupeesToPaise(returnedController.text);
  final String? note = optionalMoneyNote(noteController.text);
  keptController.dispose();
  returnedController.dispose();
  noteController.dispose();

  if (confirmed != true || !context.mounted) {
    return false;
  }
  if (keptPaise < 0 || returnedPaise < 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.deleteOrderInvalidSettlement)),
    );
    return false;
  }
  if (keptPaise + returnedPaise > rental.depositRemaining) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.deleteOrderInvalidSettlement)),
    );
    return false;
  }

  try {
    final OrderCancelResult? result =
        await ref.read(repositoryProvider).cancelOrder(
              rentalId: rental.id,
              amountKeptPaise: keptPaise,
              amountReturnedPaise: returnedPaise,
              note: note,
            );
    if (!context.mounted) {
      return result != null;
    }
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deleteOrderFailed)),
      );
      return false;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.deleteOrderSuccessSnack(
            formatMoney(result.depositBalanceAfter),
          ),
        ),
      ),
    );
    return true;
  } on StateError {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deleteOrderBlockedPartial)),
      );
    }
    return false;
  } on ArgumentError {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deleteOrderInvalidSettlement)),
      );
    }
    return false;
  }
}
