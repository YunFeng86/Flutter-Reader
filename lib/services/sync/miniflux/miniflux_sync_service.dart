import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../../../models/article.dart';
import '../../../models/feed.dart';
import '../../../repositories/article_repository.dart';
import '../../../repositories/category_repository.dart';
import '../../../repositories/feed_repository.dart';
import '../../accounts/account.dart';
import '../../accounts/credential_store.dart';
import '../../settings/app_settings.dart';
import '../outbox/outbox_store.dart';
import '../sync_service.dart';
import 'miniflux_client.dart';

class MinifluxSyncService implements SyncServiceBase {
  MinifluxSyncService({
    required this.account,
    required Dio dio,
    required CredentialStore credentials,
    required FeedRepository feeds,
    required CategoryRepository categories,
    required ArticleRepository articles,
    required OutboxStore outbox,
  }) : _dio = dio,
       _credentials = credentials,
       _feeds = feeds,
       _categories = categories,
       _articles = articles,
       _outbox = outbox;

  final Account account;

  final Dio _dio;
  final CredentialStore _credentials;
  final FeedRepository _feeds;
  final CategoryRepository _categories;
  final ArticleRepository _articles;
  final OutboxStore _outbox;

  @override
  Future<int> offlineCacheFeed(int feedId) async {
    // Cache service is wired in the Local SyncService; keep remote M1 minimal.
    return 0;
  }

  @override
  Future<FeedRefreshResult> refreshFeedSafe(
    int feedId, {
    int maxAttempts = 2,
    AppSettings? appSettings,
    bool notify = true,
  }) async {
    final batch = await refreshFeedsSafe([feedId], notify: notify);
    return batch.results.isEmpty
        ? FeedRefreshResult(feedId: feedId, incomingCount: 0, newCount: 0)
        : batch.results.first;
  }

  @override
  Future<BatchRefreshResult> refreshFeedsSafe(
    Iterable<int> feedIds, {
    int maxConcurrent = 2,
    int maxAttemptsPerFeed = 2,
    void Function(int current, int total)? onProgress,
    bool notify = true,
  }) async {
    // For Miniflux, syncing is not "per local feed"; we sync the account once.
    try {
      await syncNow();
      final total = feedIds.length;
      onProgress?.call(total, total);
      return BatchRefreshResult([
        FeedRefreshResult(
          feedId: feedIds.isEmpty ? -1 : feedIds.first,
          incomingCount: 0,
          newCount: 0,
        ),
      ]);
    } catch (e) {
      final total = feedIds.length;
      onProgress?.call(total, total);
      return BatchRefreshResult([
        FeedRefreshResult(
          feedId: feedIds.isEmpty ? -1 : feedIds.first,
          incomingCount: 0,
          newCount: 0,
          error: e,
        ),
      ]);
    }
  }

  Future<void> syncNow({int entriesLimit = 400}) async {
    final client = await _buildClient();
    await _flushOutbox(client);

    final cats = await client.getCategories();
    final remoteCatIdToLocalId = <int, int>{};
    for (final c in cats) {
      final id = c['id'];
      final title = c['title'];
      if (id is! int || title is! String) continue;
      final localId = await _categories.upsertByName(title);
      remoteCatIdToLocalId[id] = localId;
    }

    final feeds = await client.getFeeds();
    final remoteFeedIdToLocalFeed = <int, Feed>{};
    for (final f in feeds) {
      final id = f['id'];
      final feedUrl = f['feed_url'];
      if (id is! int || feedUrl is! String) continue;
      final localId = await _feeds.upsertUrl(feedUrl);
      final categoryId = f['category'] is Map
          ? (f['category'] as Map)['id']
          : f['category_id'];
      int? localCatId;
      if (categoryId is int) localCatId = remoteCatIdToLocalId[categoryId];
      if (localCatId != null) {
        await _feeds.setCategory(feedId: localId, categoryId: localCatId);
      }
      final local = await _feeds.getById(localId);
      if (local != null) {
        await _feeds.updateMeta(
          id: local.id,
          title: f['title'] as String?,
          siteUrl: f['site_url'] as String?,
          description: f['description'] as String?,
          lastSyncedAt: DateTime.now(),
        );
        remoteFeedIdToLocalFeed[id] = local;
      }
    }

    final entries = await client.getEntries(limit: entriesLimit, status: 'all');
    final raw = entries['entries'];
    if (raw is! List) return;

    // Group by local feed id for ArticleRepository.upsertMany() calls.
    final byLocalFeedId = <int, List<Article>>{};
    for (final e in raw) {
      if (e is! Map) continue;
      final m = e.cast<String, Object?>();
      final remoteEntryId = m['id'];
      final remoteFeedId = m['feed_id'];
      if (remoteEntryId is! int || remoteFeedId is! int) continue;
      final localFeed = remoteFeedIdToLocalFeed[remoteFeedId];
      if (localFeed == null) continue;

      final url = m['url'] as String? ?? '';
      if (url.trim().isEmpty) continue;

      final status = m['status'] as String?;
      final isRead = status == 'read';
      final starred = m['starred'] == true;

      final publishedAt =
          _parseEpochSeconds(m['published_at']) ??
          _parseIso(m['published_at']) ??
          _parseIso(m['created_at']);

      final content = m['content'];
      final contentHtml = (content is String) ? content : null;

      final a = Article()
        ..remoteId = remoteEntryId.toString()
        ..link = url
        ..title = m['title'] as String?
        ..author = null
        ..contentHtml = contentHtml
        ..publishedAt = (publishedAt ?? DateTime.now().toUtc())
        ..isRead = isRead
        ..isStarred = starred;

      byLocalFeedId.putIfAbsent(localFeed.id, () => []).add(a);
    }

    for (final entry in byLocalFeedId.entries) {
      // Remote-backed: we want remote read/star state to be authoritative.
      await _articles.upsertMany(
        entry.key,
        entry.value,
        preserveUserState: false,
      );
    }
  }

