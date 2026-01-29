import 'package:isar/isar.dart';

import '../models/article.dart';
import '../models/feed.dart';

class FeedRepository {
  FeedRepository(this._isar);

  final Isar _isar;

  Stream<List<Feed>> watchAll() {
    return _isar.feeds.where().watch(fireImmediately: true);
  }

  Future<List<Feed>> getAll() {
    return _isar.feeds.where().findAll();
  }

  Future<Feed?> getById(int id) {
    return _isar.feeds.get(id);
  }

  Future<int> upsertUrl(String url) async {
    final normalized = url.trim();
    if (normalized.isEmpty) {
      throw ArgumentError('Feed url is empty');
    }

    final existing = await _isar.feeds.filter().urlEqualTo(normalized).findFirst();
    final now = DateTime.now();
    final feed = existing ?? Feed()..url = normalized;
    feed.updatedAt = now;
    if (existing == null) {
      feed.createdAt = now;
    }

    return _isar.writeTxn(() async => _isar.feeds.put(feed));
  }

  Future<void> setCategory({required int feedId, int? categoryId}) async {
    await _isar.writeTxn(() async {
      final feed = await _isar.feeds.get(feedId);
      if (feed == null) return;
      feed.categoryId = categoryId;
      feed.updatedAt = DateTime.now();
      await _isar.feeds.put(feed);

      // [V2.0] Sync categoryId to all articles in this feed (denormalization)
      final articles = await _isar.articles.filter().feedIdEqualTo(feedId).findAll();
      if (articles.isNotEmpty) {
        final now = DateTime.now();
        for (final a in articles) {
          a.categoryId = categoryId;
          a.updatedAt = now;
        }
        await _isar.articles.putAll(articles);
      }
    });
  }

  Future<void> setUserTitle({required int feedId, String? userTitle}) {
    return _isar.writeTxn(() async {
      final feed = await _isar.feeds.get(feedId);
      if (feed == null) return;
      final t = userTitle?.trim();
      feed.userTitle = (t == null || t.isEmpty) ? null : t;
      feed.updatedAt = DateTime.now();
      await _isar.feeds.put(feed);
    });
  }

  Future<void> updateMeta({
    required int id,
    String? title,
    String? siteUrl,
    String? description,
    DateTime? lastSyncedAt,
  }) {
    return _isar.writeTxn(() async {
      final feed = await _isar.feeds.get(id);
      if (feed == null) return;
      feed.title = title ?? feed.title;
      feed.siteUrl = siteUrl ?? feed.siteUrl;
      feed.description = description ?? feed.description;
      feed.lastSyncedAt = lastSyncedAt ?? feed.lastSyncedAt;
      feed.updatedAt = DateTime.now();
      await _isar.feeds.put(feed);
    });
  }

  Future<void> updateSyncState({
    required int id,
    DateTime? lastCheckedAt,
    int? lastStatusCode,
    int? lastDurationMs,
    int? lastIncomingCount,
    String? etag,
    String? lastModified,
    String? lastError,
    DateTime? lastErrorAt,
    required bool clearError,
  }) {
    return _isar.writeTxn(() async {
      final feed = await _isar.feeds.get(id);
      if (feed == null) return;

      feed.lastCheckedAt = lastCheckedAt ?? feed.lastCheckedAt;
      feed.lastStatusCode = lastStatusCode ?? feed.lastStatusCode;
      feed.lastDurationMs = lastDurationMs ?? feed.lastDurationMs;
      feed.lastIncomingCount = lastIncomingCount ?? feed.lastIncomingCount;
      feed.etag = etag ?? feed.etag;
      feed.lastModified = lastModified ?? feed.lastModified;

      if (clearError) {
        feed.lastError = null;
        feed.lastErrorAt = null;
      } else {
        feed.lastError = lastError ?? feed.lastError;
        feed.lastErrorAt = lastErrorAt ?? feed.lastErrorAt;
      }

      feed.updatedAt = DateTime.now();
      await _isar.feeds.put(feed);
    });
  }

  Future<void> delete(int id) {
    return _isar.writeTxn(() async {
      await _isar.articles.filter().feedIdEqualTo(id).deleteAll();
      await _isar.feeds.delete(id);
    });
  }
}
