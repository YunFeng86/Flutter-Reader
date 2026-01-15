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
    final appSettings = ref.watch(appSettingsProvider).valueOrNull ?? const AppSettings();
    final readerSettings =
        ref.watch(readerSettingsProvider).valueOrNull ?? const ReaderSettings();

    String themeLabel(ThemeMode mode) => switch (mode) {
          ThemeMode.system => l10n.system,
          ThemeMode.light => l10n.light,
          ThemeMode.dark => l10n.dark,
        };

    String languageLabel(String? tag) => switch (tag) {
          null => l10n.systemLanguage,
          'en' => l10n.english,
          'zh' => l10n.chineseSimplified,
          'zh-Hant' || 'zh_Hant' => l10n.chineseTraditional,
          _ => tag,
        };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _Section(
            title: l10n.appearance,
            children: [
              ListTile(
                title: Text(l10n.theme),
                subtitle: Text(themeLabel(appSettings.themeMode)),
                trailing: SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(value: ThemeMode.system, label: Text(l10n.system)),
                    ButtonSegment(value: ThemeMode.light, label: Text(l10n.light)),
                    ButtonSegment(value: ThemeMode.dark, label: Text(l10n.dark)),
                  ],
                  selected: {appSettings.themeMode},
                  onSelectionChanged: (s) => ref
                      .read(appSettingsProvider.notifier)
                      .setThemeMode(s.first),
                ),
              ),
              ListTile(
                title: Text(l10n.language),
                subtitle: Text(languageLabel(appSettings.localeTag)),
                trailing: DropdownButton<String?>(
                  value: appSettings.localeTag,
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
            ],
          ),
          _Section(
            title: l10n.reader,
            children: [
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
            ],
          ),
          _Section(
            title: l10n.storage,
            children: [
              ListTile(
                title: Text(l10n.clearImageCache),
                subtitle: Text(l10n.clearImageCacheSubtitle),
                trailing: const Icon(Icons.delete_outline),
                onTap: () async {
                  await ref.read(cacheManagerProvider).emptyCache();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.cacheCleared)),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(title, style: Theme.of(context).textTheme.titleSmall),
        ),
        ...children,
        const Divider(height: 1),
      ],
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
    return ListTile(
      title: Text(title),
      subtitle: Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        onChanged: onChanged,
      ),
      trailing: Text(format(value)),
    );
  }
}
