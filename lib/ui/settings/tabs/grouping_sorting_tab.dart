import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/app_settings_providers.dart';
import '../../../services/settings/app_settings.dart';
import '../widgets/section_header.dart';

class GroupingSortingTab extends ConsumerWidget {
  const GroupingSortingTab({super.key, this.showPageTitle = true});

  final bool showPageTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final appSettings =
        ref.watch(appSettingsProvider).valueOrNull ?? AppSettings.defaults();

    return SettingsPageBody(
      children: [
        if (showPageTitle) ...[
          SectionHeader(title: l10n.groupingAndSorting),
          const SizedBox(height: 8),
        ],
        SettingsSection(
          title: l10n.groupBy,
          child: SettingsCard(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
        ),
        SettingsSection(
          title: l10n.sortOrder,
          bottomSpacing: 0,
          child: SettingsCard(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
        ),
      ],
    );
  }
}
