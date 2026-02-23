import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'subscription_layout_manager.dart';

class SubscriptionsSettingsTab extends ConsumerWidget {
  const SubscriptionsSettingsTab({super.key, this.showPageTitle = true});

  /// Whether the tab should render its own page title.
  ///
  /// In stacked navigation (mobile / narrow desktop), the parent settings page
  /// typically shows the current tab label in the title bar. In that case, this
  /// should be false to avoid "double title" UI.
  final bool showPageTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Just wrap the layout manager.
    // We can add any high-level providers here if needed in future.
    return SubscriptionLayoutManager(showPageTitle: showPageTitle);
  }
}
