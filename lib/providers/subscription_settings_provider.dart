import 'package:flutter_riverpod/flutter_riverpod.dart';

sealed class SubscriptionCategoryScope {
  const SubscriptionCategoryScope();
}

final class SubscriptionCategoryAll extends SubscriptionCategoryScope {
  const SubscriptionCategoryAll();
}

final class SubscriptionCategoryUncategorized
    extends SubscriptionCategoryScope {
  const SubscriptionCategoryUncategorized();
}

final class SubscriptionCategoryId extends SubscriptionCategoryScope {
  const SubscriptionCategoryId(this.id);

  final int id;
}

class SubscriptionState {
  /// The currently active category scope for the middle column (Feed List).
  ///
  /// This is intentionally *not* an `int?` to avoid sentinel values like `-1`
  /// for "Uncategorized".
  final SubscriptionCategoryScope categoryScope;

  /// The currently selected feed for the right column (Settings/Details).
  /// - `null`: No feed selected.
  final int? selectedFeedId;

  /// When true, show the global subscription settings in the detail panel.
  ///
  /// This lets users open global defaults without losing their current
  /// category/feed context (useful for 3-pane layouts).
  final bool showGlobalSettings;

  /// When true, show the selected category settings in the detail panel.
  ///
  /// This is primarily used for narrow layouts that reuse the tree view:
  /// expanding/collapsing a category should not automatically navigate away from
  /// the tree. Instead, users enter category settings explicitly via a "details"
  /// button.
  final bool showCategorySettings;

  const SubscriptionState({
    this.categoryScope = const SubscriptionCategoryAll(),
    this.selectedFeedId,
    this.showGlobalSettings = false,
    this.showCategorySettings = false,
  });

  SubscriptionState copyWith({
    SubscriptionCategoryScope? categoryScope,
    int? selectedFeedId,
    bool clearFeed = false,
    bool? showGlobalSettings,
    bool? showCategorySettings,
  }) {
    return SubscriptionState(
      categoryScope: categoryScope ?? this.categoryScope,
      selectedFeedId: clearFeed
          ? null
          : (selectedFeedId ?? this.selectedFeedId),
      showGlobalSettings: showGlobalSettings ?? this.showGlobalSettings,
      showCategorySettings: showCategorySettings ?? this.showCategorySettings,
    );
  }

  int? get activeCategoryId => switch (categoryScope) {
    SubscriptionCategoryId(:final id) => id,
    _ => null,
  };

  /// Whether we are currently viewing the "Uncategorized" folder.
  bool get isUncategorized =>
      categoryScope is SubscriptionCategoryUncategorized;

  bool get isAll => categoryScope is SubscriptionCategoryAll;

  /// Whether a real, editable category is selected.
  bool get isRealCategory => categoryScope is SubscriptionCategoryId;

  /// Whether the current state represents an in-page selection that can be
  /// cleared via back navigation.
  bool get canHandleBack =>
      showGlobalSettings ||
      showCategorySettings ||
      selectedFeedId != null ||
      !isAll;
}

class SubscriptionSelectionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionSelectionNotifier() : super(const SubscriptionState());

  void selectCategory(int? id) {
    if (state.activeCategoryId == id && state.selectedFeedId == null) {
      // Toggle off if clicking the currently active category (and no feed is selected)
      state = const SubscriptionState();
      return;
    }
    state = SubscriptionState(
      categoryScope: (id == null)
          ? const SubscriptionCategoryAll()
          : SubscriptionCategoryId(id),
      selectedFeedId: null,
      showGlobalSettings: false,
      showCategorySettings: false,
    );
  }

  void selectUncategorized() {
    if (state.isUncategorized && state.selectedFeedId == null) {
      state = const SubscriptionState();
      return;
    }
    state = const SubscriptionState(
      categoryScope: SubscriptionCategoryUncategorized(),
      selectedFeedId: null,
      showGlobalSettings: false,
      showCategorySettings: false,
    );
  }

  void selectFeed(int feedId, {SubscriptionCategoryScope? categoryScope}) {
    // If clicking the currently selected feed, toggle it off.
    if (state.selectedFeedId == feedId) {
      state = state.copyWith(clearFeed: true, showGlobalSettings: false);
      return;
    }
    state = SubscriptionState(
      categoryScope: categoryScope ?? state.categoryScope,
      selectedFeedId: feedId,
      showGlobalSettings: false,
      showCategorySettings: false,
    );
  }

  void clearSelection() {
    state = const SubscriptionState();
  }

  void clearFeedSelection() {
    state = state.copyWith(clearFeed: true, showGlobalSettings: false);
  }

  void openCategorySettings(int categoryId) {
    state = SubscriptionState(
      categoryScope: SubscriptionCategoryId(categoryId),
      selectedFeedId: null,
      showGlobalSettings: false,
      showCategorySettings: true,
    );
  }

  void closeCategorySettings() {
    if (!state.showCategorySettings) return;
    state = state.copyWith(showCategorySettings: false);
  }

  void toggleGlobalSettings() {
    state = state.copyWith(showGlobalSettings: !state.showGlobalSettings);
  }

  void closeGlobalSettings() {
    if (!state.showGlobalSettings) return;
    state = state.copyWith(showGlobalSettings: false);
  }

  /// Handles a single "back" step within the subscription settings UI.
  ///
  /// Returns `true` when there is nothing to handle and callers should allow
  /// the surrounding route to pop.
  bool handleBack() {
    if (state.showGlobalSettings) {
      closeGlobalSettings();
      return false;
    }
    if (state.showCategorySettings) {
      closeCategorySettings();
      return false;
    }
    if (state.selectedFeedId != null) {
      clearFeedSelection();
      return false;
    }
    if (!state.isAll) {
      state = const SubscriptionState();
      return false;
    }
    return true;
  }
}

final subscriptionSelectionProvider =
    StateNotifierProvider<SubscriptionSelectionNotifier, SubscriptionState>((
      ref,
    ) {
      return SubscriptionSelectionNotifier();
    });
