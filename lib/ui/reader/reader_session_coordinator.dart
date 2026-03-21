part of '../../widgets/reader_view.dart';

bool _shouldShowExtractedArticle(Article article) {
  final hasExtracted = (article.extractedContentHtml ?? '').trim().isNotEmpty;
  if (!hasExtracted) return false;
  return article.preferredContentView == ArticleContentView.extracted;
}

String _selectActiveHtmlForArticle(Article article) {
  final showExtracted = _shouldShowExtractedArticle(article);
  return ((showExtracted ? article.extractedContentHtml : null) ??
          article.contentHtml ??
          '')
      .trim();
}

final class _ReaderSessionCoordinator {
  _ReaderSessionCoordinator({
    required _ReaderViewState owner,
    required _ReaderViewportCoordinator viewportCoordinator,
  }) : _owner = owner,
       _viewportCoordinator = viewportCoordinator;

  final _ReaderViewState _owner;
  final _ReaderViewportCoordinator _viewportCoordinator;

  ProviderSubscription<AsyncValue<Article?>>? _articleSub;
  ProviderSubscription<String?>? _translationHtmlSub;

  WidgetRef get ref => _owner.ref;

  void dispose() {
    _articleSub?.close();
    _translationHtmlSub?.close();
  }

  void listenTranslationHtml(int articleId) {
    _translationHtmlSub?.close();
    _translationHtmlSub = ref.listenManual<String?>(
      articleAiControllerProvider(articleId).select((s) => s.translationHtml),
      (prev, next) {
        final search = ref.read(readerSearchControllerProvider(articleId));
        final prevTrimmed = (prev ?? '').trim();
        final nextTrimmed = (next ?? '').trim();
        final shouldUpdate =
            search.visible || prevTrimmed.isEmpty != nextTrimmed.isEmpty;
        if (!shouldUpdate) return;

        final article = ref.read(articleProvider(articleId)).valueOrNull;
        if (article == null) return;
        final originalHtml = _selectActiveHtmlForArticle(article);
        final displayHtml = nextTrimmed.isNotEmpty ? nextTrimmed : originalHtml;
        ref
            .read(readerSearchControllerProvider(articleId).notifier)
            .setDocumentHtml(displayHtml);
      },
      fireImmediately: false,
    );
  }

  void listenArticle(int articleId) {
    _articleSub?.close();
    var hasMarkedRead = false;
    _articleSub = ref.listenManual<AsyncValue<Article?>>(
      articleProvider(articleId),
      (prev, next) {
        final article = next.valueOrNull;

        if (!hasMarkedRead && article != null && !article.isRead) {
          final appSettings =
              ref.read(appSettingsProvider).valueOrNull ??
              AppSettings.defaults();
          if (appSettings.autoMarkRead) {
            unawaited(
              ref.read(articleActionServiceProvider).markRead(articleId, true),
            );
            hasMarkedRead = true;
          }
        }

        if (article != null) {
          _viewportCoordinator.requestContentHashUpdate(
            article: article,
            showExtracted: _shouldShowExtractedArticle(article),
          );
        }

        final previousArticle = prev?.valueOrNull;
        final previousHtml = previousArticle == null
            ? ''
            : _selectActiveHtmlForArticle(previousArticle);
        final originalHtml = article == null
            ? ''
            : _selectActiveHtmlForArticle(article);
        if (article == null || originalHtml.isEmpty) return;
        if (previousArticle != null &&
            previousArticle.id == article.id &&
            previousHtml == originalHtml) {
          return;
        }

        final translatedHtml =
            (ref.read(articleAiControllerProvider(articleId)).translationHtml ??
                    '')
                .trim();
        final displayHtml = translatedHtml.isNotEmpty
            ? translatedHtml
            : originalHtml;

        ref
            .read(readerSearchControllerProvider(articleId).notifier)
            .setDocumentHtml(displayHtml);

        final maxPrefetch = originalHtml.length >= 50000 ? 6 : 24;
        unawaited(
          ref
              .read(articleCacheServiceProvider)
              .prefetchImagesFromHtml(
                originalHtml,
                baseUrl: Uri.tryParse(article.link),
                maxImages: maxPrefetch,
                maxConcurrent: 3,
              ),
        );
      },
      fireImmediately: true,
    );
  }
}
