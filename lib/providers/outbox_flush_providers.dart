import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/accounts/account.dart';
import '../services/sync/fever/fever_sync_service.dart';
import '../services/sync/miniflux/miniflux_sync_service.dart';
import '../utils/platform.dart';
import 'account_providers.dart';
import 'outbox_status_providers.dart';
import 'service_providers.dart';

class OutboxFlushController extends AutoDisposeNotifier<void> {
  Timer? _timer;
  Duration _delay = const Duration(seconds: 3);
  bool _running = false;
  var _disposed = false;
  var _stallCount = 0;

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
    _stallCount = 0;
    ref.read(outboxFlushStallCountProvider.notifier).state = 0;
    ref.onDispose(() {
      _disposed = true;
      _timer?.cancel();
    });

    if (account.type != AccountType.miniflux &&
        account.type != AccountType.fever) {
      return;
    }

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
      if (account.type != AccountType.miniflux &&
          account.type != AccountType.fever) {
        _delay = const Duration(seconds: 30);
        shouldReschedule = false;
        return;
      }

      final pending = await ref.read(outboxStoreProvider).load(account.id);
      if (pending.isEmpty) {
        // Idle: poll slowly.
        _delay = const Duration(seconds: 30);
        _stallCount = 0;
        ref.read(outboxFlushStallCountProvider.notifier).state = 0;
        // Keep polling while the account is Miniflux.
        return;
      }

      final beforeCount = pending.length;
      final svc = ref.read(syncServiceProvider);
      final ok = switch (svc) {
        MinifluxSyncService s => await s.flushOutboxSafe(),
        FeverSyncService s => await s.flushOutboxSafe(),
        _ => false,
      };

      if (!ok) {
        _delay = _nextBackoff(_delay);
        _stallCount += 1;
        ref.read(outboxFlushStallCountProvider.notifier).state = _stallCount;
        return;
      }

      // `flushOutboxSafe()` may succeed but make no progress (e.g. permanent
      // server errors, bad credentials, or unsupported actions). Detect this to
      // avoid a fast-poll loop that burns battery/network.
      final after = await ref.read(outboxStoreProvider).load(account.id);
      if (after.isEmpty) {
        _delay = const Duration(seconds: 30);
        _stallCount = 0;
        ref.read(outboxFlushStallCountProvider.notifier).state = 0;
      } else if (after.length < beforeCount) {
        _delay = const Duration(seconds: 5);
        _stallCount = 0;
        ref.read(outboxFlushStallCountProvider.notifier).state = 0;
      } else {
        _delay = _nextBackoff(_delay);
        _stallCount += 1;
        ref.read(outboxFlushStallCountProvider.notifier).state = _stallCount;
      }
    } finally {
      _running = false;
      var doReschedule = shouldReschedule && !_disposed;
      if (doReschedule) {
        try {
          doReschedule =
              ref.read(activeAccountProvider).type == AccountType.miniflux ||
              ref.read(activeAccountProvider).type == AccountType.fever;
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
