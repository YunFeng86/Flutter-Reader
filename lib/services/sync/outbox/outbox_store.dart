import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../utils/path_manager.dart';
import '../sync_mutex.dart';

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
  static final StreamController<String> _changes =
      StreamController<String>.broadcast();

  static Stream<String> get changes => _changes.stream;

  static void _emitChange(String accountId) {
    try {
      if (_changes.hasListener) _changes.add(accountId);
    } catch (_) {
      // ignore: best-effort notify
    }
  }

  Future<List<OutboxAction>> load(String accountId) async {
    return SyncMutex.instance.run('outbox:$accountId', () async {
      final f = await _file(accountId);
      final tmp = _tmpFile(f);
      final bak = _bakFile(f);

      try {
        final decoded = await _readJsonListOrRecover(
          primary: f,
          tmp: tmp,
          bak: bak,
        );
        if (decoded == null) return const [];
        final out = <OutboxAction>[];
        for (final item in decoded) {
          if (item is! Map) continue;
          try {
            out.add(OutboxAction.fromJson(item.cast<String, Object?>()));
          } catch (_) {
            // Skip malformed entries; keep the rest of the queue.
          }
        }
        // Auto-compact legacy/duplicated actions.
        final compacted = _compact(out);
        if (compacted.length != out.length || await tmp.exists()) {
          try {
            await save(accountId, compacted);
          } catch (_) {
            // ignore: best-effort cleanup
          }
        }
        try {
          if (await tmp.exists()) await tmp.delete();
        } catch (_) {
          // ignore: best-effort cleanup
        }
        return compacted;
      } catch (_) {
        return const [];
      }
    });
  }

  Future<void> save(String accountId, List<OutboxAction> actions) async {
    await SyncMutex.instance.run('outbox:$accountId', () async {
      final f = await _file(accountId);
      final compacted = _compact(actions);
      final payload = compacted.map((a) => a.toJson()).toList(growable: false);
      await _writeJsonAtomically(f, jsonEncode(payload));
    });
    _emitChange(accountId);
  }

  Future<void> enqueue(String accountId, OutboxAction action) async {
    await SyncMutex.instance.run('outbox:$accountId', () async {
      final cur = await load(accountId);
      final next = [...cur, action];
      await save(accountId, next);
    });
  }

  Future<void> remove(String accountId, OutboxAction action) async {
    await SyncMutex.instance.run('outbox:$accountId', () async {
      final cur = await load(accountId);
      final next = [...cur];
      final idx = next.indexWhere((a) => _sameAction(a, action));
      if (idx < 0) return;
      next.removeAt(idx);
      await save(accountId, next);
    });
  }

  Future<File> _file(String accountId) async {
    final dir = await PathManager.getStateDir();
    return File('${dir.path}${Platform.pathSeparator}outbox_$accountId.json');
  }

  File _tmpFile(File primary) => File('${primary.path}.tmp');
  File _bakFile(File primary) => File('${primary.path}.bak');

  Future<List<Object?>?> _readJsonListOrRecover({
    required File primary,
    required File tmp,
    required File bak,
  }) async {
    Future<List<Object?>?> tryRead(File file) async {
      try {
        if (!await file.exists()) return null;
        final raw = await file.readAsString(encoding: utf8);
        final decoded = jsonDecode(raw);
        if (decoded is! List) return null;
        return decoded.cast<Object?>();
      } catch (_) {
        return null;
      }
    }

    // Prefer the primary file when it's valid.
    final primaryDecoded = await tryRead(primary);
    if (primaryDecoded != null) return primaryDecoded;

    // Crash safety: if an atomic write was interrupted, `.tmp` may contain the
    // new full payload; `.bak` may contain the previous valid payload.
    final tmpDecoded = await tryRead(tmp);
    if (tmpDecoded != null) {
      try {
        await _writeJsonAtomically(primary, jsonEncode(tmpDecoded));
      } catch (_) {
        // ignore: best-effort recovery
      }
      return tmpDecoded;
    }

    final bakDecoded = await tryRead(bak);
    if (bakDecoded != null) {
      try {
        await _writeJsonAtomically(primary, jsonEncode(bakDecoded));
      } catch (_) {
        // ignore: best-effort recovery
      }
      return bakDecoded;
    }

    return null;
  }

  Future<void> _writeJsonAtomically(File primary, String contents) async {
    final tmp = _tmpFile(primary);
    final bak = _bakFile(primary);

    try {
      await tmp.writeAsString(contents, encoding: utf8);
    } catch (_) {
      // If we can't write a temp file, fall back to a best-effort direct write.
      try {
        await primary.writeAsString(contents, encoding: utf8);
      } catch (_) {
        // ignore: best-effort write
      }
      return;
    }

    // Rotate the previous file to `.bak` so a crash during replace can recover.
    // Keep `.bak` as the last known-good payload (rotated on each successful write).
    var backedUp = false;
    try {
      if (await primary.exists()) {
        try {
          if (await bak.exists()) await bak.delete();
        } catch (_) {
          // ignore: best-effort cleanup
        }

        try {
          await primary.rename(bak.path);
          backedUp = true;
        } catch (_) {
          // Best-effort fallback when rename is not possible (e.g. file lock).
          try {
            await primary.copy(bak.path);
            backedUp = true;
          } catch (_) {
            // ignore: best-effort backup
          }
        }
      }
    } catch (_) {
      // ignore: best-effort backup
    }

    var replaced = false;
    try {
      await tmp.rename(primary.path);
      replaced = true;
    } catch (_) {
      // If the primary still exists (e.g. couldn't be renamed to `.bak`), only
      // delete it if we have a backup already.
      if (await primary.exists() && backedUp) {
        try {
          await primary.delete();
        } catch (_) {
          // ignore: best-effort delete
        }
        try {
          await tmp.rename(primary.path);
          replaced = true;
        } catch (_) {
          // fall through
        }
      }

      // Fall back to a direct write; leave `.tmp` for recovery on next load if that fails.
      if (!replaced) {
        try {
          await primary.writeAsString(contents, encoding: utf8);
          replaced = true;
        } catch (_) {
          // ignore: best-effort write
        }
      }
      if (replaced) {
        try {
          await tmp.delete();
        } catch (_) {
          // ignore: best-effort cleanup
        }
      }
    }

    // Keep `.bak` to allow recovery from a corrupted primary.
  }

  static bool _sameAction(OutboxAction a, OutboxAction b) {
    return a.type == b.type &&
        a.remoteEntryId == b.remoteEntryId &&
        a.value == b.value &&
        a.feedUrl == b.feedUrl &&
        a.categoryTitle == b.categoryTitle &&
        a.createdAt.toIso8601String() == b.createdAt.toIso8601String();
  }

  static List<OutboxAction> _compact(List<OutboxAction> actions) {
    if (actions.length <= 1) return actions;

    // Keep the last intent per scope; makes toggle-like operations safe to replay.
    final keptKeys = <String>{};
    final keptReversed = <OutboxAction>[];
    for (var i = actions.length - 1; i >= 0; i--) {
      final a = actions[i];
      final key = _dedupeKey(a);
      if (key == null) {
        keptReversed.add(a);
        continue;
      }
      if (keptKeys.add(key)) {
        keptReversed.add(a);
      }
    }
    return keptReversed.reversed.toList(growable: false);
  }

  static String? _dedupeKey(OutboxAction a) {
    switch (a.type) {
      case OutboxActionType.markRead:
        final id = a.remoteEntryId;
        if (id == null) return null;
        return 'markRead:$id';
      case OutboxActionType.bookmark:
        final id = a.remoteEntryId;
        if (id == null) return null;
        return 'bookmark:$id';
      case OutboxActionType.markAllRead:
        final feedUrl = (a.feedUrl ?? '').trim();
        final categoryTitle = (a.categoryTitle ?? '').trim();
        // Empty values represent "all feeds" scope.
        return 'markAllRead:feed=$feedUrl:cat=$categoryTitle';
    }
  }
}
