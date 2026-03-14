import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fleur/models/article.dart';
import 'package:fleur/models/feed.dart';
import 'package:fleur/providers/app_settings_providers.dart';
import 'package:fleur/providers/article_ai_providers.dart';
import 'package:fleur/providers/query_providers.dart';
import 'package:fleur/providers/reader_providers.dart';
import 'package:fleur/providers/reader_search_providers.dart';
import 'package:fleur/providers/service_providers.dart';
import 'package:fleur/providers/settings_providers.dart';
import 'package:fleur/providers/translation_ai_settings_providers.dart';
import 'package:fleur/services/settings/app_settings.dart';
import 'package:fleur/services/settings/reader_progress_store.dart';
import 'package:fleur/services/settings/reader_settings.dart';
import 'package:fleur/services/settings/translation_ai_settings.dart';
import 'package:fleur/widgets/reader_view.dart';

import '../test_utils/critical_workflow_test_support.dart';

class _FakeFullTextController extends FullTextController {
  static int fetchCalls = 0;
  static Future<bool> Function(
    _FakeFullTextController controller,
    int articleId,
  )?
  onFetch;

  @override
  Future<void> build() async {}

  @override
  Future<bool> fetch(int articleId) async {
    fetchCalls++;
    final handler = onFetch;
    if (handler != null) {
      return handler(this, articleId);
    }
    return false;
  }
}

