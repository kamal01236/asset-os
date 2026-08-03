import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../validation/text_rules.dart';

/// One selectable row in [ScopedSearchField] suggestions.
class SearchSuggestion {
  const SearchSuggestion({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.leadingIcon,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData leadingIcon;
}

/// Accessible typeahead search field gated at [kMinMeaningfulTextLength].
///
/// Shows a helper while the query is shorter than the minimum. Once the query
/// meets the threshold, renders a keyboard-navigable suggestion list.
class ScopedSearchField extends StatefulWidget {
  const ScopedSearchField({
    required this.hintText,
    required this.minLengthHint,
    required this.noResultsText,
    required this.suggestions,
    required this.onQueryChanged,
    required this.onSelected,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    super.key,
  });

  final String hintText;
  final String minLengthHint;
  final String noResultsText;
  final List<SearchSuggestion> suggestions;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<SearchSuggestion> onSelected;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? semanticLabel;

  @override
  State<ScopedSearchField> createState() => _ScopedSearchFieldState();
}

class _ScopedSearchFieldState extends State<ScopedSearchField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  late final FocusNode _fieldFocus = widget.focusNode ?? FocusNode();
  late final FocusNode _listFocus = FocusNode(debugLabel: 'scoped-search-list');
  late final bool _ownsController = widget.controller == null;
  late final bool _ownsFieldFocus = widget.focusNode == null;
  int _highlightedIndex = -1;

  String get _query => _controller.text.trim();

  bool get _meetsMin => _query.length >= kMinMeaningfulTextLength;

  bool get _showSuggestions => _meetsMin;

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    if (_ownsFieldFocus) {
      _fieldFocus.dispose();
    }
    _listFocus.dispose();
    super.dispose();
  }

  void _selectIndex(int index) {
    if (index < 0 || index >= widget.suggestions.length) {
      return;
    }
    widget.onSelected(widget.suggestions[index]);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!_showSuggestions || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    final int count = widget.suggestions.length;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (count == 0) {
        return KeyEventResult.ignored;
      }
      setState(() {
        _highlightedIndex = (_highlightedIndex + 1).clamp(0, count - 1);
      });
      _listFocus.requestFocus();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (count == 0) {
        return KeyEventResult.ignored;
      }
      setState(() {
        _highlightedIndex = _highlightedIndex <= 0
            ? 0
            : (_highlightedIndex - 1).clamp(0, count - 1);
      });
      _listFocus.requestFocus();
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
      _fieldFocus.requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String label = widget.semanticLabel ?? widget.hintText;

    return Focus(
      onKeyEvent: _onKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            label: label,
            textField: true,
            child: TextField(
              controller: _controller,
              focusNode: _fieldFocus,
              autofocus: widget.autofocus,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: widget.hintText,
                helperText: _meetsMin ? null : widget.minLengthHint,
              ),
              onChanged: (String value) {
                setState(() => _highlightedIndex = -1);
                widget.onQueryChanged(value);
              },
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
                child: Focus(
                  focusNode: _listFocus,
                  child: widget.suggestions.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            widget.noResultsText,
                            style: theme.textTheme.bodySmall,
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: widget.suggestions.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (BuildContext context, int index) {
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
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
