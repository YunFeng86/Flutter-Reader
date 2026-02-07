import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/app_settings_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/service_providers.dart';
import '../../../services/settings/app_settings.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/context_extensions.dart';
import '../widgets/section_header.dart';

class ServicesTab extends ConsumerWidget {
  const ServicesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final appSettings =
        ref.watch(appSettingsProvider).valueOrNull ?? const AppSettings();

    final interval = appSettings.autoRefreshMinutes;

    Future<void> refreshNow() async {
      final feeds = await ref.read(feedRepositoryProvider).getAll();
      if (feeds.isEmpty) return;

      final concurrency = appSettings.autoRefreshConcurrency;

      if (!context.mounted) return;

      // Show progress dialog.
      final progressNotifier = ValueNotifier<String>('0/${feeds.length}');
      unawaited(
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return PopScope(
              canPop: false,
              child: AlertDialog(
                content: Row(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(width: 24),
                    ValueListenableBuilder<String>(
                      valueListenable: progressNotifier,
                      builder: (context, value, _) {
                        return Text(
                          l10n.refreshingProgress(
                            int.tryParse(value.split('/')[0]) ?? 0,
                            int.tryParse(value.split('/')[1]) ?? feeds.length,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ).then((_) {}),
      );

      final batch = await ref
          .read(syncServiceProvider)
          .refreshFeedsSafe(
            feeds.map((f) => f.id),
            maxConcurrent: concurrency,
            onProgress: (current, total) {
              progressNotifier.value = '$current/$total';
            },
          );

      if (!context.mounted) return;
      Navigator.of(context).pop(); // Close progress dialog.

      final err = batch.firstError?.error;
      context.showSnack(
        err == null ? l10n.refreshedAll : l10n.errorMessage(err.toString()),
      );
    }

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
                SectionHeader(title: l10n.services),
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
                        l10n.autoRefreshSubtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          value: interval,
                          isExpanded: true,
                          items: [
                            DropdownMenuItem<int?>(
                              value: null,
                              child: Text(l10n.off),
                            ),
                            for (final m in const [5, 15, 30, 60])
                              DropdownMenuItem<int?>(
                                value: m,
                                child: Text(l10n.everyMinutes(m)),
                              ),
                          ],
                          onChanged: (v) => ref
                              .read(appSettingsProvider.notifier)
                              .setAutoRefreshMinutes(v),
                        ),
                      ),
                      const Divider(height: 24),
                      Text(
                        l10n.refreshConcurrency,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: appSettings.autoRefreshConcurrency,
                          isExpanded: true,
                          items: [
                            for (final c in [1, 2, 4, 6])
                              DropdownMenuItem(
                                value: c,
                                child: Text(c.toString()),
                              ),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            unawaited(
                              ref
                                  .read(appSettingsProvider.notifier)
                                  .setAutoRefreshConcurrency(v),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: refreshNow,
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.refreshAll),
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
