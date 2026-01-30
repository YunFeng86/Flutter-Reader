import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/subscription_settings_provider.dart';
import '../../../../providers/query_providers.dart';
import '../../../../providers/app_settings_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/feed.dart';
import '../../../../models/category.dart';
import '../../../../services/settings/app_settings.dart';
import 'subscription_actions.dart';
import 'settings_inheritance_helper.dart';

class SettingsDetailPanel extends ConsumerWidget {
  const SettingsDetailPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(subscriptionSelectionProvider);
    final l10n = AppLocalizations.of(context)!;

    // 1. Feed Selected -> Show Feed Settings
    if (selection.selectedFeedId != null) {
      final feedAsync = ref.watch(feedsProvider);
      final feed = feedAsync.valueOrNull
          ?.where((f) => f.id == selection.selectedFeedId)
          .firstOrNull;

      if (feed == null) {
        return Center(child: Text(l10n.notFound));
      }
      return _FeedSettings(feed: feed);
    }
    // 2. Category Selected (and NO Feed selected) -> Show Category Settings
    else if (selection.isRealCategory) {
      final categoriesAsync = ref.watch(categoriesProvider);
      final category = categoriesAsync.valueOrNull
          ?.where((c) => c.id == selection.activeCategoryId)
          .firstOrNull;

      if (category == null) {
        return Center(child: Text(l10n.notFound));
      }
      return _CategorySettings(category: category);
    }
    // 3. Fallback -> Global Settings
    else {
      return const _GlobalSettings();
    }
  }
}

class _GlobalSettings extends ConsumerWidget {
  const _GlobalSettings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final appSettingsAsync = ref.watch(appSettingsProvider);

    return appSettingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (appSettings) {
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              l10n.subscriptions,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.add),
              title: Text(l10n.addSubscription),
              onTap: () => SubscriptionActions.showAddFeedDialog(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.create_new_folder_outlined),
              title: Text(l10n.newCategory),
              onTap: () =>
                  SubscriptionActions.showAddCategoryDialog(context, ref),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: Text(l10n.refreshAll),
              subtitle: Text('${l10n.lastSynced}: Just now'),
              onTap: () => SubscriptionActions.refreshAll(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.file_upload_outlined),
              title: Text(l10n.importOpml),
              onTap: () => SubscriptionActions.importOpml(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.file_download_outlined),
              title: Text(l10n.exportOpml),
              onTap: () => SubscriptionActions.exportOpml(context, ref),
            ),
            const Divider(),
            _FilterSection(appSettings: appSettings),
            const Divider(),
            _SyncSection(appSettings: appSettings),
          ],
        );
      },
    );
  }
}

class _CategorySettings extends ConsumerWidget {
  final Category category;

  const _CategorySettings({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final appSettings = ref.watch(appSettingsProvider).valueOrNull;

    if (appSettings == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(category.name, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 24),
        ListTile(
          leading: const Icon(Icons.edit),
          title: Text(l10n.rename),
          onTap: () => SubscriptionActions.renameCategory(
            context,
            ref,
            categoryId: category.id,
            currentName: category.name,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.delete_outline, color: Colors.red),
          title: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          onTap: () {
            SubscriptionActions.deleteCategory(context, ref, category.id);
            ref
                .read(subscriptionSelectionProvider.notifier)
                .selectCategory(null);
          },
        ),
        const Divider(),
        _FilterSection(category: category, appSettings: appSettings),
        const Divider(),
        _SyncSection(category: category, appSettings: appSettings),
      ],
    );
  }
}

class _FeedSettings extends ConsumerWidget {
  final Feed feed;

  const _FeedSettings({required this.feed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final appSettings = ref.watch(appSettingsProvider).valueOrNull;
    final category = feed.categoryId != null
        ? categories.where((c) => c.id == feed.categoryId).firstOrNull
        : null;

    if (appSettings == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          feed.userTitle ?? feed.title ?? 'Feed',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        SelectableText(feed.url),
        const SizedBox(height: 24),
        ListTile(
          leading: const Icon(Icons.edit),
          title: Text(l10n.rename),
          onTap: () => SubscriptionActions.editFeedTitle(
            context,
            ref,
            feedId: feed.id,
            currentTitle: feed.userTitle ?? feed.title,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.folder_open),
          title: Text(l10n.moveToCategory),
          subtitle: Text(category?.name ?? l10n.uncategorized),
          onTap: () =>
              SubscriptionActions.moveFeedToCategory(context, ref, feed.id),
        ),
        ListTile(
          leading: const Icon(Icons.refresh),
          title: Text(l10n.refresh),
          onTap: () => SubscriptionActions.refreshFeed(context, ref, feed.id),
        ),
        const Divider(),
        _FilterSection(
          feed: feed,
          category: category,
          appSettings: appSettings,
        ),
        const Divider(),
        _SyncSection(feed: feed, category: category, appSettings: appSettings),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.delete_outline, color: Colors.red),
          title: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          onTap: () {
            SubscriptionActions.deleteFeed(context, ref, feed.id);
            ref
                .read(subscriptionSelectionProvider.notifier)
                .clearFeedSelection();
          },
        ),
      ],
    );
  }
}

