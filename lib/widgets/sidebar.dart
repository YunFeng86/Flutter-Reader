import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/feed.dart';
import '../providers/query_providers.dart';
import '../providers/opml_providers.dart';
import '../providers/repository_providers.dart';
import '../providers/service_providers.dart';
import '../providers/unread_providers.dart';

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key, required this.onSelectFeed});

  final void Function(int? feedId) onSelectFeed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feeds = ref.watch(feedsProvider);
    final selectedFeedId = ref.watch(selectedFeedIdProvider);
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
              data: (items) {
                return ListView(
                  children: [
                    allUnread.when(
                      loading: () => ListTile(
                        selected: selectedFeedId == null,
                        leading: const Icon(Icons.all_inbox),
                        title: const Text('All'),
                        onTap: () => _select(ref, null),
                      ),
                      error: (e, _) => ListTile(
                        selected: selectedFeedId == null,
                        leading: const Icon(Icons.all_inbox),
                        title: const Text('All'),
                        subtitle: Text('Unread count error: $e'),
                        onTap: () => _select(ref, null),
                      ),
                      data: (count) => ListTile(
                        selected: selectedFeedId == null,
                        leading: const Icon(Icons.all_inbox),
                        title: const Text('All'),
                        trailing: _UnreadBadge(count),
                        onTap: () => _select(ref, null),
                      ),
                    ),
                    for (final f in items)
                      Consumer(
                        builder: (context, ref, _) {
                          final unread = ref.watch(unreadCountProvider(f.id));
                          return unread.when(
                            loading: () => _feedTile(context, ref, f, selectedFeedId, null),
                            error: (e, _) => _feedTile(context, ref, f, selectedFeedId, null),
                            data: (count) =>
                                _feedTile(context, ref, f, selectedFeedId, count),
                          );
                        },
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _feedTile(
    BuildContext context,
    WidgetRef ref,
    Feed f,
    int? selectedFeedId,
    int? unreadCount,
  ) {
    final title = f.title?.trim().isNotEmpty == true ? f.title! : f.url;
    return ListTile(
      selected: selectedFeedId == f.id,
      leading: const Icon(Icons.rss_feed),
      title: Text(title),
      subtitle: f.title?.trim().isNotEmpty == true
          ? Text(f.url, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      trailing: unreadCount == null ? null : _UnreadBadge(unreadCount),
      onTap: () => _select(ref, f.id),
      onLongPress: () => _confirmDelete(context, ref, f.id),
    );
  }

  void _select(WidgetRef ref, int? id) {
    ref.read(selectedFeedIdProvider.notifier).state = id;
    onSelectFeed(id);
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
    onSelectFeed(id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added & synced')),
    );
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
    final urls = ref.read(opmlServiceProvider).parseFeedUrls(xml);
    if (urls.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No feeds found in OPML')),
      );
      return;
    }

    var added = 0;
    for (final u in urls) {
      await ref.read(feedRepositoryProvider).upsertUrl(u);
      added++;
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
    final xml = ref.read(opmlServiceProvider).buildOpml(feeds: feeds);
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
