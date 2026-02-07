import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/app_settings_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/service_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../../services/settings/app_settings.dart';
import '../../../services/settings/reader_settings.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/context_extensions.dart';
import '../../../utils/platform.dart';
import '../widgets/section_header.dart';
import '../widgets/slider_tile.dart';
import '../widgets/theme_radio_item.dart';

class AppPreferencesTab extends ConsumerWidget {
  const AppPreferencesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final appSettings =
        ref.watch(appSettingsProvider).valueOrNull ?? const AppSettings();
    final readerSettings =
        ref.watch(readerSettingsProvider).valueOrNull ?? const ReaderSettings();

    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Language
                SectionHeader(title: l10n.language),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: appSettings.localeTag,
                      isExpanded: true,
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(l10n.systemLanguage),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'en',
                          child: Text(l10n.english),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'zh',
                          child: Text(l10n.chineseSimplified),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'zh-Hant',
                          child: Text(l10n.chineseTraditional),
                        ),
                      ],
                      onChanged: (v) {
                        unawaited(() async {
                          await ref
                              .read(appSettingsProvider.notifier)
                              .setLocaleTag(v);
                          if (!context.mounted) return;
                          if (!isMacOS) return;
                          context.showSnack(l10n.macosMenuLanguageRestartHint);
                        }());
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Theme
                SectionHeader(title: l10n.theme),
                RadioGroup<ThemeMode>(
                  groupValue: appSettings.themeMode,
                  onChanged: (v) {
                    if (v == null) return;
                    unawaited(
                      ref.read(appSettingsProvider.notifier).setThemeMode(v),
                    );
                  },
                  child: Column(
                    children: [
                      ThemeRadioItem(
                        label: l10n.system,
                        value: ThemeMode.system,
                      ),
                      ThemeRadioItem(label: l10n.light, value: ThemeMode.light),
                      ThemeRadioItem(label: l10n.dark, value: ThemeMode.dark),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Reader Settings (Font Size, etc.)
                SectionHeader(title: l10n.readerSettings),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.autoMarkRead),
                  value: appSettings.autoMarkRead,
                  onChanged: (v) =>
                      ref.read(appSettingsProvider.notifier).setAutoMarkRead(v),
                ),
                SliderTile(
                  title: l10n.fontSize,
                  value: readerSettings.fontSize,
                  min: 12,
                  max: 28,
                  format: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => ref
                      .read(readerSettingsProvider.notifier)
                      .save(readerSettings.copyWith(fontSize: v)),
                ),
                SliderTile(
                  title: l10n.lineHeight,
                  value: readerSettings.lineHeight,
                  min: 1.1,
                  max: 2.2,
                  format: (v) => v.toStringAsFixed(1),
                  onChanged: (v) => ref
                      .read(readerSettingsProvider.notifier)
                      .save(readerSettings.copyWith(lineHeight: v)),
                ),
                SliderTile(
                  title: l10n.horizontalPadding,
                  value: readerSettings.horizontalPadding,
                  min: 8,
                  max: 32,
                  format: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => ref
                      .read(readerSettingsProvider.notifier)
                      .save(readerSettings.copyWith(horizontalPadding: v)),
                ),
                const SizedBox(height: 24),

                // Cleanup
                SectionHeader(title: l10n.storage),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(l10n.clearImageCacheSubtitle)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () async {
                          await ref.read(cacheManagerProvider).emptyCache();
                          await ref.read(imageMetaStoreProvider).clear();
                          if (!context.mounted) return;
                          context.showSnack(l10n.cacheCleared);
                        },
                        child: Text(l10n.clearImageCache),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.cleanupReadArticles,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButton<int?>(
                              value: appSettings.cleanupReadOlderThanDays,
                              isExpanded: true,
                              items: [
                                DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text(l10n.off),
                                ),
                                for (final d in const [7, 30, 90, 180])
                                  DropdownMenuItem<int?>(
                                    value: d,
                                    child: Text(l10n.days(d)),
                                  ),
                              ],
                              onChanged: (v) => ref
                                  .read(appSettingsProvider.notifier)
                                  .setCleanupReadOlderThanDays(v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed:
                                appSettings.cleanupReadOlderThanDays == null
                                ? null
                                : () async {
                                    final days =
                                        appSettings.cleanupReadOlderThanDays!;
                                    final cutoff = DateTime.now()
                                        .toUtc()
                                        .subtract(Duration(days: days));
                                    final n = await ref
                                        .read(articleRepositoryProvider)
                                        .deleteReadUnstarredOlderThan(cutoff);
                                    if (!context.mounted) return;
                                    context.showSnack(l10n.cleanedArticles(n));
                                  },
                            child: Text(l10n.cleanupNow),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
