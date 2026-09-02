import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/app_providers.dart';
import '../../../domain/models/entities.dart';
import '../../../domain/models/unknown_customer.dart';
import '../../../domain/orders/commercial_policy.dart';
import '../../../domain/pricing/rental_pricing.dart';
import '../../../domain/templates/workflows.dart';
import '../../../infrastructure/l10n/india_date_format.dart';
import '../../../infrastructure/l10n/l10n_ext.dart';
import '../../privacy/privacy_display.dart';
import '../../widgets/rental_timeline.dart';
import '../../widgets/ui_primitives.dart';
import '../customers/customer_detail_screen.dart';
import 'order_action_dialogs.dart';
import 'order_payment_screen.dart';
import 'rental_labels.dart';
import 'return_verification_sheet.dart';

/// Open rent lines grouped by catalog item (SKU), preserving first-seen order.
List<MapEntry<String, List<RentalLine>>> _groupRentLinesByItemId(
  List<RentalLine> lines,
) {
  final Map<String, List<RentalLine>> grouped = <String, List<RentalLine>>{};
  final List<String> order = <String>[];
  for (final RentalLine line in lines) {
    if (!grouped.containsKey(line.itemId)) {
      order.add(line.itemId);
      grouped[line.itemId] = <RentalLine>[];
    }
    grouped[line.itemId]!.add(line);
  }
  return order
      .map(
        (String itemId) => MapEntry<String, List<RentalLine>>(
          itemId,
          grouped[itemId]!,
        ),
      )
      .toList();
}

List<String> _resolveReturnLineIds({
  required Rental rental,
  required Map<String, int> qtyByItemId,
  required Set<String> selectedLineIds,
  required Map<String, bool> identityRequiredByItemId,
}) {
  final Set<String> resolved = <String>{...selectedLineIds};
  for (final MapEntry<String, int> entry in qtyByItemId.entries) {
    if (identityRequiredByItemId[entry.key] ?? true) {
      continue;
    }
    final int qty = entry.value;
    if (qty <= 0) {
      continue;
    }
    final List<RentalLine> open = rental.openRentLines
        .where((RentalLine l) => l.itemId == entry.key)
        .toList();
    final int take = qty < open.length ? qty : open.length;
    for (int i = 0; i < take; i++) {
      resolved.add(open[i].id);
    }
  }
  return resolved.toList();
}

class RentalDetailScreen extends ConsumerStatefulWidget {
  const RentalDetailScreen({
    required this.rentalId,
    super.key,
  });

  final String rentalId;

  @override
  ConsumerState<RentalDetailScreen> createState() => _RentalDetailScreenState();
}

class _RentalDetailScreenState extends ConsumerState<RentalDetailScreen> {
  final Set<String> _selectedRentLineIds = <String>{};
  final Set<String> _selectedJobLineIds = <String>{};
  final Map<String, int> _returnQtyByItemId = <String, int>{};

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<Rental>> rentalsAsync = ref.watch(rentalsProvider);
    final AsyncValue<List<Customer>> customersAsync = ref.watch(customersProvider);
    final List<InventoryItem> inventory =
        ref.watch(inventoryProvider).asData?.value ?? const <InventoryItem>[];
    final Map<String, bool> identityRequiredByItemId = <String, bool>{
      for (final InventoryItem item in inventory)
        item.id: item.requiresUnitIdentity,
    };

