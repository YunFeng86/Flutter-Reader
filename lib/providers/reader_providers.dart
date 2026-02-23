import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'repository_providers.dart';
import 'app_settings_providers.dart';
import 'service_providers.dart';
import '../services/settings/reader_progress_store.dart';

final readerProgressStoreProvider = Provider<ReaderProgressStore>((ref) {
  return ReaderProgressStore();
});

enum ArticleExtractionErrorType { emptyContent }

class ArticleExtractionException implements Exception {
  const ArticleExtractionException(this.type);

  final ArticleExtractionErrorType type;

  @override
  String toString() => 'ArticleExtractionException($type)';
}

class FullTextController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Fetches full text for the given article.
  ///
  /// Returns `true` if extracted content is available after the call.
  /// Returns `false` when the request fails or the extractor returns empty.
  Future<bool> fetch(int articleId) async {
    var ok = false;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(articleRepositoryProvider);
      final article = await repo.getById(articleId);
      if (article == null) return;
      if (article.extractedContentHtml != null &&
          article.extractedContentHtml!.trim().isNotEmpty) {
        ok = true;
        return;
      }
      final settings = ref.read(appSettingsProvider).valueOrNull;
      final extracted = await ref
          .read(articleExtractorProvider)
          .extract(article.link, userAgent: settings?.webUserAgent);
      if (extracted.contentHtml.trim().isEmpty) {
        await repo.markExtractionFailed(articleId);
        throw const ArticleExtractionException(
          ArticleExtractionErrorType.emptyContent,
        );
      }
      await repo.setExtractedContent(articleId, extracted.contentHtml);
      await ref
          .read(articleCacheServiceProvider)
          .prefetchImagesFromHtml(
            extracted.contentHtml,
            baseUrl: Uri.tryParse(article.link),
          );
      ok = true;
    });
    return ok;
  }
}

final fullTextControllerProvider =
    AutoDisposeAsyncNotifierProvider<FullTextController, void>(
      FullTextController.new,
      dependencies: [articleRepositoryProvider],
    );
