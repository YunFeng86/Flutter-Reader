import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Migration definition.
class Migration {
  const Migration({
    required this.id,
    required this.description,
    required this.run,
  });

  /// Unique migration identifier (e.g., '2024-01-29_add_author_field').
  /// Once executed, this ID is stored to prevent re-execution.
  final String id;

  /// Human-readable description of what this migration does.
  final String description;

  /// Migration function. Must be idempotent (safe to run multiple times).
  final Future<void> Function(Isar isar) run;
}

/// Executes all pending migrations that haven't been run yet.
///
/// Isar handles most schema changes automatically (adding/removing fields, indexes).
/// Only use manual migrations for edge cases:
/// - Field renaming (old_field → new_field)
/// - Type changes (String → int)
/// - Complex data transformations
///
/// IMPORTANT:
/// - Migrations are executed ONCE per installation
/// - Migration IDs are stored in SharedPreferences
/// - Each migration must be idempotent (safe to run multiple times)
Future<void> runPendingMigrations(Isar isar) async {
  final prefs = await SharedPreferences.getInstance();
  final executed = prefs.getStringList('executed_migrations') ?? <String>[];

  // Define migrations here - only add when truly needed!
  final migrations = <Migration>[
    // Example migration (commented out):
    // Migration(
    //   id: '2024-01-29_rename_content_field',
    //   description: 'Rename Article.content to Article.contentHtml',
    //   run: (isar) => _renameContentField(isar),
    // ),
  ];

  // Execute pending migrations
  for (final migration in migrations) {
    if (!executed.contains(migration.id)) {
      debugPrint('🔄 Running migration: ${migration.id}');
      debugPrint('   ${migration.description}');

      try {
        await migration.run(isar);
        executed.add(migration.id);
        await prefs.setStringList('executed_migrations', executed);
        debugPrint('✅ Migration completed: ${migration.id}');
      } catch (e, stackTrace) {
        debugPrint('❌ Migration failed: ${migration.id}');
        debugPrint('Error: $e');
        debugPrint('StackTrace: $stackTrace');
        // Don't rethrow - allow app to start even if migration fails
        // Users can still use the app with potentially stale data
      }
    }
  }
}

// ============================================================================
// Migration Functions
// ============================================================================
// Each migration function should:
// 1. Be idempotent (safe to run multiple times)
// 2. Handle missing/null data gracefully
// 3. Use batch operations for performance
// 4. Log progress with debugPrint
//
// Example migration template:
//
// Future<void> _renameContentField(Isar isar) async {
//   await isar.writeTxn(() async {
//     final articles = await isar.articles.where().findAll();
//     int count = 0;
//
//     for (final article in articles) {
//       // Read old field, write to new field
//       // if (article.oldField != null && article.newField == null) {
//       //   article.newField = article.oldField;
//       //   count++;
//       // }
//     }
//
//     await isar.articles.putAll(articles);
//     debugPrint('   Migrated $count articles');
//   });
// }
