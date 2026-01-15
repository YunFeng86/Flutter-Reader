import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../models/feed.dart';
import '../providers/query_providers.dart';
import '../providers/opml_providers.dart';
import '../providers/repository_providers.dart';
import '../providers/service_providers.dart';
import '../providers/unread_providers.dart';

class Sidebar extends ConsumerStatefulWidget {
  const Sidebar({super.key, required this.onSelectFeed});

  final void Function(int? feedId) onSelectFeed;

  @override
  ConsumerState<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends ConsumerState<Sidebar> {
  int? _expandedCategoryId;
  bool _expandedUncategorized = false;

  @override
  Widget build(BuildContext context) {
    final feeds = ref.watch(feedsProvider);
    final categories = ref.watch(categoriesProvider);
    final selectedFeedId = ref.watch(selectedFeedIdProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
    final allUnread = ref.watch(unreadCountProvider(null));

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Subscriptions',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                PopupMenuButton<_SidebarMenu>(
                  tooltip: 'More',
                  onSelected: (v) => _onMenu(context, ref, v),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _SidebarMenu.refreshAll,
                      child: Text('Refresh all'),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem(
                      value: _SidebarMenu.importOpml,
                      child: Text('Import OPML'),
                    ),
                    PopupMenuItem(
                      value: _SidebarMenu.exportOpml,
                      child: Text('Export OPML'),
                    ),
                  ],
                ),
                IconButton(
                  tooltip: 'Add',
                  onPressed: () => _showAddFeedDialog(context, ref),
                  icon: const Icon(Icons.add),
                ),
                IconButton(
                  tooltip: 'New category',
                  onPressed: () => _showAddCategoryDialog(context, ref),
                  icon: const Icon(Icons.create_new_folder_outlined),
                ),
                IconButton(
                  tooltip: 'Refresh selected',
                  onPressed: selectedFeedId == null
                      ? null
                      : () async {
                          await ref
                              .read(syncServiceProvider)
                              .refreshFeed(selectedFeedId);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Refreshed')),
                          );
                        },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: feeds.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (feedItems) {
                return categories.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (cats) {
                    final byCat = <int?, List<Feed>>{};
                    for (final f in feedItems) {
                      byCat.putIfAbsent(f.categoryId, () => []).add(f);
                    }

                    Widget allTile = allUnread.when(
                      loading: () => ListTile(
                        selected: selectedFeedId == null && selectedCategoryId == null,
                        leading: const Icon(Icons.all_inbox),
                        title: const Text('All'),
                        onTap: () => _selectAll(ref),
                      ),
                      error: (e, _) => ListTile(
                        selected: selectedFeedId == null && selectedCategoryId == null,
                        leading: const Icon(Icons.all_inbox),
                        title: const Text('All'),
                        subtitle: Text('Unread count error: $e'),
                        onTap: () => _selectAll(ref),
                      ),
                      data: (count) => ListTile(
                        selected: selectedFeedId == null && selectedCategoryId == null,
                        leading: const Icon(Icons.all_inbox),
                        title: const Text('All'),
                        trailing: _UnreadBadge(count),
                        onTap: () => _selectAll(ref),
                      ),
                    );

                    final children = <Widget>[allTile, const Divider(height: 1)];

                    for (final c in cats) {
                      children.add(_categoryTile(
                        context: context,
                        ref: ref,
                        category: c,
                        feeds: byCat[c.id] ?? const <Feed>[],
                        selectedFeedId: selectedFeedId,
                        selectedCategoryId: selectedCategoryId,
                      ));
                    }

                    // Uncategorized group.
                    children.add(_uncategorizedTile(
                      context: context,
                      ref: ref,
                      feeds: byCat[null] ?? const <Feed>[],
                      selectedFeedId: selectedFeedId,
                      selectedCategoryId: selectedCategoryId,
                    ));

                    return ListView(children: children);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryTile({
    required BuildContext context,
    required WidgetRef ref,
    required Category category,
    required List<Feed> feeds,
    required int? selectedFeedId,
    required int? selectedCategoryId,
  }) {
    final unread = ref.watch(unreadCountByCategoryProvider(category.id));
    final selected = selectedFeedId == null && selectedCategoryId == category.id;
    final expanded = _expandedCategoryId == category.id;

    return Column(
      children: [
        ListTile(
          selected: selected,
          leading: const Icon(Icons.folder_outlined),
          title: Text(category.name),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              unread.when(
                data: (c) => _UnreadBadge(c),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              IconButton(
                tooltip: expanded ? 'Collapse' : 'Expand',
                onPressed: () {
                  setState(() {
                    _expandedCategoryId = expanded ? null : category.id;
                  });
                },
                icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
              ),
            ],
          ),
          onTap: () => _selectCategory(ref, category.id),
          onLongPress: () => _showCategoryMenu(context, ref, category),
        ),
        if (expanded)
          ...feeds.map((f) {
            final unread = ref.watch(unreadCountProvider(f.id));
            return unread.when(
              data: (count) => _feedTile(
                context,
                ref,
                f,
                selectedFeedId,
                count,
                indent: 16,
              ),
              loading: () => _feedTile(
                context,
                ref,
                f,
                selectedFeedId,
                null,
                indent: 16,
              ),
              error: (_, _) => _feedTile(
                context,
                ref,
                f,
                selectedFeedId,
                null,
                indent: 16,
              ),
            );
          }),
      ],
    );
  }

  Widget _uncategorizedTile({
    required BuildContext context,
    required WidgetRef ref,
    required List<Feed> feeds,
    required int? selectedFeedId,
    required int? selectedCategoryId,
  }) {
    final expanded = _expandedUncategorized;
    final selected = selectedFeedId == null && selectedCategoryId == -1;
    final unread = ref.watch(unreadCountUncategorizedProvider);
    return Column(
      children: [
        ListTile(
          selected: selected,
          leading: const Icon(Icons.folder_open_outlined),
          title: const Text('Uncategorized'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              unread.when(
                data: (c) => _UnreadBadge(c),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              IconButton(
                tooltip: expanded ? 'Collapse' : 'Expand',
                onPressed: () => setState(() => _expandedUncategorized = !expanded),
                icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
              ),
            ],
          ),
          onTap: () => _selectUncategorized(ref),
        ),
        if (expanded)
          ...feeds.map((f) {
            final unread = ref.watch(unreadCountProvider(f.id));
            return unread.when(
              data: (count) => _feedTile(
                context,
                ref,
                f,
                selectedFeedId,
                count,
                indent: 16,
              ),
              loading: () => _feedTile(
                context,
                ref,
                f,
                selectedFeedId,
                null,
                indent: 16,
              ),
              error: (_, _) => _feedTile(
                context,
                ref,
                f,
                selectedFeedId,
                null,
                indent: 16,
              ),
            );
          }),
      ],
    );
  }

  Widget _feedTile(
    BuildContext context,
    WidgetRef ref,
    Feed f,
    int? selectedFeedId,
    int? unreadCount,
    {double indent = 0}
  ) {
    final title = f.title?.trim().isNotEmpty == true ? f.title! : f.url;
    return ListTile(
      selected: selectedFeedId == f.id,
      contentPadding: EdgeInsets.only(left: 16 + indent, right: 8),
      leading: const Icon(Icons.rss_feed),
      title: Text(title),
      subtitle: f.title?.trim().isNotEmpty == true
          ? Text(f.url, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      trailing: unreadCount == null ? null : _UnreadBadge(unreadCount),
      onTap: () => _select(ref, f.id),
      onLongPress: () => _showFeedMenu(context, ref, f),
    );
  }

  void _select(WidgetRef ref, int? id) {
    ref.read(selectedFeedIdProvider.notifier).state = id;
    ref.read(selectedCategoryIdProvider.notifier).state = null;
    widget.onSelectFeed(id);
  }

  void _selectAll(WidgetRef ref) {
    ref.read(selectedFeedIdProvider.notifier).state = null;
    ref.read(selectedCategoryIdProvider.notifier).state = null;
    widget.onSelectFeed(null);
  }

  void _selectCategory(WidgetRef ref, int categoryId) {
    ref.read(selectedFeedIdProvider.notifier).state = null;
    ref.read(selectedCategoryIdProvider.notifier).state = categoryId;
    widget.onSelectFeed(null);
  }

  void _selectUncategorized(WidgetRef ref) {
    // We use -1 sentinel in UI; the Article list filters by `categoryId == null`
    // by selecting no category and no feed. This keeps MVP simple.
    ref.read(selectedFeedIdProvider.notifier).state = null;
    ref.read(selectedCategoryIdProvider.notifier).state = -1;
    widget.onSelectFeed(null);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, int feedId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete subscription?'),
          content: const Text('This will delete its cached articles too.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    await ref.read(feedRepositoryProvider).delete(feedId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deleted')),
    );
  }

  Future<void> _showAddFeedDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add subscription'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'RSS/Atom URL',
              hintText: 'https://example.com/feed.xml',
            ),
            autofocus: true,
            keyboardType: TextInputType.url,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    if (url == null || url.trim().isEmpty) return;

