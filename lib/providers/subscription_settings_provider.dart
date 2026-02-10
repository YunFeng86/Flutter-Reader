import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Special ID representing the "Uncategorized" pseudo-category.
const kUncategorizedId = -1;

class SubscriptionState {
  /// The currently active category for the middle column (Feed List).
  /// - `null`: No category selected (Layout dependent: might hide middle column or show empty).
  /// - [kUncategorizedId]: The "Uncategorized" folder.
  /// - `> 0`: A valid Category ID.
  final int? activeCategoryId;

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
    this.activeCategoryId,
    this.selectedFeedId,
    this.showGlobalSettings = false,
    this.showCategorySettings = false,
  });

  SubscriptionState copyWith({
    int? activeCategoryId,
    int? selectedFeedId,
    bool clearFeed = false,
    bool? showGlobalSettings,
    bool? showCategorySettings,
  }) {
    return SubscriptionState(
      activeCategoryId: activeCategoryId ?? this.activeCategoryId,
      selectedFeedId: clearFeed
          ? null
          : (selectedFeedId ?? this.selectedFeedId),
      showGlobalSettings: showGlobalSettings ?? this.showGlobalSettings,
      showCategorySettings: showCategorySettings ?? this.showCategorySettings,
    );
  }

  /// Whether we are currently viewing the "Uncategorized" folder.
  bool get isUncategorized => activeCategoryId == kUncategorizedId;

  /// Whether a real, editable category is selected.
  bool get isRealCategory => activeCategoryId != null && activeCategoryId! > 0;

  /// Whether the current state represents an in-page selection that can be
  /// cleared via back navigation.
  bool get canHandleBack =>
      showGlobalSettings ||
      showCategorySettings ||
      selectedFeedId != null ||
      activeCategoryId != null;
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
      activeCategoryId: id,
      selectedFeedId: null,
      showGlobalSettings: false,
      showCategorySettings: false,
    );
  }

  void selectUncategorized() {
    selectCategory(kUncategorizedId);
  }

  void selectFeed(int feedId, [int? categoryId]) {
    // If clicking the currently selected feed, toggle it off.
    if (state.selectedFeedId == feedId) {
      state = state.copyWith(clearFeed: true, showGlobalSettings: false);
      return;
    }
    // If categoryId is provided, we switch context.
    // Otherwise we keep existing category.
    state = SubscriptionState(
      activeCategoryId: categoryId ?? state.activeCategoryId,
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
      activeCategoryId: categoryId,
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
    if (state.activeCategoryId != null) {
      selectCategory(null);
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
