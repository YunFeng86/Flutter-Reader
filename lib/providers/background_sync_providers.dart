import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/accounts/account.dart';
import '../services/background/background_sync_service.dart';
import 'account_providers.dart';
import 'app_settings_providers.dart';
import 'outbox_status_providers.dart';

class BackgroundSyncController extends AutoDisposeNotifier<void> {
  Duration? _lastFrequency;
  bool? _lastEnabled;

  @override
  void build() {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final appSettings = ref.watch(appSettingsProvider).valueOrNull;
    final account = ref.watch(activeAccountProvider);

    final refreshMinutes = appSettings?.autoRefreshMinutes ?? 0;
    final syncEnabled = appSettings?.syncEnabled ?? true;
    final refreshEnabled = refreshMinutes > 0 && syncEnabled;

    final outboxCapable =
        account.type == AccountType.miniflux ||
        account.type == AccountType.fever;
    final pendingAsync = ref.watch(outboxPendingCountProvider);
    final pending = pendingAsync.valueOrNull;
    final hasPendingOutbox = (pending ?? 0) > 0;

    // Only schedule background work when there is something meaningful to do:
    // - auto refresh enabled, or
    // - outbox has pending actions to flush.
    var enabled = refreshEnabled;
    if (!enabled && outboxCapable) {
      if (pending != null) {
        enabled = hasPendingOutbox;
      } else if (pendingAsync.hasError) {
        // Avoid flapping when file IO/path provider is temporarily unavailable.
        enabled = _lastEnabled ?? false;
      } else {
        // Loading: keep previous state; default to disabled to honor the user's
        // "silent" expectation when background sync is off.
        enabled = _lastEnabled ?? false;
      }
    }

    if (!enabled) {
      if (_lastEnabled == false) return;
      _lastEnabled = false;
      _lastFrequency = null;
      unawaited(BackgroundSyncService.cancelPeriodic());
      return;
    }

    final frequency = refreshEnabled
        ? Duration(minutes: refreshMinutes)
        : _outboxBackoffFrequency(ref.watch(outboxFlushStallCountProvider));

    if (_lastEnabled == true && _lastFrequency == frequency) return;
    _lastEnabled = true;
    _lastFrequency = frequency;

    unawaited(BackgroundSyncService.schedulePeriodic(frequency: frequency));
  }

  static Duration _outboxBackoffFrequency(int stalls) {
    const baseMinutes = 15;
    final step = stalls < 0 ? 0 : (stalls > 4 ? 4 : stalls);
    final minutes = baseMinutes * (1 << step);
    return Duration(minutes: minutes);
  }
}

final backgroundSyncControllerProvider =
    AutoDisposeNotifierProvider<BackgroundSyncController, void>(
      BackgroundSyncController.new,
    );
