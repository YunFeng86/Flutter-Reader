import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/article.dart';
import '../models/category.dart';
import '../models/feed.dart';
import '../models/rule.dart';

Future<Isar> openIsar() async {
  final dir = await getApplicationDocumentsDirectory();
  return Isar.open(
    [FeedSchema, ArticleSchema, CategorySchema, RuleSchema],
    directory: dir.path,
    name: 'flutter_reader',
  );
}
