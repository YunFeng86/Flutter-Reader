import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/platform.dart';
import 'app_settings_providers.dart';
import 'repository_providers.dart';
import 'service_providers.dart';

class AutoRefreshController extends AutoDisposeNotifier<void> {
  Timer? _timer;
  var _running = false;

  @override
  void build() {
    // Desktop-first; mobile background refresh should use platform-specific
    // scheduling instead of a foreground timer.
    if (!isDesktop) return;

    final settings = ref.watch(appSettingsProvider).valueOrNull;
    final minutes = settings?.autoRefreshMinutes;

    _timer?.cancel();
    _timer = null;
    ref.onDispose(() => _timer?.cancel());

    if (minutes == null || minutes <= 0) return;

    _timer = Timer.periodic(Duration(minutes: minutes), (_) {
      unawaited(_tick());
    });
  }

  Future<void> _tick() async {
    if (_running) return;
    _running = true;
    try {
      final feeds = await ref.read(feedRepositoryProvider).getAll();
      await ref
          .read(syncServiceProvider)
          .refreshFeedsSafe(feeds.map((f) => f.id));
    } finally {
      _running = false;
    }
  }
}

final autoRefreshControllerProvider =
    AutoDisposeNotifierProvider<AutoRefreshController, void>(
      AutoRefreshController.new,
    );
