import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/app_providers.dart';
import '../../../domain/inventory/inventory_categories.dart';
import '../../../domain/models/entities.dart';
import '../../../domain/orders/order_payment.dart';
import '../../../domain/pricing/rental_pricing.dart';
import '../../../domain/subscriptions/subscription_coverage.dart';
import '../../../domain/subscriptions/subscription_models.dart';
import '../../../domain/templates/field_defs.dart';
import '../../../domain/validation/text_rules.dart';
import '../../../infrastructure/l10n/l10n_ext.dart';
import '../../privacy/privacy_display.dart';
import '../../widgets/category_picker_field.dart';
import '../../widgets/dynamic_field_inputs.dart';
import '../../widgets/subscription_catalog_fields.dart';
import '../../widgets/ui_primitives.dart';
import '../orders/new_order_flow_screen.dart';

class InventoryDetailScreen extends ConsumerStatefulWidget {
  const InventoryDetailScreen({
    required this.itemId,
    super.key,
  });

  final String itemId;

  @override
  ConsumerState<InventoryDetailScreen> createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends ConsumerState<InventoryDetailScreen> {
  bool _editing = false;
  bool _saving = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _customCategoryController = TextEditingController();
  final TextEditingController _unitsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _lateFeeController = TextEditingController();
  final TextEditingController _securityDepositController = TextEditingController();
  final TextEditingController _unitCodePrefixController = TextEditingController();
  final DynamicFieldEditors _extraFields = DynamicFieldEditors();
  String? _selectedCategory;
  BillingMode _billingMode = BillingMode.weekly;
  bool _dueDateOptional = false;
  bool _requiresUnitIdentity = true;
  bool _allowsDynamicPricing = false;
  ResourceType? _kindOverride;
  SubscriptionTier _skuTier = SubscriptionTier.basic;
  SubscriptionPeriodUnit _periodUnit = SubscriptionPeriodUnit.month;
  final TextEditingController _periodCountController =
      TextEditingController(text: '1');
  SubscriptionTier _minTier = SubscriptionTier.none;

  @override
  void dispose() {
    _nameController.dispose();
    _customCategoryController.dispose();
    _unitsController.dispose();
    _notesController.dispose();
    _rateController.dispose();
    _lateFeeController.dispose();
    _securityDepositController.dispose();
    _unitCodePrefixController.dispose();
    _periodCountController.dispose();
    _extraFields.dispose();
    super.dispose();
  }

  void _beginEdit(InventoryItem item, List<String> categoryOptions) {
    _nameController.text = item.name;
    final String existing = item.category.trim();
    if (existing.isNotEmpty && categoryOptions.contains(existing)) {
      _selectedCategory = existing;
      _customCategoryController.clear();
    } else if (existing.isEmpty) {
      _selectedCategory = kCategoryOther;
      _customCategoryController.clear();
    } else {
      _selectedCategory = existing;
      _customCategoryController.clear();
    }
    _unitsController.text = '${item.totalUnits}';
    _notesController.text = item.notes ?? '';
    _rateController.text = paiseToRupeesField(item.rateAmount);
    _lateFeeController.text = paiseToRupeesField(item.lateFeePerDay);
    _securityDepositController.text =
        paiseToRupeesField(item.securityDepositPaise);
    _unitCodePrefixController.text = item.unitCodePrefix ?? '';
    _billingMode = item.billingMode;
    _dueDateOptional = item.dueDateOptional;
    _requiresUnitIdentity = item.requiresUnitIdentity;
    _allowsDynamicPricing = item.allowsDynamicPricing;
    _kindOverride = null;
    _skuTier = subscriptionTierFromMetadata(
          item.metadata,
          fallback: SubscriptionTier.basic,
        ) ??
        SubscriptionTier.basic;
    _periodUnit = subscriptionPeriodUnitFromMetadata(item.metadata) ??
        SubscriptionPeriodUnit.month;
    _periodCountController.text =
        '${subscriptionPeriodCountFromMetadata(item.metadata) ?? 1}';
    _minTier = minSubscriptionTierFromMetadata(item.metadata);
    final List<String> templateFields = ref.read(extraFieldIdsProvider);
    final List<FieldDef> fields = resolveExtraFields(
      type: item.defaultItemKind,
      templateFieldIds: templateFields.isEmpty ? null : templateFields,
    );
    _extraFields.syncFields(fields, item.metadata);
    setState(() => _editing = true);
  }

  /// Kind on edit: keep existing unless category becomes/leaves General.
  ResourceType _resolvedEditKind({
    required InventoryItem item,
    required String category,
  }) {
    if (category == kCategoryGeneral) {
      return ResourceType.sale;
    }
    if (item.defaultItemKind == ResourceType.sale) {
      return ResourceType.rental;
    }
    return item.defaultItemKind;
  }

  ResourceType _editKind({
    required InventoryItem item,
    required String category,
  }) {
    return _kindOverride ?? _resolvedEditKind(item: item, category: category);
  }

  Future<void> _saveEdit() async {
    if (_saving) {
      return;
    }
    final AppLocalizations l10n = context.l10n;
    final String name = _nameController.text.trim();
    final String category = resolveSelectedCategory(
      selected: _selectedCategory,
      customText: _customCategoryController.text,
    );
    final String notes = _notesController.text.trim();
    if (!meetsMinMeaningfulText(name) || !meetsMinMeaningfulText(category)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.minMeaningfulTextError(kMinMeaningfulTextLength)),
        ),
      );
      return;
    }
    if (!meetsMinMeaningfulText(notes, allowEmpty: true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.minMeaningfulTextError(kMinMeaningfulTextLength)),
        ),
      );
      return;
    }
    final List<InventoryItem> inventory =
        ref.read(inventoryProvider).asData?.value ?? const <InventoryItem>[];
    final int existingIndex =
        inventory.indexWhere((InventoryItem entry) => entry.id == widget.itemId);
    if (existingIndex < 0) {
      return;
    }
    final InventoryItem existing = inventory[existingIndex];
    final int units = int.tryParse(_unitsController.text.trim()) ?? 1;
    final ResourceType kind =
        _editKind(item: existing, category: category);
    final List<String> templateFields = ref.read(extraFieldIdsProvider);
    final List<FieldDef> fields = resolveExtraFields(
      type: kind,
      templateFieldIds: templateFields.isEmpty ? null : templateFields,
    );
    setState(() => _saving = true);
    await ref.read(repositoryProvider).updateInventory(
      id: widget.itemId,
      name: name,
      category: category,
      units: units < 1 ? 1 : units,
      notes: notes,
      billingMode: _billingMode,
      rateAmount: parseRupeesToPaise(_rateController.text),
      lateFeePerDay: parseRupeesToPaise(_lateFeeController.text),
      securityDepositPaise: parseRupeesToPaise(_securityDepositController.text),
      dueDateOptional: _dueDateOptional,
      requiresUnitIdentity: _requiresUnitIdentity,
      unitCodePrefix: _unitCodePrefixController.text,
      updateUnitCodePrefix: true,
      allowsDynamicPricing: _allowsDynamicPricing,
      defaultItemKind: kind,
      metadata: applySubscriptionCatalogMetadata(
        <String, Object?>{
          ...existing.metadata,
          ..._extraFields.collect(fields),
        },
        skuTier: isSubscriptionCatalogType(kind) ? _skuTier : null,
        periodUnit: _periodUnit,
        periodCount: int.tryParse(_periodCountController.text.trim()),
        minTier: isSubscriptionCatalogType(kind) ? null : _minTier,
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _saving = false;
      _editing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.resourceUpdated)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<InventoryItem>> inventoryAsync =
        ref.watch(inventoryProvider);
    return inventoryAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (Object error, StackTrace _) => Scaffold(body: Center(child: Text('$error'))),
      data: (List<InventoryItem> inventory) {
        final int index =
            inventory.indexWhere((entry) => entry.id == widget.itemId);
        if (index < 0) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.resourceDetailTitle)),
            body: Center(child: Text(l10n.resourceDeletedSnack)),
          );
        }
        final InventoryItem item = inventory[index];
        final List<String> categoryOptions = buildCategoryOptions(
          inventory,
          locale: Localizations.localeOf(context),
        );
        final AssetStatus status =
            item.availableUnits > 0 ? AssetStatus.available : AssetStatus.rented;
        return Scaffold(
          appBar: AppBar(
            title: Text(_editing ? l10n.editResourceTitle : l10n.resourceDetailTitle),
            actions: <Widget>[
              if (!_editing)
                IconButton(
                  tooltip: l10n.editTooltip,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _beginEdit(item, categoryOptions),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: _editing
                ? <Widget>[
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: l10n.itemNameLabel),
                    ),
                    const SizedBox(height: 8),
                    CategoryPickerField(
                      fieldKeyPrefix: 'edit-category',
                      options: categoryOptions,
                      selectedValue: _selectedCategory,
                      customController: _customCategoryController,
                      onSelected: (String? value) {
                        setState(() => _selectedCategory = value);
                      },
                      categoryLabel: l10n.categoryLabel,
                      otherLabel: l10n.categoryOtherLabel,
                      generalLabel: l10n.categoryGeneralLabel,
                      customLabel: l10n.categoryCustomLabel,
                      customHint: l10n.categoryCustomHint,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _unitsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.totalUnitsLabel,
                        helperText: l10n.totalUnitsHelper,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _unitCodePrefixController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: l10n.unitCodePrefixLabel,
                        hintText: l10n.unitCodePrefixHint,
                        helperText: l10n.unitCodePrefixHelper,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.pricingSectionTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<BillingMode>(
                      key: ValueKey<String>('edit-billing-$_billingMode'),
                      initialValue: _billingMode,
                      decoration: InputDecoration(labelText: l10n.billingModeLabel),
                      items: BillingMode.values
                          .map(
                            (BillingMode mode) => DropdownMenuItem<BillingMode>(
                              value: mode,
                              child: Text(localizedBillingMode(l10n, mode)),
                            ),
                          )
                          .toList(),
                      onChanged: (BillingMode? mode) {
                        if (mode != null) {
                          setState(() => _billingMode = mode);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    MoneyAmountField(
                      controller: _rateController,
                      allowDecimal: true,
                      labelText: l10n.rateAmountLabel,
                      hintText: l10n.rateAmountHint,
                    ),
                    const SizedBox(height: 8),
                    MoneyAmountField(
                      controller: _lateFeeController,
                      allowDecimal: true,
                      labelText: l10n.lateFeePerDayLabel,
                      hintText: l10n.lateFeePerDayHint,
                    ),
                    if (catalogSupportsSecurityDeposit(
                      _editKind(
                        item: item,
                        category: resolveSelectedCategory(
                          selected: _selectedCategory,
                          customText: _customCategoryController.text,
                        ),
                      ),
                    )) ...<Widget>[
                      const SizedBox(height: 8),
                      MoneyAmountField(
                        controller: _securityDepositController,
                        allowDecimal: true,
                        labelText: l10n.securityDepositLabel,
                        hintText: l10n.securityDepositHint,
                        helperText: l10n.securityDepositHelper,
                      ),
                    ],
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _dueDateOptional,
                      title: Text(l10n.dueDateOptionalLabel),
                      subtitle: Text(l10n.dueDateOptionalSubtitle),
                      onChanged: (bool value) {
                        setState(() => _dueDateOptional = value);
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _requiresUnitIdentity,
                      title: Text(l10n.requiresUnitIdentityLabel),
                      subtitle: Text(l10n.requiresUnitIdentitySubtitle),
                      onChanged: (bool value) {
                        setState(() => _requiresUnitIdentity = value);
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _allowsDynamicPricing,
                      title: Text(l10n.allowsDynamicPricingLabel),
                      subtitle: Text(l10n.allowsDynamicPricingSubtitle),
                      onChanged: (bool value) {
                        setState(() => _allowsDynamicPricing = value);
                      },
                    ),
                    ...() {
                      final String category = resolveSelectedCategory(
                        selected: _selectedCategory,
                        customText: _customCategoryController.text,
                      );
                      final ResourceType kind =
                          _editKind(item: item, category: category);
                      final List<ResourceType> enabled =
                          ref.watch(enabledResourceTypesProvider);
                      final bool showKindPicker =
                          enabled.any(isSubscriptionCatalogType) ||
                              isSubscriptionCatalogType(kind);
                      final List<ResourceType> kindOptions = <ResourceType>{
                        ...enabled,
                        kind,
                      }.toList();
                      return <Widget>[
                        if (showKindPicker) ...<Widget>[
                          const SizedBox(height: 8),
                          DropdownButtonFormField<ResourceType>(
                            key: ValueKey<String>('edit-kind-$kind'),
                            initialValue: kind,
                            decoration: InputDecoration(
                              labelText: l10n.catalogResourceTypeLabel,
                            ),
                            items: kindOptions
                                .map(
                                  (ResourceType type) =>
                                      DropdownMenuItem<ResourceType>(
                                    value: type,
                                    child: Text(
                                      localizedResourceTypeLabel(l10n, type),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (ResourceType? value) {
                              if (value != null) {
                                setState(() => _kindOverride = value);
                              }
                            },
                          ),
                        ],
                        SubscriptionCatalogFields(
                          fieldKeyPrefix: 'edit-sub',
                          kind: kind,
                          skuTier: _skuTier,
                          periodUnit: _periodUnit,
                          periodCountController: _periodCountController,
                          minTier: _minTier,
                          onSkuTierChanged: (SubscriptionTier t) {
                            setState(() => _skuTier = t);
                          },
                          onPeriodUnitChanged: (SubscriptionPeriodUnit u) {
                            setState(() => _periodUnit = u);
                          },
                          onMinTierChanged: (SubscriptionTier t) {
                            setState(() => _minTier = t);
                          },
                        ),
                      ];
                    }(),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: l10n.notesLabel,
                        hintText: l10n.notesHint,
                      ),
                    ),
                    ...() {
                      final List<String> templateFields =
                          ref.watch(extraFieldIdsProvider);
                      final ResourceType kind = _editKind(
                        item: item,
                        category: resolveSelectedCategory(
                          selected: _selectedCategory,
                          customText: _customCategoryController.text,
                        ),
                      );
                      final List<FieldDef> fields = resolveExtraFields(
                        type: kind,
                        templateFieldIds:
                            templateFields.isEmpty ? null : templateFields,
                      );
                      return buildDynamicFieldInputs(
                        context: context,
                        fields: fields,
                        editors: _extraFields,
                        onChanged: () => setState(() {}),
                      );
                    }(),
                  ]
                : <Widget>[
                    EntityCard(
                      title: item.name,
                      subtitle: l10n.inventoryAvailableSubtitle(
                        categoryWithResourceTypeBadge(l10n, item),
                        item.availableUnits,
                        item.totalUnits,
                      ),
                      leadingIcon: Icons.inventory_2_outlined,
                      status: status,
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.payments_outlined),
                        title: Text(l10n.pricingSectionTitle),
                        subtitle: Text(
                          '${localizedBillingMode(l10n, item.billingMode)} · '
                          '${displayMoney(context, ref, item.rateAmount, currencyCode: item.currencyCode)}'
                          '${item.lateFeePerDay > 0 ? ' · ${displayMoney(context, ref, item.lateFeePerDay)}/day late' : ''}'
                          '${item.securityDepositPaise > 0 ? ' · ${l10n.securityDepositShort(displayMoney(context, ref, item.securityDepositPaise))}' : ''}'
                          '${item.dueDateOptional ? ' · ${l10n.openEndedLabel}' : ''}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.label_outline),
                        title: Text(
                          item.requiresUnitIdentity
                              ? l10n.requiresUnitIdentityLabel
                              : l10n.labelsAutoAssignedHint,
                        ),
                        subtitle: () {
                          final List<String> bits = <String>[
                            if (item.requiresUnitIdentity)
                              l10n.inventoryInstancesNote,
                            if (item.hasUnitCodePool)
                              '${l10n.unitCodePrefixLabel}: ${item.unitCodePrefix}',
                          ];
                          if (bits.isEmpty) {
                            return null;
                          }
                          return Text(bits.join('\n'));
                        }(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.qr_code_2_outlined),
                        title: Text(l10n.qrCodeLabel),
                        subtitle: Text(item.qrCode),
                      ),
                    ),
                    if ((item.notes ?? '').isNotEmpty) ...<Widget>[
                      const SizedBox(height: 10),
                      Card(
                        child: ListTile(
                          title: Text(l10n.notesLabel),
                          subtitle: Text(item.notes!),
                        ),
                      ),
                    ],
                    ...() {
                      final Locale locale = Localizations.localeOf(context);
                      final List<String> templateFields =
                          ref.watch(extraFieldIdsProvider);
                      final List<FieldDef> fields = resolveExtraFields(
                        type: item.defaultItemKind,
                        templateFieldIds:
                            templateFields.isEmpty ? null : templateFields,
                      );
                      final List<Widget> metaCards = <Widget>[];
                      for (final FieldDef field in fields) {
                        final Object? value = item.metadata[field.id];
                        if (value == null ||
                            (value is String && value.trim().isEmpty)) {
                          continue;
                        }
                        metaCards.add(const SizedBox(height: 10));
                        metaCards.add(
                          Card(
                            child: ListTile(
                              title: Text(field.localizedLabel(locale)),
                              subtitle: Text(formatMetadataValue(field, value)),
                            ),
                          ),
                        );
                      }
                      return metaCards;
                    }(),
                  ],
          ),
          bottomNavigationBar: _editing
              ? SafeArea(
                  minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () => setState(() => _editing = false),
                          child: Text(l10n.cancel),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: _saving ? null : _saveEdit,
                          child: Text(_saving ? l10n.saving : l10n.saveChanges),
                        ),
                      ),
                    ],
                  ),
                )
              : item.availableUnits > 0
                  ? SafeArea(
                      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => NewOrderFlowScreen(
                                initialInventoryItemIds: <String>[item.id],
                              ),
                            ),
                          );
                        },
                        child: Text(l10n.issueItemAction),
                      ),
                    )
                  : null,
        );
      },
    );
  }
}
