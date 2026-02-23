import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_settings_providers.dart';
import 'repository_providers.dart';
import 'service_providers.dart';

class AutoRefreshController extends AutoDisposeNotifier<void> {
  Timer? _timer;
  var _running = false;

  @override
  void build() {
    final settings = ref.watch(appSettingsProvider).valueOrNull;
    final minutes = settings?.autoRefreshMinutes;

    _timer?.cancel();
    _timer = null;
    ref.onDispose(() => _timer?.cancel());

    if (minutes == null || minutes <= 0) return;
    if (settings?.syncEnabled == false) return;

    _timer = Timer.periodic(Duration(minutes: minutes), (_) {
      unawaited(_tick());
    });
  }

  Future<void> _tick() async {
    if (_running) return;
    _running = true;
    try {
      final settings = ref.read(appSettingsProvider).valueOrNull;
      if (settings?.syncEnabled == false) return;
      final concurrency = settings?.autoRefreshConcurrency ?? 2;

      final feeds = await ref.read(feedRepositoryProvider).getAll();
      await ref
          .read(syncServiceProvider)
          .refreshFeedsSafe(feeds.map((f) => f.id), maxConcurrent: concurrency);
    } finally {
      _running = false;
    }
  }
}

final autoRefreshControllerProvider =
    AutoDisposeNotifierProvider<AutoRefreshController, void>(
      AutoRefreshController.new,
    );
