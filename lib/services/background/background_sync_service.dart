import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../db/isar_db.dart';
import '../../repositories/article_repository.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/feed_repository.dart';
import '../accounts/account.dart';
import '../accounts/account_store.dart';
import '../accounts/credential_store.dart';
import '../cache/article_cache_service.dart';
import '../cache/image_meta_store.dart';
import '../extract/article_extractor.dart';
import '../logging/app_logger.dart';
import '../notifications/notification_service.dart';
import '../rss/feed_parser.dart';
import '../rss/rss_client.dart';
import '../settings/app_settings.dart';
import '../settings/app_settings_store.dart';
import '../sync/fever/fever_sync_service.dart';
import '../sync/miniflux/miniflux_sync_service.dart';
import '../sync/outbox/outbox_store.dart';
import '../sync/sync_mutex.dart';
import '../sync/sync_service.dart';

const String kBackgroundSyncUniqueName = 'com.cloudwind.fleur.background.sync';
const String kBackgroundSyncTaskName = 'backgroundSync';

@pragma('vm:entry-point')
void backgroundSyncCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await AppLogger.ensureInitialized();
    } catch (_) {
      // ignore: best-effort
    }

    try {
      final runner = BackgroundSyncRunner();
      await runner.run(taskName: taskName, inputData: inputData);
      return true;
    } catch (e, st) {
      AppLogger.e(
        'Background sync failed',
        tag: 'bg',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  });
}

class BackgroundSyncService {
  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      await Workmanager().initialize(backgroundSyncCallbackDispatcher);
      _initialized = true;
    } on MissingPluginException {
      // Best-effort: running on an unsupported platform.
    } catch (_) {
      // ignore: best-effort
    }
  }

  static Future<void> schedulePeriodic({required Duration frequency}) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await ensureInitialized();

    final effectiveFrequency = frequency.inMinutes < 15
        ? const Duration(minutes: 15)
        : frequency;

    try {
      await Workmanager().registerPeriodicTask(
        kBackgroundSyncUniqueName,
        kBackgroundSyncTaskName,
        frequency: effectiveFrequency,
        initialDelay: const Duration(minutes: 1),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );
    } on MissingPluginException {
      // ignore: best-effort
    } catch (_) {
      // ignore: best-effort
    }
  }

  static Future<void> cancelPeriodic() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      await Workmanager().cancelByUniqueName(kBackgroundSyncUniqueName);
    } on MissingPluginException {
      // ignore: best-effort
    } catch (_) {
      // ignore: best-effort
    }
  }
}

class BackgroundSyncRunner {
  BackgroundSyncRunner({
    AccountsState? accounts,
    AccountStore? accountStore,
    AppSettings? appSettings,
    AppSettingsStore? appSettingsStore,
  }) : _accounts = accounts,
       _accountStore = accountStore ?? AccountStore(),
       _appSettings = appSettings,
       _appSettingsStore = appSettingsStore ?? AppSettingsStore();

  final AccountsState? _accounts;
  final AccountStore _accountStore;
  final AppSettings? _appSettings;
  final AppSettingsStore _appSettingsStore;

  static const String _lastRefreshKeyPrefix = 'background_sync:last_refresh:';