class _FilterSection extends ConsumerWidget {
  final Feed? feed;
  final Category? category;
  final AppSettings appSettings;

  const _FilterSection({this.feed, this.category, required this.appSettings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final effectiveEnabled = SettingsInheritanceHelper.resolveFilterEnabled(
      feed,
      category,
      appSettings,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            l10n.filter,
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _TriStateSwitch(
          title: l10n.enableSync, // Using "Enable" label
          currentValue: feed?.filterEnabled ?? category?.filterEnabled,
          effectiveValue: effectiveEnabled,
          isGlobal: feed == null && category == null,
          onChanged: (val) {
            if (feed != null) {
              SubscriptionActions.updateFeedSettings(
                context,
                ref,
                feedId: feed!.id,
                filterEnabled: val,
                updateFilterEnabled: true,
              );
            } else if (category != null) {
              SubscriptionActions.updateCategorySettings(
                context,
                ref,
                categoryId: category!.id,
                filterEnabled: val,
                updateFilterEnabled: true,
              );
            } else {
              ref
                  .read(appSettingsProvider.notifier)
                  .setFilterEnabled(val ?? false);
            }
          },
        ),
        if (effectiveEnabled)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _FilterKeywordsInput(
              feed: feed,
              category: category,
              appSettings: appSettings,
            ),
          ),
      ],
    );
  }
}

class _SyncSection extends ConsumerWidget {
  final Feed? feed;
  final Category? category;
  final AppSettings appSettings;

  const _SyncSection({this.feed, this.category, required this.appSettings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            l10n.sync,
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _TriStateSwitch(
          title: l10n.enableSync,
          currentValue: feed?.syncEnabled ?? category?.syncEnabled,
          effectiveValue: SettingsInheritanceHelper.resolveSyncEnabled(
            feed,
            category,
            appSettings,
          ),
          isGlobal: feed == null && category == null,
          onChanged: (val) {
            if (feed != null) {
              SubscriptionActions.updateFeedSettings(
                context,
                ref,
                feedId: feed!.id,
                syncEnabled: val,
                updateSyncEnabled: true,
              );
            } else if (category != null) {
              SubscriptionActions.updateCategorySettings(
                context,
                ref,
                categoryId: category!.id,
                syncEnabled: val,
                updateSyncEnabled: true,
              );
            } else {
              ref
                  .read(appSettingsProvider.notifier)
                  .setSyncEnabled(val ?? true);
            }
          },
        ),
        _TriStateSwitch(
          title: l10n.syncImages,
          currentValue: feed?.syncImages ?? category?.syncImages,
          effectiveValue: SettingsInheritanceHelper.resolveSyncImages(
            feed,
            category,
            appSettings,
          ),
          isGlobal: feed == null && category == null,
          onChanged: (val) {
            if (feed != null) {
              SubscriptionActions.updateFeedSettings(
                context,
                ref,
                feedId: feed!.id,
                syncImages: val,
                updateSyncImages: true,
              );
            } else if (category != null) {
              SubscriptionActions.updateCategorySettings(
                context,
                ref,
                categoryId: category!.id,
                syncImages: val,
                updateSyncImages: true,
              );
            } else {
              ref.read(appSettingsProvider.notifier).setSyncImages(val ?? true);
            }
          },
        ),
        _TriStateSwitch(
          title: l10n.syncWebPages,
          currentValue: feed?.syncWebPages ?? category?.syncWebPages,
          effectiveValue: SettingsInheritanceHelper.resolveSyncWebPages(
            feed,
            category,
            appSettings,
          ),
          isGlobal: feed == null && category == null,
          onChanged: (val) {
            if (feed != null) {
              SubscriptionActions.updateFeedSettings(
                context,
                ref,
                feedId: feed!.id,
                syncWebPages: val,
                updateSyncWebPages: true,
              );
            } else if (category != null) {
              SubscriptionActions.updateCategorySettings(
                context,
                ref,
                categoryId: category!.id,
                syncWebPages: val,
                updateSyncWebPages: true,
              );
            } else {
              ref
                  .read(appSettingsProvider.notifier)
                  .setSyncWebPages(val ?? false);
            }
          },
        ),
      ],
    );
  }
}

class _TriStateSwitch extends StatelessWidget {
  final String title;
  final bool? currentValue;
  final bool effectiveValue;
  final bool isGlobal;
  final ValueChanged<bool?> onChanged;

