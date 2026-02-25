import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'account_providers.dart';
import '../services/accounts/account.dart';
import '../services/rss/feed_parser.dart';
import '../services/rss/feed_discovery_service.dart';
import '../services/rss/rss_client.dart';
import '../services/sync/sync_service.dart';
import '../services/sync/miniflux/miniflux_sync_service.dart';
import '../services/sync/fever/fever_sync_service.dart';
import '../services/sync/outbox/outbox_store.dart';
import 'sync_status_providers.dart';
import '../services/actions/article_action_service.dart';
import '../services/extract/article_extractor.dart';
import '../services/ai/ai_request_queue.dart';
import '../services/ai/ai_service_client.dart';
import '../services/cache/article_cache_service.dart';
import '../services/cache/ai_content_cache_store.dart';
import '../services/cache/image_meta_store.dart';
import '../services/cache/favicon_store.dart';
import '../services/notifications/notification_service.dart';
import '../services/network/favicon_service.dart';
import '../services/translation/translation_service.dart';
import 'repository_providers.dart';
import 'app_settings_providers.dart';

final dioProvider = Provider<Dio>((ref) {
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
  return dio;
});

final rssClientProvider = Provider<RssClient>((ref) {
  return RssClient(ref.watch(dioProvider));
});

final feedParserProvider = Provider<FeedParser>((ref) => FeedParser());

final feedDiscoveryServiceProvider = Provider<FeedDiscoveryService>((ref) {
  return FeedDiscoveryService(ref.watch(dioProvider));
}, dependencies: [dioProvider]);

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final outboxStoreProvider = Provider<OutboxStore>((ref) => OutboxStore());

final syncServiceProvider = Provider<SyncServiceBase>(
  (ref) {
    final account = ref.watch(activeAccountProvider);
    final feeds = ref.watch(feedRepositoryProvider);
    final categories = ref.watch(categoryRepositoryProvider);
    final articles = ref.watch(articleRepositoryProvider);
    final reporter = ref.watch(syncStatusReporterProvider);

    switch (account.type) {
      case AccountType.local:
        return SyncService(
          feeds: feeds,
          categories: categories,
          articles: articles,
          client: ref.watch(rssClientProvider),
          parser: ref.watch(feedParserProvider),
          notifications: ref.watch(notificationServiceProvider),
          cache: ref.watch(articleCacheServiceProvider),
          extractor: ref.watch(articleExtractorProvider),
          appSettingsStore: ref.watch(appSettingsStoreProvider),
          statusReporter: reporter,
        );
      case AccountType.miniflux:
        return MinifluxSyncService(
          account: account,
          dio: ref.watch(dioProvider),
          credentials: ref.watch(credentialStoreProvider),
          feeds: feeds,
          categories: categories,
          articles: articles,
          outbox: ref.watch(outboxStoreProvider),
          appSettingsStore: ref.watch(appSettingsStoreProvider),
          cache: ref.watch(articleCacheServiceProvider),
          extractor: ref.watch(articleExtractorProvider),
          statusReporter: reporter,
        );
      case AccountType.fever:
        return FeverSyncService(
          account: account,
          dio: ref.watch(dioProvider),
          credentials: ref.watch(credentialStoreProvider),
          feeds: feeds,
          categories: categories,
          articles: articles,
          outbox: ref.watch(outboxStoreProvider),
          appSettingsStore: ref.watch(appSettingsStoreProvider),
          notifications: ref.watch(notificationServiceProvider),
          cache: ref.watch(articleCacheServiceProvider),
          statusReporter: reporter,
        );
    }
  },
  dependencies: [
    activeAccountProvider,
    feedRepositoryProvider,
    categoryRepositoryProvider,
    articleRepositoryProvider,
    rssClientProvider,
    feedParserProvider,
    notificationServiceProvider,
    articleCacheServiceProvider,
    articleExtractorProvider,
    appSettingsStoreProvider,
    dioProvider,
    credentialStoreProvider,
    outboxStoreProvider,
    syncStatusReporterProvider,
  ],
);

final articleExtractorProvider = Provider<ArticleExtractor>((ref) {
  return ArticleExtractor(ref.watch(dioProvider));
});

final aiRequestQueueProvider = Provider<AiRequestQueue>((ref) {
  return AiRequestQueue(maxConcurrent: 2);
});

final aiServiceClientProvider = Provider<AiServiceClient>((ref) {
  return AiServiceClient(dio: ref.watch(dioProvider));
}, dependencies: [dioProvider]);

final translationServiceProvider = Provider<TranslationService>((ref) {
  return TranslationService(dio: ref.watch(dioProvider));
}, dependencies: [dioProvider]);

final aiContentCacheStoreProvider = Provider<AiContentCacheStore>((ref) {
  return AiContentCacheStore();
});

final cacheManagerProvider = Provider<BaseCacheManager>((ref) {
  return CacheManager(
    Config(
      'fleur_images',
      stalePeriod: const Duration(days: 45),
      maxNrOfCacheObjects: 1200,
    ),
  );
});

final faviconStoreProvider = Provider<FaviconStore>((ref) {
  return FaviconStore();
});

final faviconServiceProvider = Provider<FaviconService>((ref) {
  return FaviconService(
    dio: ref.watch(dioProvider),
    store: ref.watch(faviconStoreProvider),
  );
});

final imageMetaStoreProvider = Provider<ImageMetaStore>((ref) {
  return ImageMetaStore();
});

final articleCacheServiceProvider = Provider<ArticleCacheService>((ref) {
  return ArticleCacheService(
    ref.watch(cacheManagerProvider),
    ref.watch(imageMetaStoreProvider),
  );
});

final articleActionServiceProvider = Provider<ArticleActionService>(
  (ref) {
    return ArticleActionService(
      account: ref.watch(activeAccountProvider),
      articles: ref.watch(articleRepositoryProvider),
      feeds: ref.watch(feedRepositoryProvider),
      categories: ref.watch(categoryRepositoryProvider),
      dio: ref.watch(dioProvider),
      credentials: ref.watch(credentialStoreProvider),
      outbox: ref.watch(outboxStoreProvider),
    );
  },
  dependencies: [
    activeAccountProvider,
    articleRepositoryProvider,
    feedRepositoryProvider,
    categoryRepositoryProvider,
    dioProvider,
    credentialStoreProvider,
    outboxStoreProvider,
  ],
);
