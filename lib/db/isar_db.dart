import 'package:isar/isar.dart';

import '../models/article.dart';
import '../models/category.dart';
import '../models/feed.dart';
import '../models/tag.dart';
import '../utils/path_manager.dart';
import 'migrations.dart';

Future<Isar> openIsar() async {
  final loc = await PathManager.getIsarLocation();

  final isar = await Isar.open(
    [FeedSchema, ArticleSchema, CategorySchema, TagSchema],
    directory: loc.directory.path,
    name: loc.name,
  );

  // Run pending migrations after database is opened
  await runPendingMigrations(isar);

  return isar;
}
