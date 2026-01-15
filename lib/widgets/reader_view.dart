import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_reader/l10n/app_localizations.dart';

import '../providers/reader_providers.dart';
import '../providers/query_providers.dart';
import '../providers/repository_providers.dart';
import '../providers/service_providers.dart';
import '../providers/settings_providers.dart';
import '../services/settings/reader_settings.dart';

class ReaderView extends ConsumerWidget {
  const ReaderView({super.key, required this.articleId, this.embedded = false});

  final int articleId;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(fullTextControllerProvider, (prev, next) {
      if (next.hasError) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.fullTextFailed(next.error.toString()))),
        );
      }
    });

    ref.listen(articleProvider(articleId), (prev, next) {
      final a = next.valueOrNull;
      if (a != null && !a.isRead) {
        ref.read(articleRepositoryProvider).markRead(articleId, true);
      }

      final prevA = prev?.valueOrNull;
      final prevHtml = (prevA?.fullContentHtml ?? prevA?.contentHtml ?? '').trim();
      final html = (a?.fullContentHtml ?? a?.contentHtml ?? '').trim();
      if (a == null || html.isEmpty) return;
      if (prevA != null && prevA.id == a.id && prevHtml == html) return;
      unawaited(
        ref.read(articleCacheServiceProvider).prefetchImagesFromHtml(
              html,
              baseUrl: Uri.tryParse(a.link),
            ),
      );
    });

    final a = ref.watch(articleProvider(articleId));
    final fullText = ref.watch(fullTextControllerProvider);
    final settingsAsync = ref.watch(readerSettingsProvider);
    return a.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(AppLocalizations.of(context)!.errorMessage(e.toString()))),
      data: (article) {
        final l10n = AppLocalizations.of(context)!;
        if (article == null) return Center(child: Text(l10n.notFound));

        final settings = settingsAsync.valueOrNull ?? const ReaderSettings();
        final html = (article.fullContentHtml ?? article.contentHtml ?? '').trim();
        final title =
            article.title?.trim().isNotEmpty == true ? article.title! : l10n.reader;

        final hasFull = (article.fullContentHtml ?? '').trim().isNotEmpty;
        final actions = <Widget>[
          IconButton(
            tooltip: l10n.fullText,
            onPressed: (hasFull || fullText.isLoading)
                ? null
                : () => ref
                    .read(fullTextControllerProvider.notifier)
                    .fetch(articleId),
            icon: fullText.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chrome_reader_mode),
          ),
          IconButton(
            tooltip: l10n.readerSettings,
            onPressed: () => _showReaderSettings(context, ref, settings),
            icon: const Icon(Icons.text_fields),
          ),
          IconButton(
            tooltip: article.isStarred ? l10n.unstar : l10n.star,
            onPressed: () =>
                ref.read(articleRepositoryProvider).toggleStar(articleId),
            icon: Icon(article.isStarred ? Icons.star : Icons.star_border),
          ),
          IconButton(
            tooltip: article.isRead ? l10n.markUnread : l10n.markRead,
            onPressed: () =>
                ref.read(articleRepositoryProvider).markRead(articleId, !article.isRead),
            icon: Icon(
              article.isRead ? Icons.mark_email_unread : Icons.mark_email_read,
            ),
          ),
        ];

        final content = html.isEmpty
            ? Center(child: Text(article.link))
            : SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  settings.horizontalPadding,
                  12,
                  settings.horizontalPadding,
                  48,
                ),
                child: HtmlWidget(
                  html,
                  baseUrl: Uri.tryParse(article.link),
                  textStyle: TextStyle(
                    fontSize: settings.fontSize,
                    height: settings.lineHeight,
                  ),
                  onTapUrl: (url) async {
                    final uri = Uri.tryParse(url);
                    if (uri == null) return false;
                    return launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  onTapImage: (meta) {
                    final src = meta.sources.isNotEmpty ? meta.sources.first.url : null;
                    if (src == null || src.trim().isEmpty) return;
                    showDialog<void>(
                      context: context,
                      builder: (context) {
                        return Dialog(
                          insetPadding: EdgeInsets.zero,
                          child: Stack(
                            children: [
                              InteractiveViewer(
                                child: Image.network(src, fit: BoxFit.contain),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(Icons.close),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              );

        if (!embedded) {
          return Scaffold(appBar: AppBar(title: Text(title), actions: actions), body: content);
        }

        return Column(
          children: [
            Material(
              color: Theme.of(context).colorScheme.surface,
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    ...actions,
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(child: content),
          ],
        );
      },
    );
  }

  Future<void> _showReaderSettings(
    BuildContext context,
    WidgetRef ref,
    ReaderSettings settings,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        var cur = settings;
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.readerSettings,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await ref
                                .read(readerSettingsProvider.notifier)
                                .save(cur);
                            if (!context.mounted) return;
                            Navigator.of(context).pop();
                          },
                          child: Text(l10n.done),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _slider(
                      label: l10n.fontSize,
                      value: cur.fontSize,
                      min: 12,
                      max: 28,
                      onChanged: (v) => setState(() => cur = cur.copyWith(fontSize: v)),
                    ),
                    _slider(
                      label: l10n.lineHeight,
                      value: cur.lineHeight,
                      min: 1.1,
                      max: 2.2,
                      onChanged: (v) =>
                          setState(() => cur = cur.copyWith(lineHeight: v)),
                    ),
                    _slider(
                      label: l10n.horizontalPadding,
                      value: cur.horizontalPadding,
                      min: 8,
                      max: 32,
                      onChanged: (v) =>
                          setState(() => cur = cur.copyWith(horizontalPadding: v)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _slider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(value.toStringAsFixed(1)),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
