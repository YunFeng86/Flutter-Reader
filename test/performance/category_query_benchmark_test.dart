import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'package:flutter_reader/models/article.dart';
import 'package:flutter_reader/models/category.dart';
import 'package:flutter_reader/models/feed.dart';
import 'package:flutter_reader/models/tag.dart';
import 'package:flutter_reader/models/rule.dart';

/// Performance benchmark test to validate the value of categoryId denormalization.
///
/// This test compares two query strategies:
/// 1. Direct categoryId query (current implementation with denormalization)
/// 2. Two-step query via feedId (alternative without denormalization)
///
/// Expected result: Method 1 should be significantly faster (>30% improvement)
/// to justify the complexity cost of maintaining denormalized data.
void main() {
  late Isar isar;
  late Directory tempDir;

  setUpAll(() async {
    // Create temporary directory for test database
    tempDir = await Directory.systemTemp.createTemp('isar_benchmark_');
    isar = await Isar.open(
      [FeedSchema, ArticleSchema, CategorySchema, TagSchema, RuleSchema],
      directory: tempDir.path,
    );

    // Seed test data: 50 feeds with 500 articles each = 25000 articles
    // This simulates a moderate RSS reader usage
    await _seedTestData(isar);
  });

  tearDownAll(() async {
    await isar.close();
    await tempDir.delete(recursive: true);
  });

  test('Benchmark: categoryId direct query vs feedId two-step query', () async {
    const categoryId = 5;
    const iterations = 10;

    // Warmup (JIT compilation, cache warming)
    await _queryWithCategoryId(isar, categoryId);
    await _queryWithFeedIds(isar, categoryId);

    // Method 1: Direct categoryId query (current implementation)
    final stopwatch1 = Stopwatch()..start();
    for (var i = 0; i < iterations; i++) {
      await _queryWithCategoryId(isar, categoryId);
    }
    stopwatch1.stop();
    final avg1 = stopwatch1.elapsedMicroseconds / iterations;

    // Method 2: Two-step query via feedId (alternative approach)
    final stopwatch2 = Stopwatch()..start();
    for (var i = 0; i < iterations; i++) {
      await _queryWithFeedIds(isar, categoryId);
    }
    stopwatch2.stop();
    final avg2 = stopwatch2.elapsedMicroseconds / iterations;

    // Calculate performance difference
    final speedup = ((avg2 - avg1) / avg2 * 100).toStringAsFixed(1);
    final diff = (avg2 - avg1).toStringAsFixed(0);

    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📊 Category Query Performance Benchmark');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('Dataset: 50 feeds × 500 articles = 25,000 total articles');
    print('Category: $categoryId (contains 10 feeds)');
    print('Iterations: $iterations');
    print('');
    print('Method 1 (Direct categoryId):  ${avg1.toStringAsFixed(0)} μs/query');
    print('Method 2 (Two-step via feedId): ${avg2.toStringAsFixed(0)} μs/query');
    print('');
    print('Result: Method 1 is ${speedup}% faster ($diff μs improvement)');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    // Assert that Method 1 is faster
    expect(
      avg1,
      lessThan(avg2),
      reason: 'Direct categoryId query should be faster than two-step approach',
    );

    // We expect at least 30% improvement to justify the denormalization complexity
    // If the improvement is less than 30%, the denormalization might not be worth it
    final improvementThreshold = avg2 * 0.7;
    if (avg1 < improvementThreshold) {
      print('✅ Performance improvement (${speedup}%) justifies denormalization');
    } else {
      print('⚠️  Performance improvement (${speedup}%) is below 30% threshold');
      print('   Consider removing denormalization if complexity cost is high');
    }
  });
}

/// Method 1: Query articles directly by categoryId (current implementation)
Future<List<Article>> _queryWithCategoryId(Isar isar, int categoryId) async {
  return isar.articles
      .filter()
      .categoryIdEqualTo(categoryId)
      .sortByPublishedAtDesc()
      .limit(50)
      .findAll();
}

/// Method 2: Query articles via two-step process (alternative without denormalization)
Future<List<Article>> _queryWithFeedIds(Isar isar, int categoryId) async {
  // Step 1: Get feed IDs in this category
  final feedIds = await isar.feeds
      .filter()
      .categoryIdEqualTo(categoryId)
      .idProperty()
      .findAll();

  if (feedIds.isEmpty) return [];

  // Step 2: Query articles using feedId IN (...)
  return isar.articles
      .filter()
      .anyOf(feedIds, (q, id) => q.feedIdEqualTo(id))
      .sortByPublishedAtDesc()
      .limit(50)
      .findAll();
}

/// Seed test data: 50 feeds with 500 articles each
Future<void> _seedTestData(Isar isar) async {
  await isar.writeTxn(() async {
    // Create 10 categories
    for (var i = 1; i <= 10; i++) {
      final category = Category()
        ..id = i
        ..name = 'Category $i'
        ..createdAt = DateTime.now();
      await isar.categorys.put(category);
    }

    // Create 50 feeds (5 feeds per category)
    for (var i = 1; i <= 50; i++) {
      final categoryId = ((i - 1) ~/ 5) + 1; // Distribute evenly
      final feed = Feed()
        ..id = i
        ..url = 'https://example.com/feed$i.xml'
        ..title = 'Feed $i'
        ..categoryId = categoryId
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();
      await isar.feeds.put(feed);
    }

    // Create 500 articles per feed (25000 total)
    for (var feedId = 1; feedId <= 50; feedId++) {
      final feed = await isar.feeds.get(feedId);
      final categoryId = feed!.categoryId;

      for (var j = 1; j <= 500; j++) {
        final article = Article()
          ..feedId = feedId
          ..categoryId = categoryId // Denormalized field
          ..link = 'https://example.com/feed$feedId/article$j'
          ..title = 'Article $j from Feed $feedId'
          ..publishedAt = DateTime.now().subtract(Duration(hours: j))
          ..fetchedAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await isar.articles.put(article);
      }
    }
  });

  print('📦 Seeded ${await isar.feeds.count()} feeds');
  print('📦 Seeded ${await isar.articles.count()} articles');
  print('📦 Seeded ${await isar.categorys.count()} categories\n');
}
