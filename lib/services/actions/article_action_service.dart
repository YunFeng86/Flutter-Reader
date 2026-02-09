import 'package:dio/dio.dart';
import 'package:isar/isar.dart';

import '../../repositories/category_repository.dart';
import '../../repositories/article_repository.dart';
import '../../repositories/feed_repository.dart';
import '../accounts/account.dart';
import '../accounts/credential_store.dart';
import '../sync/miniflux/miniflux_client.dart';
import '../sync/outbox/outbox_store.dart';

class ArticleActionService {
  ArticleActionService({
    required Account account,
    required ArticleRepository articles,
    required FeedRepository feeds,
    required CategoryRepository categories,
    required Dio dio,
    required CredentialStore credentials,
    required OutboxStore outbox,
  }) : _account = account,
       _articles = articles,
       _feeds = feeds,
       _categories = categories,
       _dio = dio,
       _credentials = credentials,
       _outbox = outbox;

  final Account _account;
  final ArticleRepository _articles;
  final FeedRepository _feeds;
  final CategoryRepository _categories;
  final Dio _dio;
  final CredentialStore _credentials;
  final OutboxStore _outbox;

  Future<void> markRead(int articleId, bool isRead) async {
    final ok = await _runLocalVoid(() => _articles.markRead(articleId, isRead));
    if (!ok) return;

    if (_account.type != AccountType.miniflux) return;
    final entryId = await _resolveRemoteEntryId(articleId);
    if (entryId == null) return;

    final client = await _minifluxClientOrNull();
    if (client == null) return;
    try {
      await client.setEntriesStatus([
        entryId,
      ], status: isRead ? 'read' : 'unread');
    } catch (_) {
      await _outbox.enqueue(
        _account.id,
        OutboxAction(
          type: OutboxActionType.markRead,
          remoteEntryId: entryId,
          value: isRead,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  Future<void> toggleStar(int articleId) async {
    final ok = await _runLocalVoid(() => _articles.toggleStar(articleId));
    if (!ok) return;

    if (_account.type != AccountType.miniflux) return;
    final a = await _articles.getById(articleId);
    final rid = int.tryParse((a?.remoteId ?? '').trim());
    if (rid == null) return;

    final client = await _minifluxClientOrNull();
    if (client == null) return;
    try {
      if (a?.isStarred == true) {
        await client.bookmarkEntry(rid);
      } else {
        await client.unbookmarkEntry(rid);
      }
    } catch (_) {
      await _outbox.enqueue(
        _account.id,
        OutboxAction(
          type: OutboxActionType.bookmark,
          remoteEntryId: rid,
          value: a?.isStarred == true,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  Future<void> toggleReadLater(int articleId) async {
    // Read-later is currently local-only.
    await _runLocalVoid(() => _articles.toggleReadLater(articleId));
  }

  Future<void> markAllRead({int? feedId, int? categoryId}) async {
    final effectiveCategoryId = feedId == null ? categoryId : null;
    final ok = await _runLocalInt(
      () => _articles.markAllRead(feedId: feedId, categoryId: effectiveCategoryId),
    );
    if (ok == null) return;

    if (_account.type != AccountType.miniflux) return;

    final action = await _buildMarkAllReadAction(
      feedId: feedId,
      categoryId: effectiveCategoryId,
    );
    // Safety guard: if user targeted a specific scope but we can't resolve the
    // identifier needed for remote replay, do NOT fall back to "all".
    if (feedId != null && (action.feedUrl == null || action.feedUrl!.trim().isEmpty)) {
      return;
    }
    if (effectiveCategoryId != null &&
        (action.categoryTitle == null || action.categoryTitle!.trim().isEmpty)) {
      return;
    }
    // "Action as fact": persist intent first, then try to apply remotely.
    await _outbox.enqueue(_account.id, action);

    final client = await _minifluxClientOrNull();
    if (client == null) return;
    try {
      await _applyMarkAllRead(client, action);
      await _outbox.remove(_account.id, action);
    } catch (_) {
      // Keep in outbox; will be flushed on next sync.
    }
  }

  Future<OutboxAction> _buildMarkAllReadAction({
    required int? feedId,
    required int? categoryId,
  }) async {
    String? feedUrl;
    String? categoryTitle;
    if (feedId != null) {
      final f = await _feeds.getById(feedId);
      feedUrl = f?.url;
    } else if (categoryId != null) {
      final c = await _categories.getById(categoryId);
      categoryTitle = c?.name;
    }
    return OutboxAction(
      type: OutboxActionType.markAllRead,
      feedUrl: feedUrl,
      categoryTitle: categoryTitle,
      value: true,
      createdAt: DateTime.now(),
    );
  }

  Future<void> _applyMarkAllRead(MinifluxClient client, OutboxAction action) async {
    String normalizeFeedUrl(String url) {
      return url.trim().replaceAll(RegExp(r'/+$'), '');
    }

    final feedUrl = action.feedUrl == null ? null : normalizeFeedUrl(action.feedUrl!);
    final catTitle = action.categoryTitle?.trim();
    if (feedUrl != null && feedUrl.isNotEmpty) {
      final feeds = await client.getFeeds();
      final remote = feeds
          .where((f) => f['id'] is int && f['feed_url'] is String)
          .map(
            (f) => (
              id: f['id'] as int,
              url: normalizeFeedUrl(f['feed_url'] as String),
            ),
          )
          .firstWhere((x) => x.url == feedUrl, orElse: () => (id: -1, url: ''));
      if (remote.id <= 0) throw StateError('Remote feed not found for url: $feedUrl');
      await client.markFeedAllAsRead(remote.id);
      return;
    }
    if (catTitle != null && catTitle.isNotEmpty) {
      final cats = await client.getCategories();
      final remote = cats
          .where((c) => c['id'] is int && c['title'] is String)
          .map((c) => (id: c['id'] as int, title: (c['title'] as String).trim()))
          .firstWhere((x) => x.title == catTitle, orElse: () => (id: -1, title: ''));
      if (remote.id <= 0) {
        throw StateError('Remote category not found for title: $catTitle');
      }
      await client.markCategoryAllAsRead(remote.id);
      return;
    }

    // Fallback: apply to all feeds.
    final feeds = await client.getFeeds();
    for (final f in feeds) {
      final id = f['id'];
      if (id is! int) continue;
      await client.markFeedAllAsRead(id);
    }
  }

  Future<bool> _runLocalVoid(Future<void> Function() op) async {
    try {
      await op();
      return true;
    } on IsarError catch (e) {
      // Account switching can close Isar while UI still has pending unawaited
      // tasks. Treat this as a benign race and ignore.
      if (_isClosedError(e)) return false;
      rethrow;
    }
  }

  Future<int?> _runLocalInt(Future<int> Function() op) async {
    try {
      return await op();
    } on IsarError catch (e) {
      if (_isClosedError(e)) return null;
      rethrow;
    }
  }

  static bool _isClosedError(IsarError e) {
    // Isar throws IsarError('Isar instance has already been closed')
    // when operations are executed after close().
    return e.message.toLowerCase().contains('already been closed');
  }

  Future<int?> _resolveRemoteEntryId(int articleId) async {
    final a = await _articles.getById(articleId);
    if (a == null) return null;
    final raw = a.remoteId?.trim() ?? '';
    if (raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  Future<MinifluxClient?> _minifluxClientOrNull() async {
    final baseUrl = (_account.baseUrl ?? '').trim();
    if (baseUrl.isEmpty) return null;
    final token = await _credentials.getApiToken(
      _account.id,
      AccountType.miniflux,
    );
    if (token == null || token.trim().isEmpty) return null;
    return MinifluxClient(dio: _dio, baseUrl: baseUrl, apiToken: token);
  }
}
