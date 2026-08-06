import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/india_date_format.dart';
import '../../core/l10n/l10n_ext.dart';
import '../../core/models/entities.dart';
import '../../core/models/unknown_customer.dart';
import '../../core/pricing/rental_pricing.dart';
import '../../core/providers/app_providers.dart';
import '../../core/repositories/local_repository.dart';
import '../../core/validation/text_rules.dart';
import '../../core/widgets/ui_primitives.dart';
import 'loan_detail_screen.dart';

/// Create a cash loan now; start date can be backfilled.
///
/// Customer is name + phone with typeahead (New Order pattern). Cash loans
/// require a real phone — no Unknown / no-phone path on this screen.
class LoanCreateScreen extends ConsumerStatefulWidget {
  const LoanCreateScreen({
    this.initialCustomerId,
    super.key,
  });

  final String? initialCustomerId;

  @override
  ConsumerState<LoanCreateScreen> createState() => _LoanCreateScreenState();
}

class _LoanCreateScreenState extends ConsumerState<LoanCreateScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _principalCtrl = TextEditingController();
  final TextEditingController _rateCtrl = TextEditingController(text: '2');
  final TextEditingController _noteCtrl = TextEditingController();
  MoneyLoanDirection _direction = MoneyLoanDirection.given;
  MoneyInterestKind _interestKind = MoneyInterestKind.simple;
  MoneyRatePeriod _ratePeriod = MoneyRatePeriod.monthly;
  DateTime _startedAt = DateTime.now();
  DateTime? _endedAt;
  Customer? _resolvedCustomer;
  List<Customer> _suggestions = const <Customer>[];
  bool _prefillApplied = false;
  bool _saving = false;
  int _lookupGen = 0;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _startedAt = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyPrefill();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _principalCtrl.dispose();
    _rateCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyPrefill() async {
    if (_prefillApplied || !mounted) {
      return;
    }
    _prefillApplied = true;
    final String? id = widget.initialCustomerId;
    if (id == null ||
        isUnknownCustomerId(id) ||
        id == kLegacySelfCustomerId) {
      return;
    }
    final LocalRepository repository = ref.read(repositoryProvider);
    Customer? customer = await repository.customerById(id);
    if (!mounted || customer == null || isUnknownCustomer(customer)) {
      return;
    }
    final Customer resolved = customer;
    setState(() {
      _resolvedCustomer = resolved;
      _phoneController.text = resolved.phone;
      _nameController.text = resolved.name;
      _suggestions = const <Customer>[];
    });
  }

  Future<void> _onCustomerFieldsChanged() async {
    final int gen = ++_lookupGen;
    _clearResolvedIfEdited();
    setState(() {});
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
    final LocalRepository repository = ref.read(repositoryProvider);
    final String nameQ = _nameController.text.trim();
    final String phoneQ = _phoneController.text.trim();
    final Map<String, Customer> merged = <String, Customer>{};
    if (nameQ.length >= kMinMeaningfulTextLength) {
      for (final Customer c
          in await repository.searchCustomersByNameOrPhone(nameQ)) {
        if (!isUnknownCustomer(c)) {
          merged[c.id] = c;
        }
      }
    }
    if (!mounted || expected != _lookupGen) {
      return;
    }
    if (phoneQ.length >= kMinMeaningfulTextLength) {
      for (final Customer c
          in await repository.searchCustomersByNameOrPhone(phoneQ)) {
        if (!isUnknownCustomer(c)) {
          merged[c.id] = c;
        }
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
      _suggestions = const <Customer>[];
    });
  }

  bool _validateCustomerOrSnack() {
    final AppLocalizations l10n = context.l10n;
    if (_resolvedCustomer == null &&
        !meetsMinMeaningfulText(_nameController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.minMeaningfulTextError(kMinMeaningfulTextLength),
          ),
        ),
      );
      return false;
    }
    if (_phoneController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.phoneRequiredError)),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.loanCreateTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(l10n.loanCustomerLabel, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l10n.phoneNumberLabel,
              hintText: l10n.phoneNumberHint,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => _onCustomerFieldsChanged(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.customerNameNewLabel,
              hintText: l10n.customerNameNewHint,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => _onCustomerFieldsChanged(),
          ),
          if (_suggestions.isNotEmpty) ...<Widget>[
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
          if (_suggestions.isEmpty &&
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
          if (_resolvedCustomer != null) ...<Widget>[
            const SizedBox(height: 8),
            EntityCard(
              title: _resolvedCustomer!.name,
              subtitle:
                  l10n.existingCustomerSubtitle(_resolvedCustomer!.phone),
              leadingIcon: Icons.verified_user_outlined,
              status: AssetStatus.available,
            ),
          ],
          const SizedBox(height: 16),
          Text(l10n.loanDirectionLabel, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<MoneyLoanDirection>(
            segments: <ButtonSegment<MoneyLoanDirection>>[
              ButtonSegment<MoneyLoanDirection>(
                value: MoneyLoanDirection.given,
                label: Text(l10n.loanDirectionGiven),
              ),
              ButtonSegment<MoneyLoanDirection>(
                value: MoneyLoanDirection.taken,
                label: Text(l10n.loanDirectionTaken),
              ),
            ],
            selected: <MoneyLoanDirection>{_direction},
            onSelectionChanged: (Set<MoneyLoanDirection> s) {
              setState(() => _direction = s.first);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _principalCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.loanPrincipalLabel,
              border: const OutlineInputBorder(),
              prefixText: '₹ ',
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.loanMoneyGivenOnLabel),
            subtitle: Text(formatIndiaDate(_startedAt)),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                locale: indiaDatePickerLocale(context),
                initialDate: _startedAt,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _startedAt = picked);
              }
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.loanDueOptionalLabel),
            subtitle: Text(
              _endedAt == null ? l10n.loanDueNone : formatIndiaDate(_endedAt!),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (_endedAt != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _endedAt = null),
                  ),
                const Icon(Icons.event_outlined),
              ],
            ),
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                locale: indiaDatePickerLocale(context),
                initialDate: _endedAt ?? _startedAt,
                firstDate: _startedAt,
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() => _endedAt = picked);
              }
            },
          ),
          const SizedBox(height: 8),
          Text(l10n.loanInterestKindLabel, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<MoneyInterestKind>(
            segments: <ButtonSegment<MoneyInterestKind>>[
              ButtonSegment<MoneyInterestKind>(
                value: MoneyInterestKind.simple,
                label: Text(l10n.loanInterestSimple),
              ),
              ButtonSegment<MoneyInterestKind>(
                value: MoneyInterestKind.compound,
                label: Text(l10n.loanInterestCompound),
              ),
            ],
            selected: <MoneyInterestKind>{_interestKind},
            onSelectionChanged: (Set<MoneyInterestKind> s) {
              setState(() => _interestKind = s.first);
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _rateCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: l10n.loanRatePercentLabel,
                    border: const OutlineInputBorder(),
                    suffixText: '%',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<MoneyRatePeriod>(
                  // ignore: deprecated_member_use
                  value: _ratePeriod,
                  items: <DropdownMenuItem<MoneyRatePeriod>>[
                    DropdownMenuItem<MoneyRatePeriod>(
                      value: MoneyRatePeriod.monthly,
                      child: Text(l10n.loanRateMonthly),
                    ),
                    DropdownMenuItem<MoneyRatePeriod>(
                      value: MoneyRatePeriod.yearly,
                      child: Text(l10n.loanRateYearly),
                    ),
                  ],
                  onChanged: (MoneyRatePeriod? v) {
                    if (v != null) {
                      setState(() => _ratePeriod = v);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: l10n.loanRatePeriodLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.loanPeriodEndInterestHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: l10n.loanNoteOptionalLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? l10n.loanSaving : l10n.loanCreateAction),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final AppLocalizations l10n = context.l10n;
    if (!_validateCustomerOrSnack()) {
      return;
    }
    final int principal = parseRupeesToPaise(_principalCtrl.text);
    if (principal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.loanPrincipalRequired)),
      );
      return;
    }
    final double? ratePct = double.tryParse(_rateCtrl.text.trim());
    if (ratePct == null || ratePct < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.loanRateInvalid)),
      );
      return;
    }
    final int rateBps = (ratePct * 100).round();
    final String? note = _noteCtrl.text.trim().isEmpty
        ? null
        : _noteCtrl.text.trim();
    if (note != null && !meetsMinMeaningfulText(note)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.minMeaningfulTextError(kMinMeaningfulTextLength))),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final LocalRepository repository = ref.read(repositoryProvider);
      Customer? resolved = _resolvedCustomer;
      if (resolved == null &&
          widget.initialCustomerId != null &&
          !isUnknownCustomerId(widget.initialCustomerId!) &&
          widget.initialCustomerId != kLegacySelfCustomerId) {
        resolved = await repository.customerById(widget.initialCustomerId!);
      }
      final Customer customer = resolved ??
          await repository.upsertCustomerByPhone(
            phone: _phoneController.text.trim(),
            fallbackName: _nameController.text.trim(),
          );
      final String id = await repository.createMoneyLoan(
            customerId: customer.id,
            direction: _direction,
            principalPaise: principal,
            interestStartedAt: _startedAt,
            interestEndedAt: _endedAt,
            interestKind: _interestKind,
            rateBps: rateBps,
            ratePeriod: _ratePeriod,
            note: note,
          );
      if (!mounted) {
        return;
      }
      // Ensure detail sees the new row (avoid brief not-found flash).
      ref.invalidate(moneyLoansProvider);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => LoanDetailScreen(loanId: id),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
      setState(() => _saving = false);
    }
  }
}