  const _TriStateSwitch({
    required this.title,
    required this.currentValue,
    required this.effectiveValue,
    required this.isGlobal,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    if (isGlobal) {
      return SwitchListTile(
        title: Text(title),
        value: currentValue ?? effectiveValue,
        onChanged: onChanged,
      );
    }

    final bool isSpecific = currentValue != null;
    final bool isOn = isSpecific ? currentValue! : effectiveValue;

    // Style for the state text (Enabled/Off)
    final stateColor = isOn ? colorScheme.primary : colorScheme.error;
    final stateText = isOn ? l10n.enabled : l10n.off;

    // Suffix text: (Default Value) or empty if specific
    final suffixText = isSpecific ? '' : '  ${l10n.defaultValue}';

    return ListTile(
      title: Text(title),
      subtitle: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(
              text: stateText,
              style: TextStyle(color: stateColor, fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: suffixText,
              style: TextStyle(color: colorScheme.outline),
            ),
          ],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSpecific)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip:
                  l10n.inherit, // "Inherit" effectively means reset to default
              onPressed: () => onChanged(null),
            ),
          // We use a PopupMenuButton for selection
          PopupMenuButton<bool?>(
            icon: const Icon(Icons.arrow_drop_down),
            onSelected: onChanged,
            initialValue: currentValue,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: null,
                child: Text(
                  '${l10n.auto} (${effectiveValue ? l10n.autoOn : l10n.autoOff})',
                ),
              ),
              PopupMenuItem(value: true, child: Text(l10n.enabled)),
              PopupMenuItem(value: false, child: Text(l10n.off)),
            ],
          ),
        ],
      ),
      onTap: () {
        // Show the menu programmatically?
        // Actually, ListTile onTap connecting to the same menu is tricky without a key.
        // Let's just rely on the trailing buttons for now,
        // OR wrap the specific interactive parts.
        // User's reference Image 2 seems to have specific click areas.
        // But for better UX, clicking the tile should probably cycle or open menu.
        // Let's keep it simple: Reset button resets, Arrow/Menu button opens menu.
        // Tapping body could toggle?
        // Let's leave onTap null to avoid confusion, or map it to opening menu.
        // Implementing 'open menu' on tile tap requires a GlobalKey which is overkill here.
      },
    );
  }
}

class _FilterKeywordsInput extends ConsumerStatefulWidget {
  final Feed? feed;
  final Category? category;
  final AppSettings appSettings;

  const _FilterKeywordsInput({
    this.feed,
    this.category,
    required this.appSettings,
  });

  @override
  ConsumerState<_FilterKeywordsInput> createState() =>
      _FilterKeywordsInputState();
}

class _FilterKeywordsInputState extends ConsumerState<_FilterKeywordsInput> {
  late TextEditingController _controller;

  // Calculate effective value for placeholder
  String get _effectiveValue => SettingsInheritanceHelper.resolveFilterKeywords(
    widget.feed,
    widget.category,
    widget.appSettings,
  );

  String? get _currentValue =>
      widget.feed?.filterKeywords ?? widget.category?.filterKeywords;

  bool get _isGlobal => widget.feed == null && widget.category == null;

  @override
  void initState() {
    super.initState();
    // If global, we just use the value directly.
    // If category/feed, we prefer the explicit value, else empty (showing placeholder).
    if (_isGlobal) {
      _controller = TextEditingController(
        text: widget.appSettings.filterKeywords,
      );
    } else {
      _controller = TextEditingController(text: _currentValue);
    }
  }

  @override
  void didUpdateWidget(covariant _FilterKeywordsInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isGlobal) {
      if (widget.appSettings.filterKeywords != _controller.text) {
        _controller.text = widget.appSettings.filterKeywords;
      }
    } else {
      // Logic for feed/category updates
      final newVal = _currentValue;
      if (newVal != oldWidget.feed?.filterKeywords &&
          newVal != oldWidget.category?.filterKeywords) {
        if (_controller.text != newVal && newVal != null) {
          _controller.text = newVal;
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: _isGlobal ? null : '${l10n.inherit}: $_effectiveValue',
            border: const OutlineInputBorder(),
            filled: true,
            helperText: l10n.filterKeywordsHint,
            helperMaxLines: 2,
            suffixIcon:
                (!_isGlobal &&
                    _currentValue != null &&
                    _currentValue!.isNotEmpty)
                ? IconButton(
                    icon: const Icon(Icons.undo),
                    tooltip: l10n.inherit,
                    onPressed: () {
                      _controller.clear();
                      _save(null);
                    },
                  )
                : null,
          ),
          minLines: 1,
          maxLines: 3,
          onChanged: (value) => _save(value),
        ),
      ],
    );
  }

  void _save(String? value) {
    if (_isGlobal) {
      ref.read(appSettingsProvider.notifier).setFilterKeywords(value ?? '');
    } else if (widget.feed != null) {
      SubscriptionActions.updateFeedSettings(
        context,
        ref,
        feedId: widget.feed!.id,
        filterKeywords: value,
        updateFilterKeywords: true,
      );
    } else if (widget.category != null) {
      SubscriptionActions.updateCategorySettings(
        context,
        ref,
        categoryId: widget.category!.id,
        filterKeywords: value,
        updateFilterKeywords: true,
      );
    }
  }
}
