import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/inventory/inventory_categories.dart';
import '../../core/l10n/l10n_ext.dart';
import '../../core/models/entities.dart';
import '../../core/models/unknown_customer.dart';
import '../../core/pricing/rental_pricing.dart';
import '../../core/providers/app_providers.dart';
import '../../core/repositories/local_repository.dart';
import '../../core/validation/text_rules.dart';
import '../../core/widgets/ui_primitives.dart';

/// New Order flow: items first (with running total), then customer, then confirm.
///
/// When [initialCustomerId] is set for a normal customer, the customer step is
/// skipped and the flow is items → confirm.
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

/// Back-compat alias for call sites / older tests.
typedef NewRentalFlowScreen = NewOrderFlowScreen;

enum _OrderPhase { form, customer }

class _OrderLineDraft {
  _OrderLineDraft({this.itemId})
      : instanceNameController = TextEditingController(),
        shortCodeController = TextEditingController(),
        durationController = TextEditingController(text: '1'),
        saleAmountController = TextEditingController();

  String? itemId;
  LineFulfillment fulfillment = LineFulfillment.rent;
  final TextEditingController instanceNameController;
  final TextEditingController shortCodeController;
  final TextEditingController durationController;
  final TextEditingController saleAmountController;
  DateTime? customEnd;
  bool leaveOpenEnded = false;

  bool get isSell => fulfillment == LineFulfillment.sell;

  void dispose() {
    instanceNameController.dispose();
    shortCodeController.dispose();
    durationController.dispose();
    saleAmountController.dispose();
  }
}

