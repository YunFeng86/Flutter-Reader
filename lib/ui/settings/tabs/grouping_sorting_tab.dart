import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/app_settings_providers.dart';
import '../../../services/settings/app_settings.dart';
import '../../../theme/app_theme.dart';
import '../widgets/section_header.dart';

class GroupingSortingTab extends ConsumerWidget {
  const GroupingSortingTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final appSettings =
        ref.watch(appSettingsProvider).valueOrNull ?? AppSettings.defaults();

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            SectionHeader(title: l10n.groupingAndSorting),
            const SizedBox(height: 8),

            // Group by
            Text(l10n.groupBy, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ArticleGroupMode>(
                  value: appSettings.articleGroupMode,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(
                      value: ArticleGroupMode.none,
                      child: Text(l10n.groupNone),
                    ),
                    DropdownMenuItem(
                      value: ArticleGroupMode.day,
                      child: Text(l10n.groupByDay),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    unawaited(
                      ref
                          .read(appSettingsProvider.notifier)
                          .setArticleGroupMode(v),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Sort order
            Text(l10n.sortOrder, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ArticleSortOrder>(
                  value: appSettings.articleSortOrder,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(
                      value: ArticleSortOrder.newestFirst,
                      child: Text(l10n.sortNewestFirst),
                    ),
                    DropdownMenuItem(
                      value: ArticleSortOrder.oldestFirst,
                      child: Text(l10n.sortOldestFirst),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    unawaited(
                      ref
                          .read(appSettingsProvider.notifier)
                          .setArticleSortOrder(v),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
