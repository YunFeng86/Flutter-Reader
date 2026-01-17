import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'repository_providers.dart';
import 'service_providers.dart';

class FullTextController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> fetch(int articleId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(articleRepositoryProvider);
      final article = await repo.getById(articleId);
      if (article == null) return;
      if (article.fullContentHtml != null &&
          article.fullContentHtml!.trim().isNotEmpty) {
        return;
      }
      final extracted = await ref
          .read(articleExtractorProvider)
          .extract(article.link);
      await repo.setFullContent(articleId, extracted.contentHtml);
      await ref
          .read(articleCacheServiceProvider)
          .prefetchImagesFromHtml(
            extracted.contentHtml,
            baseUrl: Uri.tryParse(article.link),
          );
    });
  }
}

final fullTextControllerProvider =
    AutoDisposeAsyncNotifierProvider<FullTextController, void>(
      FullTextController.new,
    );

/// Whether the reader should show full text (when available) for a given
/// article. This is purely a view concern and is not persisted.
final fullTextViewEnabledProvider = StateProvider.autoDispose.family<bool, int>(
  (ref, articleId) => false,
);
