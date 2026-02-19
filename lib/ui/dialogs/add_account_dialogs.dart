import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fleur/l10n/app_localizations.dart';

import '../../providers/account_providers.dart';
import '../../services/accounts/account.dart';
import '../../utils/context_extensions.dart';

enum _MinifluxAuthMode { apiToken, basicAuth }

enum _FeverAuthMode { apiKey, basicAuth }

Future<String?> showAddLocalAccountDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final l10n = AppLocalizations.of(context)!;
  final nameCtrl = TextEditingController(text: l10n.local);
  if (!context.mounted) return null;
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

  final trimmed = (name ?? '').trim();
  if (trimmed.isEmpty) return null;

  final id = await ref
      .read(accountsControllerProvider.notifier)
      .addAccount(type: AccountType.local, name: trimmed);
  await ref.read(accountsControllerProvider.notifier).setActive(id);
  if (!context.mounted) return id;
  context.showSnack(l10n.done);
  return id;
}

Future<String?> showAddFeverAccountDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final l10n = AppLocalizations.of(context)!;

  final nameCtrl = TextEditingController(text: l10n.fever);
  final baseUrlCtrl = TextEditingController();
  final apiKeyCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  bool obscureApiKey = true;
  bool obscurePassword = true;
  var authMode = _FeverAuthMode.apiKey;
  var submitting = false;

  String? createdId;

  Future<void> submit(StateSetter setState, BuildContext dialogContext) async {
    if (submitting) return;
    final name = nameCtrl.text.trim();
    final baseUrl = baseUrlCtrl.text.trim();
    final apiKey = apiKeyCtrl.text.trim();
    final username = usernameCtrl.text.trim();
    final password = passwordCtrl.text;
    final uri = Uri.tryParse(baseUrl);
    final hasCreds = switch (authMode) {
      _FeverAuthMode.apiKey => apiKey.isNotEmpty,
      _FeverAuthMode.basicAuth => username.isNotEmpty && password.isNotEmpty,
    };

    if (name.isEmpty || baseUrl.isEmpty || !hasCreds) {
      dialogContext.showSnack(l10n.errorMessage(l10n.missingRequiredFields));
      return;
    }
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      dialogContext.showSnack(l10n.errorMessage(l10n.invalidBaseUrl));
      return;
    }

    setState(() => submitting = true);
    try {
      final id = await ref
          .read(accountsControllerProvider.notifier)
          .addAccount(type: AccountType.fever, name: name, baseUrl: baseUrl);

      final store = ref.read(credentialStoreProvider);
      switch (authMode) {
        case _FeverAuthMode.apiKey:
          await store.setApiToken(id, AccountType.fever, apiKey);
          await store.deleteBasicAuth(id, AccountType.fever);
          break;
        case _FeverAuthMode.basicAuth:
          await store.setBasicAuth(
            id,
            AccountType.fever,
            username: username,
            password: password,
          );
          await store.deleteApiToken(id, AccountType.fever);
          break;
      }

      await ref.read(accountsControllerProvider.notifier).setActive(id);
      createdId = id;
      if (!dialogContext.mounted) return;
      Navigator.of(dialogContext).pop();
    } catch (e) {
      if (!dialogContext.mounted) return;
      setState(() => submitting = false);
      dialogContext.showSnack(l10n.errorMessage(e.toString()));
    }
  }

  if (!context.mounted) return null;
  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: Text(l10n.addFever),
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
                      hintText: l10n.feverBaseUrlHint,
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
                        label: Text(l10n.apiKey),
                        selected: authMode == _FeverAuthMode.apiKey,
                        onSelected: (v) {
                          if (!v) return;
                          setState(() => authMode = _FeverAuthMode.apiKey);
                        },
                      ),
                      ChoiceChip(
                        label: Text(l10n.usernamePassword),
                        selected: authMode == _FeverAuthMode.basicAuth,
                        onSelected: (v) {
                          if (!v) return;
                          setState(() => authMode = _FeverAuthMode.basicAuth);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.feverAuthHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  if (authMode == _FeverAuthMode.apiKey) ...[
                    TextField(
                      controller: apiKeyCtrl,
                      obscureText: obscureApiKey,
                      decoration: InputDecoration(
                        labelText: l10n.apiKey,
                        suffixIcon: IconButton(
                          tooltip: obscureApiKey ? l10n.show : l10n.hide,
                          icon: Icon(
                            obscureApiKey
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () =>
                              setState(() => obscureApiKey = !obscureApiKey),
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
                onPressed: submitting
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: submitting
                    ? null
                    : () => unawaited(submit(setState, dialogContext)),
                child: submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.add),
              ),
            ],
          );
        },
      );
    },
  );

  final id = createdId;
  if (id == null) return null;
  if (!context.mounted) return id;
  context.showSnack(l10n.done);
  return id;
}

Future<String?> showAddMinifluxAccountDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final l10n = AppLocalizations.of(context)!;

  final nameCtrl = TextEditingController(text: l10n.miniflux);
  final baseUrlCtrl = TextEditingController();
  final tokenCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  bool obscureToken = true;
  bool obscurePassword = true;
  var authMode = _MinifluxAuthMode.apiToken;
  var submitting = false;

  String? createdId;

  Future<void> submit(StateSetter setState, BuildContext dialogContext) async {
    if (submitting) return;
    final name = nameCtrl.text.trim();
    final baseUrl = baseUrlCtrl.text.trim();
    final token = tokenCtrl.text.trim();
    final username = usernameCtrl.text.trim();
    final password = passwordCtrl.text;
    final uri = Uri.tryParse(baseUrl);
    final hasCreds = switch (authMode) {
      _MinifluxAuthMode.apiToken => token.isNotEmpty,
      _MinifluxAuthMode.basicAuth => username.isNotEmpty && password.isNotEmpty,
    };

    if (name.isEmpty || baseUrl.isEmpty || !hasCreds) {
      dialogContext.showSnack(l10n.errorMessage(l10n.missingRequiredFields));
      return;
    }
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      dialogContext.showSnack(l10n.errorMessage(l10n.invalidBaseUrl));
      return;
    }

    setState(() => submitting = true);
    try {
      final id = await ref
          .read(accountsControllerProvider.notifier)
          .addAccount(type: AccountType.miniflux, name: name, baseUrl: baseUrl);

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
      createdId = id;
      if (!dialogContext.mounted) return;
      Navigator.of(dialogContext).pop();
    } catch (e) {
      if (!dialogContext.mounted) return;
      setState(() => submitting = false);
      dialogContext.showSnack(l10n.errorMessage(e.toString()));
    }
  }

  if (!context.mounted) return null;
  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (dialogContext, setState) {
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
                          setState(() => authMode = _MinifluxAuthMode.apiToken);
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
                onPressed: submitting
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: submitting
                    ? null
                    : () => unawaited(submit(setState, dialogContext)),
                child: submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.add),
              ),
            ],
          );
        },
      );
    },
  );

  final id = createdId;
  if (id == null) return null;
  if (!context.mounted) return id;
  context.showSnack(l10n.done);
  return id;
}
