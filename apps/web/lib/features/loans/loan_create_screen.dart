import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n_ext.dart';
import '../../core/models/entities.dart';
import '../../core/models/unknown_customer.dart';
import '../../core/pricing/rental_pricing.dart';
import '../../core/providers/app_providers.dart';
import '../../core/validation/text_rules.dart';
import 'loan_detail_screen.dart';

/// Create a cash loan now; start date can be backfilled.
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
  final TextEditingController _principalCtrl = TextEditingController();
  final TextEditingController _rateCtrl = TextEditingController(text: '2');
  final TextEditingController _noteCtrl = TextEditingController();
  MoneyLoanDirection _direction = MoneyLoanDirection.given;
  MoneyInterestKind _interestKind = MoneyInterestKind.simple;
  MoneyRatePeriod _ratePeriod = MoneyRatePeriod.monthly;
  DateTime _startedAt = DateTime.now();
  DateTime? _endedAt;
  String? _customerId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _customerId = widget.initialCustomerId;
    final DateTime now = DateTime.now();
    _startedAt = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _principalCtrl.dispose();
    _rateCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final List<Customer> customers =
        (ref.watch(customersProvider).valueOrNull ?? const <Customer>[])
            .where((Customer c) => c.id != kUnknownCustomerId)
            .toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.loanCreateTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(l10n.loanCustomerLabel, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _customerId != null &&
                    customers.any((Customer c) => c.id == _customerId)
                ? _customerId
                : null,
            items: customers
                .map(
                  (Customer c) => DropdownMenuItem<String>(
                    value: c.id,
                    child: Text('${c.name} (${c.phone})'),
                  ),
                )
                .toList(),
            onChanged: (String? id) => setState(() => _customerId = id),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: l10n.loanCustomerHint,
            ),
          ),
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
            subtitle: Text(_formatDate(_startedAt)),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
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
              _endedAt == null ? l10n.loanDueNone : _formatDate(_endedAt!),
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
    final String? customerId = _customerId;
    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.loanCustomerRequired)),
      );
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
      final String id = await ref.read(repositoryProvider).createMoneyLoan(
            customerId: customerId,
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

  String _formatDate(DateTime value) {
    final String y = value.year.toString().padLeft(4, '0');
    final String m = value.month.toString().padLeft(2, '0');
    final String d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
