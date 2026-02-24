import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleur/l10n/app_localizations.dart';

import '../providers/reader_search_providers.dart';
import '../ui/layout.dart';

class ReaderSearchBar extends ConsumerStatefulWidget {
  const ReaderSearchBar({super.key, required this.articleId});

  final int articleId;

  @override
  ConsumerState<ReaderSearchBar> createState() => _ReaderSearchBarState();
}

class _ReaderSearchBarState extends ConsumerState<ReaderSearchBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _wasVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode(debugLabel: 'reader_search');
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ReaderSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.articleId != widget.articleId) {
      _controller.clear();
      _focusNode.unfocus();
      _wasVisible = false;
    }
  }

  void _selectAll() {
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(readerSearchControllerProvider(widget.articleId));
    final controller = ref.read(
      readerSearchControllerProvider(widget.articleId).notifier,
    );

    if (!state.visible) {
      if (_wasVisible) {
        if (state.query.isEmpty && _controller.text.isNotEmpty) {
          _controller.clear();
        }
        _focusNode.unfocus();
      }
      _wasVisible = false;
      return const SizedBox.shrink();
    }

    if (!_wasVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _focusNode.requestFocus();
        _selectAll();
      });
    }
    _wasVisible = true;

    final counterText = '${state.currentMatchNumber}/${state.totalMatches}';

    return Positioned(
      top: 12,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kMaxReadingWidth),
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.surfaceContainerHigh,
              shadowColor: theme.shadowColor.withValues(alpha: 0.2),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    const SizedBox(width: 4),
                    Icon(
                      Icons.search,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        onChanged: controller.setQuery,
                        onSubmitted: (_) => controller.nextMatch(),
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: l10n.findInPage,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      counterText,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      iconSize: 20,
                      tooltip: l10n.previousMatch,
                      onPressed: state.totalMatches > 0
                          ? controller.previousMatch
                          : null,
                      icon: const Icon(Icons.keyboard_arrow_up),
                    ),
                    IconButton(
                      iconSize: 20,
                      tooltip: l10n.nextMatch,
                      onPressed: state.totalMatches > 0
                          ? controller.nextMatch
                          : null,
                      icon: const Icon(Icons.keyboard_arrow_down),
                    ),
                    IconButton(
                      iconSize: 20,
                      tooltip: l10n.caseSensitive,
                      onPressed: controller.toggleCaseSensitive,
                      color: state.caseSensitive
                          ? theme.colorScheme.primary
                          : null,
                      icon: const Icon(Icons.keyboard_capslock),
                    ),
                    if (state.isSearching) ...[
                      const SizedBox(width: 4),
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 4),
                    ],
                    IconButton(
                      iconSize: 20,
                      tooltip: l10n.close,
                      onPressed: () {
                        _controller.clear();
                        controller.close(clearQuery: true);
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
