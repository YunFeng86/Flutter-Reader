import 'dart:convert';
import 'dart:io';

import '../../../utils/path_manager.dart';

enum OutboxActionType { markRead, bookmark, markAllRead }

extension OutboxActionTypeX on OutboxActionType {
  String get wire => switch (this) {
    OutboxActionType.markRead => 'markRead',
    OutboxActionType.bookmark => 'bookmark',
    OutboxActionType.markAllRead => 'markAllRead',
  };

  static OutboxActionType fromWire(String wire) {
    switch (wire) {
      case 'markRead':
        return OutboxActionType.markRead;
      case 'bookmark':
        return OutboxActionType.bookmark;
      case 'markAllRead':
        return OutboxActionType.markAllRead;
      default:
        throw ArgumentError('Unknown outbox action: $wire');
    }
  }
}

class OutboxAction {
  OutboxAction({
    required this.type,
    required this.createdAt,
    this.remoteEntryId,
    this.value,
    this.feedUrl,
    this.categoryTitle,
  });

  final OutboxActionType type;

  /// For entry-level actions (markRead/bookmark).
  final int? remoteEntryId;
  final bool? value;

  /// For bulk actions (markAllRead).
  final String? feedUrl;
  final String? categoryTitle;

  final DateTime createdAt;

  static OutboxAction fromJson(Map<String, Object?> json) {
    return OutboxAction(
      type: OutboxActionTypeX.fromWire(json['type'] as String),
      remoteEntryId: json['remoteEntryId'] as int?,
      value: json['value'] as bool?,
      feedUrl: json['feedUrl'] as String?,
      categoryTitle: json['categoryTitle'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'type': type.wire,
    'remoteEntryId': remoteEntryId,
    'value': value,
    'feedUrl': feedUrl,
    'categoryTitle': categoryTitle,
    'createdAt': createdAt.toIso8601String(),
  };
}

class OutboxStore {
  Future<List<OutboxAction>> load(String accountId) async {
    final f = await _file(accountId);
    try {
      if (!await f.exists()) return const [];
      final raw = await f.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final out = <OutboxAction>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        try {
          out.add(OutboxAction.fromJson(item.cast<String, Object?>()));
        } catch (_) {
          // Skip malformed entries; keep the rest of the queue.
        }
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  Future<void> save(String accountId, List<OutboxAction> actions) async {
    final f = await _file(accountId);
    final payload = actions.map((a) => a.toJson()).toList(growable: false);
    await f.writeAsString(jsonEncode(payload));
  }

  Future<void> enqueue(String accountId, OutboxAction action) async {
    final cur = await load(accountId);
    final next = [...cur, action];
    await save(accountId, next);
  }

  Future<void> remove(String accountId, OutboxAction action) async {
    final cur = await load(accountId);
    final next = [...cur];
    final idx = next.indexWhere((a) => _sameAction(a, action));
    if (idx < 0) return;
    next.removeAt(idx);
    await save(accountId, next);
  }

  Future<File> _file(String accountId) async {
    final dir = await PathManager.getStateDir();
    return File('${dir.path}${Platform.pathSeparator}outbox_$accountId.json');
  }

  static bool _sameAction(OutboxAction a, OutboxAction b) {
    return a.type == b.type &&
        a.remoteEntryId == b.remoteEntryId &&
        a.value == b.value &&
        a.feedUrl == b.feedUrl &&
        a.categoryTitle == b.categoryTitle &&
        a.createdAt.toIso8601String() == b.createdAt.toIso8601String();
  }
}
