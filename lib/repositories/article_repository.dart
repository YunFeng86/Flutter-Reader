import 'package:isar/isar.dart';

import '../models/article.dart';
import '../models/rule.dart';
import '../models/tag.dart';

class ArticleQuery {
  const ArticleQuery({
    this.feedId,
    this.categoryId,
    this.unreadOnly = false,
    this.starredOnly = false,
    this.readLaterOnly = false,
    this.tagId,
    this.searchQuery = '',
    this.sortAscending = false,
    this.searchInContent = true,
  });

  final int? feedId;
  final int? categoryId;
  final bool unreadOnly;
  final bool starredOnly;
  final bool readLaterOnly;
  final int? tagId;
  final String searchQuery;
  final bool sortAscending;
  final bool searchInContent;

  ArticleQuery copyWith({
    int? feedId,
    int? categoryId,
    bool? unreadOnly,
    bool? starredOnly,
    bool? readLaterOnly,
    int? tagId,
    String? searchQuery,
    bool? sortAscending,
    bool? searchInContent,
  }) {
    return ArticleQuery(
      feedId: feedId ?? this.feedId,
      categoryId: categoryId ?? this.categoryId,
      unreadOnly: unreadOnly ?? this.unreadOnly,
      starredOnly: starredOnly ?? this.starredOnly,
      readLaterOnly: readLaterOnly ?? this.readLaterOnly,
      tagId: tagId ?? this.tagId,
      searchQuery: searchQuery ?? this.searchQuery,
      sortAscending: sortAscending ?? this.sortAscending,
      searchInContent: searchInContent ?? this.searchInContent,
    );
  }
}

class ArticleRepository {
  ArticleRepository(this._isar);

  final Isar _isar;

  static const int defaultPageSize = 50;

  QueryBuilder<Article, Article, QAfterFilterCondition> _buildQuery(
    ArticleQuery query,
  ) {
    final cid = query.categoryId;
    final tid = query.tagId;
    final q = query.searchQuery.trim();
    final hasQuery = q.isNotEmpty;
    return _isar.articles
        .filter()
        .optional(query.feedId != null, (q) => q.feedIdEqualTo(query.feedId!))
        .optional(cid != null && cid < 0, (q) => q.categoryIdIsNull())
        .optional(cid != null && cid >= 0, (q) => q.categoryIdEqualTo(cid!))
        .optional(tid != null, (q) => q.tags((t) => t.idEqualTo(tid!)))
        .optional(query.unreadOnly, (q) => q.isReadEqualTo(false))
        .optional(query.starredOnly, (q) => q.isStarredEqualTo(true))
        .optional(query.readLaterOnly, (q) => q.isReadLaterEqualTo(true))
        .optional(
          hasQuery,
          (q0) => q0.group(
            (q1) => query.searchInContent
                ? q1
                      .titleContains(q, caseSensitive: false)
                      .or()
                      .authorContains(q, caseSensitive: false)
                      .or()
                      .linkContains(q, caseSensitive: false)
                      .or()
                      .contentHtmlContains(q, caseSensitive: false)
                      .or()
                      .fullContentHtmlContains(q, caseSensitive: false)
                : q1
                      .titleContains(q, caseSensitive: false)
                      .or()
                      .authorContains(q, caseSensitive: false)
                      .or()
                      .linkContains(q, caseSensitive: false),
          ),
        );
  }

  QueryBuilder<Article, Article, QAfterSortBy> _applySort(
    QueryBuilder<Article, Article, QAfterFilterCondition> qb, {
    required bool sortAscending,
  }) {
    return sortAscending ? qb.sortByPublishedAt() : qb.sortByPublishedAtDesc();
  }

