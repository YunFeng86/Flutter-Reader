import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/query_providers.dart';
import '../../../../providers/subscription_settings_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/section_header.dart';

class CategoryListComponent extends ConsumerWidget {
  const CategoryListComponent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selection = ref.watch(subscriptionSelectionProvider);
    final l10n = AppLocalizations.of(context)!;

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (categories) {
        if (categories.isEmpty) {
          // If no categories exist at all, this column might be hidden or show empty state?
          // For now, allow selecting "Uncategorized" or "Global" (clear).
          // We always show "Uncategorized" if there are feeds there?
          // We can't easily know if there are uncategorized feeds without fetching feeds.
          // Let's assume we always show "Uncategorized" item if we are in this view.
        }

        return Scrollbar(
          child: ListView(
            primary: false,
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              for (final category in categories)
                SettingsTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(category.name),
                  selected: selection.activeCategoryId == category.id,
                  onTap: () {
                    ref
                        .read(subscriptionSelectionProvider.notifier)
                        .selectCategory(category.id);
                  },
                ),
              const SizedBox(height: 8),
              SettingsTile(
                title: Text(l10n.uncategorized),
                leading: const Icon(Icons.rss_feed),
                selected: selection.isUncategorized,
                onTap: () {
                  ref
                      .read(subscriptionSelectionProvider.notifier)
                      .selectUncategorized();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
