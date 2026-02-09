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
import '../widgets/section_header.dart';

class ServicesTab extends ConsumerWidget {
  const ServicesTab({super.key});

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

    Future<void> addMiniflux() async {
      final nameCtrl = TextEditingController(text: 'Miniflux');
      final baseUrlCtrl = TextEditingController();
      final tokenCtrl = TextEditingController();
      bool obscure = true;

      Future<void> submit(StateSetter setState) async {
        final name = nameCtrl.text.trim();
        final baseUrl = baseUrlCtrl.text.trim();
        final token = tokenCtrl.text.trim();
        final uri = Uri.tryParse(baseUrl);
        if (name.isEmpty || baseUrl.isEmpty || token.isEmpty) {
          context.showSnack(l10n.errorMessage('Missing required fields'));
          return;
        }
        if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
          context.showSnack(l10n.errorMessage('Invalid base URL'));
          return;
        }

        final id = await ref
            .read(accountsControllerProvider.notifier)
            .addAccount(
              type: AccountType.miniflux,
              name: name,
              baseUrl: baseUrl,
            );
        await ref
            .read(credentialStoreProvider)
            .setApiToken(id, AccountType.miniflux, token);
        await ref.read(accountsControllerProvider.notifier).setActive(id);
        if (!context.mounted) return;
        Navigator.of(context).pop();
        context.showSnack(l10n.done);
      }

      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Add Miniflux'),
                content: SizedBox(
                  width: 520,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Name'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: baseUrlCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Base URL',
                          hintText: 'https://miniflux.example.com',
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: tokenCtrl,
                        obscureText: obscure,
                        decoration: InputDecoration(
                          labelText: 'API Token',
                          suffixIcon: IconButton(
                            tooltip: obscure ? 'Show' : 'Hide',
                            icon: Icon(
                              obscure ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () => setState(() => obscure = !obscure),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                  FilledButton(
                    onPressed: () => submit(setState),
                    child: Text(l10n.add),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    Future<void> addLocal() async {
      final nameCtrl = TextEditingController(text: 'Local');
      if (!context.mounted) return;
      final name = await showDialog<String?>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Add Local Account'),
            content: TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(nameCtrl.text),
                child: Text(l10n.add),
              ),
            ],
          );
        },
      );
      if (name == null || name.trim().isEmpty) return;
      final id = await ref
          .read(accountsControllerProvider.notifier)
          .addAccount(type: AccountType.local, name: name.trim());
      await ref.read(accountsControllerProvider.notifier).setActive(id);
      if (!context.mounted) return;
      context.showSnack(l10n.done);
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
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Account',
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
                          OutlinedButton(
                            onPressed: addLocal,
                            child: const Text('Add Local'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: addMiniflux,
                            child: const Text('Add Miniflux'),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
