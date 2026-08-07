import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n_ext.dart';
import '../../core/models/entities.dart';
import '../../core/orders/order_payment.dart';
import '../../core/pricing/rental_pricing.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/ui_primitives.dart';
import 'rental_detail_nav.dart';

/// Post-order payment: sell min due, editable rental security, amount received.
class OrderPaymentScreen extends ConsumerStatefulWidget {
  const OrderPaymentScreen({
    required this.rentalId,
    this.afterCreate = false,
    super.key,
  });

  final String rentalId;

  /// When true (right after New Order), Skip / Pay later returns to detail.
  final bool afterCreate;

  @override
  ConsumerState<OrderPaymentScreen> createState() => _OrderPaymentScreenState();
}

class _OrderPaymentScreenState extends ConsumerState<OrderPaymentScreen> {
  final TextEditingController _securityController = TextEditingController();
  final TextEditingController _receivedController = TextEditingController();
  bool _seeded = false;
  bool _treatExcessAsDiscount = false;
  bool _submitting = false;

  @override
  void dispose() {
    _securityController.dispose();
    _receivedController.dispose();
    super.dispose();
  }

  void _seedFields(Rental rental, List<InventoryItem> inventory) {
    if (_seeded) {
      return;
    }
    final Map<String, InventoryItem> byId = <String, InventoryItem>{
      for (final InventoryItem item in inventory) item.id: item,
    };
    final int suggested = computeSuggestedSecurityPaise(rental, byId);
    final int sellOutstanding = rental.sellOutstandingPaise;
    _securityController.text = paiseToRupeesField(suggested);
    _receivedController.text = paiseToRupeesField(sellOutstanding + suggested);
    _seeded = true;
  }

  int _securityPaise() => parseRupeesToPaise(_securityController.text);

  int _receivedPaise() => parseRupeesToPaise(_receivedController.text);

