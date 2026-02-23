import 'package:isar/isar.dart';

import '../models/article.dart';
import '../models/category.dart';
import '../models/feed.dart';
import '../models/tag.dart';
import '../utils/path_manager.dart';
import 'migrations.dart';

const String kPrimaryAccountId = 'local';

/// Open the Isar database for a given account.
///
/// - Primary account uses [PathManager.getIsarLocation] to avoid silent data
///   loss during migrations/legacy fallback.
/// - Other accounts always live under the new Support/db directory with a
///   stable per-account db name.
Future<Isar> openIsarForAccount({
  required String accountId,
  String? dbName,
  required bool isPrimary,
}) async {
  final schemas = [FeedSchema, ArticleSchema, CategorySchema, TagSchema];

  if (isPrimary) {
    final loc = await PathManager.getIsarLocation();
    final isar = await Isar.open(
      schemas,
      directory: loc.directory.path,
      name: loc.name,
    );
    await runPendingMigrations(isar);
    return isar;
  }

  final dir = await PathManager.getDbDir();
  final name = (dbName == null || dbName.trim().isEmpty)
      ? _dbNameForAccount(accountId)
      : dbName.trim();
  final isar = await Isar.open(schemas, directory: dir.path, name: name);
  await runPendingMigrations(isar);
  return isar;
}

String _dbNameForAccount(String accountId) {
  final sanitized = accountId.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
  return 'fleur_$sanitized';
}