class _NewOrderFlowScreenState extends ConsumerState<NewOrderFlowScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _depositTopUpController = TextEditingController();
  final List<_OrderLineDraft> _lines = <_OrderLineDraft>[];

  Customer? _resolvedCustomer;
  List<Customer> _suggestions = const <Customer>[];
  bool _noPhone = false;
  bool _submitting = false;
  bool _prefillApplied = false;
  late _OrderPhase _phase;

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
    _depositTopUpController.dispose();
    for (final _OrderLineDraft line in _lines) {
      line.dispose();
    }
    super.dispose();
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

  int _usedCount(String itemId, {int? exceptIndex}) {
    int count = 0;
    for (var i = 0; i < _lines.length; i++) {
      if (exceptIndex == i) {
        continue;
      }
      if (_lines[i].itemId == itemId) {
        count += 1;
      }
    }
    return count;
  }

  List<InventoryItem> _choicesForLine(
    int index,
    List<InventoryItem> available,
  ) {
    final List<InventoryItem> filtered = available.where((InventoryItem item) {
      final int used = _usedCount(item.id, exceptIndex: index);
      final bool current = _lines[index].itemId == item.id;
      return item.availableUnits > used || current;
    }).toList();
    return sortInventoryForOrderPicker(filtered);
  }

  void _applyAutoLabels(int index, InventoryItem item) {
    if (item.requiresUnitIdentity) {
      return;
    }
    final _OrderLineDraft draft = _lines[index];
    final Set<String> usedCodes = <String>{};
    for (var i = 0; i < _lines.length; i++) {
      if (i == index) {
        continue;
      }
      final String code = LocalRepository.normalizeShortCode(
        _lines[i].shortCodeController.text,
      );
      if (code.isNotEmpty) {
        usedCodes.add(code);
      }
    }
    final int siblingIndex = _usedCount(item.id, exceptIndex: index) + 1;
    if (draft.instanceNameController.text.trim().isEmpty) {
      draft.instanceNameController.text = item.name;
    }
    if (draft.shortCodeController.text.trim().isEmpty) {
      draft.shortCodeController.text = LocalRepository.generateAutoShortCode(
        catalogName: item.name,
        index: siblingIndex,
        usedCodes: usedCodes,
      );
    }
  }

  Future<void> _seedPrefillLabels() async {
    final List<InventoryItem> available =
        (await ref.read(repositoryProvider).listInventory())
            .where((InventoryItem i) => i.availableUnits > 0)
            .toList();
    if (!mounted || available.isEmpty) {
      return;
    }
    setState(() {
      for (var i = 0; i < _lines.length; i++) {
        final String? itemId = _lines[i].itemId;
        if (itemId == null) {
          continue;
        }
        for (final InventoryItem item in available) {
          if (item.id == itemId) {
            _lines[i].fulfillment = item.isGeneral
                ? LineFulfillment.sell
                : LineFulfillment.rent;
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
      draft.instanceNameController.clear();
      draft.shortCodeController.clear();
      draft.saleAmountController.clear();
      draft.customEnd = null;
      draft.leaveOpenEnded = false;
      draft.durationController.text = '1';
      if (itemId == null) {
        draft.fulfillment = LineFulfillment.rent;
        return;
      }
      final InventoryItem item =
          available.firstWhere((InventoryItem i) => i.id == itemId);
      draft.fulfillment = item.isGeneral
          ? LineFulfillment.sell
          : LineFulfillment.rent;
      _applyAutoLabels(index, item);
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
    if (draft.isSell) {
      return _saleAmountPaise(draft);
    }
    final DateTime? due = _previewDue(draft, item);
    if (due == null) {
      return 0;
    }
    return computeBaseAmount(
      mode: item.billingMode,
      rateAmount: item.rateAmount,
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
      total += _lineAmount(draft, item);
    }
    return total;
  }

  bool _labelsReady(_OrderLineDraft draft, InventoryItem item) {
    final String name = draft.instanceNameController.text.trim();
    final String code = LocalRepository.normalizeShortCode(
      draft.shortCodeController.text,
    );
    if (name.isEmpty || code.isEmpty) {
      return false;
    }
    if (item.requiresUnitIdentity && !meetsMinMeaningfulText(name)) {
      return false;
    }
    return true;
  }

  bool _lineReady(_OrderLineDraft draft, InventoryItem? item) {
    if (item == null) {
      return false;
    }
    if (!_labelsReady(draft, item)) {
      return false;
    }
    if (draft.isSell) {
      return _saleAmountPaise(draft) > 0;
    }
    if (item.dueDateOptional) {
      return true;
    }
    return _durationComplete(draft, item);
  }

  bool _formReady(List<InventoryItem> available) {
    if (_lines.isEmpty) {
      return false;
    }
    final Set<String> codes = <String>{};
    for (final _OrderLineDraft draft in _lines) {
      final InventoryItem? item = _itemFor(draft, available);
      if (!_lineReady(draft, item)) {
        return false;
      }
      final String code = LocalRepository.normalizeShortCode(
        draft.shortCodeController.text,
      );
      if (!codes.add(code)) {
        return false;
      }
    }
    return true;
  }

  List<RentalLineInput> _buildLineInputs(List<InventoryItem> available) {
    final List<RentalLineInput> inputs = <RentalLineInput>[];
    for (final _OrderLineDraft draft in _lines) {
      final InventoryItem item = _itemFor(draft, available)!;
      if (draft.isSell) {
        inputs.add(
          RentalLineInput(
            itemId: item.id,
            instanceName: draft.instanceNameController.text.trim(),
            shortCode: draft.shortCodeController.text.trim(),
            fulfillment: LineFulfillment.sell,
            manualSaleAmountPaise: _saleAmountPaise(draft),
          ),
        );
        continue;
      }
      final bool openEnded = _lineIsOpenEnded(draft, item);
      inputs.add(
        RentalLineInput(
          itemId: item.id,
          instanceName: draft.instanceNameController.text.trim(),
          shortCode: draft.shortCodeController.text.trim(),
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
        ),
      );
    }
    return inputs;
  }

  int _depositTopUpPaise() {
    final String raw = _depositTopUpController.text.trim();
    if (raw.isEmpty) {
      return 0;
    }
    final double? rupees = double.tryParse(raw);
    if (rupees == null || rupees <= 0) {
      return 0;
    }
    return (rupees * 100).round();
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

  Future<void> _confirmFromCustomer(List<InventoryItem> available) async {
    if (!_validateCustomerOrSnack()) {
      return;
    }
    await _generateOrder(available);
  }

  Future<void> _generateOrder(List<InventoryItem> available) async {
    if (!_formReady(available)) {
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
      await repository.createRental(
        customer: customer,
        lines: _buildLineInputs(available),
        nickname: nickname,
        depositTopUpPaise: _depositTopUpPaise(),
      );
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
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<InventoryItem>> inventoryAsync =
        ref.watch(inventoryProvider);
    final List<InventoryItem> inventory =
        inventoryAsync.valueOrNull ?? const <InventoryItem>[];
    final List<InventoryItem> availableItems =
        inventory.where((InventoryItem item) => item.availableUnits > 0).toList();

    final bool onForm = _phase == _OrderPhase.form;
    final bool formReady = _formReady(availableItems);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.actionNewRental)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (!_skipCustomerStep)
            Text(
              l10n.stepOf(onForm ? 1 : 2, 2),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          if (!_skipCustomerStep) const SizedBox(height: 8),
          if (onForm) ..._buildFormStep(l10n, availableItems),
          if (!onForm) ..._buildCustomerStep(l10n, availableItems),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(
          children: <Widget>[
            if (!onForm)
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting
                      ? null
                      : () => setState(() => _phase = _OrderPhase.form),
                  child: Text(l10n.back),
                ),
              ),
            if (!onForm) const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: _submitting
                    ? null
                    : (onForm
                        ? (formReady
                            ? (_skipCustomerStep
                                ? () => _generateOrder(availableItems)
                                : () => setState(
                                      () => _phase = _OrderPhase.customer,
                                    ))
                            : null)
                        : (_customerReady
                            ? () => _confirmFromCustomer(availableItems)
                            : null)),
                child: Text(
                  onForm && !_skipCustomerStep
                      ? l10n.continueAction
                      : l10n.confirmRental,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCustomerStep(
    AppLocalizations l10n,
    List<InventoryItem> availableItems,
  ) {
    final int depositBalance =
        (_noPhone ? 0 : (_resolvedCustomer?.depositBalance ?? 0));
    return <Widget>[
      Text(
        l10n.orderTotalLabel(formatMoney(_orderTotal(availableItems))),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _nameController,
        textCapitalization: TextCapitalization.words,
        enabled: true,
        decoration: InputDecoration(
          labelText: l10n.customerNameNewLabel,
          hintText: _noPhone
              ? l10n.noPhoneOptionalNameHint
              : l10n.customerNameNewHint,
        ),
        onChanged: (_) => _onCustomerFieldsChanged(),
      ),
      const SizedBox(height: 8),
      if (!_noPhone)
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: l10n.phoneNumberLabel,
            hintText: l10n.phoneNumberHint,
          ),
          onChanged: (_) => _onCustomerFieldsChanged(),
        ),
      if (!_noPhone) const SizedBox(height: 8),
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
          subtitle: _resolvedCustomer!.depositBalance > 0
              ? l10n.existingCustomerWithDeposit(
                  _resolvedCustomer!.phone,
                  formatMoney(_resolvedCustomer!.depositBalance),
                )
              : l10n.existingCustomerSubtitle(_resolvedCustomer!.phone),
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
      const SizedBox(height: 12),
      Text(l10n.depositBalanceAmount(formatMoney(depositBalance))),
      const SizedBox(height: 8),
      TextField(
        controller: _depositTopUpController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: l10n.depositTopUpOptionalLabel,
          hintText: l10n.depositTopUpOptionalHint,
        ),
        onChanged: (_) => setState(() {}),
      ),
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
    final int depositBalance =
        (_noPhone ? 0 : (_resolvedCustomer?.depositBalance ?? 0));

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
      if (_skipCustomerStep) ...<Widget>[
        const SizedBox(height: 8),
        Text(l10n.depositBalanceAmount(formatMoney(depositBalance))),
        const SizedBox(height: 8),
        TextField(
          controller: _depositTopUpController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l10n.depositTopUpOptionalLabel,
            hintText: l10n.depositTopUpOptionalHint,
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    ];
  }

  Widget _buildLineCard(
    AppLocalizations l10n,
    List<InventoryItem> availableItems,
    int index,
  ) {
    final _OrderLineDraft draft = _lines[index];
    final List<InventoryItem> choices =
        _choicesForLine(index, availableItems);
    final InventoryItem? selected = _itemFor(draft, availableItems);
    final String? value = selected == null
        ? null
        : (choices.any((InventoryItem i) => i.id == selected.id)
            ? selected.id
            : null);

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
                  labelText: l10n.selectInventoryItemLabel,
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
                SegmentedButton<LineFulfillment>(
                  segments: <ButtonSegment<LineFulfillment>>[
                    ButtonSegment<LineFulfillment>(
                      value: LineFulfillment.rent,
                      label: Text(l10n.lineFulfillmentRent),
                    ),
                    ButtonSegment<LineFulfillment>(
                      value: LineFulfillment.sell,
                      label: Text(l10n.lineFulfillmentSell),
                    ),
                  ],
                  selected: <LineFulfillment>{draft.fulfillment},
                  onSelectionChanged: (Set<LineFulfillment> selection) {
                    setState(() {
                      draft.fulfillment = selection.first;
                      if (draft.isSell) {
                        draft.leaveOpenEnded = false;
                        draft.customEnd = null;
                      } else if (draft.durationController.text.isEmpty) {
                        draft.durationController.text = '1';
                      }
                    });
                  },
                ),
                const SizedBox(height: 8),
                if (selected.requiresUnitIdentity) ...<Widget>[
                  TextField(
                    controller: draft.instanceNameController,
                    decoration: InputDecoration(
                      labelText: l10n.instanceNameLabel,
                      hintText: l10n.instanceNameHint,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: draft.shortCodeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: l10n.shortCodeLabel,
                      hintText: l10n.shortCodeHint,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ] else
                  Text(
                    l10n.labelsAutoAssignedHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const SizedBox(height: 8),
                if (draft.isSell) ...<Widget>[
                  TextField(
                    controller: draft.saleAmountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l10n.saleAmountLabel,
                      hintText: l10n.saleAmountHint,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_saleAmountPaise(draft) > 0) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      l10n.chargeLineAmount(
                        selected.name,
                        formatMoney(
                          _saleAmountPaise(draft),
                          currencyCode: selected.currencyCode,
                        ),
                      ),
                    ),
                  ],
                ] else ...<Widget>[
                  Text(
                    localizedBillingMode(l10n, selected.billingMode),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
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
                  if (!draft.leaveOpenEnded) ...<Widget>[
                    if (selected.billingMode == BillingMode.custom)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.customEndDateLabel),
                        subtitle: Text(
                          draft.customEnd == null
                              ? '—'
                              : _formatDate(draft.customEnd!),
                        ),
                        trailing: const Icon(Icons.calendar_today_outlined),
                        onTap: () async {
                          final DateTime now = DateTime.now();
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: draft.customEnd ??
                                now.add(const Duration(days: 1)),
                            firstDate: DateTime(now.year, now.month, now.day),
                            lastDate: now.add(const Duration(days: 365 * 2)),
                          );
                          if (picked != null) {
                            setState(() => draft.customEnd = picked);
                          }
                        },
                      )
                    else
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
                  ],
                  if (_durationComplete(draft, selected) &&
                      !draft.leaveOpenEnded) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      l10n.chargePreviewDue(
                        _formatDate(_previewDue(draft, selected)!),
                      ),
                    ),
                    Text(
                      l10n.chargeLineAmount(
                        selected.name,
                        formatMoney(
                          _lineAmount(draft, selected),
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
              ],
            ],
          ),
        ),
      ),
    );
  }
}
