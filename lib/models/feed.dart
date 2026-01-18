import 'package:isar/isar.dart';

part 'feed.g.dart';

@collection
class Feed {
  Id id = Isar.autoIncrement;

  /// Subscription URL (RSS/Atom).
  @Index(unique: true, replace: true)
  late String url;

  String? title;
  /// User-defined display title. When set, it takes precedence over `title`
  /// parsed from the feed.
  String? userTitle;
  String? siteUrl;
  String? description;

  /// HTTP caching headers from the last successful fetch. Used to perform
  /// conditional requests (ETag / If-Modified-Since) for faster refresh.
  String? etag;
  String? lastModified;

  @Index()
  int? categoryId;

  /// Last time we attempted to check this feed (200/304).
  DateTime? lastCheckedAt;

  /// Last successful sync time when the feed content was updated (200).
  DateTime? lastSyncedAt;

  /// Last HTTP status code for the feed fetch (e.g. 200/304/4xx/5xx when known).
  int? lastStatusCode;

  /// Last refresh duration in milliseconds (best-effort).
  int? lastDurationMs;

  /// Number of incoming items observed on last refresh (best-effort).
  int? lastIncomingCount;

  /// Last error message (best-effort). Cleared on success.
  String? lastError;
  DateTime? lastErrorAt;

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
}
