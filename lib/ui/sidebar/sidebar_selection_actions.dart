import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/query_providers.dart';

typedef SidebarFeedSelectionCallback = void Function(int? feedId);

class SidebarSelectionActions {
  const SidebarSelectionActions({
    required WidgetRef ref,
    required SidebarFeedSelectionCallback onSelectFeed,
    required VoidCallback closeSidebar,
  }) : _ref = ref,
       _onSelectFeed = onSelectFeed,
       _closeSidebar = closeSidebar;

  final WidgetRef _ref;
  final SidebarFeedSelectionCallback _onSelectFeed;
  final VoidCallback _closeSidebar;

  void _resetBrowseFilters() {
    _ref.read(starredOnlyProvider.notifier).state = false;
    _ref.read(readLaterOnlyProvider.notifier).state = false;
    _ref.read(articleSearchQueryProvider.notifier).state = '';
  }

  void selectFeed(int feedId) {
    if (_ref.read(selectedFeedIdProvider) == feedId) {
      selectAll();
      return;
    }

    _resetBrowseFilters();
    _ref.read(selectedFeedIdProvider.notifier).state = feedId;
    _ref.read(selectedCategoryIdProvider.notifier).state = null;
    _ref.read(selectedTagIdProvider.notifier).state = null;
    _onSelectFeed(feedId);
    _closeSidebar();
  }

  void selectAll() {
    _resetBrowseFilters();
    _ref.read(selectedFeedIdProvider.notifier).state = null;
    _ref.read(selectedCategoryIdProvider.notifier).state = null;
    _ref.read(selectedTagIdProvider.notifier).state = null;
    _onSelectFeed(null);
    _closeSidebar();
  }

  void selectCategory(int categoryId) {
    if (_ref.read(selectedCategoryIdProvider) == categoryId) {
      selectAll();
      return;
    }

    _resetBrowseFilters();
    _ref.read(selectedFeedIdProvider.notifier).state = null;
    _ref.read(selectedCategoryIdProvider.notifier).state = categoryId;
    _ref.read(selectedTagIdProvider.notifier).state = null;
    _onSelectFeed(null);
    _closeSidebar();
  }

  void selectTag(int tagId) {
    if (_ref.read(selectedTagIdProvider) == tagId) {
      selectAll();
      return;
    }

    _resetBrowseFilters();
    _ref.read(selectedFeedIdProvider.notifier).state = null;
    _ref.read(selectedCategoryIdProvider.notifier).state = null;
    _ref.read(selectedTagIdProvider.notifier).state = tagId;
    _onSelectFeed(null);
    _closeSidebar();
  }
}