  Future<void> run({
    required String taskName,
    required Map<String, dynamic>? inputData,
  }) async {
    if (taskName != kBackgroundSyncTaskName &&
        taskName != kBackgroundSyncUniqueName &&
        taskName != Workmanager.iOSBackgroundTask) {
      return;
    }

    await SyncMutex.instance.run('sync', () async {
      final accounts = _accounts ?? await _accountStore.loadOrCreate();
      final activeAccount =
          accounts.findById(accounts.activeAccountId) ??
          accounts.accounts.first;
      final appSettings = _appSettings ?? await _appSettingsStore.load();

      final refreshMinutes = appSettings.autoRefreshMinutes ?? 0;
      var shouldRefresh = refreshMinutes > 0 && appSettings.syncEnabled;
      final outboxEnabled =
          activeAccount.type == AccountType.miniflux ||
          activeAccount.type == AccountType.fever;

      // Avoid opening Isar when there's nothing to do.
      final outbox = OutboxStore();
      final hasPendingOutbox =
          outboxEnabled && (await outbox.load(activeAccount.id)).isNotEmpty;
      if (!shouldRefresh && !hasPendingOutbox) return;

      // iOS can wake the app more frequently than the user's configured interval
      // (BGTaskScheduler is best-effort). Gate refresh work in Dart.
      if (shouldRefresh && Platform.isIOS) {
        final now = DateTime.now();
        try {
          final prefs = await SharedPreferences.getInstance();
          final key = '$_lastRefreshKeyPrefix${activeAccount.id}';
          final lastMs = prefs.getInt(key);
          if (lastMs != null) {
            final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
            final minInterval = Duration(minutes: refreshMinutes);
            if (now.difference(last) < minInterval) {
              shouldRefresh = false;
            }
          }
          if (shouldRefresh) {
            // Record attempt early to prevent repeated costly wakeups.
            await prefs.setInt(key, now.millisecondsSinceEpoch);
          }
        } catch (_) {
          // ignore: best-effort gating (fall back to refreshing)
        }
      }

      if (!shouldRefresh && !hasPendingOutbox) return;

      final isar = await openIsarForAccount(
        accountId: activeAccount.id,
        dbName: activeAccount.dbName,
        isPrimary: activeAccount.isPrimary,
      );

      try {
        final feeds = FeedRepository(isar);
        final categories = CategoryRepository(isar);
        final articles = ArticleRepository(isar);

        final dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 20),
            sendTimeout: const Duration(seconds: 10),
            followRedirects: true,
            maxRedirects: 5,
          ),
        );
        if (kDebugMode) {
          dio.interceptors.add(
            LogInterceptor(
              requestHeader: false,
              requestBody: false,
              responseHeader: false,
              responseBody: false,
              error: true,
            ),
          );
        }

        final cacheManager = CacheManager(
          Config(
            'fleur_images',
            stalePeriod: const Duration(days: 45),
            maxNrOfCacheObjects: 1200,
          ),
        );
        final cache = ArticleCacheService(cacheManager, ImageMetaStore());
        final extractor = ArticleExtractor(dio);

        final svc = _buildSyncService(
          account: activeAccount,
          dio: dio,
          credentials: CredentialStore(),
          feeds: feeds,
          categories: categories,
          articles: articles,
          outbox: outbox,
          appSettingsStore: _appSettingsStore,
          cache: cache,
          extractor: extractor,
        );

        if (hasPendingOutbox) {
          await _flushOutboxSafe(activeAccount, svc);
        }

        if (!shouldRefresh) return;

        final allFeeds = await feeds.getAll();
        if (allFeeds.isEmpty && activeAccount.type == AccountType.local) return;

        final concurrency = appSettings.autoRefreshConcurrency;
        await svc.refreshFeedsSafe(
          allFeeds.map((f) => f.id),
          maxConcurrent: concurrency,
          notify: true,
        );
      } finally {
        await isar.close();
      }
    });
  }

  SyncServiceBase _buildSyncService({
    required Account account,
    required Dio dio,
    required CredentialStore credentials,
    required FeedRepository feeds,
    required CategoryRepository categories,
    required ArticleRepository articles,
    required OutboxStore outbox,
    required AppSettingsStore appSettingsStore,
    required ArticleCacheService cache,
    required ArticleExtractor extractor,
  }) {
    switch (account.type) {
      case AccountType.local:
        return SyncService(
          feeds: feeds,
          categories: categories,
          articles: articles,
          client: RssClient(dio),
          parser: FeedParser(),
          notifications: NotificationService(),
          cache: cache,
          extractor: extractor,
          appSettingsStore: appSettingsStore,
        );
      case AccountType.miniflux:
        return MinifluxSyncService(
          account: account,
          dio: dio,
          credentials: credentials,
          feeds: feeds,
          categories: categories,
          articles: articles,
          outbox: outbox,
          appSettingsStore: appSettingsStore,
          cache: cache,
          extractor: extractor,
        );
      case AccountType.fever:
        return FeverSyncService(
          account: account,
          dio: dio,
          credentials: credentials,
          feeds: feeds,
          categories: categories,
          articles: articles,
          outbox: outbox,
          appSettingsStore: appSettingsStore,
          notifications: NotificationService(),
          cache: cache,
        );
    }
  }

  Future<void> _flushOutboxSafe(Account account, SyncServiceBase svc) async {
    switch (account.type) {
      case AccountType.miniflux:
        final minifluxSvc = svc;
        if (minifluxSvc is MinifluxSyncService) {
          await minifluxSvc.flushOutboxSafe();
        }
        return;
      case AccountType.fever:
        final feverSvc = svc;
        if (feverSvc is FeverSyncService) {
          await feverSvc.flushOutboxSafe();
        }
        return;
      case AccountType.local:
        return;
    }
  }
}