  Future<void> _confirm(Rental rental) async {
    if (_submitting) {
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(repositoryProvider).recordOrderPayment(
            rentalId: rental.id,
            amountReceivedPaise: _receivedPaise(),
            securityPaise: _securityPaise(),
            treatExcessAsDiscount: _treatExcessAsDiscount,
          );
      if (!mounted) {
        return;
      }
      _finishToDetail();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }

  void _finishToDetail() {
    if (widget.afterCreate) {
      pushReplacementRentalDetail(context, rentalId: widget.rentalId);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _payLaterOrSkip({required bool sellDuePositive}) {
    if (widget.afterCreate) {
      pushReplacementRentalDetail(context, rentalId: widget.rentalId);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<Rental>> rentalsAsync = ref.watch(rentalsProvider);
    final AsyncValue<List<InventoryItem>> inventoryAsync =
        ref.watch(inventoryProvider);

    if (rentalsAsync.isLoading || inventoryAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<Rental> rentals = rentalsAsync.valueOrNull ?? const <Rental>[];
    final List<InventoryItem> inventory =
        inventoryAsync.valueOrNull ?? const <InventoryItem>[];
    final Rental rental = rentals.firstWhere(
      (Rental r) => r.id == widget.rentalId,
    );
    _seedFields(rental, inventory);

    final int sellDue = rental.sellDuePaise;
    final int sellOutstanding = rental.sellOutstandingPaise;
    final int securityPaise = _securityPaise();
    final int receivedPaise = _receivedPaise();
    final OrderPaymentAllocation preview = allocateOrderPayment(
      sellOutstandingPaise: sellOutstanding,
      amountReceivedPaise: receivedPaise < 0 ? 0 : receivedPaise,
      securityPaise: securityPaise < 0 ? 0 : securityPaise,
      treatExcessAsDiscount: _treatExcessAsDiscount,
    );
    final int remainingSellAfter = (sellOutstanding -
            preview.sellPaidDelta -
            preview.sellDiscountDelta)
        .clamp(0, sellOutstanding);
    final bool hasExcess = receivedPaise > sellOutstanding + securityPaise;
    final bool canSkipWithoutPayLater =
        sellOutstanding == 0 && widget.afterCreate;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.orderPaymentTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            l10n.orderPaymentHeading,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(l10n.orderPaymentSubtitle),
          const SizedBox(height: 16),
          MoneyStack(
            label: l10n.paymentMinSoldLabel,
            amount: formatMoney(sellDue),
            emphasis: MoneyStackEmphasis.total,
          ),
          if (rental.sellPaidPaise > 0 || rental.sellDiscountPaise > 0) ...<
              Widget>[
            MoneyStack(
              label: l10n.paymentSellPaidLabel,
              amount: formatMoney(rental.sellPaidPaise),
              emphasis: MoneyStackEmphasis.muted,
            ),
            if (rental.sellDiscountPaise > 0)
              MoneyStack(
                label: l10n.paymentSellDiscountLabel,
                amount: formatMoney(rental.sellDiscountPaise),
                emphasis: MoneyStackEmphasis.muted,
              ),
            MoneyStack(
              label: l10n.paymentSellOutstandingLabel,
              amount: formatMoney(sellOutstanding),
              emphasis: sellOutstanding > 0
                  ? MoneyStackEmphasis.due
                  : MoneyStackEmphasis.muted,
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _securityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              labelText: l10n.paymentSecurityLabel,
              hintText: l10n.paymentSecurityHint,
              helperText: l10n.paymentSecurityHelper,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _receivedController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              labelText: l10n.paymentAmountReceivedLabel,
              hintText: l10n.paymentAmountReceivedHint,
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (hasExcess) ...<Widget>[
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _treatExcessAsDiscount,
              title: Text(l10n.paymentTreatExcessAsDiscount),
              subtitle: Text(l10n.paymentTreatExcessAsDiscountHint),
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (bool? value) {
                setState(() => _treatExcessAsDiscount = value ?? false);
              },
            ),
          ],
          const SizedBox(height: 16),
          Text(
            l10n.paymentAllocationPreview,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          MoneyStack(
            label: l10n.paymentPreviewSellCovered,
            amount: formatMoney(preview.sellPaidDelta),
            emphasis: MoneyStackEmphasis.muted,
          ),
          if (preview.sellDiscountDelta > 0)
            MoneyStack(
              label: l10n.paymentPreviewSellDiscount,
              amount: formatMoney(preview.sellDiscountDelta),
              emphasis: MoneyStackEmphasis.due,
            ),
          MoneyStack(
            label: l10n.paymentPreviewAdvance,
            amount: formatMoney(preview.advanceDelta),
            emphasis: MoneyStackEmphasis.muted,
          ),
          MoneyStack(
            label: l10n.paymentPreviewRemainingSell,
            amount: formatMoney(remainingSellAfter),
            emphasis: remainingSellAfter > 0
                ? MoneyStackEmphasis.due
                : MoneyStackEmphasis.muted,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _submitting ? null : () => _confirm(rental),
                child: Text(l10n.paymentConfirmAction),
              ),
            ),
            if (widget.afterCreate) ...<Widget>[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _submitting
                      ? null
                      : () => _payLaterOrSkip(
                            sellDuePositive: sellOutstanding > 0,
                          ),
                  child: Text(
                    canSkipWithoutPayLater
                        ? l10n.paymentSkipAction
                        : l10n.paymentPayLaterAction,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Opens payment for [rentalId]; [afterCreate] replaces the route stack to detail.
void pushOrderPayment(
  BuildContext context, {
  required String rentalId,
  bool afterCreate = false,
}) {
  final NavigatorState navigator = Navigator.of(context);
  final MaterialPageRoute<void> route = MaterialPageRoute<void>(
    builder: (_) => OrderPaymentScreen(
      rentalId: rentalId,
      afterCreate: afterCreate,
    ),
  );
  if (afterCreate) {
    navigator.pushReplacement(route);
  } else {
    navigator.push(route);
  }
}