  Stream<List<Article>> watchLatest({int? feedId, bool unreadOnly = false}) {
    var q = _isar.articles.where().sortByPublishedAtDesc();

    // Isar's `where()` doesn't support filtering by arbitrary fields; use filter().
    // We keep a separate branch to preserve sorting.
    if (feedId == null && !unreadOnly) {
      return q.watch(fireImmediately: true);
    }

    final f = _isar.articles.filter();
    final filtered = (feedId == null ? f : f.feedIdEqualTo(feedId))
        .optional(unreadOnly, (q) => q.isReadEqualTo(false))
        .sortByPublishedAtDesc();
    return filtered.watch(fireImmediately: true);
  }

  Future<List<Article>> fetchPage(
    ArticleQuery query, {
    required int offset,
    required int limit,
  }) {
    final qb = _buildQuery(query);
    final sorted = _applySort(qb, sortAscending: query.sortAscending);
    return sorted.offset(offset).limit(limit).findAll();
  }

  Stream<void> watchQueryChanges(ArticleQuery query) {
    final qb = _buildQuery(query);
    final sorted = _applySort(qb, sortAscending: query.sortAscending);
    return sorted.watchLazy();
  }

  Stream<Article?> watchById(int id) {
    return _isar.articles.watchObject(id, fireImmediately: true);
  }

  Future<Article?> getById(int id) {
    return _isar.articles.get(id);
  }

  Future<void> markRead(int id, bool isRead) {
    return _isar.writeTxn(() async {
      final a = await _isar.articles.get(id);
      if (a == null) return;
      a.isRead = isRead;
      a.updatedAt = DateTime.now();
      await _isar.articles.put(a);
    });
  }

  Future<void> toggleStar(int id) {
    return _isar.writeTxn(() async {
      final a = await _isar.articles.get(id);
      if (a == null) return;
      a.isStarred = !a.isStarred;
      a.updatedAt = DateTime.now();
      await _isar.articles.put(a);
    });
  }

  Future<void> toggleReadLater(int id) {
    return _isar.writeTxn(() async {
      final a = await _isar.articles.get(id);
      if (a == null) return;
      a.isReadLater = !a.isReadLater;
      a.updatedAt = DateTime.now();
      await _isar.articles.put(a);
    });
  }

  Future<void> setFullContent(int id, String html) {
    return _isar.writeTxn(() async {
      final a = await _isar.articles.get(id);
      if (a == null) return;
      a.fullContentHtml = html;
      a.updatedAt = DateTime.now();
      await _isar.articles.put(a);
    });
  }

  Future<int> deleteReadUnstarredOlderThan(DateTime cutoffUtc) {
    return _isar.writeTxn(() async {
      return _isar.articles
          .filter()
          .isReadEqualTo(true)
          .isStarredEqualTo(false)
          .publishedAtLessThan(cutoffUtc)
          .deleteAll();
    });
  }

  Future<void> addTag(int articleId, Tag tag) {
    return _isar.writeTxn(() async {
      final a = await _isar.articles.get(articleId);
      if (a == null) return;
      a.tags.add(tag);
      a.updatedAt = DateTime.now();
      await a.tags.save();
      await _isar.articles.put(a); // Update updatedAt
    });
  }

  Future<void> removeTag(int articleId, Tag tag) {
    return _isar.writeTxn(() async {
      final a = await _isar.articles.get(articleId);
      if (a == null) return;
      a.tags.remove(tag);
      a.updatedAt = DateTime.now();
      await a.tags.save();
      await _isar.articles.put(a);
    });
  }

  Future<int> markAllRead({int? feedId, int? categoryId}) {
    return _markAllReadBatched(feedId: feedId, categoryId: categoryId);
  }

