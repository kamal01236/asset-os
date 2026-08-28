import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/inventory/inventory_categories.dart';
import '../../../infrastructure/l10n/india_date_format.dart';
import '../../../infrastructure/l10n/l10n_ext.dart';
import '../../../domain/models/entities.dart';
import '../../../domain/models/unknown_customer.dart';
import '../../../domain/orders/commercial_policy.dart';
import '../../../domain/payments/payment_reference.dart';
import '../../../domain/pricing/rental_pricing.dart';
import '../../../domain/subscriptions/subscription_coverage.dart';
import '../../../domain/subscriptions/subscription_models.dart';
import '../../../domain/templates/industry_templates.dart';
import '../../../application/providers/app_providers.dart';
import '../../../application/local_repository.dart';
import '../../validation/input_formatters.dart';
import '../../../domain/validation/text_rules.dart';
import '../../widgets/ui_primitives.dart';
import 'rental_detail_nav.dart';

/// New Order flow: items first (with running total), then customer, then
/// order summary (sample bill), then generate.
///
/// Available unit counts are shown for awareness only — quantity and generate
/// are not blocked when the order exceeds stock.
///
/// When [initialCustomerId] is set for a normal customer, the customer step is
/// skipped and the flow is items → summary → generate.
class NewOrderFlowScreen extends ConsumerStatefulWidget {
  const NewOrderFlowScreen({
    super.key,
    this.initialCustomerId,
    this.initialInventoryItemIds = const <String>[],
  });

  final String? initialCustomerId;
  final List<String> initialInventoryItemIds;

  @override
  ConsumerState<NewOrderFlowScreen> createState() => _NewOrderFlowScreenState();
}

enum _OrderPhase { form, customer, commercial, summary }

/// Soft upper bound for qty stepper (not stock-related).
const int _kMaxOrderLineQuantity = 999;

class _UnitIdentityDraft {
  _UnitIdentityDraft()
      : instanceNameController = TextEditingController(),
        shortCodeController = TextEditingController();

  final TextEditingController instanceNameController;
  final TextEditingController shortCodeController;

  void dispose() {
    instanceNameController.dispose();
    shortCodeController.dispose();
  }
}

class _OrderLineDraft {
  _OrderLineDraft({this.itemId})
      : durationController = TextEditingController(text: '1'),
        saleAmountController = TextEditingController(),
        rateController = TextEditingController() {
    ensureIdentitySlots(1);
  }

  String? itemId;
  int quantity = 1;
  LineFulfillment fulfillment = LineFulfillment.rent;
  final List<_UnitIdentityDraft> identities = <_UnitIdentityDraft>[];
  final TextEditingController durationController;
  final TextEditingController saleAmountController;
  final TextEditingController rateController;
  DateTime? customEnd;
  bool leaveOpenEnded = false;
  /// Optional unit labels when catalog does not require identity.
  bool showUnitLabels = false;

  bool get isSell => fulfillment == LineFulfillment.sell;

  bool get isJob => fulfillment == LineFulfillment.job;

  bool get usesManualAmount => isSell || isJob;

  void ensureIdentitySlots(int count) {
    final int target = count < 1 ? 1 : count;
    while (identities.length < target) {
      identities.add(_UnitIdentityDraft());
    }
    while (identities.length > target) {
      identities.removeLast().dispose();
    }
  }

  void clearIdentityFields() {
    for (final _UnitIdentityDraft unit in identities) {
      unit.instanceNameController.clear();
      unit.shortCodeController.clear();
    }
  }

  void dispose() {
    for (final _UnitIdentityDraft unit in identities) {
      unit.dispose();
    }
    durationController.dispose();
    saleAmountController.dispose();
    rateController.dispose();
  }
}

