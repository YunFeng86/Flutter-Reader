import 'package:isar/isar.dart';

part 'category.g.dart';

@collection
class Category {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String name;

  // Filter Settings
  bool? filterEnabled;
  String? filterKeywords;

  // Sync Settings
  bool? syncEnabled;

  /// Whether to download images during sync
  bool? syncImages;

  /// Whether to download full web pages (Readability) during sync
  bool? syncWebPages;

  /// Whether to show AI summary
  bool? showAiSummary;

  /// Whether to auto-translate the article when opened in the reader.
  bool? autoTranslate;

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
}
