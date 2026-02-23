import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/translation_ai_settings_providers.dart';
import '../../../services/settings/translation_ai_settings.dart';
import '../../../utils/context_extensions.dart';
import 'ai_service_templates.dart';

Future<void> showAiServiceEditorDialog(
  BuildContext context,
  WidgetRef ref, {
  required AiServiceTemplate? template,
  AiServiceConfig? existing,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final secrets = ref.read(translationAiSecretStoreProvider);

  final editing = existing != null;
  final apiType = existing?.apiType ?? template!.apiType;

  final nameCtrl = TextEditingController(
    text: existing?.name ?? (template?.name ?? ''),
  );
  final baseUrlCtrl = TextEditingController(
    text: existing?.baseUrl ?? (template?.baseUrl ?? ''),
  );
  final modelCtrl = TextEditingController(
    text: existing?.defaultModel ?? (template?.defaultModel ?? ''),
  );

  final existingKey = editing
      ? await secrets.getAiServiceApiKey(existing.id)
      : null;
  if (!context.mounted) return;

  final apiKeyCtrl = TextEditingController(text: existingKey ?? '');
  var obscure = true;
  var submitting = false;

  Future<void> submit(StateSetter setState, BuildContext dialogContext) async {
    if (submitting) return;
    final name = nameCtrl.text.trim();
    final baseUrl = baseUrlCtrl.text.trim();
    final model = modelCtrl.text.trim();
    final apiKey = apiKeyCtrl.text.trim();

    if (baseUrl.isNotEmpty) {
      final uri = Uri.tryParse(baseUrl);
      if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
        dialogContext.showErrorMessage(l10n.invalidBaseUrl);
        return;
      }
    }

    setState(() => submitting = true);
    try {
      final controller = ref.read(translationAiSettingsProvider.notifier);
      if (editing) {
        final updated = existing.copyWith(
          name: name.isEmpty ? existing.name : name,
          baseUrl: baseUrl,
          defaultModel: model,
        );
        await controller.updateAiService(
          updated,
          apiKey: apiKey,
          previousApiKey: existingKey ?? '',
        );
      } else {
        await controller.addAiService(
          name: name.isEmpty ? template!.name : name,
          apiType: apiType,
          baseUrl: baseUrl,
          defaultModel: model,
          enabled: true,
          apiKey: apiKey,
        );
      }
      if (!dialogContext.mounted) return;
      Navigator.of(dialogContext).pop();
    } catch (e) {
      if (!dialogContext.mounted) return;
      setState(() => submitting = false);
      dialogContext.showError(e);
    }
  }

  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            scrollable: true,
            title: Text(editing ? l10n.edit : l10n.add),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(apiTypeIcon(apiType), size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(apiTypeLabel(apiType))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: baseUrlCtrl,
                    decoration: InputDecoration(labelText: l10n.baseUrl),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: modelCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Default Model',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: apiKeyCtrl,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: l10n.apiKey,
                      suffixIcon: IconButton(
                        tooltip: obscure ? l10n.show : l10n.hide,
                        icon: Icon(
                          obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () => setState(() => obscure = !obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '留空将清除已保存的 API Key。',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
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
                    : Text(l10n.done),
              ),
            ],
          );
        },
      );
    },
  );
}
