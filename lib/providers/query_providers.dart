import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/article.dart';
import '../models/category.dart';
import '../models/feed.dart';
import '../models/tag.dart';
import 'repository_providers.dart';

final feedsProvider = StreamProvider<List<Feed>>((ref) {
  return ref.watch(feedRepositoryProvider).watchAll();
}, dependencies: [feedRepositoryProvider]);

final feedProvider = StreamProvider.family<Feed?, int>((ref, id) {
  return ref.watch(feedRepositoryProvider).watchById(id);
}, dependencies: [feedRepositoryProvider]);

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchAll();
}, dependencies: [categoryRepositoryProvider]);

final categoryProvider = StreamProvider.family<Category?, int>((ref, id) {
  return ref.watch(categoryRepositoryProvider).watchById(id);
}, dependencies: [categoryRepositoryProvider]);

final tagsProvider = StreamProvider<List<Tag>>((ref) {
  return ref.watch(tagRepositoryProvider).watchAll();
}, dependencies: [tagRepositoryProvider]);

final selectedFeedIdProvider = StateProvider<int?>((ref) => null);
final selectedCategoryIdProvider = StateProvider<int?>((ref) => null);
final selectedTagIdProvider = StateProvider<int?>((ref) => null);

/// Whether the article list should show only starred articles.
final starredOnlyProvider = StateProvider<bool>((ref) => false);

/// Whether the article list should show only read-later articles.
final readLaterOnlyProvider = StateProvider<bool>((ref) => false);

/// User-entered article search query (best-effort substring match).
final articleSearchQueryProvider = StateProvider<String>((ref) => '');

final articlesProvider = StreamProvider.family<List<Article>, int?>((
  ref,
  feedId,
) {
  return ref.watch(articleRepositoryProvider).watchLatest(feedId: feedId);
}, dependencies: [articleRepositoryProvider]);

final articleProvider = StreamProvider.family<Article?, int>((ref, id) {
  return ref.watch(articleRepositoryProvider).watchById(id);
}, dependencies: [articleRepositoryProvider]);

final feedMapProvider = Provider<Map<int, Feed>>((ref) {
  final feeds = ref.watch(feedsProvider).valueOrNull ?? [];
  return {for (final feed in feeds) feed.id: feed};
}, dependencies: [feedsProvider]);
