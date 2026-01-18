import 'dart:async';

import '../../models/article.dart';
import '../../repositories/article_repository.dart';
import '../../repositories/feed_repository.dart';
import '../rss/feed_parser.dart';
import '../rss/rss_client.dart';

class FeedRefreshResult {
  const FeedRefreshResult({
    required this.feedId,
    required this.incomingCount,
    this.error,
  });

  final int feedId;
  final int incomingCount;
  final Object? error;

  bool get ok => error == null;
}

class BatchRefreshResult {
  const BatchRefreshResult(this.results);

  final List<FeedRefreshResult> results;

  int get okCount => results.where((r) => r.ok).length;
  int get errorCount => results.length - okCount;
  int get incomingTotal => results.fold(0, (sum, r) => sum + r.incomingCount);
  FeedRefreshResult? get firstError => results
      .cast<FeedRefreshResult?>()
      .firstWhere((r) => r?.error != null, orElse: () => null);
}

class SyncService {
  SyncService({
    required FeedRepository feeds,
    required ArticleRepository articles,
    required RssClient client,
    required FeedParser parser,
  }) : _feeds = feeds,
       _articles = articles,
       _client = client,
       _parser = parser;

  final FeedRepository _feeds;
  final ArticleRepository _articles;
  final RssClient _client;
  final FeedParser _parser;

  Future<int> refreshFeed(int feedId) async {
    final feed = await _feeds.getById(feedId);
    if (feed == null) return 0;

    final xml = await _client.fetchXml(feed.url);
    final parsed = _parser.parse(xml);

    await _feeds.updateMeta(
      id: feedId,
      title: parsed.title,
      siteUrl: parsed.siteUrl,
      description: parsed.description,
      lastSyncedAt: DateTime.now(),
    );

    final incoming = parsed.items
        .map((it) {
          final a = Article()
            ..remoteId = it.remoteId
            ..link = it.link
            ..title = it.title
            ..author = it.author
            ..contentHtml = it.contentHtml
            ..categoryId = feed.categoryId
            ..publishedAt = (it.publishedAt ?? DateTime.now()).toUtc();
          return a;
        })
        .toList(growable: false);

    await _articles.upsertMany(feedId, incoming);
    return incoming.length;
  }

  Future<FeedRefreshResult> refreshFeedSafe(
    int feedId, {
    int maxAttempts = 2,
  }) async {
    Object? lastError;
    final attempts = maxAttempts < 1 ? 1 : maxAttempts;
    for (var i = 0; i < attempts; i++) {
      try {
        final count = await refreshFeed(feedId);
        return FeedRefreshResult(feedId: feedId, incomingCount: count);
      } catch (e) {
        lastError = e;
        // Small backoff so quick transient failures (DNS/timeout) have a chance
        // to recover without blocking the whole batch for too long.
        if (i < attempts - 1) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      }
    }
    return FeedRefreshResult(
      feedId: feedId,
      incomingCount: 0,
      error: lastError ?? Exception('Unknown sync error'),
    );
  }

  Future<BatchRefreshResult> refreshFeedsSafe(
    Iterable<int> feedIds, {
    int maxConcurrent = 4,
    int maxAttemptsPerFeed = 2,
  }) async {
    final ids = feedIds.toList(growable: false);
    if (ids.isEmpty) return const BatchRefreshResult([]);

    final sem = _Semaphore(maxConcurrent < 1 ? 1 : maxConcurrent);
    final results = <FeedRefreshResult>[];
    final futures = <Future<void>>[];

    for (final id in ids) {
      futures.add(() async {
        await sem.acquire();
        try {
          final r = await refreshFeedSafe(id, maxAttempts: maxAttemptsPerFeed);
          results.add(r);
        } finally {
          sem.release();
        }
      }());
    }

    await Future.wait(futures);
    return BatchRefreshResult(results);
  }
}

class _Semaphore {
  _Semaphore(this._max);
  final int _max;
  int _cur = 0;
  final _waiters = <Completer<void>>[];

  Future<void> acquire() {
    if (_cur < _max) {
      _cur++;
      return Future.value();
    }
    final c = Completer<void>();
    _waiters.add(c);
    return c.future;
  }

  void release() {
    if (_cur > 0) _cur--;
    if (_waiters.isNotEmpty && _cur < _max) {
      _cur++;
      _waiters.removeAt(0).complete();
    }
  }
}
