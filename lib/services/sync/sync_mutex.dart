import 'dart:async';
import 'dart:io';

import '../../utils/path_manager.dart';

/// A best-effort mutex for sync-related operations.
///
/// Why:
/// - Prevents foreground timers, manual refreshes, outbox flushes, and
///   background tasks from running sync concurrently (battery + DB safety).
/// - Uses an OS file lock to coordinate across isolates.
///
/// Notes:
/// - Locks are re-entrant within the same async context (Zone-based).
/// - Lock failures (e.g. unsupported platform) fall back to in-isolate queuing.
class SyncMutex {
  SyncMutex._();

  static final SyncMutex instance = SyncMutex._();

  static final Object _heldKeysZoneKey = Object();

  final Map<String, Future<void>> _queues = <String, Future<void>>{};
  final Map<String, Future<File?>> _lockFiles = <String, Future<File?>>{};

  Future<T> run<T>(
    String key,
    Future<T> Function() op,
  ) {
    final held = _heldKeys;
    if (held.contains(key)) return op();

    final prev = _queues[key] ?? Future<void>.value();
    final task = prev.then((_) => _runLocked(key, op, held));
    _queues[key] = task.then((_) {}).catchError((_) {});
    return task;
  }

  Set<String> get _heldKeys =>
      (Zone.current[_heldKeysZoneKey] as Set<String>?) ?? const <String>{};

  Future<T> _runLocked<T>(
    String key,
    Future<T> Function() op,
    Set<String> held,
  ) async {
    final nextHeld = {...held, key};
    return runZoned(
      () async {
        RandomAccessFile? raf;
        try {
          final lockFile = await _lockFileOrNull(key);
          if (lockFile != null) {
            try {
              raf = await lockFile.open(mode: FileMode.append);
            } catch (_) {
              raf = null;
            }
            if (raf != null) {
              try {
                await raf.lock(FileLock.exclusive);
              } catch (_) {
                // ignore: best-effort file locking
              }
            }
          }
          return await op();
        } finally {
          if (raf != null) {
            try {
              await raf.unlock();
            } catch (_) {
              // ignore: best-effort unlock
            }
            try {
              await raf.close();
            } catch (_) {
              // ignore: best-effort close
            }
          }
        }
      },
      zoneValues: <Object, Object?>{_heldKeysZoneKey: nextHeld},
    );
  }

  Future<File?> _lockFileOrNull(String key) {
    final cached = _lockFiles[key];
    if (cached != null) return cached;

    final task = _createLockFileOrNull(key);
    _lockFiles[key] = task;
    return task;
  }

  Future<File?> _createLockFileOrNull(String key) async {
    try {
      final safeName = key.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final dir = await PathManager.getStateDir();
      final file = File(
        '${dir.path}${Platform.pathSeparator}mutex_$safeName.lock',
      );
      try {
        if (!await file.exists()) {
          await file.create(recursive: true);
        }
      } catch (_) {
        // ignore: best-effort create
      }
      return file;
    } catch (_) {
      // If PathProvider is not available (e.g. background isolate init issues),
      // or file IO fails, fall back to in-isolate queuing.
      final prev = _lockFiles.remove(key);
      if (prev != null) {
        unawaited(prev);
      }
      return null;
    }
  }
}