    final id = await ref.read(feedRepositoryProvider).upsertUrl(url);
    await ref.read(syncServiceProvider).refreshFeed(id);
    ref.read(selectedFeedIdProvider.notifier).state = id;
    ref.read(selectedCategoryIdProvider.notifier).state = null;
    widget.onSelectFeed(id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added & synced')),
    );
  }

  Future<void> _showAddCategoryDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New category'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Name'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
    if (name == null || name.trim().isEmpty) return;
    final id = await ref.read(categoryRepositoryProvider).upsertByName(name);
    setState(() => _expandedCategoryId = id);
  }

  Future<void> _showCategoryMenu(BuildContext context, WidgetRef ref, Category c) async {
    final v = await showModalBottomSheet<_CategoryAction>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete category'),
                onTap: () => Navigator.of(context).pop(_CategoryAction.delete),
              ),
            ],
          ),
        );
      },
    );
    if (v != _CategoryAction.delete) return;
    await ref.read(categoryRepositoryProvider).delete(c.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Category deleted')),
    );
  }

  Future<void> _showFeedMenu(BuildContext context, WidgetRef ref, Feed f) async {
    final action = await showModalBottomSheet<_FeedAction>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Refresh'),
                onTap: () => Navigator.of(context).pop(_FeedAction.refresh),
              ),
              ListTile(
                leading: const Icon(Icons.drive_file_move_outline),
                title: const Text('Move to category'),
                onTap: () => Navigator.of(context).pop(_FeedAction.move),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete subscription'),
                onTap: () => Navigator.of(context).pop(_FeedAction.delete),
              ),
            ],
          ),
        );
      },
    );
    if (!context.mounted) return;

    switch (action) {
      case _FeedAction.refresh:
        await ref.read(syncServiceProvider).refreshFeed(f.id);
        return;
      case _FeedAction.move:
        await _moveFeedToCategory(context, ref, f);
        return;
      case _FeedAction.delete:
        await _confirmDelete(context, ref, f.id);
        return;
      case null:
        return;
    }
  }

  Future<void> _moveFeedToCategory(BuildContext context, WidgetRef ref, Feed f) async {
    final cats = await ref.read(categoryRepositoryProvider).getAll();
    if (!context.mounted) return;
    final selected = await showDialog<int?>(
      context: context,
      builder: (context) {
        final picked = f.categoryId;
        return SimpleDialog(
          title: const Text('Move to category'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(null),
              child: Row(
                children: [
                  Icon(picked == null ? Icons.check : Icons.clear),
                  const SizedBox(width: 8),
                  const Text('Uncategorized'),
                ],
              ),
            ),
            for (final c in cats)
              SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(c.id),
                child: Row(
                  children: [
                    Icon(picked == c.id ? Icons.check : Icons.clear),
                    const SizedBox(width: 8),
                    Text(c.name),
                  ],
                ),
              ),
          ],
        );
      },
    );
    if (selected == f.categoryId) return;
    await ref.read(feedRepositoryProvider).setCategory(feedId: f.id, categoryId: selected);
  }

  Future<void> _onMenu(BuildContext context, WidgetRef ref, _SidebarMenu v) async {
    switch (v) {
      case _SidebarMenu.refreshAll:
        final feeds = await ref.read(feedRepositoryProvider).getAll();
        for (final f in feeds) {
          await ref.read(syncServiceProvider).refreshFeed(f.id);
        }
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Refreshed all')),
        );
        return;
      case _SidebarMenu.importOpml:
        await _importOpml(context, ref);
        return;
      case _SidebarMenu.exportOpml:
        await _exportOpml(context, ref);
        return;
    }
  }

  Future<void> _importOpml(BuildContext context, WidgetRef ref) async {
    const group = XTypeGroup(
      label: 'OPML',
      extensions: ['opml', 'xml'],
      mimeTypes: ['text/xml', 'application/xml'],
    );
    final file = await openFile(acceptedTypeGroups: [group]);
    if (file == null) return;
    final xml = await file.readAsString();
    final entries = ref.read(opmlServiceProvider).parseEntries(xml);
    if (entries.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No feeds found in OPML')),
      );
      return;
    }

    var added = 0;
    for (final e in entries) {
      final feedId = await ref.read(feedRepositoryProvider).upsertUrl(e.url);
      if (e.category != null && e.category!.trim().isNotEmpty) {
        final catId = await ref.read(categoryRepositoryProvider).upsertByName(e.category!);
        await ref.read(feedRepositoryProvider).setCategory(feedId: feedId, categoryId: catId);
      }
      added += 1;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Imported $added feeds')),
    );
  }

  Future<void> _exportOpml(BuildContext context, WidgetRef ref) async {
    final loc = await getSaveLocation(suggestedName: 'subscriptions.opml');
    if (loc == null) return;
    final feeds = await ref.read(feedRepositoryProvider).getAll();
    final cats = await ref.read(categoryRepositoryProvider).getAll();
    final names = {for (final c in cats) c.id: c.name};
    final xml = ref.read(opmlServiceProvider).buildOpml(feeds: feeds, categoryNames: names);
    final xfile = XFile.fromData(
      Uint8List.fromList(utf8.encode(xml)),
      mimeType: 'text/xml',
      name: 'subscriptions.opml',
    );
    await xfile.saveTo(loc.path);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exported OPML')),
    );
  }
}

enum _SidebarMenu { refreshAll, importOpml, exportOpml }
enum _FeedAction { refresh, move, delete }
enum _CategoryAction { delete }

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge(this.count);

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Badge(
      label: Text('$count'),
      backgroundColor: Theme.of(context).colorScheme.primary,
      textColor: Theme.of(context).colorScheme.onPrimary,
    );
  }
}
