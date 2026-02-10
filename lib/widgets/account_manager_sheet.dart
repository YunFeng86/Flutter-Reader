import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fleur/l10n/app_localizations.dart';

import '../providers/account_providers.dart';
import '../services/accounts/account.dart';
import '../ui/dialogs/add_account_dialogs.dart';
import '../ui/dialogs/text_input_dialog.dart';
import '../utils/context_extensions.dart';
import 'account_avatar.dart';

enum _AccountItemAction { rename, delete }

class AccountManagerSheet extends ConsumerWidget {
  const AccountManagerSheet({super.key});

  Future<void> _addAccount(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
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

  Future<void> _renameAccount(
    BuildContext context,
    WidgetRef ref,
    Account account,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final next = await showTextInputDialog(
      context,
      title: l10n.rename,
      labelText: l10n.fieldName,
      initialText: account.name,
      confirmText: l10n.done,
    );
    final trimmed = (next ?? '').trim();
    if (trimmed.isEmpty || trimmed == account.name) return;
    await ref
        .read(accountsControllerProvider.notifier)
        .renameAccount(account.id, trimmed);
    if (!context.mounted) return;
    context.showSnack(l10n.done);
  }

  Future<void> _deleteAccount(
    BuildContext context,
    WidgetRef ref,
    Account account,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (account.isPrimary) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.delete),
          content: Text('${l10n.delete} "${account.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );

    if (ok != true) return;
    await ref
        .read(accountsControllerProvider.notifier)
        .deleteAccount(account.id);
    if (!context.mounted) return;
    context.showSnack(l10n.done);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final accountsAsync = ref.watch(accountsControllerProvider);
    final active = ref.watch(activeAccountProvider);

    return accountsAsync.when(
      loading: () => const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => SizedBox(
        height: 240,
        child: Center(child: Text(l10n.errorMessage(e.toString()))),
      ),
      data: (state) {
        final accounts = state.accounts;

        return SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        l10n.account,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).closeButtonTooltip,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: accounts.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final a = accounts[index];
                      final isActive = a.id == active.id;
                      final subtitle = switch (a.type) {
                        AccountType.local => l10n.local,
                        AccountType.miniflux =>
                          (a.baseUrl ?? '').trim().isEmpty
                              ? l10n.miniflux
                              : a.baseUrl!.trim(),
                        AccountType.fever => l10n.comingSoon,
                      };

                      return ListTile(
                        leading: AccountAvatar(
                          account: a,
                          radius: 18,
                          showTypeBadge: true,
                        ),
                        title: Text(a.name),
                        subtitle: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isActive) const Icon(Icons.check),
                            PopupMenuButton<_AccountItemAction>(
                              tooltip: l10n.more,
                              onSelected: (action) async {
                                switch (action) {
                                  case _AccountItemAction.rename:
                                    await _renameAccount(context, ref, a);
                                    return;
                                  case _AccountItemAction.delete:
                                    await _deleteAccount(context, ref, a);
                                    return;
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: _AccountItemAction.rename,
                                  child: Text(l10n.rename),
                                ),
                                PopupMenuItem(
                                  value: _AccountItemAction.delete,
                                  enabled: !a.isPrimary,
                                  child: Text(l10n.delete),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () async {
                          if (isActive) {
                            Navigator.of(context).pop();
                            return;
                          }
                          await ref
                              .read(accountsControllerProvider.notifier)
                              .setActive(a.id);
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => unawaited(_addAccount(context, ref)),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.add),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
