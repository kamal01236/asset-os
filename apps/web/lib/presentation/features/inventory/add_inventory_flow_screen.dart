import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/app_providers.dart';
import '../../../domain/inventory/inventory_categories.dart';
import '../../../domain/models/entities.dart';
import '../../../domain/orders/order_payment.dart';
import '../../../domain/pricing/rental_pricing.dart';
import '../../../domain/subscriptions/subscription_coverage.dart';
import '../../../domain/subscriptions/subscription_models.dart';
import '../../../domain/validation/text_rules.dart';
import '../../../infrastructure/l10n/l10n_ext.dart';
import '../../widgets/category_picker_field.dart';
import '../../widgets/dynamic_field_inputs.dart';
import '../../widgets/subscription_catalog_fields.dart';
import '../../widgets/ui_primitives.dart';

class AddInventoryFlowScreen extends ConsumerStatefulWidget {
  const AddInventoryFlowScreen({super.key});

  @override
  ConsumerState<AddInventoryFlowScreen> createState() => _AddInventoryFlowScreenState();
}

class _AddInventoryFlowScreenState extends ConsumerState<AddInventoryFlowScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _customCategoryController = TextEditingController();
  final TextEditingController _unitsController = TextEditingController(text: '1');
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _rateController = TextEditingController(text: '0');
  final TextEditingController _lateFeeController = TextEditingController(text: '0');
  final TextEditingController _securityDepositController =
      TextEditingController(text: '0');
  final TextEditingController _unitCodePrefixController = TextEditingController();
  final DynamicFieldEditors _extraFields = DynamicFieldEditors();
  late String _selectedCategory;
  BillingMode _billingMode = BillingMode.weekly;
  bool _dueDateOptional = false;
  bool _requiresUnitIdentity = false;
  bool _allowsDynamicPricing = false;
  bool _submitting = false;
  ResourceType? _kindOverride;
  SubscriptionTier _skuTier = SubscriptionTier.basic;
  SubscriptionPeriodUnit _periodUnit = SubscriptionPeriodUnit.month;
  final TextEditingController _periodCountController =
      TextEditingController(text: '1');
  SubscriptionTier _minTier = SubscriptionTier.none;

  @override
  void initState() {
    super.initState();
    _selectedCategory = kPresetInventoryCategories.isNotEmpty
        ? kPresetInventoryCategories.first
        : kCategoryOther;
  }

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

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final List<InventoryItem> inventory =
        ref.watch(inventoryProvider).asData?.value ?? const <InventoryItem>[];
    final List<String> categoryOptions = buildCategoryOptions(
      inventory,
      locale: Localizations.localeOf(context),
    );
    final String selectedCategory = categoryOptions.contains(_selectedCategory)
        ? _selectedCategory
        : (categoryOptions.isNotEmpty
            ? categoryOptions.first
            : kCategoryOther);
    final String addCategory = resolveSelectedCategory(
      selected: selectedCategory,
      customText: _customCategoryController.text,
    );
    final ResourceType addKind =
        _kindOverride ?? defaultKindForCategory(addCategory);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.actionAddResource)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(l10n.quickAdd),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: l10n.itemNameLabel),
          ),
          const SizedBox(height: 8),
          CategoryPickerField(
            fieldKeyPrefix: 'add-category',
            options: categoryOptions,
            selectedValue: selectedCategory,
            customController: _customCategoryController,
            onSelected: (String? value) {
              if (value != null) {
                setState(() => _selectedCategory = value);
              }
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
            decoration: InputDecoration(labelText: l10n.unitsLabel),
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
            key: ValueKey<String>('add-billing-$_billingMode'),
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
          if (catalogSupportsSecurityDeposit(addKind)) ...<Widget>[
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
            final List<ResourceType> enabled =
                ref.watch(enabledResourceTypesProvider);
            final bool showKindPicker =
                enabled.any(isSubscriptionCatalogType) ||
                    isSubscriptionCatalogType(addKind);
            final List<ResourceType> kindOptions = <ResourceType>{
              ...enabled,
              addKind,
            }.toList();
            return <Widget>[
              if (showKindPicker) ...<Widget>[
                const SizedBox(height: 8),
                DropdownButtonFormField<ResourceType>(
                  key: ValueKey<String>('add-kind-$addKind'),
                  initialValue: addKind,
                  decoration: InputDecoration(
                    labelText: l10n.catalogResourceTypeLabel,
                  ),
                  items: kindOptions
                      .map(
                        (ResourceType type) => DropdownMenuItem<ResourceType>(
                          value: type,
                          child: Text(localizedResourceTypeLabel(l10n, type)),
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
                fieldKeyPrefix: 'add-sub',
                kind: addKind,
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
          ...() {
            final String category = resolveSelectedCategory(
              selected: selectedCategory,
              customText: _customCategoryController.text,
            );
            final ResourceType kind =
                _kindOverride ?? defaultKindForCategory(category);
            final List<String> templateFields = ref.watch(extraFieldIdsProvider);
            final List<FieldDef> fields = resolveExtraFields(
              type: kind,
              templateFieldIds: templateFields.isEmpty ? null : templateFields,
            );
            return buildDynamicFieldInputs(
              context: context,
              fields: fields,
              editors: _extraFields,
              onChanged: () => setState(() {}),
            );
          }(),
          const SizedBox(height: 8),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(l10n.advancedFields),
            subtitle: Text(l10n.advancedFieldsSubtitle),
            children: <Widget>[
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: l10n.notesLabel,
                  hintText: l10n.notesHint,
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: FilledButton(
          onPressed: _submitting
              ? null
              : () async {
                  final String category = resolveSelectedCategory(
                    selected: selectedCategory,
                    customText: _customCategoryController.text,
                  );
                  if (!meetsMinMeaningfulText(_nameController.text) ||
                      !meetsMinMeaningfulText(category)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.minMeaningfulTextError(kMinMeaningfulTextLength),
                        ),
                      ),
                    );
                    return;
                  }
                  if (!meetsMinMeaningfulText(
                    _notesController.text,
                    allowEmpty: true,
                  )) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.minMeaningfulTextError(kMinMeaningfulTextLength),
                        ),
                      ),
                    );
                    return;
                  }
                  final int units = int.tryParse(_unitsController.text.trim()) ?? 1;
                  final ResourceType kind =
                      _kindOverride ?? defaultKindForCategory(category);
                  final List<String> templateFields =
                      ref.read(extraFieldIdsProvider);
                  final List<FieldDef> fields = resolveExtraFields(
                    type: kind,
                    templateFieldIds:
                        templateFields.isEmpty ? null : templateFields,
                  );
                  setState(() => _submitting = true);
                  await ref.read(repositoryProvider).addInventory(
                    name: _nameController.text.trim(),
                    category: category,
                    units: units < 1 ? 1 : units,
                    notes: _notesController.text.trim(),
                    billingMode: _billingMode,
                    rateAmount: parseRupeesToPaise(_rateController.text),
                    lateFeePerDay: parseRupeesToPaise(_lateFeeController.text),
                    securityDepositPaise:
                        parseRupeesToPaise(_securityDepositController.text),
                    dueDateOptional: _dueDateOptional,
                    requiresUnitIdentity: _requiresUnitIdentity,
                    unitCodePrefix: _unitCodePrefixController.text,
                    allowsDynamicPricing: _allowsDynamicPricing,
                    defaultItemKind: kind,
                    metadata: applySubscriptionCatalogMetadata(
                      _extraFields.collect(fields),
                      skuTier:
                          isSubscriptionCatalogType(kind) ? _skuTier : null,
                      periodUnit: _periodUnit,
                      periodCount:
                          int.tryParse(_periodCountController.text.trim()),
                      minTier:
                          isSubscriptionCatalogType(kind) ? null : _minTier,
                    ),
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
          child: Text(l10n.saveItem),
        ),
      ),
    );
  }
}