  Future<MinifluxClient> _buildClient() async {
    final baseUrl = (account.baseUrl ?? '').trim();
    if (baseUrl.isEmpty) {
      throw StateError('Miniflux baseUrl is empty');
    }
    final token = await _credentials.getApiToken(
      account.id,
      AccountType.miniflux,
    );
    if (token == null || token.trim().isEmpty) {
      throw StateError('Miniflux api token is missing');
    }
    return MinifluxClient(dio: _dio, baseUrl: baseUrl, apiToken: token);
  }

  Future<void> _flushOutbox(MinifluxClient client) async {
    final pending = await _outbox.load(account.id);
    if (pending.isEmpty) return;

    Map<String, int>? feedUrlToRemoteId;
    Map<String, int>? categoryTitleToRemoteId;

    String normalizeFeedUrl(String url) {
      // Feed URL equality should be stable across sync/mark-all calls.
      // Strip trailing slashes to avoid needless mismatches.
      return url.trim().replaceAll(RegExp(r'/+$'), '');
    }

    Future<Map<String, int>> getFeedUrlMap() async {
      final cached = feedUrlToRemoteId;
      if (cached != null) return cached;
      final feeds = await client.getFeeds();
      final map = <String, int>{};
      for (final f in feeds) {
        final id = f['id'];
        final feedUrl = f['feed_url'];
        if (id is! int || feedUrl is! String) continue;
        final key = normalizeFeedUrl(feedUrl);
        if (key.isEmpty) continue;
        map[key] = id;
      }
      feedUrlToRemoteId = map;
      return map;
    }

    Future<Map<String, int>> getCategoryTitleMap() async {
      final cached = categoryTitleToRemoteId;
      if (cached != null) return cached;
      final cats = await client.getCategories();
      final map = <String, int>{};
      for (final c in cats) {
        final id = c['id'];
        final title = c['title'];
        if (id is! int || title is! String) continue;
        final key = title.trim();
        if (key.isEmpty) continue;
        map[key] = id;
      }
      categoryTitleToRemoteId = map;
      return map;
    }

    final remaining = <OutboxAction>[];
    for (final a in pending) {
      try {
        switch (a.type) {
          case OutboxActionType.markRead:
            final entryId = a.remoteEntryId;
            final value = a.value;
            if (entryId == null || value == null) continue;
            await client.setEntriesStatus([
              entryId,
            ], status: value ? 'read' : 'unread');
            break;
          case OutboxActionType.bookmark:
            final entryId = a.remoteEntryId;
            final value = a.value;
            if (entryId == null || value == null) continue;
            if (value) {
              await client.bookmarkEntry(entryId);
            } else {
              await client.unbookmarkEntry(entryId);
            }
            break;
          case OutboxActionType.markAllRead:
            final feedUrl = a.feedUrl == null ? null : normalizeFeedUrl(a.feedUrl!);
            final catTitle = a.categoryTitle?.trim();
            if (feedUrl != null && feedUrl.isNotEmpty) {
              final map = await getFeedUrlMap();
              final remoteFeedId = map[feedUrl];
              if (remoteFeedId == null) {
                throw StateError('Remote feed not found for url: $feedUrl');
              }
              await client.markFeedAllAsRead(remoteFeedId);
            } else if (catTitle != null && catTitle.isNotEmpty) {
              final map = await getCategoryTitleMap();
              final remoteCatId = map[catTitle];
              if (remoteCatId == null) {
                throw StateError('Remote category not found for title: $catTitle');
              }
              await client.markCategoryAllAsRead(remoteCatId);
            } else {
              final map = await getFeedUrlMap();
              for (final remoteFeedId in map.values) {
                await client.markFeedAllAsRead(remoteFeedId);
              }
            }
            break;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('outbox flush failed: $e');
        }
        remaining.add(a);
      }
    }

    if (remaining.length != pending.length) {
      await _outbox.save(account.id, remaining);
    }
  }

  static DateTime? _parseEpochSeconds(Object? v) {
    if (v is int) {
      return DateTime.fromMillisecondsSinceEpoch(v * 1000, isUtc: true);
    }
    return null;
  }

  static DateTime? _parseIso(Object? v) {
    if (v is String) return DateTime.tryParse(v)?.toUtc();
    return null;
  }
}
