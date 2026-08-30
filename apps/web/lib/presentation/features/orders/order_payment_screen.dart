import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../infrastructure/l10n/l10n_ext.dart';
import '../../../domain/models/entities.dart';
import '../../../domain/orders/commercial_policy.dart';
import '../../../domain/orders/order_payment.dart';
import '../../../domain/payments/payment_reference.dart';
import '../../../domain/pricing/rental_pricing.dart';
import '../../../domain/templates/industry_templates.dart';
import '../../../application/providers/app_providers.dart';
import '../../widgets/ui_primitives.dart';

/// Payment opened from order detail: sell min due, editable rental security,
/// amount received.
class OrderPaymentScreen extends ConsumerStatefulWidget {
  const OrderPaymentScreen({
    required this.rentalId,
    super.key,
  });

  final String rentalId;

  @override
  ConsumerState<OrderPaymentScreen> createState() => _OrderPaymentScreenState();
}

class _OrderPaymentScreenState extends ConsumerState<OrderPaymentScreen> {
  final TextEditingController _securityController = TextEditingController();
  final TextEditingController _receivedController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  bool _seeded = false;
  bool _treatExcessAsDiscount = false;
  bool _submitting = false;
  Map<ResourceType, CommercialPolicy>? _templateByType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final String? id =
          await ref.read(repositoryProvider).selectedIndustryTemplateId();
      if (!mounted) {
        return;
      }
      setState(() {
        _templateByType =
            id == null ? null : industryTemplateById(id)?.commercialByType;
      });
    });
  }

  @override
  void dispose() {
    _securityController.dispose();
    _receivedController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  AggregatedOrderCommercial _aggregated(
    Rental rental,
    List<InventoryItem> inventory,
  ) {
    final Map<String, InventoryItem> byId = <String, InventoryItem>{
      for (final InventoryItem item in inventory) item.id: item,
    };
    return resolveRentalCommercial(
      rental,
      byId,
      templateByType: _templateByType,
    );
  }

  void _seedFields(
    Rental rental,
    List<InventoryItem> inventory,
    AggregatedOrderCommercial commercial,
  ) {
    if (_seeded) {
      return;
    }
    final int suggested =
        commercial.showSecurity ? commercial.suggestedSecurityPaise : 0;
    final int sellOutstanding = rental.sellOutstandingPaise;
    if (commercial.showSecurity) {
      _securityController.text = paiseToRupeesField(suggested);
    } else {
      _securityController.text = '0';
    }
    final int receivedSeed = commercial.showPay || sellOutstanding > 0
        ? sellOutstanding + suggested
        : suggested;
    _receivedController.text = paiseToRupeesField(receivedSeed);
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
            referenceCode: optionalMoneyNote(_referenceController.text),
            treatExcessAsDiscount: _treatExcessAsDiscount,
          );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
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
    final AggregatedOrderCommercial commercial =
        _aggregated(rental, inventory);
    _seedFields(rental, inventory, commercial);

    final int sellDue = rental.sellDuePaise;
    final int sellOutstanding = rental.sellOutstandingPaise;
    final bool showSecurity = commercial.showSecurity;
    final bool showPay = commercial.showPay || sellOutstanding > 0;
    final int securityPaise = showSecurity ? _securityPaise() : 0;
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
          if (showPay) ...<Widget>[
            MoneyStack(
              label: l10n.paymentMinSoldLabel,
              amount: formatMoney(sellDue),
              emphasis: MoneyStackEmphasis.total,
            ),
            if (rental.sellPaidPaise > 0)
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
            if (sellOutstanding > 0)
              MoneyStack(
                label: l10n.paymentSellOutstandingLabel,
                amount: formatMoney(sellOutstanding),
                emphasis: MoneyStackEmphasis.due,
              ),
            const SizedBox(height: 12),
          ],
          if (showSecurity) ...<Widget>[
            MoneyAmountField(
              controller: _securityController,
              allowDecimal: true,
              labelText: l10n.paymentSecurityLabel,
              hintText: l10n.paymentSecurityHint,
              helperText: l10n.paymentSecurityHelper,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
          ],
          MoneyAmountField(
            controller: _receivedController,
            allowDecimal: true,
            labelText: l10n.paymentAmountReceivedLabel,
            hintText: l10n.paymentAmountReceivedHint,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _referenceController,
            maxLength: kMoneyNoteMaxLength,
            decoration: InputDecoration(
              labelText: l10n.loanNoteOptionalLabel,
              hintText: l10n.paymentReferenceHint,
              counterText: '',
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (hasExcess) ...<Widget>[
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.paymentTreatExcessAsDiscount),
              subtitle: Text(l10n.paymentTreatExcessAsDiscountHint),
              value: _treatExcessAsDiscount,
              onChanged: (bool value) {
                setState(() => _treatExcessAsDiscount = value);
              },
            ),
          ],
          const SizedBox(height: 16),
          Text(
            l10n.paymentAllocationPreview,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          MoneyStack(
            label: l10n.paymentPreviewSellCovered,
            amount: formatMoney(preview.sellPaidDelta),
            emphasis: MoneyStackEmphasis.muted,
          ),
          MoneyStack(
            label: l10n.paymentPreviewSellDiscount,
            amount: formatMoney(preview.sellDiscountDelta),
            emphasis: MoneyStackEmphasis.muted,
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
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: _submitting ? null : () => _confirm(rental),
            child: Text(l10n.paymentConfirmAction),
          ),
        ),
      ),
    );
  }
}

/// Opens payment for [rentalId] from order detail (push; pop on confirm).
void pushOrderPayment(
  BuildContext context, {
  required String rentalId,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => OrderPaymentScreen(rentalId: rentalId),
    ),
  );
}