  Future<int> _markAllReadBatched({int? feedId, int? categoryId}) async {
    final cid = categoryId;
    final qb = _isar.articles
        .filter()
        .optional(feedId != null, (q) => q.feedIdEqualTo(feedId!))
        .optional(cid != null && cid < 0, (q) => q.categoryIdIsNull())
        .optional(cid != null && cid >= 0, (q) => q.categoryIdEqualTo(cid!))
        .isReadEqualTo(false);

    // 先取出 ID，避免单次事务加载过多数据。
    final ids = await qb.idProperty().findAll();
    if (ids.isEmpty) return 0;

    const batchSize = 200;
    for (var i = 0; i < ids.length; i += batchSize) {
      final end = i + batchSize > ids.length ? ids.length : i + batchSize;
      final batchIds = ids.sublist(i, end);
      await _isar.writeTxn(() async {
        final items = await _isar.articles.getAll(batchIds);
        final now = DateTime.now();
        final updates = <Article>[];
        for (final a in items) {
          if (a == null) continue;
          a.isRead = true;
          a.updatedAt = now;
          updates.add(a);
        }
        if (updates.isNotEmpty) {
          await _isar.articles.putAll(updates);
        }
      });
    }
    return ids.length;
  }

  Future<List<Article>> getUnread({int? feedId}) {
    final q = _isar.articles.filter().isReadEqualTo(false);
    if (feedId != null) {
      return q.feedIdEqualTo(feedId).findAll();
    }
    return q.findAll();
  }

  Future<(List<Article> newArticles, List<Article> keywordArticles)> upsertMany(
    int feedId,
    List<Article> incoming, {
    List<Rule> rules = const [],
  }) {
    return _isar.writeTxn(() async {
      final enabledRules = rules
          .where((r) => r.enabled)
          .toList(growable: false);

      final newArticles = <Article>[];
      final keywordArticles = <Article>[];

      for (final a in incoming) {
        final existing = await _isar.articles
            .where()
            .linkFeedIdEqualTo(a.link, feedId)
            .findFirst();

        a.feedId = feedId;
        a.updatedAt = DateTime.now();
        a.fetchedAt = DateTime.now();

        bool isNew = false;

        if (existing != null) {
          a.id = existing.id;
          a.isRead = existing.isRead;
          a.isStarred = existing.isStarred;
          a.isReadLater = existing.isReadLater;
          a.fullContentHtml = existing.fullContentHtml;
          if (a.publishedAt.millisecondsSinceEpoch == 0) {
            a.publishedAt = existing.publishedAt;
          }
        } else {
          isNew = true;
          // Apply automation rules only on first insert so we don't override
          // user actions on subsequent refreshes.
          if (enabledRules.isNotEmpty) {
            final (markRead, star, notify) = _applyRules(enabledRules, a);
            if (markRead) a.isRead = true;
            if (star) a.isStarred = true;
            if (notify) keywordArticles.add(a);
          }
        }

        await _isar.articles.put(a);
        if (isNew) {
          newArticles.add(a);
        }
      }
      return (newArticles, keywordArticles);
    });
  }

  (bool markRead, bool star, bool notify) _applyRules(
    List<Rule> rules,
    Article a,
  ) {
    bool shouldMarkRead = false;
    bool shouldStar = false;
    bool shouldNotify = false;

    final keywordCache = <int, String>{};

    bool matches(Rule r) {
      final needle = keywordCache.putIfAbsent(
        r.id,
        () => r.keyword.trim().toLowerCase(),
      );
      if (needle.isEmpty) return false;

      bool contains(String? haystack) {
        if (haystack == null || haystack.isEmpty) return false;
        return haystack.toLowerCase().contains(needle);
      }

      if (r.matchTitle && contains(a.title)) return true;
      if (r.matchAuthor && contains(a.author)) return true;
      if (r.matchLink && contains(a.link)) return true;
      if (r.matchContent &&
          (contains(a.contentHtml) || contains(a.fullContentHtml))) {
        return true;
      }
      return false;
    }

    for (final r in rules) {
      if (!matches(r)) continue;
      if (r.autoMarkRead) shouldMarkRead = true;
      if (r.autoStar) shouldStar = true;
      if (r.notify) shouldNotify = true;
      if (shouldMarkRead && shouldStar && shouldNotify) break;
    }

    return (shouldMarkRead, shouldStar, shouldNotify);
  }
}
