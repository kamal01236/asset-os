import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/pricing/amount_in_words.dart';
import '../../infrastructure/l10n/l10n_ext.dart';
import '../validation/input_formatters.dart';

/// Live amount-in-words helper for the current app locale (Indian crore scale).
String? moneyAmountWordsHelper(BuildContext context, String raw) {
  final String languageCode = Localizations.localeOf(context).languageCode;
  final String words = amountInWordsFromRupeesField(
    raw,
    languageCode: languageCode,
  );
  if (words.isEmpty) {
    return null;
  }
  if (words == kAmountInWordsOverflow) {
    return context.l10n.amountExceedsMaxCrores;
  }
  return words;
}

/// Shared money entry field: ₹ prefix, digit/decimal/signed formatters,
/// 1-lakh-crore cap ([kMaxAmountRupees]), and live amount-in-words helper.
class MoneyAmountField extends StatefulWidget {
  const MoneyAmountField({
    required this.controller,
    super.key,
    this.labelText,
    this.hintText,
    this.helperText,
    this.prefixText = '₹ ',
    this.border,
    this.allowDecimal = false,
    this.allowSigned = false,
    this.maxRupees = kMaxAmountRupees,
    this.onChanged,
    this.enabled = true,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  /// Existing helper (e.g. security deposit guidance). Words render below when set.
  final String? helperText;
  final String? prefixText;
  final InputBorder? border;
  final bool allowDecimal;
  final bool allowSigned;
  final int maxRupees;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool autofocus;

  @override
  State<MoneyAmountField> createState() => _MoneyAmountFieldState();
}

class _MoneyAmountFieldState extends State<MoneyAmountField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerTick);
  }

  @override
  void didUpdateWidget(covariant MoneyAmountField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerTick);
      widget.controller.addListener(_onControllerTick);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerTick);
    super.dispose();
  }

  void _onControllerTick() {
    if (mounted) {
      setState(() {});
    }
  }

  List<TextInputFormatter> _formatters() {
    return <TextInputFormatter>[
      maxRupeesInputFormatter(
        maxRupees: widget.maxRupees,
        allowDecimal: widget.allowDecimal,
        allowSigned: widget.allowSigned,
      ),
    ];
  }

  TextInputType get _keyboardType {
    if (widget.allowSigned && widget.allowDecimal) {
      return const TextInputType.numberWithOptions(decimal: true, signed: true);
    }
    if (widget.allowSigned) {
      return const TextInputType.numberWithOptions(signed: true);
    }
    if (widget.allowDecimal) {
      return const TextInputType.numberWithOptions(decimal: true);
    }
    return TextInputType.number;
  }

  @override
  Widget build(BuildContext context) {
    final String? words = moneyAmountWordsHelper(
      context,
      widget.controller.text,
    );
    final String? existingHelper = widget.helperText;
    final bool splitHelper = existingHelper != null && existingHelper.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TextField(
          controller: widget.controller,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          keyboardType: _keyboardType,
          inputFormatters: _formatters(),
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            prefixText: widget.prefixText,
            border: widget.border,
            helperText: splitHelper ? existingHelper : words,
            helperMaxLines: 3,
          ),
          onChanged: (String value) {
            widget.onChanged?.call(value);
          },
        ),
        if (splitHelper && words != null) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            words,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }
}
