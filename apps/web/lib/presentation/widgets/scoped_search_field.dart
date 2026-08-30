import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/validation/text_rules.dart';
import '../../infrastructure/l10n/l10n_ext.dart';

/// Entity kind for a [SearchSuggestion], used by global typeahead navigation.
enum SearchHitKind { customer, rental, inventory }

/// One selectable row in [ScopedSearchField] suggestions.
class SearchSuggestion {
  const SearchSuggestion({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.leadingIcon,
    this.kind,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData leadingIcon;

  /// Optional hit kind so global search can navigate without ambiguous IDs.
  final SearchHitKind? kind;
}

/// Accessible typeahead search field gated at [kMinMeaningfulTextLength].
///
/// Once the query meets the threshold, renders a keyboard-navigable suggestion
/// list. Shows a clear control when the field is non-empty.
class ScopedSearchField extends StatefulWidget {
  const ScopedSearchField({
    required this.hintText,
    required this.noResultsText,
    required this.suggestions,
    required this.onQueryChanged,
    required this.onSelected,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.showSuggestionList = true,
    super.key,
  });

  final String hintText;
  final String noResultsText;
  final List<SearchSuggestion> suggestions;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<SearchSuggestion> onSelected;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? semanticLabel;

  /// When false, only the field is shown (inline list filter).
  final bool showSuggestionList;

  @override
  State<ScopedSearchField> createState() => _ScopedSearchFieldState();
}

class _ScopedSearchFieldState extends State<ScopedSearchField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  late final FocusNode _fieldFocus = widget.focusNode ?? FocusNode();
  late final bool _ownsController = widget.controller == null;
  late final bool _ownsFieldFocus = widget.focusNode == null;
  int _highlightedIndex = -1;

  String get _query => _controller.text.trim();

  bool get _meetsMin => _query.length >= kMinMeaningfulTextLength;

  bool get _showSuggestions => _meetsMin && widget.showSuggestionList;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    if (_ownsFieldFocus) {
      _fieldFocus.dispose();
    }
    super.dispose();
  }

  void _clearQuery() {
    _controller.clear();
    setState(() => _highlightedIndex = -1);
    widget.onQueryChanged('');
  }

  void _selectIndex(int index) {
    if (index < 0 || index >= widget.suggestions.length) {
      return;
    }
    widget.onSelected(widget.suggestions[index]);
  }

  void _moveHighlight(int delta) {
    final int count = widget.suggestions.length;
    if (!_showSuggestions || count == 0) {
      return;
    }
    setState(() {
      if (_highlightedIndex < 0) {
        _highlightedIndex = delta > 0 ? 0 : count - 1;
      } else {
        _highlightedIndex = (_highlightedIndex + delta).clamp(0, count - 1);
      }
    });
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (!_showSuggestions || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _moveHighlight(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _moveHighlight(-1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (_highlightedIndex >= 0) {
        _selectIndex(_highlightedIndex);
        return KeyEventResult.handled;
      }
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      setState(() => _highlightedIndex = -1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String label = widget.semanticLabel ?? widget.hintText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          label: label,
          textField: true,
          child: Focus(
            onKeyEvent: _handleKey,
            child: TextField(
              controller: _controller,
              focusNode: _fieldFocus,
              autofocus: widget.autofocus,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: widget.hintText,
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: context.l10n.clearSearchTooltip,
                        onPressed: _clearQuery,
                      )
                    : null,
              ),
              onChanged: (String value) {
                setState(() => _highlightedIndex = -1);
                widget.onQueryChanged(value);
              },
            ),
          ),
        ),
        if (_showSuggestions) ...<Widget>[
          const SizedBox(height: 8),
          Semantics(
            label: widget.suggestions.isEmpty
                ? widget.noResultsText
                : '${widget.suggestions.length} suggestions',
            child: Material(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
              child: widget.suggestions.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        widget.noResultsText,
                        style: theme.textTheme.bodySmall,
                      ),
                    )
                  : Column(
                      children: <Widget>[
                        for (int index = 0;
                            index < widget.suggestions.length;
                            index++) ...<Widget>[
                          if (index > 0) const Divider(height: 1),
                          Builder(
                            builder: (BuildContext context) {
                              final SearchSuggestion suggestion =
                                  widget.suggestions[index];
                              final bool highlighted =
                                  index == _highlightedIndex;
                              return Semantics(
                                button: true,
                                label:
                                    '${suggestion.title}. ${suggestion.subtitle}',
                                child: ListTile(
                                  selected: highlighted,
                                  leading: Icon(suggestion.leadingIcon),
                                  title: Text(suggestion.title),
                                  subtitle: Text(suggestion.subtitle),
                                  onTap: () => _selectIndex(index),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ],
    );
  }
}
