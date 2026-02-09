import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/account_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/service_providers.dart';
import '../../services/accounts/account.dart';
import '../../utils/context_extensions.dart';

class _AddSubscriptionDialog extends StatefulWidget {
  const _AddSubscriptionDialog();

  @override
  State<_AddSubscriptionDialog> createState() => _AddSubscriptionDialogState();
}

class _AddSubscriptionDialogState extends State<_AddSubscriptionDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.addSubscription),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: l10n.rssAtomUrl,
          hintText: 'https://example.com/feed.xml',
        ),
        autofocus: true,
        keyboardType: TextInputType.url,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l10n.add),
        ),
      ],
    );
  }
}

Future<int?> showAddSubscriptionDialog(
  BuildContext context,
  WidgetRef ref, {
  NavigatorState? navigator,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final nav = navigator ?? Navigator.of(context);

  final account = ref.read(activeAccountProvider);
  if (account.type != AccountType.local) {
    if (context.mounted) {
      context.showSnack(l10n.errorMessage(l10n.onlySupportedInLocalAccount));
    }
    return null;
  }

  final url = await nav.push<String?>(
    DialogRoute<String?>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      useSafeArea: true,
      builder: (context) => const _AddSubscriptionDialog(),
    ),
  );
  if (url == null || url.trim().isEmpty) return null;

  final id = await ref.read(feedRepositoryProvider).upsertUrl(url);
  final r = await ref.read(syncServiceProvider).refreshFeedSafe(id);
  if (!context.mounted) return id;
  context.showSnack(
    r.ok ? l10n.addedAndSynced : l10n.errorMessage(r.error.toString()),
  );
  return id;
}
