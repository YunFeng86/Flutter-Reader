import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_reader/l10n/app_localizations.dart';

import '../providers/app_settings_providers.dart';
import '../providers/service_providers.dart';
import '../providers/settings_providers.dart';
import '../services/settings/app_settings.dart';
import '../services/settings/reader_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: null,
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(
                icon: const Icon(Icons.settings_outlined),
                text: l10n.appPreferences,
              ),
              Tab(
                icon: const Icon(Icons.rss_feed_outlined),
                text: l10n.subscriptions,
              ),
              Tab(
                icon: const Icon(Icons.format_list_bulleted),
                text: l10n.groupingAndSorting,
              ),
              Tab(
                icon: const Icon(Icons.filter_alt_outlined),
                text: l10n.rules,
              ),
              Tab(
                icon: const Icon(Icons.cloud_outlined),
                text: l10n.services,
              ),
              Tab(
                icon: const Icon(Icons.info_outline),
                text: l10n.about,
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const _AppPreferencesTab(),
            _PlaceholderTab(l10n.subscriptions),
            _PlaceholderTab(l10n.groupingAndSorting),
            _PlaceholderTab(l10n.rules),
            _PlaceholderTab(l10n.services),
            _PlaceholderTab(l10n.about),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
    );
  }
}

class _AppPreferencesTab extends ConsumerWidget {
  const _AppPreferencesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final appSettings =
        ref.watch(appSettingsProvider).valueOrNull ?? const AppSettings();
    final readerSettings =
        ref.watch(readerSettingsProvider).valueOrNull ?? const ReaderSettings();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Language
            _SectionHeader(title: l10n.language),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(4),
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
                  onChanged: (v) =>
                      ref.read(appSettingsProvider.notifier).setLocaleTag(v),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Theme
            _SectionHeader(title: l10n.theme),
            RadioGroup<ThemeMode>(
              groupValue: appSettings.themeMode,
              onChanged: (v) {
                if (v == null) return;
                ref.read(appSettingsProvider.notifier).setThemeMode(v);
              },
              child: Column(
                children: [
                  _ThemeRadioItem(
                    label: l10n.system,
                    value: ThemeMode.system,
                  ),
                  _ThemeRadioItem(
                    label: l10n.light,
                    value: ThemeMode.light,
                  ),
                  _ThemeRadioItem(
                    label: l10n.dark,
                    value: ThemeMode.dark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Reader Settings (Font Size, etc.)
            // Kept here to maintain functionality even though not strictly in reference image
            _SectionHeader(title: l10n.readerSettings),
            _SliderTile(
              title: l10n.fontSize,
              value: readerSettings.fontSize,
              min: 12,
              max: 28,
              format: (v) => v.toStringAsFixed(0),
              onChanged: (v) => ref
                  .read(readerSettingsProvider.notifier)
                  .save(readerSettings.copyWith(fontSize: v)),
            ),
            _SliderTile(
              title: l10n.lineHeight,
              value: readerSettings.lineHeight,
              min: 1.1,
              max: 2.2,
              format: (v) => v.toStringAsFixed(1),
              onChanged: (v) => ref
                  .read(readerSettingsProvider.notifier)
                  .save(readerSettings.copyWith(lineHeight: v)),
            ),
            _SliderTile(
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
            _SectionHeader(title: l10n.storage),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(l10n.clearImageCacheSubtitle),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () async {
                      await ref.read(cacheManagerProvider).emptyCache();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.cacheCleared)),
                      );
                    },
                    child: Text(l10n.clearImageCache),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _ThemeRadioItem extends StatelessWidget {
  const _ThemeRadioItem({
    required this.label,
    required this.value,
  });

  final String label;
  final ThemeMode value;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<ThemeMode>(
      title: Text(label),
      value: value,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.format,
  });

  final String title;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String Function(double v) format;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title),
            Text(format(value)),
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
