import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/article.dart';
import '../models/category.dart';
import '../models/feed.dart';
import 'repository_providers.dart';

final feedsProvider = StreamProvider<List<Feed>>((ref) {
  return ref.watch(feedRepositoryProvider).watchAll();
});

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchAll();
});

final selectedFeedIdProvider = StateProvider<int?>((ref) => null);
final selectedCategoryIdProvider = StateProvider<int?>((ref) => null);

/// Whether the article list should show only starred articles.
final starredOnlyProvider = StateProvider<bool>((ref) => false);

/// User-entered article search query (best-effort substring match).
final articleSearchQueryProvider = StateProvider<String>((ref) => '');

final articlesProvider = StreamProvider.family<List<Article>, int?>((
  ref,
  feedId,
) {
  return ref.watch(articleRepositoryProvider).watchLatest(feedId: feedId);
});

final articleProvider = StreamProvider.family<Article?, int>((ref, id) {
  return ref.watch(articleRepositoryProvider).watchById(id);
});

final feedMapProvider = Provider<Map<int, Feed>>((ref) {
  final feeds = ref.watch(feedsProvider).valueOrNull ?? [];
  return {for (final feed in feeds) feed.id: feed};
});