    if (rentalsAsync.isLoading || customersAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<Rental> rentals = rentalsAsync.valueOrNull ?? const <Rental>[];
    final List<Customer> customers = customersAsync.valueOrNull ?? const <Customer>[];

    final Rental rental = rentals.firstWhere((item) => item.id == widget.rentalId);
    final Customer customer = customers.firstWhere((item) => item.id == rental.customerId);
    final DateTime now = DateTime.now();
    final WorkflowDefinition workflow = ref.watch(activeWorkflowProvider);
    final String? workflowStatusId = effectiveWorkflowStatusId(
      stored: rental.workflowStatus,
      orderStatus: rental.orderStatus,
      workflow: workflow,
    );
    final WorkflowStatus? workflowStatus = resolveWorkflowStatusDisplay(
      workflow: workflow,
      statusId: workflowStatusId,
    );
    final List<WorkflowStatus> nextStatuses =
        rental.isActive ? workflow.nextAllowed(workflowStatusId) : const <WorkflowStatus>[];
    final int lateShown = rental.lateAmountAsOf(now);
    final int totalShown = rental.totalAmountAsOf(now);
    final List<RentalLine> openRentLines = rental.openRentLines;
    final List<RentalLine> openJobLines = rental.openJobLines;
    final List<RentalLine> closedLines = rental.returnedLines;
    final Set<String> openRentIds =
        openRentLines.map((RentalLine l) => l.id).toSet();
    final Set<String> openJobIds =
        openJobLines.map((RentalLine l) => l.id).toSet();
    final Set<String> selectedRentIds =
        _selectedRentLineIds.where(openRentIds.contains).toSet();
    final Set<String> selectedJobIds =
        _selectedJobLineIds.where(openJobIds.contains).toSet();
    final List<String> batchReturnIds = _resolveReturnLineIds(
      rental: rental,
      qtyByItemId: _returnQtyByItemId,
      selectedLineIds: selectedRentIds,
      identityRequiredByItemId: identityRequiredByItemId,
    );
    final List<MapEntry<String, List<RentalLine>>> openRentGroups =
        _groupRentLinesByItemId(openRentLines);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            Flexible(
              child: Text(
                shortOrderId(rental.id),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            OrderStatusPill(
              status: rental.orderStatus,
              urgency: rental.isActive ? rental.statusFor(now) : null,
            ),
            if (rental.hasUnpaidSell) ...<Widget>[
              const SizedBox(width: 8),
              Chip(
                label: Text(l10n.unpaidSellBadge),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor:
                    Theme.of(context).colorScheme.errorContainer,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          ListEntityRow(
            title: rentalPartyLabel(customer, rental),
            secondary: rental.nickname?.trim().isNotEmpty == true
                ? l10n.rentalNicknameSubtitle(
                    customer.name,
                    displayPhone(context, ref, customer.phone),
                  )
                : l10n.phoneLabel(displayPhone(context, ref, customer.phone)),
            leadingIcon: Icons.person_outline,
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      CustomerDetailScreen(customerId: customer.id),
                ),
              );
            },
          ),
          if (rental.replacedFromRentalId != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              '← ${rental.replacedFromRentalId}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.workflowStatusHeading,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    workflowStatus?.localizedLabel(
                          Localizations.localeOf(context),
                        ) ??
                        localizedOrderStatus(l10n, rental.orderStatus),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (rental.isActive && nextStatuses.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              await ref
                                  .read(repositoryProvider)
                                  .advanceWorkflowStatus(rental.id);
                            },
                            child: Text(l10n.workflowAdvanceAction),
                          ),
                        ),
                        if (nextStatuses.length > 1) ...<Widget>[
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final String? picked =
                                    await showModalBottomSheet<String>(
                                  context: context,
                                  builder: (BuildContext sheetContext) {
                                    final Locale locale =
                                        Localizations.localeOf(sheetContext);
                                    return SafeArea(
                                      child: ListView(
                                        shrinkWrap: true,
                                        children: <Widget>[
                                          Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Text(
                                              l10n.workflowPickStatusAction,
                                              style: Theme.of(sheetContext)
                                                  .textTheme
                                                  .titleMedium,
                                            ),
                                          ),
                                          ...nextStatuses.map(
                                            (WorkflowStatus status) => ListTile(
                                              title: Text(
                                                status.localizedLabel(locale),
                                              ),
                                              onTap: () => Navigator.of(
                                                sheetContext,
                                              ).pop(status.id),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                                if (picked == null || !mounted) {
                                  return;
                                }
                                await ref
                                    .read(repositoryProvider)
                                    .advanceWorkflowStatus(
                                      rental.id,
                                      toStatusId: picked,
                                    );
                              },
                              child: Text(l10n.workflowPickStatusAction),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ] else if (!rental.isActive &&
                      rental.orderStatus == OrderStatus.completed) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      l10n.workflowStatusTerminalHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(l10n.itemsHeading, style: Theme.of(context).textTheme.titleSmall),
                  if (rental.isActive &&
                      (openRentLines.isNotEmpty ||
                          openJobLines.isNotEmpty)) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      l10n.linesOpenCount(
                        openRentLines.length + openJobLines.length,
                        rental.lines.length,
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (rental.isActive && openRentLines.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(l10n.returnByQuantityHint),
                    ...openRentGroups.map((MapEntry<String, List<RentalLine>> group) {
                      final String itemId = group.key;
                      final List<RentalLine> openGroup = group.value;
                      final List<RentalLine> allForSku = rental.lines
                          .where(
                            (RentalLine l) =>
                                l.itemId == itemId && l.isRent,
                          )
                          .toList();
                      final int issued = allForSku.length;
                      final int returnedCount =
                          allForSku.where((RentalLine l) => !l.isOpen).length;
                      final int remaining = openGroup.length;
                      final String catalogName =
                          openGroup.first.catalogName.trim().isEmpty
                              ? itemId
                              : openGroup.first.catalogName.trim();
                      final bool needsIdentity =
                          identityRequiredByItemId[itemId] ?? true;
                      final int returnQty =
                          (_returnQtyByItemId[itemId] ?? 0).clamp(0, remaining);

                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              catalogName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              l10n.skuIssuedReturnedRemaining(
                                issued,
                                returnedCount,
                                remaining,
                              ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (needsIdentity) ...<Widget>[
                              const SizedBox(height: 4),
                              Text(
                                l10n.pickUnitsToReturn,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              ...openGroup.map((RentalLine line) {
                                  final bool selected =
                                      selectedRentIds.contains(line.id);
                                  final int lineTotal = line.totalAmountAsOf(
                                    rental.startedAt,
                                    rental.dueAt,
                                    now,
                                  );
                                  return CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                    value: selected,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedRentLineIds.add(line.id);
                                        } else {
                                          _selectedRentLineIds.remove(line.id);
                                        }
                                      });
                                    },
                                    title: Text(line.displayLabel),
                                    subtitle: Text(
                                      '${l10n.lineOpenLabel} · ${formatMoney(lineTotal)}',
                                    ),
                                  );
                                }),
                              if (selectedRentIds.any(
                                (String id) => openGroup
                                    .any((RentalLine l) => l.id == id),
                              ))
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton(
                                    onPressed: () async {
                                      final List<String> lostIds = openGroup
                                          .where(
                                            (RentalLine l) =>
                                                selectedRentIds.contains(l.id),
                                          )
                                          .map((RentalLine l) => l.id)
                                          .toList();
                                      final bool done =
                                          await confirmAndMarkLinesLost(
                                        context: context,
                                        ref: ref,
                                        rental: rental,
                                        lineIds: lostIds,
                                      );
                                      if (!done || !mounted) {
                                        return;
                                      }
                                      setState(() {
                                        _selectedRentLineIds.removeAll(lostIds);
                                      });
                                      final Rental? updated = (await ref
                                              .read(repositoryProvider)
                                              .listRentals())
                                          .cast<Rental?>()
                                          .firstWhere(
                                            (Rental? r) => r?.id == rental.id,
                                            orElse: () => null,
                                          );
                                      if (!mounted) {
                                        return;
                                      }
                                      if (updated == null || !updated.isActive) {
                                        Navigator.of(this.context).pop();
                                      }
                                    },
                                    child: Text(l10n.markSelectedLostAction),
                                  ),
                                ),
                            ] else ...<Widget>[
                              const SizedBox(height: 6),
                              Row(
                                children: <Widget>[
                                  Text(l10n.returnQtyLabel),
                                  const Spacer(),
                                  IconButton(
                                    tooltip: l10n.returnQtyLabel,
                                    onPressed: returnQty <= 0
                                        ? null
                                        : () {
                                            setState(() {
                                              _returnQtyByItemId[itemId] =
                                                  returnQty - 1;
                                            });
                                          },
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                  ),
                                  Text(
                                    '$returnQty',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  IconButton(
                                    tooltip: l10n.returnQtyLabel,
                                    onPressed: returnQty >= remaining
                                        ? null
                                        : () {
                                            setState(() {
                                              _returnQtyByItemId[itemId] =
                                                  returnQty + 1;
                                            });
                                          },
                                    icon: const Icon(Icons.add_circle_outline),
                                  ),
                                ],
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: remaining == 0
                                      ? null
                                      : () async {
                                          final bool done =
                                              await confirmAndMarkLinesLost(
                                            context: context,
                                            ref: ref,
                                            rental: rental,
                                            lineIds: openGroup
                                                .map((RentalLine l) => l.id)
                                                .toList(),
                                          );
                                          if (!done || !mounted) {
                                            return;
                                          }
                                          setState(() {
                                            _returnQtyByItemId.remove(itemId);
                                          });
                                          final Rental? updated = (await ref
                                                  .read(repositoryProvider)
                                                  .listRentals())
                                              .cast<Rental?>()
                                              .firstWhere(
                                                (Rental? r) =>
                                                    r?.id == rental.id,
                                                orElse: () => null,
                                              );
                                          if (!mounted) {
                                            return;
                                          }
                                          if (updated == null ||
                                              !updated.isActive) {
                                            Navigator.of(this.context).pop();
                                          }
                                        },
                                  child: Text(l10n.markRemainingLostAction),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                  if (rental.isActive && openJobLines.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(l10n.selectLinesToComplete),
                    ...openJobLines.map((RentalLine line) {
                      final bool selected = selectedJobIds.contains(line.id);
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        value: selected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedJobLineIds.add(line.id);
                            } else {
                              _selectedJobLineIds.remove(line.id);
                            }
                          });
                        },
                        title: Text(line.displayLabel),
                        subtitle: Text(
                          '${l10n.lineFulfillmentJob} · ${formatMoney(line.totalAmount)}',
                        ),
                      );
                    }),
                  ],
                  if (closedLines.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      closedLinesHeading(l10n, closedLines),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    ...closedLines.map(
                      (RentalLine line) => Padding(
                        padding: const EdgeInsets.only(bottom: 4, top: 4),
                        child: Text(
                          '• ${line.displayLabel} — '
                          '${closedLineStatusLabel(l10n, line)} · '
                          '${formatMoney(line.totalAmount)}'
                          '${line.depositApplied > 0 ? ' · ${l10n.depositAppliedLabel(formatMoney(line.depositApplied))}' : ''}',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(l10n.chargesHeading, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Text(
                    rental.isOpenEnded
                        ? l10n.reviewOpenEndedLabel
                        : (rental.dueAt == null
                            ? l10n.reviewOpenEndedLabel
                            : l10n.reviewDueLabel(formatIndiaDate(rental.dueAt!))),
                  ),
                  if (rental.isOpenEnded && rental.isActive)
                    Text(l10n.accruedAmountHint),
                  Text(
                    l10n.inventoryRateSubtitle(
                      localizedBillingMode(l10n, rental.billingMode),
                      displayMoney(context, ref, rental.rateAmount),
                    ),
                  ),
                  const SizedBox(height: 8),
                  MoneyStack(
                    label: l10n.moneyLabelBase,
                    amount: displayMoney(
                      context,
                      ref,
                      rental.isOpenEnded && rental.isActive
                          ? totalShown
                          : rental.baseAmount,
                    ),
                  ),
                  if (lateShown > 0)
                    MoneyStack(
                      label: l10n.moneyLabelLate,
                      amount: displayMoney(context, ref, lateShown),
                    ),
                  MoneyStack(
                    label: l10n.moneyLabelTotal,
                    amount: displayMoney(context, ref, totalShown),
                    emphasis: MoneyStackEmphasis.total,
                  ),
                  MoneyStack(
                    label: l10n.moneyLabelDeposit,
                    amount: displayMoney(
                      context,
                      ref,
                      rental.isActive
                          ? rental.depositRemaining
                          : rental.depositAmount,
                    ),
                    emphasis: MoneyStackEmphasis.muted,
                  ),
                  if (rental.sellDuePaise > 0) ...<Widget>[
                    MoneyStack(
                      label: l10n.paymentMinSoldLabel,
                      amount: displayMoney(context, ref, rental.sellDuePaise),
                      emphasis: MoneyStackEmphasis.muted,
                    ),
                    if (rental.sellPaidPaise > 0)
                      MoneyStack(
                        label: l10n.paymentSellPaidLabel,
                        amount: displayMoney(context, ref, rental.sellPaidPaise),
                        emphasis: MoneyStackEmphasis.muted,
                      ),
                    if (rental.sellDiscountPaise > 0)
                      MoneyStack(
                        label: l10n.paymentSellDiscountLabel,
                        amount: displayMoney(context, ref, rental.sellDiscountPaise),
                        emphasis: MoneyStackEmphasis.muted,
                      ),
                    if (rental.hasUnpaidSell)
                      MoneyStack(
                        label: l10n.paymentSellOutstandingLabel,
                        amount: displayMoney(context, ref, rental.sellOutstandingPaise),
                        emphasis: MoneyStackEmphasis.due,
                      ),
                  ],
                  if (rental.isActive && openRentLines.isNotEmpty) ...<Widget>[
                    Builder(
                      builder: (BuildContext context) {
                        final List<RentalLine> settleLines = batchReturnIds.isEmpty
                            ? openRentLines
                            : openRentLines
                                .where(
                                  (RentalLine l) =>
                                      batchReturnIds.contains(l.id),
                                )
                                .toList();
                        int previewTotal = 0;
                        for (final RentalLine line in settleLines) {
                          previewTotal += line.totalAmountAsOf(
                            rental.startedAt,
                            rental.dueAt,
                            now,
                          );
                        }
                        final int willApply =
                            rental.depositRemaining < previewTotal
                                ? rental.depositRemaining
                                : previewTotal;
                        final int remainingDue = previewTotal - willApply;
                        final int leftover = rental.depositRemaining - willApply;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            MoneyStack(
                              label: l10n.moneyLabelWillApply,
                              amount: formatMoney(willApply),
                              emphasis: MoneyStackEmphasis.muted,
                            ),
                            if (remainingDue > 0)
                              MoneyStack(
                                label: l10n.moneyLabelRemainingDue,
                                amount: formatMoney(remainingDue),
                                emphasis: MoneyStackEmphasis.due,
                              )
                            else if (leftover > 0)
                              MoneyStack(
                                label: l10n.moneyLabelLeftover,
                                amount: formatMoney(leftover),
                                emphasis: MoneyStackEmphasis.muted,
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                  if (!rental.isActive) ...<Widget>[
                    if (rental.depositApplied > 0)
                      MoneyStack(
                        label: l10n.moneyLabelDeposit,
                        amount: displayMoney(context, ref, rental.depositApplied),
                        emphasis: MoneyStackEmphasis.muted,
                      ),
                    MoneyStack(
                      label: l10n.moneyLabelNetDue,
                      amount: displayMoney(context, ref, rental.amountDueAfterDeposit),
                      emphasis: rental.amountDueAfterDeposit > 0
                          ? MoneyStackEmphasis.due
                          : MoneyStackEmphasis.normal,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.orderNotesHeading,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  if (rental.notes.isEmpty)
                    Text(
                      l10n.orderNotesEmpty,
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  else
                    ...rental.notes.map((RentalNote note) {
                      final RentalLine? linked = note.rentalItemId == null
                          ? null
                          : rental.lines
                              .where(
                                (RentalLine line) =>
                                    line.id == note.rentalItemId,
                              )
                              .firstOrNull;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              localizedRentalNoteKind(l10n, note.kind),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            if (linked != null)
                              Text(
                                linked.displayLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            Text(note.body),
                            Text(
                              formatIndiaDateTime(note.createdAt),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(l10n.returnEvidenceHeading, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  RentalMediaThumbnailGrid(rentalId: rental.id),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(l10n.timelineHeading, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  RentalTimeline(events: rental.timeline),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (rental.orderStatus != OrderStatus.cancelled) ...<Widget>[
              Builder(
                builder: (BuildContext context) {
                  final Map<String, InventoryItem> byId =
                      <String, InventoryItem>{
                    for (final InventoryItem item in inventory) item.id: item,
                  };
                  final AggregatedOrderCommercial payPolicy =
                      resolveRentalCommercial(rental, byId);
                  if (!shouldShowOrderPayCta(
                    aggregated: payPolicy,
                    rental: rental,
                  )) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => pushOrderPayment(
                            context,
                            rentalId: rental.id,
                          ),
                          icon: const Icon(Icons.payments_outlined),
                          label: Text(
                            rental.hasUnpaidSell
                                ? l10n.paymentPayAction
                                : l10n.paymentAddAdvanceAction,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                },
              ),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => showAddOrderNoteSheet(
                  context: context,
                  ref: ref,
                  rental: rental,
                ),
                icon: const Icon(Icons.note_add_outlined),
                label: Text(l10n.addOrderNoteAction),
              ),
            ),
            if (rental.isActive && openRentLines.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => extendRentalDue(
                    context: context,
                    ref: ref,
                    rental: rental,
                  ),
                  icon: const Icon(Icons.event_available_outlined),
                  label: Text(l10n.extendAction),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final bool done = await confirmAndReturnRental(
                          context: context,
                          ref: ref,
                          rental: rental,
                          customer: customer,
                          lineIds: openRentLines
                              .map((RentalLine l) => l.id)
                              .toList(),
                        );
                        if (done && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Text(l10n.returnAllAction),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: batchReturnIds.isEmpty
                          ? null
                          : () async {
                              final bool done = await confirmAndReturnRental(
                                context: context,
                                ref: ref,
                                rental: rental,
                                customer: customer,
                                lineIds: batchReturnIds,
                              );
                              if (!done || !mounted) {
                                return;
                              }
                              final Rental? updated = (await ref
                                      .read(repositoryProvider)
                                      .listRentals())
                                  .cast<Rental?>()
                                  .firstWhere(
                                    (Rental? r) => r?.id == rental.id,
                                    orElse: () => null,
                                  );
                              if (!mounted) {
                                return;
                              }
                              if (updated == null || !updated.isActive) {
                                Navigator.of(this.context).pop();
                              } else {
                                setState(() {
                                  _selectedRentLineIds.clear();
                                  _returnQtyByItemId.clear();
                                });
                              }
                            },
                      child: Text(l10n.returnSelectedAction),
                    ),
                  ),
                ],
              ),
            ],
            if (rental.isActive && openJobLines.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final bool done = await confirmAndCompleteJobs(
                          context: context,
                          ref: ref,
                          rental: rental,
                          lineIds: openJobLines
                              .map((RentalLine l) => l.id)
                              .toList(),
                        );
                        if (done && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Text(l10n.markCompleteAllAction),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: selectedJobIds.isEmpty
                          ? null
                          : () async {
                              final bool done = await confirmAndCompleteJobs(
                                context: context,
                                ref: ref,
                                rental: rental,
                                lineIds: selectedJobIds.toList(),
                              );
                              if (!done || !mounted) {
                                return;
                              }
                              final Rental? updated = (await ref
                                      .read(repositoryProvider)
                                      .listRentals())
                                  .cast<Rental?>()
                                  .firstWhere(
                                    (Rental? r) => r?.id == rental.id,
                                    orElse: () => null,
                                  );
                              if (!mounted) {
                                return;
                              }
                              if (updated == null || !updated.isActive) {
                                Navigator.of(this.context).pop();
                              } else {
                                setState(() => _selectedJobLineIds.clear());
                              }
                            },
                      child: Text(l10n.markCompleteSelectedAction),
                    ),
                  ),
                ],
              ),
            ],
            if (rental.isActive && !rental.hasSettledWorkLines) ...<Widget>[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onPressed: () async {
                    final bool done = await confirmAndCancelOrder(
                      context: context,
                      ref: ref,
                      rental: rental,
                      customer: customer,
                    );
                    if (done && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(l10n.deleteOrderAction),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
