import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_settings_providers.dart';
import '../providers/service_providers.dart';
import '../providers/settings_providers.dart';
import '../services/settings/app_settings.dart';
import '../services/settings/reader_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appSettings = ref.watch(appSettingsProvider).valueOrNull ?? const AppSettings();
    final readerSettings =
        ref.watch(readerSettingsProvider).valueOrNull ?? const ReaderSettings();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _Section(
            title: 'Appearance',
            children: [
              ListTile(
                title: const Text('Theme'),
                subtitle: Text(appSettings.themeMode.name),
                trailing: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, label: Text('System')),
                    ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                  ],
                  selected: {appSettings.themeMode},
                  onSelectionChanged: (s) => ref
                      .read(appSettingsProvider.notifier)
                      .setThemeMode(s.first),
                ),
              ),
            ],
          ),
          _Section(
            title: 'Reader',
            children: [
              _SliderTile(
                title: 'Font size',
                value: readerSettings.fontSize,
                min: 12,
                max: 28,
                format: (v) => v.toStringAsFixed(0),
                onChanged: (v) => ref
                    .read(readerSettingsProvider.notifier)
                    .save(readerSettings.copyWith(fontSize: v)),
              ),
              _SliderTile(
                title: 'Line height',
                value: readerSettings.lineHeight,
                min: 1.1,
                max: 2.2,
                format: (v) => v.toStringAsFixed(1),
                onChanged: (v) => ref
                    .read(readerSettingsProvider.notifier)
                    .save(readerSettings.copyWith(lineHeight: v)),
              ),
              _SliderTile(
                title: 'Horizontal padding',
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
            title: 'Storage',
            children: [
              ListTile(
                title: const Text('Clear image cache'),
                subtitle: const Text('Remove cached images used for offline reading'),
                trailing: const Icon(Icons.delete_outline),
                onTap: () async {
                  await ref.read(cacheManagerProvider).emptyCache();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cache cleared')),
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

