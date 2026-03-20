import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fleur/models/article.dart';
import 'package:fleur/models/category.dart';
import 'package:fleur/models/feed.dart';
import 'package:fleur/providers/account_providers.dart';
import 'package:fleur/providers/app_settings_providers.dart';
import 'package:fleur/providers/article_ai_providers.dart';
import 'package:fleur/providers/query_providers.dart';
import 'package:fleur/providers/service_providers.dart';
import 'package:fleur/providers/translation_ai_settings_providers.dart';
import 'package:fleur/services/cache/ai_content_cache_store.dart';
import 'package:fleur/services/settings/app_settings.dart';
import 'package:fleur/services/settings/translation_ai_settings.dart';
import 'package:fleur/services/translation/article_translation.dart';

import '../test_utils/critical_workflow_test_support.dart';

void main() {
  const articleId = 1;
  const accountId = 'article-ai-test';

  Feed buildFeed() {
    return Feed()
      ..id = 10
      ..url = 'https://example.com/feed.xml'
      ..title = 'Example Feed'
      ..categoryId = 100;
  }

  Category buildCategory() {
    return Category()
      ..id = 100
      ..name = 'Tech';
  }

  Article buildArticle({
    String html = '<p>Hello world from Fleur.</p>',
    String? contentHash = 'hash-1',
  }) {
    return Article()
      ..id = articleId
      ..feedId = 10
      ..categoryId = 100
      ..link = 'https://example.com/article'
      ..title = 'Hello'
      ..contentHtml = html
      ..contentHash = contentHash
      ..publishedAt = DateTime.utc(2026, 1, 2)
      ..updatedAt = DateTime.utc(2026, 1, 2);
  }

  AiServiceConfig buildAiService({String id = 'svc-1', bool enabled = true}) {
    return AiServiceConfig(
      id: id,
      name: 'Test AI',
      apiType: AiServiceApiType.openAiResponses,
      baseUrl: 'https://example.com/v1/',
      defaultModel: 'gpt-test',
      enabled: enabled,
    );
  }

  Future<void> flushAsync() async {
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  ProviderContainer buildContainer({
    required Stream<Article?> articleStream,
    AppSettings? appSettings,
    TranslationAiSettings? translationSettings,
    FakeTranslationAiSecretStore? secrets,
    InMemoryAiContentCacheStore? cacheStore,
    ImmediateAiRequestQueue? queue,
    FakeAiServiceClient? aiClient,
    FakeTranslationService? translationService,
  }) {
    final appStore = FakeAppSettingsStore(
      appSettings ?? AppSettings.defaults(),
    );
    final settingsStore = FakeTranslationAiSettingsStore(
      translationSettings ?? TranslationAiSettings.defaults(),
    );
    final secretStore = secrets ?? FakeTranslationAiSecretStore();
    final cache = cacheStore ?? InMemoryAiContentCacheStore();
    final aiQueue = queue ?? ImmediateAiRequestQueue();
    final client = aiClient ?? FakeAiServiceClient();
    final translator = translationService ?? FakeTranslationService();

    final container = ProviderContainer(
      overrides: [
        activeAccountProvider.overrideWithValue(
          buildTestAccount(id: accountId, isPrimary: true),
        ),
        appSettingsStoreProvider.overrideWithValue(appStore),
        translationAiSettingsStoreProvider.overrideWithValue(settingsStore),
        translationAiSecretStoreProvider.overrideWithValue(secretStore),
        aiContentCacheStoreProvider.overrideWithValue(cache),
        aiRequestQueueProvider.overrideWithValue(aiQueue),
        aiServiceClientProvider.overrideWithValue(client),
        translationServiceProvider.overrideWithValue(translator),
        articleProvider(articleId).overrideWith((ref) => articleStream),
        feedsProvider.overrideWith((ref) => Stream.value([buildFeed()])),
        categoriesProvider.overrideWith(
          (ref) => Stream.value([buildCategory()]),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('inherits overridden article dependencies from nested scope', () async {
    final root = ProviderContainer(
      overrides: [
        activeAccountProvider.overrideWithValue(
          buildTestAccount(id: accountId, isPrimary: true),
        ),
        appSettingsStoreProvider.overrideWithValue(
          FakeAppSettingsStore(AppSettings.defaults()),
        ),
        translationAiSettingsStoreProvider.overrideWithValue(
          FakeTranslationAiSettingsStore(TranslationAiSettings.defaults()),
        ),
      ],
    );
    addTearDown(root.dispose);

    final scoped = ProviderContainer(
      parent: root,
      overrides: [
        articleProvider(
          articleId,
        ).overrideWith((ref) => Stream.value(buildArticle())),
        feedsProvider.overrideWith((ref) => Stream.value([buildFeed()])),
        categoriesProvider.overrideWith(
          (ref) => Stream.value([buildCategory()]),
        ),
      ],
    );
    addTearDown(scoped.dispose);

    final sub = scoped.listen<ArticleAiState>(
      articleAiControllerProvider(articleId),
      (previous, next) {},
      fireImmediately: true,
    );
    addTearDown(sub.close);

    await flushAsync();

    expect(
      scoped.read(articleAiControllerProvider(articleId)).articleId,
      articleId,
    );
  });

  test(
    'uses cached summary and reports outdated prompt without calling AI',
    () async {
      final article = buildArticle();
      const targetLanguageTag = 'zh';
      final service = buildAiService();
      final settings = TranslationAiSettings.defaults().copyWith(
        targetLanguageTag: targetLanguageTag,
        defaultAiServiceId: service.id,
        aiServices: [service],
        aiSummaryPrompt: 'new prompt {{content}}',
      );
      final cacheStore = InMemoryAiContentCacheStore();
      final currentPromptHash = 'old-prompt-hash';
      await cacheStore.write(
        AiContentCacheEntry(
          key: AiContentCacheKey.summary(
            accountId: accountId,
            articleId: article.id,
            targetLanguageTag: targetLanguageTag,
            aiServiceId: service.id,
          ),
          contentHash: 'hash-1',
          promptHash: currentPromptHash,
          data: 'cached summary',
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      );
      final aiClient = FakeAiServiceClient();
      final container = buildContainer(
        articleStream: Stream.value(article),
        appSettings: AppSettings.defaults().copyWith(showAiSummary: true),
        translationSettings: settings,
        secrets: FakeTranslationAiSecretStore(
          aiServiceApiKeys: <String, String>{service.id: 'secret-key'},
        ),
        cacheStore: cacheStore,
        aiClient: aiClient,
      );

      final sub = container.listen<ArticleAiState>(
        articleAiControllerProvider(articleId),
        (previous, next) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);

      await flushAsync();

      final state = container.read(articleAiControllerProvider(articleId));
      expect(state.summaryStatus, ArticleAiTaskStatus.ready);
      expect(state.summaryText, 'cached summary');
      expect(state.summaryOutdated, isTrue);
      expect(aiClient.prompts, isEmpty);
    },
  );

  test('returns error when summary service is not configured', () async {
    final container = buildContainer(
      articleStream: Stream.value(buildArticle()),
      translationSettings: TranslationAiSettings.defaults(),
    );

    final sub = container.listen<ArticleAiState>(
      articleAiControllerProvider(articleId),
      (previous, next) {},
      fireImmediately: true,
    );
    addTearDown(sub.close);

    await container.read(appSettingsProvider.future);
    await container.read(translationAiSettingsProvider.future);
    await flushAsync();
    await container
        .read(articleAiControllerProvider(articleId).notifier)
        .ensureSummary();
    await flushAsync();

    final state = container.read(articleAiControllerProvider(articleId));
    expect(state.summaryStatus, ArticleAiTaskStatus.error);
    expect(state.summaryError, isNotEmpty);
  });

  test(
    'shows language mismatch banner when source differs from target',
    () async {
      final service = buildAiService();
      final container = buildContainer(
        articleStream: Stream.value(
          buildArticle(
            html:
                '<p>This article is written in English with enough repeated '
                'latin words to trigger the language detector reliably. '
                'English text English text English text English text.</p>',
          ),
        ),
        translationSettings: TranslationAiSettings.defaults().copyWith(
          targetLanguageTag: 'zh',
          defaultAiServiceId: service.id,
          aiServices: [service],
        ),
        secrets: FakeTranslationAiSecretStore(
          aiServiceApiKeys: <String, String>{service.id: 'secret-key'},
        ),
      );

      final sub = container.listen<ArticleAiState>(
        articleAiControllerProvider(articleId),
        (previous, next) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);

      await container.read(appSettingsProvider.future);
      await container.read(translationAiSettingsProvider.future);
      await flushAsync();

      final state = container.read(articleAiControllerProvider(articleId));
      expect(state.sourceLanguageTag, isNotNull);
      expect(state.targetLanguageTag, 'zh');
      expect(state.showLanguageMismatchBanner, isTrue);
    },
  );

  test('recomputes translation when article content changes', () async {
    final controller = StreamController<Article?>();
    addTearDown(controller.close);

    final service = buildAiService();
    final translator = FakeTranslationService(
      onTranslateText:
          ({
            required provider,
            required settings,
            required secrets,
            required text,
            required targetLanguageTag,
          }) async {
            return '[$targetLanguageTag] $text';
          },
    );
    final container = buildContainer(
      articleStream: controller.stream,
      appSettings: AppSettings.defaults().copyWith(autoTranslate: true),
      translationSettings: TranslationAiSettings.defaults().copyWith(
        targetLanguageTag: 'zh',
        defaultAiServiceId: service.id,
        aiServices: [service],
      ),
      secrets: FakeTranslationAiSecretStore(
        aiServiceApiKeys: <String, String>{service.id: 'secret-key'},
      ),
      translationService: translator,
    );

    final sub = container.listen<ArticleAiState>(
      articleAiControllerProvider(articleId),
      (previous, next) {},
      fireImmediately: true,
    );
    addTearDown(sub.close);

    await container.read(appSettingsProvider.future);
    await container.read(translationAiSettingsProvider.future);
    controller.add(
      buildArticle(
        html:
            '<p>Hello world repeated many times to make sure the language '
            'detector sees enough latin letters for auto translation. '
            'Hello world hello world hello world hello world.</p>',
        contentHash: 'hash-1',
      ),
    );
    await flushAsync();
    await container
        .read(articleAiControllerProvider(articleId).notifier)
        .ensureTranslation(mode: ArticleTranslationMode.immersive);
    await flushAsync();

    var state = container.read(articleAiControllerProvider(articleId));
    expect(state.translationStatus, ArticleAiTaskStatus.ready);
    expect(state.translationHtml, contains('[zh] Hello world'));

    controller.add(
      buildArticle(html: '<p>Updated article text</p>', contentHash: 'hash-2'),
    );
    await flushAsync();

    state = container.read(articleAiControllerProvider(articleId));
    expect(state.translationStatus, ArticleAiTaskStatus.idle);
    expect(state.translationHtml, isNull);

    await container
        .read(articleAiControllerProvider(articleId).notifier)
        .ensureTranslation(mode: ArticleTranslationMode.immersive);
    await flushAsync();

    state = container.read(articleAiControllerProvider(articleId));
    expect(state.translationStatus, ArticleAiTaskStatus.ready);
    expect(state.translationHtml, contains('[zh] Updated article text'));
    expect(translator.translatedInputs, hasLength(2));
    expect(translator.translatedInputs.first, contains('Hello world'));
    expect(translator.translatedInputs.last, 'Updated article text');
  });
}
