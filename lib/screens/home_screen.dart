import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

import '../providers/query_providers.dart';
import '../providers/repository_providers.dart';
import '../providers/service_providers.dart';
import '../providers/unread_providers.dart';
import '../providers/article_list_controller.dart';
import '../widgets/article_list.dart';
import '../widgets/reader_view.dart';
import '../widgets/sidebar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.selectedArticleId});

  final int? selectedArticleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;

    if (!isWide) {
      final unreadOnly = ref.watch(unreadOnlyProvider);
      final selectedFeedId = ref.watch(selectedFeedIdProvider);
      final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
      return Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Reader'),
          actions: [
            IconButton(
              tooltip: unreadOnly ? 'Show all' : 'Unread only',
              onPressed: () => ref.read(unreadOnlyProvider.notifier).state = !unreadOnly,
              icon: Icon(unreadOnly ? Icons.filter_alt : Icons.filter_alt_outlined),
            ),
            IconButton(
              tooltip: 'Mark all read',
              onPressed: () async {
                await ref.read(articleRepositoryProvider).markAllRead(
                      feedId: selectedFeedId,
                      categoryId: selectedFeedId == null ? selectedCategoryId : null,
                    );
              },
              icon: const Icon(Icons.done_all),
            ),
          ],
        ),
        drawer: Drawer(
          child: Sidebar(
            onSelectFeed: (_) {
              Navigator.of(context).maybePop(); // close drawer
            },
          ),
        ),
        body: ArticleList(selectedArticleId: selectedArticleId),
      );
    }

    final shortcuts = <ShortcutActivator, Intent>{
      const SingleActivator(LogicalKeyboardKey.keyJ): const _NextArticleIntent(),
      const SingleActivator(LogicalKeyboardKey.keyK): const _PrevArticleIntent(),
      const SingleActivator(LogicalKeyboardKey.keyR): const _RefreshIntent(),
      const SingleActivator(LogicalKeyboardKey.keyU): const _ToggleUnreadIntent(),
      const SingleActivator(LogicalKeyboardKey.keyM): const _ToggleReadIntent(),
      const SingleActivator(LogicalKeyboardKey.keyS): const _ToggleStarIntent(),
    };

    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: {
          _NextArticleIntent: CallbackAction<_NextArticleIntent>(
            onInvoke: (intent) {
              final list = ref.read(articleListControllerProvider).valueOrNull?.items ?? const [];
              if (list.isEmpty) return null;
              final idx = selectedArticleId == null
                  ? -1
                  : list.indexWhere((a) => a.id == selectedArticleId);
              final next = list[(idx + 1).clamp(0, list.length - 1)];
              context.go('/article/${next.id}');
              return null;
            },
          ),
          _PrevArticleIntent: CallbackAction<_PrevArticleIntent>(
            onInvoke: (intent) {
              final list = ref.read(articleListControllerProvider).valueOrNull?.items ?? const [];
              if (list.isEmpty) return null;
              final idx = selectedArticleId == null
                  ? 0
                  : list.indexWhere((a) => a.id == selectedArticleId);
              final prev = list[(idx - 1).clamp(0, list.length - 1)];
              context.go('/article/${prev.id}');
              return null;
            },
          ),
          _RefreshIntent: CallbackAction<_RefreshIntent>(
            onInvoke: (intent) async {
              final feedId = ref.read(selectedFeedIdProvider);
              final categoryId = ref.read(selectedCategoryIdProvider);
              if (feedId != null) {
                await ref.read(syncServiceProvider).refreshFeed(feedId);
              } else if (categoryId != null) {
                final feeds = await ref.read(feedRepositoryProvider).getAll();
                final filtered = categoryId < 0
                    ? feeds.where((f) => f.categoryId == null)
                    : feeds.where((f) => f.categoryId == categoryId);
                for (final f in filtered) {
                  await ref.read(syncServiceProvider).refreshFeed(f.id);
                }
              } else {
                final feeds = await ref.read(feedRepositoryProvider).getAll();
                for (final f in feeds) {
                  await ref.read(syncServiceProvider).refreshFeed(f.id);
                }
              }
              return null;
            },
          ),
          _ToggleUnreadIntent: CallbackAction<_ToggleUnreadIntent>(
            onInvoke: (intent) {
              final cur = ref.read(unreadOnlyProvider);
              ref.read(unreadOnlyProvider.notifier).state = !cur;
              return null;
            },
          ),
          _ToggleReadIntent: CallbackAction<_ToggleReadIntent>(
            onInvoke: (intent) async {
              if (selectedArticleId == null) return null;
              final a = await ref.read(articleRepositoryProvider).getById(selectedArticleId!);
              if (a == null) return null;
              await ref.read(articleRepositoryProvider).markRead(selectedArticleId!, !a.isRead);
              return null;
            },
          ),
          _ToggleStarIntent: CallbackAction<_ToggleStarIntent>(
            onInvoke: (intent) async {
              if (selectedArticleId == null) return null;
              await ref.read(articleRepositoryProvider).toggleStar(selectedArticleId!);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: Row(
              children: [
                SizedBox(
                  width: 280,
                  child: Sidebar(
                    onSelectFeed: (_) {
                      if (selectedArticleId != null) context.go('/');
                    },
                  ),
                ),
                const VerticalDivider(width: 1),
                SizedBox(
                  width: 420,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 56,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              Consumer(
                                builder: (context, ref, _) {
                                  final unreadOnly = ref.watch(unreadOnlyProvider);
                                  return FilterChip(
                                    selected: unreadOnly,
                                    label: const Text('Unread'),
                                    onSelected: (v) => ref
                                        .read(unreadOnlyProvider.notifier)
                                        .state = v,
                                  );
                                },
                              ),
                              const Spacer(),
                              Consumer(
                                builder: (context, ref, _) {
                                  final selectedFeedId =
                                      ref.watch(selectedFeedIdProvider);
                                  final selectedCategoryId =
                                      ref.watch(selectedCategoryIdProvider);
                                  return IconButton(
                                    tooltip: 'Mark all read',
                                    onPressed: () async {
                                      await ref
                                          .read(articleRepositoryProvider)
                                          .markAllRead(
                                            feedId: selectedFeedId,
                                            categoryId: selectedFeedId == null
                                                ? selectedCategoryId
                                                : null,
                                          );
                                    },
                                    icon: const Icon(Icons.done_all),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ArticleList(selectedArticleId: selectedArticleId),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: selectedArticleId == null
                      ? const Center(child: Text('Select an article'))
                      : ReaderView(articleId: selectedArticleId!, embedded: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NextArticleIntent extends Intent {
  const _NextArticleIntent();
}

class _PrevArticleIntent extends Intent {
  const _PrevArticleIntent();
}

class _RefreshIntent extends Intent {
  const _RefreshIntent();
}

class _ToggleUnreadIntent extends Intent {
  const _ToggleUnreadIntent();
}

class _ToggleReadIntent extends Intent {
  const _ToggleReadIntent();
}

class _ToggleStarIntent extends Intent {
  const _ToggleStarIntent();
}
