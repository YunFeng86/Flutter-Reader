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

enum _MinifluxAuthMode { apiToken, basicAuth }

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

    Future<void> addMiniflux() async {
      final nameCtrl = TextEditingController(text: l10n.miniflux);
      final baseUrlCtrl = TextEditingController();
      final tokenCtrl = TextEditingController();
      final usernameCtrl = TextEditingController();
      final passwordCtrl = TextEditingController();
      bool obscureToken = true;
      bool obscurePassword = true;
      var authMode = _MinifluxAuthMode.apiToken;

      Future<void> submit(StateSetter setState) async {
        final name = nameCtrl.text.trim();
        final baseUrl = baseUrlCtrl.text.trim();
        final token = tokenCtrl.text.trim();
        final username = usernameCtrl.text.trim();
        final password = passwordCtrl.text;
        final uri = Uri.tryParse(baseUrl);
        final hasCreds = switch (authMode) {
          _MinifluxAuthMode.apiToken => token.isNotEmpty,
          _MinifluxAuthMode.basicAuth =>
            username.isNotEmpty && password.isNotEmpty,
        };
        if (name.isEmpty || baseUrl.isEmpty || !hasCreds) {
          context.showSnack(l10n.errorMessage(l10n.missingRequiredFields));
          return;
        }
        if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
          context.showSnack(l10n.errorMessage(l10n.invalidBaseUrl));
          return;
        }

        final id = await ref
            .read(accountsControllerProvider.notifier)
            .addAccount(
              type: AccountType.miniflux,
              name: name,
              baseUrl: baseUrl,
            );
        final store = ref.read(credentialStoreProvider);
        switch (authMode) {
          case _MinifluxAuthMode.apiToken:
            await store.setApiToken(id, AccountType.miniflux, token);
            // Strict mode: only keep one auth mechanism on disk.
            await store.deleteBasicAuth(id, AccountType.miniflux);
            break;
          case _MinifluxAuthMode.basicAuth:
            await store.setBasicAuth(
              id,
              AccountType.miniflux,
              username: username,
              password: password,
            );
            await store.deleteApiToken(id, AccountType.miniflux);
            break;
        }
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
                title: Text(l10n.addMiniflux),
                content: SizedBox(
                  width: 520,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration: InputDecoration(labelText: l10n.fieldName),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: baseUrlCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.baseUrl,
                          hintText: l10n.minifluxBaseUrlHint,
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.authenticationMethod,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: Text(l10n.apiToken),
                            selected: authMode == _MinifluxAuthMode.apiToken,
                            onSelected: (v) {
                              if (!v) return;
                              setState(
                                () => authMode = _MinifluxAuthMode.apiToken,
                              );
                            },
                          ),
                          ChoiceChip(
                            label: Text(l10n.usernamePassword),
                            selected: authMode == _MinifluxAuthMode.basicAuth,
                            onSelected: (v) {
                              if (!v) return;
                              setState(
                                () => authMode = _MinifluxAuthMode.basicAuth,
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.minifluxAuthHint,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      if (authMode == _MinifluxAuthMode.apiToken) ...[
                        TextField(
                          controller: tokenCtrl,
                          obscureText: obscureToken,
                          decoration: InputDecoration(
                            labelText: l10n.apiToken,
                            suffixIcon: IconButton(
                              tooltip: obscureToken ? l10n.show : l10n.hide,
                              icon: Icon(
                                obscureToken
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () =>
                                  setState(() => obscureToken = !obscureToken),
                            ),
                          ),
                        ),
                      ] else ...[
                        TextField(
                          controller: usernameCtrl,
                          decoration: InputDecoration(labelText: l10n.username),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: passwordCtrl,
                          obscureText: obscurePassword,
                          decoration: InputDecoration(
                            labelText: l10n.password,
                            suffixIcon: IconButton(
                              tooltip: obscurePassword ? l10n.show : l10n.hide,
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () => setState(
                                () => obscurePassword = !obscurePassword,
                              ),
                            ),
                          ),
                        ),
                      ],
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
      final nameCtrl = TextEditingController(text: l10n.local);
      if (!context.mounted) return;
      final name = await showDialog<String?>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(l10n.addLocalAccount),
            content: TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: l10n.fieldName),
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
                          OutlinedButton(
                            onPressed: addLocal,
                            child: Text(l10n.addLocal),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: addMiniflux,
                            child: Text(l10n.addMiniflux),
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
