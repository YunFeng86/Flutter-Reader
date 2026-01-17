import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/article.dart';
import 'core_providers.dart';
import 'repository_providers.dart';
import 'query_providers.dart';
import 'unread_providers.dart';

class ArticleListState {
  const ArticleListState({
    required this.items,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  final List<Article> items;
  final bool hasMore;
  final bool isLoadingMore;

  ArticleListState copyWith({
    List<Article>? items,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return ArticleListState(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class ArticleListController extends AutoDisposeAsyncNotifier<ArticleListState> {
  static const _pageSize = 50;

  StreamSubscription<void>? _sub;
  int? _feedId;
  int? _categoryId;
  bool _unreadOnly = false;

  @override
  Future<ArticleListState> build() async {
    _feedId = ref.watch(selectedFeedIdProvider);
    _categoryId = ref.watch(selectedCategoryIdProvider);
    _unreadOnly = ref.watch(unreadOnlyProvider);

    // Refresh the list when the underlying query changes (new items from sync,
    // read/star toggles, etc.). For MVP we simply reload the first page.
    _sub?.cancel();
    final isar = ref.watch(isarProvider);
    // Watch the whole collection so we refresh even when toggling read/star on
    // a query that doesn't filter/sort by those fields (e.g. "All articles").
    _sub = isar.articles.watchLazy().listen((_) {
      unawaited(refresh());
    });
    ref.onDispose(() => _sub?.cancel());

    final repo = ref.watch(articleRepositoryProvider);
    final items = await repo.fetchPage(
      offset: 0,
      limit: _pageSize,
      feedId: _feedId,
      categoryId: _categoryId,
      unreadOnly: _unreadOnly,
    );
    return ArticleListState(items: items, hasMore: items.length == _pageSize);
  }

  Future<void> refresh() async {
    final repo = ref.read(articleRepositoryProvider);
    final items = await repo.fetchPage(
      offset: 0,
      limit: _pageSize,
      feedId: _feedId,
      categoryId: _categoryId,
      unreadOnly: _unreadOnly,
    );
    final current = state.valueOrNull;
    if (current == null) {
      state = AsyncValue.data(ArticleListState(
        items: items,
        hasMore: items.length == _pageSize,
      ));
      return;
    }
    state = AsyncValue.data(
      current.copyWith(items: items, hasMore: items.length == _pageSize),
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncValue.data(current.copyWith(isLoadingMore: true));
    try {
      final repo = ref.read(articleRepositoryProvider);
      final more = await repo.fetchPage(
        offset: current.items.length,
        limit: _pageSize,
        feedId: _feedId,
        categoryId: _categoryId,
        unreadOnly: _unreadOnly,
      );
      state = AsyncValue.data(
        current.copyWith(
          items: [...current.items, ...more],
          hasMore: more.length == _pageSize,
          isLoadingMore: false,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final articleListControllerProvider =
    AutoDisposeAsyncNotifierProvider<ArticleListController, ArticleListState>(
  ArticleListController.new,
);