void main() {
  const articleId = 7;

  Future<void> settleReader(WidgetTester tester, {int rounds = 20}) async {
    for (var i = 0; i < rounds; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Feed buildFeed() {
    return Feed()
      ..id = 70
      ..url = 'https://example.com/feed.xml'
      ..title = 'Feed'
      ..categoryId = 5;
  }

  Article buildArticle({
    String? html,
    bool isRead = false,
    String? contentHash = 'reader-hash',
  }) {
    return Article()
      ..id = articleId
      ..feedId = 70
      ..categoryId = 5
      ..link = 'https://example.com/article'
      ..title = 'Reader Article'
      ..contentHtml = html ?? '<p>Hello world</p>'
      ..contentHash = contentHash
      ..isRead = isRead
      ..publishedAt = DateTime.utc(2026, 1, 2)
      ..updatedAt = DateTime.utc(2026, 1, 2);
  }

  Future<void> pumpReader(
    WidgetTester tester, {
    required Article article,
    AppSettings? appSettings,
    TranslationAiSettings? translationSettings,
    RecordingArticleActionService? actionService,
    InMemoryReaderProgressStore? progressStore,
    InMemoryImageMetaStore? imageMetaStore,
    FakeTranslationService? translationService,
    ImmediateAiRequestQueue? aiQueue,
    InMemoryAiContentCacheStore? cacheStore,
    FakeTranslationAiSecretStore? secretStore,
    Size size = const Size(800, 1200),
  }) async {
    _FakeFullTextController.onFetch = null;
    _FakeFullTextController.fetchCalls = 0;
    addTearDown(() => _FakeFullTextController.onFetch = null);

    await pumpLocalizedTestApp(
      tester,
      home: ReaderView(articleId: articleId),
      overrides: [
        appSettingsStoreProvider.overrideWithValue(
          FakeAppSettingsStore(appSettings ?? AppSettings.defaults()),
        ),
        readerSettingsStoreProvider.overrideWithValue(
          FakeReaderSettingsStore(const ReaderSettings()),
        ),
        translationAiSettingsStoreProvider.overrideWithValue(
          FakeTranslationAiSettingsStore(
            translationSettings ?? TranslationAiSettings.defaults(),
          ),
        ),
        translationAiSecretStoreProvider.overrideWithValue(
          secretStore ?? FakeTranslationAiSecretStore(),
        ),
        articleProvider(articleId).overrideWith((ref) => Stream.value(article)),
        feedsProvider.overrideWith((ref) => Stream.value([buildFeed()])),
        readerProgressStoreProvider.overrideWithValue(
          progressStore ?? InMemoryReaderProgressStore(),
        ),
        imageMetaStoreProvider.overrideWithValue(
          imageMetaStore ?? InMemoryImageMetaStore(),
        ),
        articleActionServiceProvider.overrideWithValue(
          actionService ?? RecordingArticleActionService(),
        ),
        translationServiceProvider.overrideWithValue(
          translationService ?? FakeTranslationService(),
        ),
        aiContentCacheStoreProvider.overrideWithValue(
          cacheStore ?? InMemoryAiContentCacheStore(),
        ),
        aiRequestQueueProvider.overrideWithValue(
          aiQueue ?? ImmediateAiRequestQueue(),
        ),
        fullTextControllerProvider.overrideWith(_FakeFullTextController.new),
      ],
      size: size,
    );
    await settleReader(tester, rounds: 8);
  }

  testWidgets('marks article as read when opening the reader', (tester) async {
    final actionService = RecordingArticleActionService();

    await pumpReader(
      tester,
      article: buildArticle(isRead: false),
      appSettings: AppSettings.defaults().copyWith(autoMarkRead: true),
      actionService: actionService,
    );

    expect(actionService.markReadCalls, [(articleId: articleId, isRead: true)]);
  });

  testWidgets('full-text button triggers fetch from reader action', (
    tester,
  ) async {
    _FakeFullTextController.onFetch = (controller, _) async {
      return false;
    };

    await pumpReader(
      tester,
      article: buildArticle(),
      appSettings: AppSettings.defaults().copyWith(autoMarkRead: false),
    );

    await tester.tap(find.byKey(const Key('reader_full_text_button')));
    await tester.pump();
    await settleReader(tester, rounds: 4);
    expect(_FakeFullTextController.fetchCalls, 1);
  });

  testWidgets('translate button drives translation and find-in-page search', (
    tester,
  ) async {
    final translationService = FakeTranslationService(
      onTranslateText:
          ({
            required provider,
            required settings,
            required secrets,
            required text,
            required targetLanguageTag,
          }) async {
            return 'bonjour';
          },
    );

    await pumpReader(
      tester,
      article: buildArticle(
        html:
            '<p>Hello world repeated many times to make sure the reader '
            'AI flow detects English content reliably before translation. '
            'Hello world hello world hello world hello world.</p>',
      ),
      appSettings: AppSettings.defaults().copyWith(autoMarkRead: false),
      translationSettings: TranslationAiSettings.defaults().copyWith(
        targetLanguageTag: 'fr',
      ),
      translationService: translationService,
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(ReaderView)),
    );
    await tester.tap(find.byKey(const Key('reader_translate_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Immersive translation').last);
    await settleReader(tester, rounds: 8);
    expect(
      container.read(articleAiControllerProvider(articleId)).translationHtml,
      contains('bonjour'),
    );

    container.read(readerSearchControllerProvider(articleId).notifier).open();
    container
        .read(readerSearchControllerProvider(articleId).notifier)
        .setQuery('bonjour');
    await settleReader(tester, rounds: 5);

    expect(find.text('Find in page'), findsOneWidget);
    expect(
      container.read(readerSearchControllerProvider(articleId)).totalMatches,
      1,
    );
  });

  testWidgets('saves reading progress after scrolling', (tester) async {
    final progressStore = InMemoryReaderProgressStore();
    final longHtml = List<String>.generate(
      300,
      (index) => '<p>Paragraph ${index + 1} ${'content ' * 32}</p>',
    ).join();
    final article = buildArticle(html: longHtml);

    await pumpReader(
      tester,
      article: article,
      appSettings: AppSettings.defaults().copyWith(autoMarkRead: false),
      progressStore: progressStore,
      size: const Size(560, 320),
    );
    await settleReader(tester, rounds: 100);

    final scrollableStates = tester
        .stateList<ScrollableState>(find.byType(Scrollable))
        .where((state) => state.position.maxScrollExtent > 0)
        .toList(growable: false);
    expect(scrollableStates, isNotEmpty);
    final scrollableState = scrollableStates.first;
    final targetOffset = scrollableState.position.maxScrollExtent * 0.8;
    scrollableState.position.jumpTo(targetOffset);
    await settleReader(tester, rounds: 4);
    final firstScrollPosition = scrollableState.position.pixels;
    expect(firstScrollPosition, greaterThan(0));
    await settleReader(tester, rounds: 15);
    final saved = await progressStore.getProgress(
      articleId: articleId,
      contentHash: 'reader-hash',
    );
    expect(saved, isNotNull);
    expect(saved!.pixels, greaterThan(0));
  });

  testWidgets('restores reading progress after reopening the article', (
    tester,
  ) async {
    final progressStore = InMemoryReaderProgressStore();
    final longHtml = List<String>.generate(
      300,
      (index) => '<p>Paragraph ${index + 1} ${'content ' * 32}</p>',
    ).join();
    final article = buildArticle(html: longHtml);
    await progressStore.saveProgress(
      ReaderProgress(
        articleId: articleId,
        contentHash: 'reader-hash',
        pixels: 900,
        progress: 0.45,
        updatedAt: DateTime.utc(2026, 1, 1),
      ),
    );

    await pumpReader(
      tester,
      article: article,
      appSettings: AppSettings.defaults().copyWith(autoMarkRead: false),
      progressStore: progressStore,
      size: const Size(560, 320),
    );

    await settleReader(tester, rounds: 100);
    final restoredPixels = tester
        .stateList<ScrollableState>(find.byType(Scrollable))
        .firstWhere((state) => state.position.maxScrollExtent > 0)
        .position
        .pixels;
    final restoredScrollState = tester
        .stateList<ScrollableState>(find.byType(Scrollable))
        .firstWhere((state) => state.position.maxScrollExtent > 0);
    final expectedOffset = restoredScrollState.position.maxScrollExtent * 0.45;

    expect(restoredPixels, greaterThan(0));
    expect(restoredPixels, closeTo(expectedOffset, 40));
  });
}
