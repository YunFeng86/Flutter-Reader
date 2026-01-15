import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../models/article.dart';
import 'core_providers.dart';

final unreadOnlyProvider = StateProvider<bool>((ref) => false);

/// Watches unread count for a given feedId. Use `null` for "All".
final unreadCountProvider = StreamProvider.family<int, int?>((ref, feedId) async* {
  final isar = ref.watch(isarProvider);

  final qb = isar.articles
      .filter()
      .optional(feedId != null, (q) => q.feedIdEqualTo(feedId!))
      .isReadEqualTo(false);

  // Emit immediately, then re-count on query change.
  yield await qb.count();
  await for (final _ in qb.watchLazy()) {
    yield await qb.count();
  }
});

final unreadCountByCategoryProvider =
    StreamProvider.family<int, int>((ref, categoryId) async* {
  final isar = ref.watch(isarProvider);
  final qb = isar.articles
      .filter()
      .categoryIdEqualTo(categoryId)
      .isReadEqualTo(false);
  yield await qb.count();
  await for (final _ in qb.watchLazy()) {
    yield await qb.count();
  }
});

final unreadCountUncategorizedProvider = StreamProvider<int>((ref) async* {
  final isar = ref.watch(isarProvider);
  final qb = isar.articles.filter().categoryIdIsNull().isReadEqualTo(false);
  yield await qb.count();
  await for (final _ in qb.watchLazy()) {
    yield await qb.count();
  }
});
