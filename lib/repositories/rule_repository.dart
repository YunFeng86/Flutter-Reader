import 'package:isar/isar.dart';

import '../models/rule.dart';

class RuleRepository {
  RuleRepository(this._isar);

  final Isar _isar;

  Stream<List<Rule>> watchAll() {
    return _isar.rules.where().sortByUpdatedAtDesc().watch(fireImmediately: true);
  }

  Future<List<Rule>> getAll() {
    return _isar.rules.where().sortByUpdatedAtDesc().findAll();
  }

  Future<List<Rule>> getEnabled() {
    return _isar.rules.filter().enabledEqualTo(true).sortByUpdatedAtDesc().findAll();
  }

  Future<int> upsert({
    int? id,
    required String name,
    required String keyword,
    required bool enabled,
    required bool matchTitle,
    required bool matchAuthor,
    required bool matchLink,
    required bool matchContent,
    required bool autoStar,
    required bool autoMarkRead,
  }) async {
    final n = name.trim();
    final k = keyword.trim();
    if (n.isEmpty) throw ArgumentError('Rule name is empty');
    if (k.isEmpty) throw ArgumentError('Rule keyword is empty');

    final now = DateTime.now();
    return _isar.writeTxn(() async {
      final r = id == null ? null : await _isar.rules.get(id);
      final rule = r ?? (Rule()..createdAt = now);
      rule
        ..name = n
        ..keyword = k
        ..enabled = enabled
        ..matchTitle = matchTitle
        ..matchAuthor = matchAuthor
        ..matchLink = matchLink
        ..matchContent = matchContent
        ..autoStar = autoStar
        ..autoMarkRead = autoMarkRead
        ..updatedAt = now;
      return _isar.rules.put(rule);
    });
  }

  Future<void> setEnabled(int id, bool enabled) {
    return _isar.writeTxn(() async {
      final r = await _isar.rules.get(id);
      if (r == null) return;
      r.enabled = enabled;
      r.updatedAt = DateTime.now();
      await _isar.rules.put(r);
    });
  }

  Future<void> delete(int id) {
    return _isar.writeTxn(() async {
      await _isar.rules.delete(id);
    });
  }
}

