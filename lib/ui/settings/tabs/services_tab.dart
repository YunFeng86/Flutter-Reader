import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/account_providers.dart';
import '../../../providers/app_settings_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/service_providers.dart';
import '../../../services/accounts/account.dart';
import '../../../services/settings/app_settings.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/context_extensions.dart';
import '../../dialogs/add_account_dialogs.dart';
import '../widgets/section_header.dart';
import '../../../widgets/account_manager_sheet.dart';

class ServicesTab extends ConsumerWidget {
  const ServicesTab({super.key, this.showPageTitle = true});

  final bool showPageTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final appSettings =
        ref.watch(appSettingsProvider).valueOrNull ?? AppSettings.defaults();
    final accounts = ref.watch(accountsControllerProvider).valueOrNull;
    final activeAccount = ref.watch(activeAccountProvider);

    final interval = appSettings.autoRefreshMinutes;

    Future<void> refreshNow() async {
      final feeds = await ref.read(feedRepositoryProvider).getAll();
      // Remote-backed accounts can sync even when local DB is empty.
      if (feeds.isEmpty && activeAccount.type == AccountType.local) return;

      final concurrency = appSettings.autoRefreshConcurrency;

      if (!context.mounted) return;
      final navigator = Navigator.of(context, rootNavigator: true);

      // Show progress dialog.
      final progressNotifier = ValueNotifier<String>('0/${feeds.length}');
      try {
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

        final err = batch.firstError?.error;
        if (!context.mounted) return;
        context.showSnack(
          err == null ? l10n.refreshedAll : l10n.errorMessage(err.toString()),
        );
      } finally {
        // Close progress dialog even if the settings page was popped.
        try {
          if (navigator.mounted && navigator.canPop()) {
            navigator.pop();
          }
        } catch (_) {
          // ignore: best-effort cleanup
        }
        progressNotifier.dispose();
      }
    }

    Future<void> addAccount() async {
      final picked = await showModalBottomSheet<AccountType>(
        context: context,
        showDragHandle: true,
        builder: (context) {
          return SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.rss_feed),
                  title: Text(l10n.addLocal),
                  onTap: () => Navigator.of(context).pop(AccountType.local),
                ),
                ListTile(
                  leading: const Icon(Icons.cloud_outlined),
                  title: Text(l10n.addMiniflux),
                  onTap: () => Navigator.of(context).pop(AccountType.miniflux),
                ),
              ],
            ),
          );
        },
      );
      if (picked == null || !context.mounted) return;
      switch (picked) {
        case AccountType.local:
          await showAddLocalAccountDialog(context, ref);
          return;
        case AccountType.miniflux:
          await showAddMinifluxAccountDialog(context, ref);
          return;
        case AccountType.fever:
          context.showSnack(l10n.comingSoon);
          return;
      }
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
                if (showPageTitle) SectionHeader(title: l10n.services),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.account,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: activeAccount.id,
                                isExpanded: true,
                                items: (accounts?.accounts ?? const [])
                                    .map(
                                      (a) => DropdownMenuItem<String>(
                                        value: a.id,
                                        child: Text(
                                          '${a.name} (${a.type.wire})',
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                                onChanged: (v) {
                                  if (v == null) return;
                                  unawaited(
                                    ref
                                        .read(
                                          accountsControllerProvider.notifier,
                                        )
                                        .setActive(v),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: addAccount,
                            icon: const Icon(Icons.add),
                            label: Text(l10n.add),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: l10n.more,
                            onPressed: () async {
                              await showModalBottomSheet<void>(
                                context: context,
                                useRootNavigator: true,
                                showDragHandle: true,
                                builder: (context) =>
                                    const AccountManagerSheet(),
                              );
                            },
                            icon: const Icon(Icons.manage_accounts_outlined),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
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
                      const SizedBox(height: 16),
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
                if (activeAccount.type == AccountType.miniflux) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.minifluxStrategy,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.minifluxStrategySubtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.minifluxEntriesLimit,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: appSettings.minifluxEntriesLimit,
                            isExpanded: true,
                            items: [
                              for (final v in const [100, 200, 400, 800, 1200])
                                DropdownMenuItem(value: v, child: Text('$v')),
                              DropdownMenuItem(
                                value: 0,
                                child: Text(l10n.unlimited),
                              ),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              unawaited(
                                ref
                                    .read(appSettingsProvider.notifier)
                                    .setMinifluxEntriesLimit(v),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.minifluxWebFetchMode,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.minifluxWebFetchModeSubtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<MinifluxWebFetchMode>(
                            value: appSettings.minifluxWebFetchMode,
                            isExpanded: true,
                            items: [
                              DropdownMenuItem(
                                value: MinifluxWebFetchMode.clientReadability,
                                child: Text(l10n.minifluxWebFetchModeClient),
                              ),
                              DropdownMenuItem(
                                value: MinifluxWebFetchMode.serverFetchContent,
                                child: Text(l10n.minifluxWebFetchModeServer),
                              ),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              unawaited(
                                ref
                                    .read(appSettingsProvider.notifier)
                                    .setMinifluxWebFetchMode(v),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