class _NewOrderFlowScreenState extends ConsumerState<NewOrderFlowScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final List<_OrderLineDraft> _lines = <_OrderLineDraft>[];
  final Map<String, List<String>> _availableCodesByItem = <String, List<String>>{};

  Customer? _resolvedCustomer;
  List<Customer> _suggestions = const <Customer>[];
  bool _noPhone = false;
  bool _submitting = false;
  bool _prefillApplied = false;
  late _OrderPhase _phase;
  Map<ResourceType, CommercialPolicy>? _templateCommercialByType;
  List<CustomerSubscription> _customerSubscriptions =
      const <CustomerSubscription>[];
  int _upsellLineIndex = -1;
  final TextEditingController _payController = TextEditingController();
  final TextEditingController _securityController = TextEditingController();
  final TextEditingController _advanceController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  bool _commercialSeeded = false;

  bool get _skipCustomerStep {
    final String? id = widget.initialCustomerId;
    if (id == null) {
      return false;
    }
    // Prefill skips only for normal customers (not Unknown / legacy SELF).
    return !isUnknownCustomerId(id) && id != kLegacySelfCustomerId;
  }

  @override
  void initState() {
    super.initState();
    // Always start on items; [_skipCustomerStep] only omits the customer phase.
    _phase = _OrderPhase.form;
    if (widget.initialInventoryItemIds.isNotEmpty) {
      for (final String id in widget.initialInventoryItemIds) {
        _lines.add(_OrderLineDraft(itemId: id));
      }
    } else {
      _lines.add(_OrderLineDraft());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTemplateCommercial();
      _applyPrefill();
      if (widget.initialInventoryItemIds.isNotEmpty) {
        _seedPrefillLabels();
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _payController.dispose();
    _securityController.dispose();
    _advanceController.dispose();
    _referenceController.dispose();
    for (final _OrderLineDraft line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _loadTemplateCommercial() async {
    final String? id =
        await ref.read(repositoryProvider).selectedIndustryTemplateId();
    if (!mounted) {
      return;
    }
    setState(() {
      _templateCommercialByType =
          id == null ? null : industryTemplateById(id)?.commercialByType;
    });
  }

  Future<void> _applyPrefill() async {
    if (_prefillApplied || !mounted) {
      return;
    }
    _prefillApplied = true;
    if (widget.initialCustomerId == null) {
      return;
    }
    final LocalRepository repository = ref.read(repositoryProvider);
    Customer? customer;
    final List<Customer> customers = await repository.listCustomers();
    final Iterable<Customer> matches = customers.where(
      (Customer c) => c.id == widget.initialCustomerId,
    );
    if (matches.isNotEmpty) {
      customer = matches.first;
    } else if (isUnknownCustomerId(widget.initialCustomerId!) ||
        widget.initialCustomerId == kLegacySelfCustomerId) {
      customer = await repository.ensureUnknownCustomer();
    }
    if (!mounted || customer == null) {
      return;
    }
    setState(() {
      _resolvedCustomer = customer;
      if (isUnknownCustomer(customer!)) {
        _noPhone = true;
        _phoneController.clear();
        _nameController.clear();
      } else {
        _noPhone = false;
        _phoneController.text = customer.phone;
        _nameController.text = customer.name;
      }
    });
  }

  int _lookupGen = 0;

  Widget? _clearSuffix(TextEditingController controller, VoidCallback onClear) {
    if (controller.text.isEmpty) {
      return null;
    }
    return IconButton(
      icon: const Icon(Icons.clear),
      onPressed: () {
        controller.clear();
        onClear();
      },
    );
  }

  Future<void> _onCustomerFieldsChanged() async {
    final int gen = ++_lookupGen;
    _clearResolvedIfEdited();
    setState(() {});
    if (!_noPhone) {
      final String phone = _phoneController.text.trim();
      if (phone.length >= 10) {
        final Customer? matched =
            await ref.read(repositoryProvider).customerByPhone(phone);
        if (!mounted || gen != _lookupGen) {
          return;
        }
        if (matched != null && !isUnknownCustomer(matched)) {
          _resolvedCustomer = matched;
          if (_nameController.text.trim().isEmpty) {
            _nameController.text = matched.name;
          }
        }
      }
    }
    if (!mounted || gen != _lookupGen) {
      return;
    }
    await _refreshSuggestions(gen: gen);
    if (mounted && gen == _lookupGen) {
      setState(() {});
    }
  }

  Future<void> _refreshSuggestions({int? gen}) async {
    final int expected = gen ?? _lookupGen;
    if (_noPhone) {
      if (_suggestions.isNotEmpty && mounted && expected == _lookupGen) {
        setState(() => _suggestions = const <Customer>[]);
      }
      return;
    }
    final LocalRepository repository = ref.read(repositoryProvider);
    final String nameQ = _nameController.text.trim();
    final String phoneQ = _phoneController.text.trim();
    final Map<String, Customer> merged = <String, Customer>{};
    if (nameQ.length >= kMinMeaningfulTextLength) {
      for (final Customer c
          in await repository.searchCustomersByNameOrPhone(nameQ)) {
        merged[c.id] = c;
      }
    }
    if (!mounted || expected != _lookupGen) {
      return;
    }
    if (phoneQ.length >= kMinMeaningfulTextLength) {
      for (final Customer c
          in await repository.searchCustomersByNameOrPhone(phoneQ)) {
        merged[c.id] = c;
      }
    }
    if (!mounted || expected != _lookupGen) {
      return;
    }
    _suggestions = merged.values.toList();
  }

  void _clearResolvedIfEdited() {
    final Customer? resolved = _resolvedCustomer;
    if (resolved == null || isUnknownCustomer(resolved)) {
      return;
    }
    if (_nameController.text.trim() != resolved.name ||
        _phoneController.text.trim() != resolved.phone) {
      _resolvedCustomer = null;
    }
  }

  void _selectSuggestion(Customer customer) {
    setState(() {
      _resolvedCustomer = customer;
      _nameController.text = customer.name;
      _phoneController.text = customer.phone;
      _noPhone = false;
      _suggestions = const <Customer>[];
    });
  }

  void _setNoPhone(bool value) {
    setState(() {
      _noPhone = value;
      _suggestions = const <Customer>[];
      if (value) {
        _resolvedCustomer = null;
        _phoneController.clear();
      } else {
        _resolvedCustomer = null;
      }
    });
  }

  bool get _customerReady {
    if (_noPhone) {
      final String name = _nameController.text.trim();
      return name.isEmpty || meetsMinMeaningfulText(name);
    }
    return _phoneController.text.trim().length >= 10 &&
        (_resolvedCustomer != null ||
            meetsMinMeaningfulText(_nameController.text));
  }

  void _addLine() {
    setState(() => _lines.add(_OrderLineDraft()));
  }

  void _removeLine(int index) {
    if (_lines.length <= 1) {
      return;
    }
    setState(() {
      _lines.removeAt(index).dispose();
    });
  }

  void _setQuantity(int index, int quantity, InventoryItem item) {
    setState(() {
      final _OrderLineDraft draft = _lines[index];
      draft.quantity = quantity.clamp(1, _kMaxOrderLineQuantity);
      if (item.requiresUnitIdentity || draft.showUnitLabels) {
        draft.ensureIdentitySlots(draft.quantity);
      }
    });
  }

  List<InventoryItem> _choicesForLine(List<InventoryItem> catalog) {
    return sortInventoryForOrderPicker(catalog);
  }

  void _applyAutoLabels(int index, InventoryItem item) {
    // Individual items get catalog name + short codes at submit.
    if (item.requiresUnitIdentity) {
      _lines[index].ensureIdentitySlots(_lines[index].quantity);
    }
  }

  LineFulfillment _defaultFulfillment(InventoryItem item) {
    return item.defaultItemKind.defaultFulfillment;
  }

  void _applyFulfillmentDefaults(_OrderLineDraft draft, InventoryItem item) {
    draft.fulfillment = _defaultFulfillment(item);
    if (draft.usesManualAmount && item.rateAmount > 0) {
      draft.saleAmountController.text = paiseToRupeesField(item.rateAmount);
    } else if (!draft.usesManualAmount) {
      draft.saleAmountController.clear();
    }
    if (!draft.usesManualAmount) {
      draft.rateController.text = paiseToRupeesField(item.rateAmount);
    } else {
      draft.rateController.clear();
    }
  }

  int _effectiveRatePaise(_OrderLineDraft draft, InventoryItem item) {
    if (!item.allowsDynamicPricing) {
      return item.rateAmount;
    }
    final String raw = draft.rateController.text.trim();
    if (raw.isEmpty) {
      return item.rateAmount;
    }
    return parseRupeesToPaise(raw);
  }

  Future<void> _seedPrefillLabels() async {
    final List<InventoryItem> catalog =
        await ref.read(repositoryProvider).listInventory();
    if (!mounted || catalog.isEmpty) {
      return;
    }
    setState(() {
      for (var i = 0; i < _lines.length; i++) {
        final String? itemId = _lines[i].itemId;
        if (itemId == null) {
          continue;
        }
        for (final InventoryItem item in catalog) {
          if (item.id == itemId) {
            _applyFulfillmentDefaults(_lines[i], item);
            _applyAutoLabels(i, item);
            break;
          }
        }
      }
    });
  }

  void _onItemSelected(
    int index,
    String? itemId,
    List<InventoryItem> available,
  ) {
    setState(() {
      final _OrderLineDraft draft = _lines[index];
      draft.itemId = itemId;
      draft.quantity = 1;
      draft.showUnitLabels = false;
      draft.ensureIdentitySlots(1);
      draft.clearIdentityFields();
      draft.saleAmountController.clear();
      draft.rateController.clear();
      draft.customEnd = null;
      draft.leaveOpenEnded = false;
      draft.durationController.text = '1';
      if (itemId == null) {
        draft.fulfillment = LineFulfillment.rent;
        return;
      }
      final InventoryItem item =
          available.firstWhere((InventoryItem i) => i.id == itemId);
      _applyFulfillmentDefaults(draft, item);
      _applyAutoLabels(index, item);
    });
    if (itemId != null) {
      _refreshAvailableCodes(itemId);
    }
  }

  Future<void> _refreshAvailableCodes(String itemId) async {
    final List<String> codes =
        await ref.read(repositoryProvider).listAvailableUnitCodes(itemId);
    if (!mounted) {
      return;
    }
    setState(() {
      _availableCodesByItem[itemId] = codes;
    });
  }

  InventoryItem? _itemFor(
    _OrderLineDraft draft,
    List<InventoryItem> available,
  ) {
    if (draft.itemId == null) {
      return null;
    }
    for (final InventoryItem item in available) {
      if (item.id == draft.itemId) {
        return item;
      }
    }
    return null;
  }

  int _durationUnits(_OrderLineDraft draft) {
    final int parsed = int.tryParse(draft.durationController.text.trim()) ?? 0;
    return parsed < 1 ? 0 : parsed;
  }

  bool _durationComplete(_OrderLineDraft draft, InventoryItem item) {
    if (item.billingMode == BillingMode.custom) {
      if (draft.customEnd == null) {
        return false;
      }
      final DateTime today = DateTime.now();
      final DateTime startDay = DateTime(today.year, today.month, today.day);
      final DateTime endDay = DateTime(
        draft.customEnd!.year,
        draft.customEnd!.month,
        draft.customEnd!.day,
      );
      return !endDay.isBefore(startDay);
    }
    return _durationUnits(draft) >= 1;
  }

  bool _lineIsOpenEnded(_OrderLineDraft draft, InventoryItem item) {
    if (!item.dueDateOptional) {
      return false;
    }
    return draft.leaveOpenEnded || !_durationComplete(draft, item);
  }

  DateTime? _previewDue(_OrderLineDraft draft, InventoryItem item) {
    if (_lineIsOpenEnded(draft, item)) {
      return null;
    }
    return computeDueAt(
      start: DateTime.now(),
      mode: item.billingMode,
      durationUnits: _durationUnits(draft) < 1 ? 1 : _durationUnits(draft),
      customEnd: item.billingMode == BillingMode.custom ? draft.customEnd : null,
    );
  }

  int _saleAmountPaise(_OrderLineDraft draft) {
    return parseRupeesToPaise(draft.saleAmountController.text);
  }

  int _lineAmount(_OrderLineDraft draft, InventoryItem item) {
    if (draft.usesManualAmount) {
      return _saleAmountPaise(draft);
    }
    final DateTime? due = _previewDue(draft, item);
    if (due == null) {
      return 0;
    }
    return computeBaseAmount(
      mode: item.billingMode,
      rateAmount: _effectiveRatePaise(draft, item),
      start: DateTime.now(),
      due: due,
    );
  }

  int _orderTotal(List<InventoryItem> available) {
    int total = 0;
    for (final _OrderLineDraft draft in _lines) {
      final InventoryItem? item = _itemFor(draft, available);
      if (item == null) {
        continue;
      }
      total += _lineAmount(draft, item) * draft.quantity;
    }
    return total;
  }

  List<CommercialLineInput> _commercialInputs(List<InventoryItem> catalog) {
    final List<CommercialLineInput> inputs = <CommercialLineInput>[];
    for (final _OrderLineDraft draft in _lines) {
      final InventoryItem? item = _itemFor(draft, catalog);
      if (item == null) {
        continue;
      }
      inputs.add(
        CommercialLineInput.fromCatalog(
          item: item,
          fulfillment: draft.fulfillment,
          lineAmountPaise: _lineAmount(draft, item) * draft.quantity,
          quantity: draft.quantity,
          unitRatePaise: draft.usesManualAmount
              ? _saleAmountPaise(draft)
              : _effectiveRatePaise(draft, item),
        ),
      );
    }
    return inputs;
  }

  AggregatedOrderCommercial _aggregatedCommercial(List<InventoryItem> catalog) {
    return resolveOrderCommercial(
      _commercialInputs(catalog),
      templateByType: _templateCommercialByType,
    );
  }

  bool _customerCanHoldLedger() {
    if (_noPhone) {
      return false;
    }
    final Customer? customer = _resolvedCustomer;
    if (customer != null && isUnknownCustomer(customer)) {
      return false;
    }
    final String? id = customer?.id ?? widget.initialCustomerId;
    if (id == null ||
        isUnknownCustomerId(id) ||
        id == kLegacySelfCustomerId) {
      return false;
    }
    return true;
  }

  int _customerRank() {
    return effectiveSubscriptionRank(
      _customerSubscriptions,
      DateTime.now(),
    );
  }

  Iterable<({ResourceType type, Map<String, Object?> metadata})>
      _subscriptionViews(List<InventoryItem> catalog) {
    return _commercialInputs(catalog).map(
      (CommercialLineInput line) => line.subscriptionView,
    );
  }

  bool _subscriptionSatisfied(List<InventoryItem> catalog) {
    return subscriptionCoverageSatisfied(
      customerRank: _customerRank(),
      lines: _subscriptionViews(catalog),
      customerCanHoldLedger: _customerCanHoldLedger(),
    );
  }

  bool _hasMembershipEntitlement(List<InventoryItem> catalog) {
    return hasSubscriptionEntitlement(
      customerRank: _customerRank(),
      lines: _subscriptionViews(catalog),
      customerCanHoldLedger: _customerCanHoldLedger(),
    );
  }

  bool _shouldShowCommercial(
    AggregatedOrderCommercial agg,
    List<InventoryItem> catalog,
  ) {
    if (agg.shouldShowCommercialStep) {
      return true;
    }
    final SubscriptionTier min = cartMinSubscriptionTier(
      _subscriptionViews(catalog),
    );
    if (min == SubscriptionTier.none) {
      return false;
    }
    return !_subscriptionSatisfied(catalog);
  }

  int _payPaise() => parseRupeesToPaise(_payController.text);

  int _securityPaise() => parseRupeesToPaise(_securityController.text);

  int _advancePaise() => parseRupeesToPaise(_advanceController.text);

  bool _settlementCollectsCash(AggregatedOrderCommercial agg) =>
      _settlementReceivedPaise(agg) > 0 || _settlementSecurityPaise(agg) > 0;

  bool _paymentReferenceReady(AggregatedOrderCommercial agg) {
    if (!_settlementCollectsCash(agg)) {
      return true;
    }
    try {
      validatePaymentReference(_referenceController.text);
      return true;
    } on ArgumentError {
      return false;
    }
  }

  bool _commercialSatisfied(
    AggregatedOrderCommercial agg,
    List<InventoryItem> catalog,
  ) {
    try {
      assertCommercialSatisfied(
        aggregated: agg,
        amountReceivedPaise: _payPaise() +
            (agg.showSecurity ? _securityPaise() : _advancePaise()),
        securityPaise: agg.showSecurity ? _securityPaise() : _advancePaise(),
        advancePaise: _advancePaise(),
        subscriptionSatisfied: _hasMembershipEntitlement(catalog),
        minTierCovered: _subscriptionSatisfied(catalog),
      );
      return _paymentReferenceReady(agg);
    } on ArgumentError {
      return false;
    }
  }

  void _seedCommercialFields(AggregatedOrderCommercial agg) {
    if (_commercialSeeded) {
      return;
    }
    if (agg.showPay && agg.minPayNowPaise > 0) {
      _payController.text = paiseToRupeesField(agg.minPayNowPaise);
    }
    if (agg.showSecurity && agg.suggestedSecurityPaise > 0) {
      _securityController.text =
          paiseToRupeesField(agg.suggestedSecurityPaise);
    }
    if (agg.showAdvance && agg.suggestedSecurityPaise > 0) {
      _advanceController.text = paiseToRupeesField(agg.suggestedSecurityPaise);
    }
    _commercialSeeded = true;
  }

  int _settlementReceivedPaise(AggregatedOrderCommercial agg) {
    final int pay = agg.showPay ? _payPaise() : 0;
    final int hold = agg.showSecurity
        ? _securityPaise()
        : (agg.showAdvance ? _advancePaise() : 0);
    if (agg.showPay && (agg.showSecurity || agg.showAdvance)) {
      return pay + hold;
    }
    if (agg.showPay) {
      return pay;
    }
    return hold;
  }

  int _settlementSecurityPaise(AggregatedOrderCommercial agg) {
    if (agg.showSecurity) {
      return _securityPaise();
    }
    if (agg.showAdvance) {
      return _advancePaise();
    }
    return 0;
  }

  Future<void> _enterCommercialOrSummary(List<InventoryItem> catalog) async {
    await _refreshCustomerSubscriptions();
    if (!mounted) {
      return;
    }
    _seedUpsellIfNeeded(catalog);
    final AggregatedOrderCommercial agg = _aggregatedCommercial(catalog);
    if (!_shouldShowCommercial(agg, catalog)) {
      setState(() => _phase = _OrderPhase.summary);
      return;
    }
    setState(() {
      _commercialSeeded = false;
      _seedCommercialFields(agg);
      _phase = _OrderPhase.commercial;
    });
  }

  Future<void> _refreshCustomerSubscriptions() async {
    if (!_customerCanHoldLedger()) {
      _customerSubscriptions = const <CustomerSubscription>[];
      return;
    }
    final String? customerId = _resolvedCustomer?.id ??
        (widget.initialCustomerId != null &&
                !isUnknownCustomerId(widget.initialCustomerId!) &&
                widget.initialCustomerId != kLegacySelfCustomerId
            ? widget.initialCustomerId
            : null);
    if (customerId == null) {
      _customerSubscriptions = const <CustomerSubscription>[];
      return;
    }
    _customerSubscriptions = await ref
        .read(repositoryProvider)
        .listCustomerSubscriptions(customerId);
  }

  void _seedUpsellIfNeeded(List<InventoryItem> catalog) {
    if (!_customerCanHoldLedger()) {
      return;
    }
    if (_subscriptionSatisfied(catalog)) {
      return;
    }
    final SubscriptionTier? needed = requiredUpsellTier(
      cartMinTier: cartMinSubscriptionTier(_subscriptionViews(catalog)),
      customerRank: _customerRank(),
    );
    if (needed == null || needed == SubscriptionTier.none) {
      return;
    }
    if (cartGrantedSubscriptionRank(_subscriptionViews(catalog)) >=
        needed.rank) {
      return;
    }
    String? preferredCategory;
    for (final _OrderLineDraft draft in _lines) {
      final InventoryItem? item = _itemFor(draft, catalog);
      if (item == null || isSubscriptionCatalogType(item.defaultItemKind)) {
        continue;
      }
      if (minSubscriptionTierFromMetadata(item.metadata) !=
          SubscriptionTier.none) {
        preferredCategory = item.category;
        break;
      }
    }
    final InventoryItem? sku = cheapestCoveringSubscriptionSku(
      catalog: catalog,
      minTier: needed,
      preferredCategory: preferredCategory,
    );
    if (sku == null) {
      return;
    }
    final _OrderLineDraft draft = _OrderLineDraft(itemId: sku.id);
    _applyFulfillmentDefaults(draft, sku);
    _lines.add(draft);
    _upsellLineIndex = _lines.length - 1;
  }

  void _applyUpsellSku(String itemId, List<InventoryItem> catalog) {
    InventoryItem? found;
    for (final InventoryItem item in catalog) {
      if (item.id == itemId) {
        found = item;
        break;
      }
    }
    if (found == null) {
      return;
    }
    final InventoryItem sku = found;
    setState(() {
      if (_upsellLineIndex >= 0 && _upsellLineIndex < _lines.length) {
        final _OrderLineDraft draft = _lines[_upsellLineIndex];
        draft.itemId = sku.id;
        _applyFulfillmentDefaults(draft, sku);
      } else {
        final _OrderLineDraft draft = _OrderLineDraft(itemId: sku.id);
        _applyFulfillmentDefaults(draft, sku);
        _lines.add(draft);
        _upsellLineIndex = _lines.length - 1;
      }
    });
  }

  bool _labelsReady(_OrderLineDraft draft, InventoryItem item) {
    if (!item.requiresUnitIdentity) {
      return true;
    }
    if (draft.identities.length < draft.quantity) {
      return false;
    }
    for (var u = 0; u < draft.quantity; u++) {
      final _UnitIdentityDraft unit = draft.identities[u];
      final String name = unit.instanceNameController.text.trim();
      final String code = LocalRepository.normalizeShortCode(
        unit.shortCodeController.text,
      );
      if (name.isEmpty || code.isEmpty) {
        return false;
      }
      if (!meetsMinMeaningfulText(name)) {
        return false;
      }
    }
    return true;
  }

  bool _lineReady(_OrderLineDraft draft, InventoryItem? item) {
    if (item == null) {
      return false;
    }
    if (draft.quantity < 1) {
      return false;
    }
    if (!_labelsReady(draft, item)) {
      return false;
    }
    if (draft.usesManualAmount) {
      return _saleAmountPaise(draft) > 0;
    }
    if (item.dueDateOptional) {
      return true;
    }
    return _durationComplete(draft, item);
  }

  bool _formReady(List<InventoryItem> catalog) {
    if (_lines.isEmpty) {
      return false;
    }
    final Set<String> codes = <String>{};
    for (var i = 0; i < _lines.length; i++) {
      final _OrderLineDraft draft = _lines[i];
      final InventoryItem? item = _itemFor(draft, catalog);
      if (!_lineReady(draft, item)) {
        return false;
      }
      if (!item!.requiresUnitIdentity) {
        continue;
      }
      for (var u = 0; u < draft.quantity; u++) {
        final String code = LocalRepository.normalizeShortCode(
          draft.identities[u].shortCodeController.text,
        );
        if (!codes.add(code)) {
          return false;
        }
      }
    }
    return true;
  }

  String _customerDisplayLabel(AppLocalizations l10n) {
    if (_noPhone) {
      final String nick = _nameController.text.trim();
      return nick.isEmpty
          ? l10n.unknownCustomer
          : '$nick · ${l10n.unknownCustomer}';
    }
    final String name =
        _resolvedCustomer?.name ?? _nameController.text.trim();
    final String phone =
        _resolvedCustomer?.phone ?? _phoneController.text.trim();
    if (name.isEmpty && phone.isEmpty) {
      return l10n.unknownCustomer;
    }
    if (name.isEmpty) {
      return phone;
    }
    if (phone.isEmpty) {
      return name;
    }
    return '$name · $phone';
  }

  List<RentalLineInput> _buildLineInputs(List<InventoryItem> available) {
    final List<RentalLineInput> inputs = <RentalLineInput>[];
    final Set<String> usedCodes = <String>{};
    final Map<String, int> autoIndexByItem = <String, int>{};

    for (final _OrderLineDraft draft in _lines) {
      final InventoryItem item = _itemFor(draft, available)!;
      if (item.requiresUnitIdentity) {
        draft.ensureIdentitySlots(draft.quantity);
      }
      for (var u = 0; u < draft.quantity; u++) {
        final String instanceName;
        final String shortCode;
        if (item.requiresUnitIdentity) {
          final _UnitIdentityDraft unit = draft.identities[u];
          instanceName = unit.instanceNameController.text.trim();
          shortCode = unit.shortCodeController.text.trim();
          usedCodes.add(LocalRepository.normalizeShortCode(shortCode));
        } else {
          String? optionalName;
          String? optionalCode;
          if (draft.showUnitLabels && u < draft.identities.length) {
            final _UnitIdentityDraft unit = draft.identities[u];
            final String name = unit.instanceNameController.text.trim();
            final String code = unit.shortCodeController.text.trim();
            if (name.isNotEmpty && code.isNotEmpty) {
              optionalName = name;
              optionalCode = code;
            }
          }
          if (optionalName != null && optionalCode != null) {
            instanceName = optionalName;
            shortCode = optionalCode;
            usedCodes.add(LocalRepository.normalizeShortCode(shortCode));
          } else {
            final int nextIndex = (autoIndexByItem[item.id] ?? 0) + 1;
            autoIndexByItem[item.id] = nextIndex;
            instanceName = item.name;
            if (item.hasUnitCodePool) {
              final List<String> pool =
                  _availableCodesByItem[item.id] ?? const <String>[];
              String? fromPool;
              for (final String code in pool) {
                if (!usedCodes
                    .contains(LocalRepository.normalizeShortCode(code))) {
                  fromPool = code;
                  break;
                }
              }
              if (fromPool != null) {
                shortCode = fromPool;
              } else {
                shortCode = LocalRepository.generateAutoShortCode(
                  catalogName: item.unitCodePrefix ?? item.name,
                  index: nextIndex,
                  usedCodes: usedCodes,
                );
              }
            } else {
              shortCode = LocalRepository.generateAutoShortCode(
                catalogName: item.name,
                index: nextIndex,
                usedCodes: usedCodes,
              );
            }
            usedCodes.add(LocalRepository.normalizeShortCode(shortCode));
          }
        }

        if (draft.isSell) {
          inputs.add(
            RentalLineInput(
              itemId: item.id,
              instanceName: instanceName,
              shortCode: shortCode,
              fulfillment: LineFulfillment.sell,
              manualSaleAmountPaise: _saleAmountPaise(draft),
            ),
          );
          continue;
        }
        if (draft.isJob) {
          inputs.add(
            RentalLineInput(
              itemId: item.id,
              instanceName: instanceName,
              shortCode: shortCode,
              fulfillment: LineFulfillment.job,
              manualSaleAmountPaise: _saleAmountPaise(draft),
            ),
          );
          continue;
        }
        final bool openEnded = _lineIsOpenEnded(draft, item);
        final int effectiveRate = _effectiveRatePaise(draft, item);
        inputs.add(
          RentalLineInput(
            itemId: item.id,
            instanceName: instanceName,
            shortCode: shortCode,
            fulfillment: LineFulfillment.rent,
            openEnded: openEnded,
            durationUnits: openEnded
                ? 0
                : (item.billingMode == BillingMode.custom
                    ? 1
                    : _durationUnits(draft)),
            customEnd: openEnded || item.billingMode != BillingMode.custom
                ? null
                : draft.customEnd,
            rateAmountOverride:
                item.allowsDynamicPricing ? effectiveRate : null,
          ),
        );
      }
    }
    return inputs;
  }

  bool _validateCustomerOrSnack() {
    if (_noPhone) {
      final String name = _nameController.text.trim();
      if (name.isNotEmpty && !meetsMinMeaningfulText(name)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.minMeaningfulTextError(kMinMeaningfulTextLength),
            ),
          ),
        );
        return false;
      }
      return true;
    }
    if (_resolvedCustomer == null &&
        !meetsMinMeaningfulText(_nameController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.minMeaningfulTextError(kMinMeaningfulTextLength),
          ),
        ),
      );
      return false;
    }
    if (_phoneController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.phoneRequiredError)),
      );
      return false;
    }
    return true;
  }

  Future<void> _continueFromCustomer(List<InventoryItem> catalog) async {
    if (!_validateCustomerOrSnack()) {
      return;
    }
    await _enterCommercialOrSummary(catalog);
  }

  Future<void> _generateOrder(List<InventoryItem> catalog) async {
    if (!_formReady(catalog)) {
      return;
    }
    setState(() => _submitting = true);
    final AppLocalizations l10n = context.l10n;
    final LocalRepository repository = ref.read(repositoryProvider);
    final Customer customer;
    final String? nickname;
    try {
      if (_noPhone) {
        customer = await repository.ensureUnknownCustomer();
        final String nick = _nameController.text.trim();
        nickname = nick.isEmpty ? null : nick;
      } else {
        Customer? resolved = _resolvedCustomer;
        if (resolved == null &&
            widget.initialCustomerId != null &&
            !isUnknownCustomerId(widget.initialCustomerId!) &&
            widget.initialCustomerId != kLegacySelfCustomerId) {
          resolved =
              await repository.customerById(widget.initialCustomerId!);
        }
        customer = resolved ??
            await repository.upsertCustomerByPhone(
              phone: _phoneController.text.trim(),
              fallbackName: _nameController.text.trim(),
            );
        nickname = null;
      }
      for (final InventoryItem item in catalog) {
        if (item.hasUnitCodePool) {
          _availableCodesByItem[item.id] =
              await repository.listAvailableUnitCodes(item.id);
        }
      }
      final AggregatedOrderCommercial commercial =
          _aggregatedCommercial(catalog);
      final List<RentalLineInput> lineInputs = _buildLineInputs(catalog);
      final String rentalId;
      if (_shouldShowCommercial(commercial, catalog) ||
          _payPaise() > 0 ||
          _securityPaise() > 0 ||
          _advancePaise() > 0) {
        rentalId = await repository.createOrderWithSettlement(
          customer: customer,
          lines: lineInputs,
          nickname: nickname,
          amountReceivedPaise: _settlementReceivedPaise(commercial),
          securityPaise: _settlementSecurityPaise(commercial),
          subscriptionSatisfied: _hasMembershipEntitlement(catalog),
          minTierCovered: _subscriptionSatisfied(catalog),
          commercial: commercial,
          referenceCode: _settlementCollectsCash(commercial)
              ? requirePaymentReference(_referenceController.text)
              : null,
        );
      } else {
        rentalId = await repository.createRental(
          customer: customer,
          lines: lineInputs,
          nickname: nickname,
        );
      }
      if (!mounted) {
        return;
      }
      // Payment is collected from order detail (Pay), not auto-opened.
      pushReplacementRentalDetail(context, rentalId: rentalId);
    } catch (error) {
      if (mounted) {
        setState(() => _submitting = false);
        final String message;
        if (error is DuplicateActiveShortCodeException) {
          message = l10n.duplicateShortCode(error.shortCode);
        } else if (error is ArgumentError) {
          final String raw = error.message?.toString() ?? '';
          final String lower = raw.toLowerCase();
          if (lower.contains('reserved phone') ||
              lower.contains('phone is required')) {
            message = l10n.phoneRequiredError;
          } else if (lower.contains('instance') ||
              lower.contains('short code')) {
            message = l10n.instanceLabelsRequired;
          } else {
            message = raw.isEmpty ? '$error' : raw;
          }
        } else {
          message = '$error';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<InventoryItem>> inventoryAsync =
        ref.watch(inventoryProvider);
    final List<InventoryItem> inventory =
        inventoryAsync.valueOrNull ?? const <InventoryItem>[];

    final bool onForm = _phase == _OrderPhase.form;
    final bool onCustomer = _phase == _OrderPhase.customer;
    final bool onCommercial = _phase == _OrderPhase.commercial;
    final bool onSummary = _phase == _OrderPhase.summary;
    final bool formReady = _formReady(inventory);
    final AggregatedOrderCommercial commercial =
        _aggregatedCommercial(inventory);
    final bool showCommercial = _shouldShowCommercial(commercial, inventory);
    final int totalSteps = (_skipCustomerStep ? 2 : 3) + (showCommercial ? 1 : 0);
    final int stepCurrent;
    if (onForm) {
      stepCurrent = 1;
    } else if (onCustomer) {
      stepCurrent = 2;
    } else if (onCommercial) {
      stepCurrent = _skipCustomerStep ? 2 : 3;
    } else {
      stepCurrent = totalSteps;
    }

    VoidCallback? primaryAction;
    final String primaryLabel;
    if (onForm) {
      primaryLabel = l10n.continueAction;
      if (formReady) {
        primaryAction = () {
          if (_skipCustomerStep) {
            _enterCommercialOrSummary(inventory);
          } else {
            setState(() => _phase = _OrderPhase.customer);
          }
        };
      }
    } else if (onCustomer) {
      primaryLabel = l10n.continueAction;
      if (_customerReady) {
        primaryAction = () => _continueFromCustomer(inventory);
      }
    } else if (onCommercial) {
      primaryLabel = l10n.continueAction;
      if (_commercialSatisfied(commercial, inventory)) {
        primaryAction = () => setState(() => _phase = _OrderPhase.summary);
      }
    } else {
      primaryLabel = l10n.confirmRental;
      if (formReady && _commercialSatisfied(commercial, inventory)) {
        primaryAction = () => _generateOrder(inventory);
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.actionNewRental)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (!_skipCustomerStep || showCommercial)
            Text(
              l10n.stepOf(stepCurrent, totalSteps),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          if (!_skipCustomerStep || showCommercial) const SizedBox(height: 8),
          if (onForm) ..._buildFormStep(l10n, inventory),
          if (onCustomer) ..._buildCustomerStep(l10n, inventory),
          if (onCommercial) ..._buildCommercialStep(l10n, commercial, inventory),
          if (onSummary) ..._buildSummaryStep(l10n, inventory),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(
          children: <Widget>[
            if (!onForm)
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _submitting
                        ? null
                        : () => setState(() {
                              if (onSummary) {
                                _phase = showCommercial
                                    ? _OrderPhase.commercial
                                    : (_skipCustomerStep
                                        ? _OrderPhase.form
                                        : _OrderPhase.customer);
                              } else if (onCommercial) {
                                _phase = _skipCustomerStep
                                    ? _OrderPhase.form
                                    : _OrderPhase.customer;
                              } else {
                                _phase = _OrderPhase.form;
                              }
                            }),
                    child: Text(l10n.back),
                  ),
                ),
              ),
            if (!onForm) const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 48,
                child: FilledButton(
                  key: const ValueKey<String>('order-primary-action'),
                  onPressed: _submitting ? null : primaryAction,
                  child: Text(primaryLabel),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCommercialStep(
    AppLocalizations l10n,
    AggregatedOrderCommercial commercial,
    List<InventoryItem> inventory,
  ) {
    return <Widget>[
      Text(
        l10n.commercialStepHeading,
        key: const ValueKey<String>('order-commercial-heading'),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
      const SizedBox(height: 8),
      Text(l10n.commercialStepSubtitle),
      const SizedBox(height: 16),
      if (commercial.showPay) ...<Widget>[
        Text(
          l10n.commercialStepPay,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        if (commercial.minPayNowPaise > 0) ...<Widget>[
          const SizedBox(height: 8),
          MoneyStack(
            label: l10n.commercialMinPayLabel,
            amount: formatMoney(commercial.minPayNowPaise),
            emphasis: MoneyStackEmphasis.due,
          ),
        ],
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey<String>('commercial-pay-field'),
          controller: _payController,
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
        const SizedBox(height: 16),
      ],
      if (commercial.showAdvance) ...<Widget>[
        Text(
          l10n.commercialStepAdvance,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey<String>('commercial-advance-field'),
          controller: _advanceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: InputDecoration(
            labelText: l10n.paymentSecurityLabel,
            hintText: l10n.paymentSecurityHint,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
      ],
      if (commercial.showSecurity) ...<Widget>[
        Text(
          l10n.commercialStepSecurity,
          key: const ValueKey<String>('commercial-security-title'),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey<String>('commercial-security-field'),
          controller: _securityController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: InputDecoration(
            labelText: l10n.paymentSecurityLabel,
            hintText: l10n.paymentSecurityHint,
            helperText: commercial.requireSecurity
                ? l10n.commercialSecurityRequiredHelper
                : l10n.paymentSecurityHelper,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
      ],
      if (commercial.showSubscription ||
          commercial.requireAnyOf.contains(CommercialStep.subscription) ||
          commercial.needsSubscriptionCoverage) ...<
          Widget>[
        Text(
          l10n.commercialStepMembershipRequired,
          key: const ValueKey<String>('commercial-membership-title'),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        ..._buildSubscriptionGate(l10n, inventory, commercial),
      ],
      if (commercial.showPay ||
          commercial.showSecurity ||
          commercial.showAdvance) ...<Widget>[
        TextField(
          key: const ValueKey<String>('commercial-reference-field'),
          controller: _referenceController,
          maxLength: kPaymentReferenceMaxLength,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_-]')),
          ],
          decoration: InputDecoration(
            labelText: l10n.paymentReferenceLabel,
            hintText: l10n.paymentReferenceHint,
            counterText: '',
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    ];
  }

  List<Widget> _buildSubscriptionGate(
    AppLocalizations l10n,
    List<InventoryItem> inventory,
    AggregatedOrderCommercial commercial,
  ) {
    final SubscriptionTier minTier = commercial.cartMinTier;
    final CustomerSubscription? active = highestActiveSubscription(
      _customerSubscriptions,
      DateTime.now(),
    );
    final bool covered = _subscriptionSatisfied(inventory);
    final List<Widget> out = <Widget>[];
    if (!_customerCanHoldLedger() && minTier != SubscriptionTier.none) {
      out.add(
        Text(
          l10n.subscriptionNamedCustomerRequired,
          key: const ValueKey<String>('subscription-named-customer'),
        ),
      );
      return out;
    }
    final bool ledgerCovers = minTier == SubscriptionTier.none ||
        coversSubscriptionTier(
          minTier: minTier,
          effectiveRank: _customerRank(),
        );
    if (ledgerCovers && active != null) {
      out.add(
        InputChip(
          key: const ValueKey<String>('subscription-ok-chip'),
          avatar: const Icon(Icons.verified_outlined, size: 18),
          label: Text(
            l10n.subscriptionChipOk(
              localizedSubscriptionTier(l10n, active.tier),
              formatIndiaDate(active.validUntil),
            ),
          ),
        ),
      );
      return out;
    }
    if (ledgerCovers && covered) {
      out.add(Text(l10n.commercialSubscriptionSatisfied));
      return out;
    }
    if (minTier != SubscriptionTier.none) {
      out.add(
        Text(
          l10n.subscriptionChipUncovered(
            localizedSubscriptionTier(l10n, minTier),
          ),
        ),
      );
      out.add(const SizedBox(height: 8));
    }
    out.add(Text(l10n.commercialSubscriptionHint));
    final SubscriptionTier? needed = requiredUpsellTier(
      cartMinTier: minTier == SubscriptionTier.none
          ? SubscriptionTier.basic
          : minTier,
      customerRank: _customerRank(),
    );
    if (needed != null && _customerCanHoldLedger()) {
      final List<InventoryItem> options = inventory
          .where(
            (InventoryItem item) =>
                item.catalogActive &&
                isSubscriptionCatalogType(item.defaultItemKind) &&
                (subscriptionTierFromMetadata(
                          item.metadata,
                          fallback: SubscriptionTier.basic,
                        ) ??
                        SubscriptionTier.basic)
                    .rank >=
                    needed.rank,
          )
          .toList();
      if (options.isNotEmpty) {
        String? selectedId;
        if (_upsellLineIndex >= 0 && _upsellLineIndex < _lines.length) {
          selectedId = _lines[_upsellLineIndex].itemId;
        }
        out.add(const SizedBox(height: 8));
        out.add(
          DropdownButtonFormField<String>(
            key: const ValueKey<String>('subscription-upsell-sku'),
            initialValue: selectedId != null &&
                    options.any((InventoryItem i) => i.id == selectedId)
                ? selectedId
                : options.first.id,
            decoration: InputDecoration(labelText: l10n.subscriptionUpsellLabel),
            items: options
                .map(
                  (InventoryItem item) => DropdownMenuItem<String>(
                    value: item.id,
                    child: Text(
                      '${item.name} · ${localizedSubscriptionTier(l10n, subscriptionTierFromMetadata(item.metadata, fallback: SubscriptionTier.basic) ?? SubscriptionTier.basic)}',
                    ),
                  ),
                )
                .toList(),
            onChanged: (String? id) {
              if (id != null) {
                _applyUpsellSku(id, inventory);
              }
            },
          ),
        );
      }
    }
    return out;
  }

  List<Widget> _buildSummaryStep(
    AppLocalizations l10n,
    List<InventoryItem> inventory,
  ) {
    final int total = _orderTotal(inventory);
    final CustomerSubscription? active = highestActiveSubscription(
      _customerSubscriptions,
      DateTime.now(),
    );
    final List<Widget> billLines = <Widget>[];
    if (_subscriptionSatisfied(inventory) && active != null) {
      billLines.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InputChip(
            key: const ValueKey<String>('subscription-summary-chip'),
            avatar: const Icon(Icons.verified_outlined, size: 18),
            label: Text(
              l10n.subscriptionChipOk(
                localizedSubscriptionTier(l10n, active.tier),
                formatIndiaDate(active.validUntil),
              ),
            ),
          ),
        ),
      );
    }
    for (final _OrderLineDraft draft in _lines) {
      final InventoryItem? item = _itemFor(draft, inventory);
      if (item == null) {
        continue;
      }
      final int unitPaise = _lineAmount(draft, item);
      final int linePaise = unitPaise * draft.quantity;
      final String fulfillment = switch (draft.fulfillment) {
        LineFulfillment.sell => l10n.lineFulfillmentSell,
        LineFulfillment.job => l10n.lineFulfillmentJob,
        LineFulfillment.rent => l10n.lineFulfillmentRent,
      };
      billLines.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                item.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                '${l10n.orderSummaryQuantity(draft.quantity)} · $fulfillment',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                l10n.orderSummaryUnitCharge(
                  formatMoney(unitPaise, currencyCode: item.currencyCode),
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (!draft.usesManualAmount &&
                  _durationComplete(draft, item) &&
                  !draft.leaveOpenEnded) ...<Widget>[
                Text(
                  l10n.chargePreviewDue(
                    formatIndiaDate(_previewDue(draft, item)!),
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (!draft.usesManualAmount && _lineIsOpenEnded(draft, item))
                Text(
                  l10n.reviewOpenEndedLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              Text(
                l10n.chargeLineAmount(
                  item.name,
                  formatMoney(linePaise, currencyCode: item.currencyCode),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return <Widget>[
      Text(
        l10n.orderSummaryHeading,
        key: const ValueKey<String>('order-summary-heading'),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
      const SizedBox(height: 8),
      Text(
        _customerDisplayLabel(l10n),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 16),
      ...billLines,
      const Divider(),
      Text(
        l10n.orderTotalLabel(formatMoney(total)),
        key: const ValueKey<String>('order-summary-total'),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    ];
  }

  List<Widget> _buildCustomerStep(
    AppLocalizations l10n,
    List<InventoryItem> availableItems,
  ) {
    return <Widget>[
      Text(
        l10n.orderTotalLabel(formatMoney(_orderTotal(availableItems))),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
      const SizedBox(height: 12),
      if (!_noPhone)
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: <TextInputFormatter>[kDigitsOnlyInputFormatter],
          decoration: InputDecoration(
            labelText: l10n.phoneNumberLabel,
            hintText: l10n.phoneNumberHint,
            suffixIcon: _clearSuffix(
              _phoneController,
              () {
                _onCustomerFieldsChanged();
              },
            ),
          ),
          onChanged: (_) => _onCustomerFieldsChanged(),
        ),
      if (!_noPhone) const SizedBox(height: 8),
      TextField(
        controller: _nameController,
        textCapitalization: TextCapitalization.words,
        enabled: true,
        decoration: InputDecoration(
          labelText: l10n.customerNameNewLabel,
          hintText: _noPhone
              ? l10n.noPhoneOptionalNameHint
              : l10n.customerNameNewHint,
          suffixIcon: _clearSuffix(
            _nameController,
            () {
              _onCustomerFieldsChanged();
            },
          ),
        ),
        onChanged: (_) => _onCustomerFieldsChanged(),
      ),
      const SizedBox(height: 8),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(l10n.noPhoneNumberLabel),
        value: _noPhone,
        controlAffinity: ListTileControlAffinity.leading,
        onChanged: (bool? value) => _setNoPhone(value ?? false),
      ),
      if (!_noPhone && _suggestions.isNotEmpty) ...<Widget>[
        const SizedBox(height: 4),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: <Widget>[
              for (final Customer suggestion in _suggestions)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.person_outline),
                  title: Text(
                    l10n.customerSuggestionSubtitle(
                      suggestion.name,
                      suggestion.phone,
                    ),
                  ),
                  onTap: () => _selectSuggestion(suggestion),
                ),
            ],
          ),
        ),
      ],
      if (!_noPhone &&
          _suggestions.isEmpty &&
          (_nameController.text.trim().length >= kMinMeaningfulTextLength ||
              _phoneController.text.trim().length >=
                  kMinMeaningfulTextLength) &&
          _resolvedCustomer == null) ...<Widget>[
        const SizedBox(height: 4),
        Text(
          l10n.customerTypeaheadEmpty,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
      if (_resolvedCustomer != null && !_noPhone) ...<Widget>[
        const SizedBox(height: 8),
        EntityCard(
          title: _resolvedCustomer!.name,
          subtitle: l10n.existingCustomerSubtitle(_resolvedCustomer!.phone),
          leadingIcon: Icons.verified_user_outlined,
          status: AssetStatus.available,
        ),
      ],
      if (_noPhone) ...<Widget>[
        const SizedBox(height: 8),
        EntityCard(
          title: l10n.unknownCustomer,
          subtitle: l10n.noPhoneNumberLabel,
          leadingIcon: Icons.help_outline,
          status: AssetStatus.archived,
        ),
      ],
    ];
  }

  List<Widget> _buildFormStep(
    AppLocalizations l10n,
    List<InventoryItem> availableItems,
  ) {
    final String customerLabel;
    if (_noPhone) {
      final String nick = _nameController.text.trim();
      customerLabel = nick.isEmpty
          ? l10n.unknownCustomer
          : '$nick · ${l10n.unknownCustomer}';
    } else {
      customerLabel =
          _resolvedCustomer?.name ?? _nameController.text.trim();
    }

    return <Widget>[
      if (_skipCustomerStep) ...<Widget>[
        InputChip(
          avatar: const Icon(Icons.person_outline, size: 18),
          label: Text(
            customerLabel.isEmpty ? l10n.unknownCustomer : customerLabel,
          ),
        ),
        const SizedBox(height: 8),
      ],
      for (var i = 0; i < _lines.length; i++)
        _buildLineCard(l10n, availableItems, i),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _addLine,
          icon: const Icon(Icons.add),
          label: Text(l10n.addOrderLineAction),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        l10n.orderTotalLabel(formatMoney(_orderTotal(availableItems))),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    ];
  }

  Widget _buildLineCard(
    AppLocalizations l10n,
    List<InventoryItem> availableItems,
    int index,
  ) {
    final _OrderLineDraft draft = _lines[index];
    final List<InventoryItem> choices = _choicesForLine(availableItems);
    final InventoryItem? selected = _itemFor(draft, availableItems);
    final String? value = selected == null
        ? null
        : (choices.any((InventoryItem i) => i.id == selected.id)
            ? selected.id
            : null);
    final List<LineFulfillment> fulfillmentOptions =
        fulfillmentOptionsForEnabledTypes(
      ref.read(enabledResourceTypesProvider),
      current: draft.fulfillment,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      l10n.orderLineHeading(index + 1),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  if (_lines.length > 1)
                    IconButton(
                      tooltip: l10n.removeOrderLineAction,
                      onPressed: () => _removeLine(index),
                      icon: const Icon(Icons.delete_outline),
                    ),
                ],
              ),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: value,
                decoration: InputDecoration(
                  labelText: l10n.selectResourceItemLabel,
                ),
                items: choices
                    .map(
                      (InventoryItem item) => DropdownMenuItem<String>(
                        value: item.id,
                        child: Text(
                          '${item.name} (${item.availableUnits})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (String? id) =>
                    _onItemSelected(index, id, availableItems),
              ),
              if (selected != null) ...<Widget>[
                const SizedBox(height: 8),
                _buildQuantityStepper(l10n, index, selected),
                const SizedBox(height: 8),
                if (draft.usesManualAmount) ...<Widget>[
                  TextField(
                    controller: draft.saleAmountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      kDigitsOnlyInputFormatter,
                    ],
                    decoration: InputDecoration(
                      labelText: draft.isJob
                          ? l10n.jobAmountLabel
                          : l10n.saleAmountLabel,
                      hintText: draft.isJob
                          ? l10n.jobAmountHint
                          : l10n.saleAmountHint,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_saleAmountPaise(draft) > 0) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      l10n.chargeLineAmount(
                        selected.name,
                        formatMoney(
                          _saleAmountPaise(draft) * draft.quantity,
                          currencyCode: selected.currencyCode,
                        ),
                      ),
                    ),
                  ],
                ] else ...<Widget>[
                  if (selected.allowsDynamicPricing) ...<Widget>[
                    TextField(
                      controller: draft.rateController,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        kDigitsOnlyInputFormatter,
                      ],
                      decoration: InputDecoration(
                        labelText: l10n.orderLineRateLabel,
                        hintText: l10n.orderLineRateHint,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (!draft.leaveOpenEnded &&
                      selected.billingMode != BillingMode.custom)
                    TextField(
                      controller: draft.durationController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: switch (selected.billingMode) {
                          BillingMode.daily => l10n.durationUnitsDaily,
                          BillingMode.weekly => l10n.durationUnitsWeekly,
                          BillingMode.monthly => l10n.durationUnitsMonthly,
                          BillingMode.fixed => l10n.durationUnitsFixed,
                          BillingMode.custom => l10n.durationUnitsLabel,
                        },
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  if (_durationComplete(draft, selected) &&
                      !draft.leaveOpenEnded) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      l10n.chargePreviewDue(
                        formatIndiaDate(_previewDue(draft, selected)!),
                      ),
                    ),
                    Text(
                      l10n.chargeLineAmount(
                        selected.name,
                        formatMoney(
                          _lineAmount(draft, selected) * draft.quantity,
                          currencyCode: selected.currencyCode,
                        ),
                      ),
                    ),
                  ],
                  if (_lineIsOpenEnded(draft, selected)) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(l10n.reviewOpenEndedLabel),
                  ],
                ],
                const SizedBox(height: 8),
                if (selected.requiresUnitIdentity)
                  ..._buildIdentityFields(l10n, index, selected)
                else ...<Widget>[
                  Text(
                    l10n.labelsAutoAssignedHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (!draft.showUnitLabels)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            draft.showUnitLabels = true;
                            draft.ensureIdentitySlots(draft.quantity);
                          });
                        },
                        child: Text(l10n.addUnitLabelsAction),
                      ),
                    )
                  else
                    ..._buildIdentityFields(l10n, index, selected),
                ],
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  title: Text(l10n.moreOptions),
                  children: <Widget>[
                    if (fulfillmentOptions.length > 1)
                      SegmentedButton<LineFulfillment>(
                        segments: <ButtonSegment<LineFulfillment>>[
                          for (final LineFulfillment option
                              in fulfillmentOptions)
                            ButtonSegment<LineFulfillment>(
                              value: option,
                              label: Text(switch (option) {
                                LineFulfillment.rent =>
                                  l10n.lineFulfillmentRent,
                                LineFulfillment.sell =>
                                  l10n.lineFulfillmentSell,
                                LineFulfillment.job =>
                                  l10n.lineFulfillmentJob,
                              }),
                            ),
                        ],
                        selected: <LineFulfillment>{draft.fulfillment},
                        onSelectionChanged: (Set<LineFulfillment> selection) {
                          setState(() {
                            draft.fulfillment = selection.first;
                            if (draft.usesManualAmount) {
                              draft.leaveOpenEnded = false;
                              draft.customEnd = null;
                              if (selected.rateAmount > 0 &&
                                  draft.saleAmountController.text
                                      .trim()
                                      .isEmpty) {
                                draft.saleAmountController.text =
                                    paiseToRupeesField(selected.rateAmount);
                              }
                            } else if (draft.durationController.text.isEmpty) {
                              draft.durationController.text = '1';
                            }
                          });
                        },
                      )
                    else
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          switch (draft.fulfillment) {
                            LineFulfillment.rent => l10n.lineFulfillmentRent,
                            LineFulfillment.sell => l10n.lineFulfillmentSell,
                            LineFulfillment.job => l10n.lineFulfillmentJob,
                          },
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                    if (!draft.usesManualAmount) ...<Widget>[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          localizedBillingMode(l10n, selected.billingMode),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      if (selected.dueDateOptional)
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.openEndedLabel),
                          subtitle: Text(l10n.openEndedDurationHint),
                          value: draft.leaveOpenEnded,
                          onChanged: (bool value) {
                            setState(() {
                              draft.leaveOpenEnded = value;
                              if (value) {
                                draft.durationController.clear();
                                draft.customEnd = null;
                              } else if (draft.durationController.text.isEmpty) {
                                draft.durationController.text = '1';
                              }
                            });
                          },
                        ),
                      if (!draft.leaveOpenEnded &&
                          selected.billingMode == BillingMode.custom)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.customEndDateLabel),
                          subtitle: Text(
                            draft.customEnd == null
                                ? '—'
                                : formatIndiaDate(draft.customEnd!),
                          ),
                          trailing: const Icon(Icons.calendar_today_outlined),
                          onTap: () async {
                            final DateTime now = DateTime.now();
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              locale: indiaDatePickerLocale(context),
                              initialDate: draft.customEnd ??
                                  now.add(const Duration(days: 1)),
                              firstDate:
                                  DateTime(now.year, now.month, now.day),
                              lastDate:
                                  now.add(const Duration(days: 365 * 2)),
                            );
                            if (picked != null) {
                              setState(() => draft.customEnd = picked);
                            }
                          },
                        ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityStepper(
    AppLocalizations l10n,
    int index,
    InventoryItem selected,
  ) {
    final _OrderLineDraft draft = _lines[index];
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            l10n.quantityLabel,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        IconButton(
          key: ValueKey<String>('qty-dec-$index'),
          tooltip: l10n.quantityLabel,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: draft.quantity <= 1
              ? null
              : () => _setQuantity(index, draft.quantity - 1, selected),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text(
          '${draft.quantity}',
          key: ValueKey<String>('qty-value-$index'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        IconButton(
          key: ValueKey<String>('qty-inc-$index'),
          tooltip: l10n.quantityLabel,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: draft.quantity >= _kMaxOrderLineQuantity
              ? null
              : () => _setQuantity(index, draft.quantity + 1, selected),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }

  List<Widget> _buildIdentityFields(
    AppLocalizations l10n,
    int index,
    InventoryItem selected,
  ) {
    final _OrderLineDraft draft = _lines[index];
    final int slots = draft.identities.length < draft.quantity
        ? draft.identities.length
        : draft.quantity;
    final bool usePool = selected.hasUnitCodePool;
    if (usePool && !_availableCodesByItem.containsKey(selected.id)) {
      _refreshAvailableCodes(selected.id);
    }
    final List<String> poolCodes =
        List<String>.from(_availableCodesByItem[selected.id] ?? const <String>[]);
    final Set<String> pickedInDraft = <String>{};
    for (var i = 0; i < slots; i++) {
      final String code = draft.identities[i].shortCodeController.text.trim();
      if (code.isNotEmpty) {
        pickedInDraft.add(LocalRepository.normalizeShortCode(code));
      }
    }
    final List<Widget> fields = <Widget>[];
    for (var u = 0; u < slots; u++) {
      final _UnitIdentityDraft unit = draft.identities[u];
      if (draft.quantity > 1) {
        fields.add(
          Padding(
            padding: EdgeInsets.only(top: u == 0 ? 0 : 8),
            child: Text(
              l10n.labelUnitHeading(selected.name, u + 1),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        );
      }
      fields.add(
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: TextField(
            controller: unit.instanceNameController,
            decoration: InputDecoration(
              labelText: l10n.instanceNameLabel,
              hintText: l10n.instanceNameHint,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      );
      if (usePool) {
        final String current =
            LocalRepository.normalizeShortCode(unit.shortCodeController.text);
        final List<String> options = poolCodes
            .where(
              (String code) =>
                  code == current ||
                  !pickedInDraft.contains(
                    LocalRepository.normalizeShortCode(code),
                  ),
            )
            .toList();
        if (current.isNotEmpty && !options.contains(current)) {
          options.insert(0, current);
        }
        fields.add(
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: DropdownButtonFormField<String>(
              key: ValueKey<String>('pool-code-$index-$u-$current'),
              initialValue: current.isEmpty || !options.contains(current)
                  ? null
                  : current,
              decoration: InputDecoration(
                labelText: l10n.pickShortCodeLabel,
                hintText: options.isEmpty
                    ? l10n.noAvailableUnitCodes
                    : l10n.pickShortCodeHint,
              ),
              items: options
                  .map(
                    (String code) => DropdownMenuItem<String>(
                      value: code,
                      child: Text(code),
                    ),
                  )
                  .toList(),
              onChanged: options.isEmpty
                  ? null
                  : (String? value) {
                      setState(() {
                        unit.shortCodeController.text = value ?? '';
                      });
                    },
            ),
          ),
        );
      } else {
        fields.add(
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextField(
              controller: unit.shortCodeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: l10n.shortCodeLabel,
                hintText: l10n.shortCodeHint,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        );
      }
    }
    return fields;
  }
}
