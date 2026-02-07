import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleur/l10n/app_localizations.dart';

import '../ui/global_nav.dart';
import '../ui/settings/subscriptions/subscriptions_settings_tab.dart';
import '../ui/settings/tabs/about_tab.dart';
import '../ui/settings/tabs/app_preferences_tab.dart';
import '../ui/settings/tabs/grouping_sorting_tab.dart';
import '../ui/settings/tabs/services_tab.dart';
import '../utils/platform.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Nullable index: null means "List View" (Narrow) or "Default" (Wide, usually 0).
  // In Wide mode, if null, we treat it as 0.
  // In Narrow mode, if null, we show List.
  int? _selectedIndex;

  List<_SettingsPageItem> _buildItems(BuildContext context) {
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
        content: const SubscriptionsSettingsTab(),
      ),
      _SettingsPageItem(
        icon: Icons.format_list_bulleted,
        selectedIcon: Icons.format_list_bulleted,
        label: l10n.groupingAndSorting,
        content: const GroupingSortingTab(),
      ),
      _SettingsPageItem(
        icon: Icons.cloud_outlined,
        selectedIcon: Icons.cloud,
        label: l10n.services,
        content: const ServicesTab(),
      ),
      _SettingsPageItem(
        icon: Icons.info_outline,
        selectedIcon: Icons.info,
        label: l10n.about,
        content: const AboutTab(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final items = _buildItems(context);
    final hasGlobalNav = GlobalNavScope.maybeOf(context)?.hasGlobalNav ?? false;
    // Desktop has a top title bar provided by App chrome; avoid in-page AppBar.
    final useCompactTopBar = !isDesktop;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 700;

          if (isNarrow) {
            // Mobile / Narrow Layout
            // State-driven: If selection exists, show Detail. Else show List.
            if (_selectedIndex != null) {
              final item = items[_selectedIndex!];
              return PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, _) {
                  if (didPop) return;
                  setState(() => _selectedIndex = null);
                },
                child: Scaffold(
                  appBar: useCompactTopBar
                      ? AppBar(
                          leading: BackButton(
                            onPressed: () =>
                                setState(() => _selectedIndex = null),
                          ),
                          title: Text(item.label),
                        )
                      : null,
                  body: item.content,
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

          // Desktop / Wide Layout
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
