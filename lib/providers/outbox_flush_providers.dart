import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/accounts/account.dart';
import '../services/sync/miniflux/miniflux_sync_service.dart';
import '../utils/platform.dart';
import 'account_providers.dart';
import 'service_providers.dart';

class OutboxFlushController extends AutoDisposeNotifier<void> {
  Timer? _timer;
  Duration _delay = const Duration(seconds: 3);
  bool _running = false;
  var _disposed = false;

  @override
  void build() {
    // Desktop-first: keep it lightweight and foreground-only.
    // Mobile background flush should use platform-specific scheduling.
    if (!isDesktop) {
      // Still allow foreground flushing; just be less aggressive.
      _delay = const Duration(seconds: 10);
    }

    final account = ref.watch(activeAccountProvider);

    _timer?.cancel();
    _timer = null;
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _timer?.cancel();
    });

    if (account.type != AccountType.miniflux) return;

    _schedule();
  }

  void _schedule() {
    if (_disposed) return;
    _timer?.cancel();
    _timer = Timer(_delay, () {
      unawaited(_tick());
    });
  }

  Future<void> _tick() async {
    if (_running) return;
    _running = true;
    var shouldReschedule = true;
    try {
      final account = ref.read(activeAccountProvider);
      if (account.type != AccountType.miniflux) {
        _delay = const Duration(seconds: 30);
        shouldReschedule = false;
        return;
      }

      final pending = await ref.read(outboxStoreProvider).load(account.id);
      if (pending.isEmpty) {
        // Idle: poll slowly.
        _delay = const Duration(seconds: 30);
        // Keep polling while the account is Miniflux.
        return;
      }

      final svc = ref.read(syncServiceProvider);
      final ok = svc is MinifluxSyncService && await svc.flushOutboxSafe();

      if (ok) {
        // If there are still pending actions, retry quickly; otherwise we will
        // fall back to the idle delay on the next tick.
        _delay = const Duration(seconds: 5);
      } else {
        _delay = _nextBackoff(_delay);
      }
    } finally {
      _running = false;
      var doReschedule = shouldReschedule && !_disposed;
      if (doReschedule) {
        try {
          doReschedule =
              ref.read(activeAccountProvider).type == AccountType.miniflux;
        } catch (_) {
          doReschedule = false;
        }
      }
      if (doReschedule) {
        _schedule();
      }
    }
  }

  static Duration _nextBackoff(Duration cur) {
    final secs = cur.inSeconds <= 0 ? 3 : cur.inSeconds;
    final next = secs * 2;
    // Cap to avoid infinite hammering on flaky networks or bad credentials.
    final capped = next > 300 ? 300 : next;
    // Keep a floor to avoid busy looping.
    final floored = capped < 5 ? 5 : capped;
    return Duration(seconds: floored);
  }
}

final outboxFlushControllerProvider =
    AutoDisposeNotifierProvider<OutboxFlushController, void>(
      OutboxFlushController.new,
    );
