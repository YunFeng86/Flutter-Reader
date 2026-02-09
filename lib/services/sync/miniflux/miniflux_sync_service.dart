import 'dart:async';

import 'package:flutter/foundation.dart' hide Category;
import 'package:dio/dio.dart';
import 'package:pool/pool.dart';

import '../../../models/article.dart';
import '../../../models/category.dart';
import '../../../models/feed.dart';
import '../../../repositories/article_repository.dart';
import '../../../repositories/category_repository.dart';
import '../../../repositories/feed_repository.dart';
import '../../accounts/account.dart';
import '../../accounts/credential_store.dart';
import '../../cache/article_cache_service.dart';
import '../../extract/article_extractor.dart';
import '../../settings/app_settings.dart';
import '../../settings/app_settings_store.dart';
import '../effective_feed_settings.dart';
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
    required AppSettingsStore appSettingsStore,
    required ArticleCacheService cache,
    required ArticleExtractor extractor,
  }) : _dio = dio,
       _credentials = credentials,
       _feeds = feeds,
       _categories = categories,
       _articles = articles,
       _outbox = outbox,
       _appSettingsStore = appSettingsStore,
       _cache = cache,
       _extractor = extractor;

  final Account account;

  final Dio _dio;
  final CredentialStore _credentials;
  final FeedRepository _feeds;
  final CategoryRepository _categories;
  final ArticleRepository _articles;
  final OutboxStore _outbox;
  final AppSettingsStore _appSettingsStore;
  final ArticleCacheService _cache;
  final ArticleExtractor _extractor;

  @override
  Future<int> offlineCacheFeed(int feedId) async {
    final feed = await _feeds.getById(feedId);
    if (feed == null) return 0;
    final appSettings = await _appSettingsStore.load();
    final settings = await _resolveSettings(feed, appSettings);
    final unread = await _articles.getUnread(feedId: feedId);

    // Best-effort: do not throw to callers.
    try {
      // If web pages are enabled, prefer extracting + caching from extracted HTML.
      if (settings.syncWebPages && unread.isNotEmpty) {
        MinifluxClient? client;
        final preferServerFetch =
            appSettings.minifluxWebFetchMode ==
            MinifluxWebFetchMode.serverFetchContent;
        if (preferServerFetch) {
          try {
            client = await _buildClient();
          } catch (_) {
            client = null;
          }
        }
        await _syncWebPagesForArticles(
          unread,
          client: client,
          preferServerFetch: preferServerFetch,
          webUserAgent: appSettings.webUserAgent,
          syncImages: settings.syncImages,
        );
      }
      if (settings.syncImages && unread.isNotEmpty) {
        return await _cache.cacheArticles(unread);
      }
    } catch (_) {}
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

  Future<void> syncNow({int? entriesLimit}) async {
    final client = await _buildClient();
    await _flushOutbox(client);
    final appSettings = await _appSettingsStore.load();
    final effectiveEntriesLimit =
        entriesLimit ?? appSettings.minifluxEntriesLimit;
    final preferServerFetch =
        appSettings.minifluxWebFetchMode ==
        MinifluxWebFetchMode.serverFetchContent;

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
    final localFeedIdToFeed = <int, Feed>{};
    final localFeedIdToSettings = <int, EffectiveFeedSettings>{};
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
        final settings = await _resolveSettings(local, appSettings);
        await _feeds.updateMeta(
          id: local.id,
          title: f['title'] as String?,
          siteUrl: f['site_url'] as String?,
          description: f['description'] as String?,
          lastSyncedAt: settings.syncEnabled ? DateTime.now() : null,
        );
        remoteFeedIdToLocalFeed[id] = local;
        localFeedIdToFeed[local.id] = local;
        localFeedIdToSettings[local.id] = settings;
      }
    }

    // 0 means "unlimited": paginate until server has no more entries.
    if (effectiveEntriesLimit == 0) {
      const pageSize = 1000;
      var offset = 0;
      while (true) {
        final r = await _syncEntriesBatch(
          client,
          appSettings,
          remoteFeedIdToLocalFeed: remoteFeedIdToLocalFeed,
          localFeedIdToFeed: localFeedIdToFeed,
          localFeedIdToSettings: localFeedIdToSettings,
          limit: pageSize,
          offset: offset,
          preferServerFetch: preferServerFetch,
        );
        if (r.processed == 0) break;
        offset += r.processed;
        if (r.total != null && offset >= r.total!) break;
        if (r.processed < pageSize) break;
      }
      return;
    }

    if (effectiveEntriesLimit < 0) return;
    await _syncEntriesBatch(
      client,
      appSettings,
      remoteFeedIdToLocalFeed: remoteFeedIdToLocalFeed,
      localFeedIdToFeed: localFeedIdToFeed,
      localFeedIdToSettings: localFeedIdToSettings,
      limit: effectiveEntriesLimit,
      offset: 0,
      preferServerFetch: preferServerFetch,
    );
  }

  Future<({int processed, int? total})> _syncEntriesBatch(
    MinifluxClient client,
    AppSettings appSettings, {
    required Map<int, Feed> remoteFeedIdToLocalFeed,
    required Map<int, Feed> localFeedIdToFeed,
    required Map<int, EffectiveFeedSettings> localFeedIdToSettings,
    required int limit,
    required int offset,
    required bool preferServerFetch,
  }) async {
    if (limit <= 0) return (processed: 0, total: null);
    final resp = await client.getEntries(limit: limit, offset: offset);
    final raw = resp['entries'];
    final totalRaw = resp['total'];
    final total = totalRaw is int ? totalRaw : null;
    if (raw is! List) return (processed: 0, total: total);

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
      final effectiveSettings = localFeedIdToSettings[localFeed.id];
      if (effectiveSettings != null && !effectiveSettings.syncEnabled) continue;

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
      final newArticles = await _articles.upsertMany(
        entry.key,
        entry.value,
        preserveUserState: false,
      );

      // Best-effort offline "inventory": cache/extract newly discovered items.
      if (newArticles.isNotEmpty) {
        final feed =
            localFeedIdToFeed[entry.key] ?? await _feeds.getById(entry.key);
        if (feed != null) {
          final settings =
              localFeedIdToSettings[feed.id] ??
              await _resolveSettings(feed, appSettings);
          await _prefetchNewArticles(
            newArticles,
            settings,
            appSettings,
            client: client,
            preferServerFetch: preferServerFetch,
          );
        }
      }
    }

    return (processed: raw.length, total: total);
  }

  Future<bool> flushOutboxSafe() async {
    try {
      final client = await _buildClient();
      await _flushOutbox(client);
      return true;
    } catch (_) {
      return false;
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
    if (token != null && token.trim().isNotEmpty) {
      return MinifluxClient(dio: _dio, baseUrl: baseUrl, apiToken: token);
    }

    final basic = await _credentials.getBasicAuth(
      account.id,
      AccountType.miniflux,
    );
    if (basic != null) {
      return MinifluxClient(
        dio: _dio,
        baseUrl: baseUrl,
        username: basic.username,
        password: basic.password,
      );
    }

    throw StateError('Miniflux credentials are missing');
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
            await client.setBookmarkState(entryId, value);
            break;
          case OutboxActionType.markAllRead:
            final feedUrl = a.feedUrl == null
                ? null
                : normalizeFeedUrl(a.feedUrl!);
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
                throw StateError(
                  'Remote category not found for title: $catTitle',
                );
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

  Future<EffectiveFeedSettings> _resolveSettings(
    Feed feed,
    AppSettings appSettings,
  ) async {
    final categoryId = feed.categoryId;
    final Category? category = categoryId == null
        ? null
        : await _categories.getById(categoryId);
    return EffectiveFeedSettings.resolve(feed, category, appSettings);
  }

  Future<void> _prefetchNewArticles(
    List<Article> newArticles,
    EffectiveFeedSettings settings,
    AppSettings appSettings, {
    required MinifluxClient client,
    required bool preferServerFetch,
  }) async {
    // Best-effort prefetch; do not break sync flow.
    if (newArticles.isEmpty) return;

    // Mirror local SyncService behavior: cache feed/extracted images first.
    if (settings.syncImages) {
      try {
        // Avoid accidental long stalls when syncing a large batch.
        const maxArticles = 30;
        final targets = newArticles.length <= maxArticles
            ? newArticles
            : newArticles.sublist(0, maxArticles);
        await _cache.cacheArticles(targets);
      } catch (_) {}
    }

    if (settings.syncWebPages) {
      try {
        await _syncWebPagesForArticles(
          newArticles,
          client: client,
          preferServerFetch: preferServerFetch,
          webUserAgent: appSettings.webUserAgent,
          syncImages: settings.syncImages,
        );
      } catch (_) {}
    }
  }

  static const int _maxWebPagesPerSync = 8;

  Future<void> _syncWebPagesForArticles(
    List<Article> articles, {
    required MinifluxClient? client,
    required bool preferServerFetch,
    required String webUserAgent,
    required bool syncImages,
  }) async {
    final pool = Pool(2);
    final targets = articles.length <= _maxWebPagesPerSync
        ? articles
        : articles.sublist(0, _maxWebPagesPerSync);

    final futures = <Future<void>>[];
    for (final a in targets) {
      futures.add(
        pool.withResource(() async {
          try {
            // Skip if already extracted (common when re-syncing the same window).
            if ((a.extractedContentHtml ?? '').trim().isNotEmpty) return;

            String html = '';
            if (preferServerFetch && client != null) {
              final rid = int.tryParse((a.remoteId ?? '').trim());
              if (rid != null) {
                html = await client.fetchEntryContent(rid);
              }
            }
            if (html.trim().isEmpty) {
              final extracted = await _extractor.extract(
                a.link,
                userAgent: webUserAgent,
              );
              html = extracted.contentHtml;
            }

            if (html.trim().isEmpty) {
              await _articles.markExtractionFailed(a.id);
              return;
            }
            await _articles.setExtractedContent(a.id, html);

            if (syncImages) {
              await _cache.prefetchImagesFromHtml(
                html,
                baseUrl: Uri.tryParse(a.link),
                maxConcurrent: 3,
              );
            }
          } catch (_) {
            // Best-effort: don't persist failure for transient network errors.
          }
        }),
      );
    }

    await Future.wait(futures);
    await pool.close();
  }
}
