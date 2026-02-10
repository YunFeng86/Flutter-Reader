import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/subscription_settings_provider.dart';
import 'category_list_component.dart';
import 'feed_list_component.dart';
import 'settings_detail_panel.dart';
import 'subscription_tree_view.dart';
import 'subscription_toolbar.dart';
import '../../layout.dart';

class SubscriptionLayoutManager extends ConsumerWidget {
  const SubscriptionLayoutManager({super.key, this.showPageTitle = true});

  final bool showPageTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Breakpoints
    // Wide: > 1000
    // Medium: kCompactWidth - 1000
    // Narrow: < kCompactWidth

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final selection = ref.watch(subscriptionSelectionProvider);
        final notifier = ref.read(subscriptionSelectionProvider.notifier);

        final content = Builder(
          builder: (context) {
              if (width >= 1000) {
                // 3 Columns
                return Column(
                  children: [
                    SubscriptionToolbar(showPageTitle: showPageTitle),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 280,
                            child: CategoryListComponent(),
                          ),
                          const SizedBox(width: kPaneGap),
                          const SizedBox(
                            width: 320,
                            child: FeedListComponent(),
                          ),
                          const SizedBox(width: kPaneGap),
                          const Expanded(child: SettingsDetailPanel()),
                        ],
                      ),
                    ),
                  ],
                );
              } else if (width >= kCompactWidth) {
                // 2 Columns: Nav (Tree) | Details
                // User requested Tree View for Medium
                // 2 Columns: Nav (Tree) | Details
                // User requested Tree View for Medium
                return Column(
                  children: [
                    SubscriptionToolbar(showPageTitle: showPageTitle),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 320,
                            child: SubscriptionTreeView(),
                          ),
                          const SizedBox(width: kPaneGap),
                          const Expanded(child: SettingsDetailPanel()),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                // Narrow: 1 Column (Stack)
                final showDetails =
                    selection.showGlobalSettings ||
                    selection.showCategorySettings ||
                    selection.selectedFeedId != null;
                final body = showDetails
                    ? const SettingsDetailPanel()
                    : const SubscriptionTreeView(showDetailButtons: true);

                return Column(
                  children: [
                    SubscriptionToolbar(showPageTitle: showPageTitle),
                    const SizedBox(height: 8),
                    Expanded(child: body),
                  ],
                );
              }
          },
        );

        // If the parent page is already providing title/back handling, avoid
        // installing a nested PopScope here. This prevents "double back" when
        // the Subscriptions tab is embedded in a stacked Settings detail page.
        if (!showPageTitle) return content;

        return PopScope(
          // If selection exists, PopScope prevents backing out and instead goes
          // up a level within the in-page navigation.
          canPop: !selection.canHandleBack,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            notifier.handleBack();
          },
          child: content,
        );
      },
    );
  }
}
