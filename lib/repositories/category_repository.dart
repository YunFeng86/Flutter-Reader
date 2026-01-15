import 'package:isar/isar.dart';

import '../models/article.dart';
import '../models/category.dart';
import '../models/feed.dart';

class CategoryRepository {
  CategoryRepository(this._isar);

  final Isar _isar;

  Stream<List<Category>> watchAll() {
    return _isar.categorys.where().watch(fireImmediately: true);
  }

  Future<List<Category>> getAll() {
    return _isar.categorys.where().findAll();
  }

  Future<int> upsertByName(String name) async {
    final n = name.trim();
    if (n.isEmpty) throw ArgumentError('Category name is empty');

    final existing = await _isar.categorys.filter().nameEqualTo(n).findFirst();
    final now = DateTime.now();
    final c = existing ?? Category()..name = n;
    if (existing == null) c.createdAt = now;
    c.updatedAt = now;
    return _isar.writeTxn(() async => _isar.categorys.put(c));
  }

  Future<void> delete(int id) {
    return _isar.writeTxn(() async {
      final feeds = await _isar.feeds.filter().categoryIdEqualTo(id).findAll();
      for (final f in feeds) {
        f.categoryId = null;
        f.updatedAt = DateTime.now();
      }
      if (feeds.isNotEmpty) {
        await _isar.feeds.putAll(feeds);
      }

      final articles = await _isar.articles.filter().categoryIdEqualTo(id).findAll();
      for (final a in articles) {
        a.categoryId = null;
        a.updatedAt = DateTime.now();
      }
      if (articles.isNotEmpty) {
        await _isar.articles.putAll(articles);
      }

      await _isar.categorys.delete(id);
    });
  }
}
