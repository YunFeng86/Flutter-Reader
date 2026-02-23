import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/subscription_settings_provider.dart';
import '../../../../utils/platform.dart';
import 'subscription_actions.dart';
import '../../layout.dart';

class SubscriptionToolbar extends ConsumerWidget {
  const SubscriptionToolbar({super.key, this.showPageTitle = true});

  final bool showPageTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selection = ref.watch(subscriptionSelectionProvider);
    final selectionNotifier = ref.read(subscriptionSelectionProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final centerTitle = switch (defaultTargetPlatform) {
          TargetPlatform.iOS || TargetPlatform.macOS => true,
          _ => false,
        };

        final isNarrow = maxWidth < kCompactWidth;

        // Show the global gear only when the layout cannot show global defaults
        // side-by-side with the list/detail panes (i.e. narrow stack mode).
        final showGlobalGear = isNarrow;

        // Whether we should render the page title in this toolbar.
        // In stacked navigation, the parent usually shows the current tab label
        // in its title bar, so [showPageTitle] will be false.
        final showTitle = showPageTitle && maxWidth >= 420;

        final canBackInternal = selection.canHandleBack;

        void handleBack() => selectionNotifier.handleBack();

        Widget buildActions() {
          // Responsive action priority:
          // 1) OPML import/export stay inline as long as width allows.
          // 2) Add subscription compresses before OPML drops into overflow.
          // 3) Only on very tight widths do we move actions into the "more" menu.
          final showOpmlText = maxWidth >= 860;
          final showOpmlInline = maxWidth >= 520;
          final showAddText = maxWidth >= 680;
          final showNewCategoryInline = maxWidth >= 440;

          final overflowActions = <_OverflowAction>[];
          if (!showOpmlInline) {
            overflowActions.addAll([
              _OverflowAction.importOpml,
              _OverflowAction.exportOpml,
            ]);
          }
          if (!showNewCategoryInline) {
            overflowActions.add(_OverflowAction.newCategory);
          }

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showGlobalGear)
                IconButton(
                  tooltip: l10n.settings,
                  icon: Icon(
                    selection.showGlobalSettings
                        ? Icons.settings
                        : Icons.settings_outlined,
                  ),
                  onPressed: selectionNotifier.toggleGlobalSettings,
                ),
              if (showAddText)
                FilledButton.icon(
                  onPressed: () {
                    unawaited(
                      SubscriptionActions.showAddFeedDialog(context, ref),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addSubscription),
                )
              else
                IconButton(
                  tooltip: l10n.addSubscription,
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    unawaited(
                      SubscriptionActions.showAddFeedDialog(context, ref),
                    );
                  },
                ),
              const SizedBox(width: 8),
              if (showNewCategoryInline)
                IconButton(
                  tooltip: l10n.newCategory,
                  icon: const Icon(Icons.create_new_folder_outlined),
                  onPressed: () {
                    unawaited(
                      SubscriptionActions.showAddCategoryDialog(context, ref),
                    );
                  },
                ),
              IconButton(
                tooltip: l10n.refreshAll,
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  unawaited(SubscriptionActions.refreshAll(context, ref));
                },
              ),
              if (showOpmlInline) ...[
                if (showOpmlText) ...[
                  TextButton.icon(
                    onPressed: () {
                      unawaited(SubscriptionActions.importOpml(context, ref));
                    },
                    icon: const Icon(Icons.file_upload_outlined),
                    label: Text(l10n.importOpml),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      unawaited(SubscriptionActions.exportOpml(context, ref));
                    },
                    icon: const Icon(Icons.file_download_outlined),
                    label: Text(l10n.exportOpml),
                  ),
                ] else ...[
                  IconButton(
                    tooltip: l10n.importOpml,
                    icon: const Icon(Icons.file_upload_outlined),
                    onPressed: () {
                      unawaited(SubscriptionActions.importOpml(context, ref));
                    },
                  ),
                  IconButton(
                    tooltip: l10n.exportOpml,
                    icon: const Icon(Icons.file_download_outlined),
                    onPressed: () {
                      unawaited(SubscriptionActions.exportOpml(context, ref));
                    },
                  ),
                ],
              ],
              if (overflowActions.isNotEmpty)
                PopupMenuButton<_OverflowAction>(
                  icon: const Icon(Icons.more_vert),
                  tooltip: l10n.more,
                  onSelected: (value) {
                    switch (value) {
                      case _OverflowAction.importOpml:
                        unawaited(SubscriptionActions.importOpml(context, ref));
                        return;
                      case _OverflowAction.exportOpml:
                        unawaited(SubscriptionActions.exportOpml(context, ref));
                        return;
                      case _OverflowAction.newCategory:
                        unawaited(
                          SubscriptionActions.showAddCategoryDialog(
                            context,
                            ref,
                          ),
                        );
                        return;
                    }
                  },
                  itemBuilder: (context) {
                    return overflowActions
                        .map(
                          (a) => PopupMenuItem<_OverflowAction>(
                            value: a,
                            child: switch (a) {
                              _OverflowAction.importOpml => ListTile(
                                leading: const Icon(Icons.file_upload_outlined),
                                title: Text(l10n.importOpml),
                                contentPadding: EdgeInsets.zero,
                              ),
                              _OverflowAction.exportOpml => ListTile(
                                leading: const Icon(
                                  Icons.file_download_outlined,
                                ),
                                title: Text(l10n.exportOpml),
                                contentPadding: EdgeInsets.zero,
                              ),
                              _OverflowAction.newCategory => ListTile(
                                leading: const Icon(
                                  Icons.create_new_folder_outlined,
                                ),
                                title: Text(l10n.newCategory),
                                contentPadding: EdgeInsets.zero,
                              ),
                            },
                          ),
                        )
                        .toList();
                  },
                ),
            ],
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: centerTitle
              ? Row(
                  children: [
                    if (showPageTitle &&
                        isDesktop &&
                        isNarrow &&
                        canBackInternal)
                      IconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                        icon: const Icon(Icons.arrow_back),
                        onPressed: handleBack,
                      ),
                    // Balance trailing actions so the title is truly centered in the
                    // full toolbar width (not just centered between start/end slots).
                    ExcludeSemantics(
                      child: IgnorePointer(
                        child: Opacity(opacity: 0, child: buildActions()),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: showTitle
                            ? Text(
                                l10n.subscriptions,
                                style: Theme.of(context).textTheme.titleLarge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    buildActions(),
                  ],
                )
              : Row(
                  children: [
                    if (showPageTitle &&
                        isDesktop &&
                        isNarrow &&
                        canBackInternal)
                      IconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                        icon: const Icon(Icons.arrow_back),
                        onPressed: handleBack,
                      ),
                    if (showTitle)
                      Text(
                        l10n.subscriptions,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    const Spacer(),
                    buildActions(),
                  ],
                ),
        );
      },
    );
  }
}

enum _OverflowAction { importOpml, exportOpml, newCategory }
