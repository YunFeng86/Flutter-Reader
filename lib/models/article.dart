import 'package:isar/isar.dart';

import 'tag.dart';

part 'article.g.dart';

enum ContentSource {
  feed,
  extracted,
  extractionFailed,
}

@collection
class Article {
  Id id = Isar.autoIncrement;

  @Index()
  late int feedId;

  /// Best-effort remote identifier (guid/id/link). Not guaranteed to be present.
  @Index(composite: [CompositeIndex('feedId')])
  String? remoteId;

  @Index(composite: [CompositeIndex('feedId')], unique: true, replace: true)
  late String link;

  String? title;
  String? author;

  /// 来自 Feed 的 HTML 内容。
  String? contentHtml;

  /// 提取后的 HTML 内容。
  String? extractedContentHtml;

  /// 内容来源状态。
  @enumerated
  ContentSource contentSource = ContentSource.feed;

  /// Key for pagination/sorting.
  @Index()
  DateTime publishedAt = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  @Index()
  bool isRead = false;

  @Index()
  bool isStarred = false;

  @Index()
  bool isReadLater = false;

  final tags = IsarLinks<Tag>();

  DateTime fetchedAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
}
