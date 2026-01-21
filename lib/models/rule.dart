import 'package:isar/isar.dart';

part 'rule.g.dart';

@collection
class Rule {
  Id id = Isar.autoIncrement;

  @Index()
  bool enabled = true;

  @Index()
  late String name;

  /// Case-insensitive substring match.
  @Index()
  late String keyword;

  bool matchTitle = true;
  bool matchAuthor = false;
  bool matchLink = false;
  bool matchContent = false;

  bool autoStar = false;
  bool autoMarkRead = false;
  bool notify = false;

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
}
