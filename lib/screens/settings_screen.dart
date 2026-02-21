import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleur/l10n/app_localizations.dart';

import '../ui/global_nav.dart';
import '../ui/settings/subscriptions/subscriptions_settings_tab.dart';
import '../ui/settings/tabs/about_tab.dart';
import '../ui/settings/tabs/app_preferences_tab.dart';
import '../ui/settings/tabs/grouping_sorting_tab.dart';
import '../ui/settings/tabs/services_tab.dart';
import '../providers/subscription_settings_provider.dart';
import '../utils/platform.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _kTwoColumnWidth = 900.0;

  // Nullable index: null means "List View" (Narrow) or "Default" (Wide, usually 0).
  // In Wide mode, if null, we treat it as 0.
  // In Narrow mode, if null, we show List.
  int? _selectedIndex;

  List<_SettingsPageItem> _buildItems(
    BuildContext context, {
    required bool showPageTitle,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return [
      _SettingsPageItem(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: l10n.appPreferences,
        content: const AppPreferencesTab(),
      ),
      _SettingsPageItem(
        icon: Icons.rss_feed_outlined,
        selectedIcon: Icons.rss_feed,
        label: l10n.subscriptions,
        content: SubscriptionsSettingsTab(showPageTitle: showPageTitle),
      ),
      _SettingsPageItem(
        icon: Icons.format_list_bulleted,
        selectedIcon: Icons.format_list_bulleted,
        label: l10n.groupingAndSorting,
        content: GroupingSortingTab(showPageTitle: showPageTitle),
      ),
      _SettingsPageItem(
        icon: Icons.cloud_outlined,
        selectedIcon: Icons.cloud,
        label: l10n.services,
        content: ServicesTab(showPageTitle: showPageTitle),
      ),
      _SettingsPageItem(
        icon: Icons.info_outline,
        selectedIcon: Icons.info,
        label: l10n.about,
        content: AboutTab(showPageTitle: showPageTitle),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final hasGlobalNav = GlobalNavScope.maybeOf(context)?.hasGlobalNav ?? false;
    // Desktop has a top title bar provided by App chrome; avoid in-page AppBar.
    final useCompactTopBar = !isDesktop;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isStacked = constraints.maxWidth < _kTwoColumnWidth;
          final isShowingDetail = isStacked && _selectedIndex != null;
          final items = _buildItems(context, showPageTitle: !isShowingDetail);

          if (isStacked) {
            // Stacked Layout (mobile / narrow desktop / medium desktop)
            // State-driven: If selection exists, show Detail. Else show List.
            if (_selectedIndex != null) {
              final item = items[_selectedIndex!];

              void handleDetailBack() {
                // Special-case Subscriptions tab: allow in-page back (feed -> list -> categories)
                // before leaving the tab back to the Settings list.
                if (_selectedIndex == 1) {
                  final notifier = ref.read(
                    subscriptionSelectionProvider.notifier,
                  );
                  final shouldPop = notifier.handleBack();
                  if (!shouldPop) return;
                }
                setState(() => _selectedIndex = null);
              }

              return PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, _) {
                  if (didPop) return;
                  handleDetailBack();
                },
                child: Scaffold(
                  appBar: useCompactTopBar
                      ? AppBar(
                          leading: BackButton(onPressed: handleDetailBack),
                          title: Text(item.label),
                        )
                      : null,
                  body: useCompactTopBar
                      ? item.content
                      : Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    tooltip: MaterialLocalizations.of(
                                      context,
                                    ).backButtonTooltip,
                                    icon: const Icon(Icons.arrow_back),
                                    onPressed: handleDetailBack,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            Expanded(child: item.content),
                          ],
                        ),
                ),
              );
            }

            return Scaffold(
              appBar: useCompactTopBar
                  ? AppBar(
                      leading: hasGlobalNav ? null : const BackButton(),
                      title: Text(l10n.settings),
                    )
                  : null,
              body: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      leading: Icon(item.icon, size: 20),
                      title: Text(item.label),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () {
                        setState(() => _selectedIndex = index);
                      },
                    ),
                  );
                },
              ),
            );
          }

          // Two-column Layout
          // Ensure valid selection
          final currentIndex = _selectedIndex ?? 0;
          final selectedItem = items[currentIndex];

          return Column(
            children: [
              if (useCompactTopBar)
                AppBar(
                  leading: hasGlobalNav ? null : const BackButton(),
                  title: Text(l10n.settings),
                ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Sidebar
                    Material(
                      color: theme.colorScheme.surfaceContainerLow,
                      child: SizedBox(
                        width: 260,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          itemCount: items.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 4),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final isSelected = index == currentIndex;

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: ListTile(
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                selected: isSelected,
                                leading: Icon(
                                  isSelected ? item.selectedIcon : item.icon,
                                  size: 20,
                                ),
                                title: Text(item.label),
                                onTap: () {
                                  setState(() {
                                    _selectedIndex = index;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Right Content Area
                    Expanded(
                      child: FocusTraversalGroup(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                          child: KeyedSubtree(
                            key: ValueKey(currentIndex),
                            child: Scaffold(
                              backgroundColor: Colors.transparent,
                              body: selectedItem.content,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsPageItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget content;

  const _SettingsPageItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.content,
  });
}
