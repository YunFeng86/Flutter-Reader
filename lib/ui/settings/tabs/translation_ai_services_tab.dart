import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/translation_ai_settings_providers.dart';
import '../../../services/settings/translation_ai_settings.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/context_extensions.dart';
import '../../dialogs/text_input_dialog.dart';
import '../translation_ai/ai_service_editor_dialog.dart';
import '../translation_ai/ai_service_templates.dart';
import '../widgets/section_header.dart';

enum _AiServiceAction { setDefault, edit, delete }

class TranslationAiServicesTab extends ConsumerWidget {
  const TranslationAiServicesTab({super.key, this.showPageTitle = true});

  final bool showPageTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final settingsAsync = ref.watch(translationAiSettingsProvider);

    return settingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l10n.errorMessage(e.toString()))),
      data: (settings) {
        final enabledServices = settings.aiServices
            .where((s) => s.enabled)
            .toList(growable: false);

        Future<void> pickTranslationProvider() async {
          final picked =
              await showModalBottomSheet<TranslationProviderSelection>(
                context: context,
                showDragHandle: true,
                builder: (context) {
                  final current = settings.translationProvider;
                  final options = <TranslationProviderSelection>[
                    const TranslationProviderSelection.googleWeb(),
                    const TranslationProviderSelection.bingWeb(),
                    const TranslationProviderSelection.baiduApi(),
                    const TranslationProviderSelection.deepLApi(),
                    const TranslationProviderSelection.deepLX(),
                    ...enabledServices.map(
                      (s) => TranslationProviderSelection.aiService(s.id),
                    ),
                  ];

                  return SafeArea(
                    top: false,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Text(
                            l10n.translationProvider,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        for (final option in options)
                          ListTile(
                            title: Text(
                              _translationProviderLabel(l10n, option, settings),
                            ),
                            trailing: option == current
                                ? const Icon(Icons.check)
                                : null,
                            onTap: () => Navigator.of(context).pop(option),
                          ),
                      ],
                    ),
                  );
                },
              );
          if (picked == null) return;
          await ref
              .read(translationAiSettingsProvider.notifier)
              .setTranslationProvider(picked);
        }

        Future<void> setDeepLXBaseUrl() async {
          final next = await showTextInputDialog(
            context,
            title: 'DeepLX Base URL',
            labelText: l10n.baseUrl,
            hintText: 'https://deeplx.example.com',
            initialText: settings.deepLX.baseUrl,
            keyboardType: TextInputType.url,
            confirmText: l10n.done,
          );
          if (next == null) return;
          final trimmed = next.trim();
          if (trimmed.isNotEmpty) {
            final uri = Uri.tryParse(trimmed);
            if (uri == null ||
                !(uri.scheme == 'http' || uri.scheme == 'https')) {
              if (!context.mounted) return;
              context.showErrorMessage(l10n.invalidBaseUrl);
              return;
            }
          }
          await ref
              .read(translationAiSettingsProvider.notifier)
              .setDeepLXBaseUrl(trimmed);
          if (!context.mounted) return;
          context.showSuccess(l10n.done);
        }

        Future<void> configureDeepL() async {
          final secrets = ref.read(translationAiSecretStoreProvider);
          final existingKey = await secrets.getDeepLApiKey();
          if (!context.mounted) return;

          final apiKeyCtrl = TextEditingController(text: existingKey ?? '');
          var endpoint = settings.deepL.endpoint;
          var obscure = true;
          var submitting = false;

          Future<void> submit(
            StateSetter setState,
            BuildContext dialogContext,
          ) async {
            if (submitting) return;
            setState(() => submitting = true);
            try {
              final key = apiKeyCtrl.text.trim();
              if (key.isEmpty) {
                await secrets.deleteDeepLApiKey();
              } else {
                await secrets.setDeepLApiKey(key);
              }
              await ref
                  .read(translationAiSettingsProvider.notifier)
                  .setDeepLEndpoint(endpoint);
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
                    title: const Text('DeepL'),
                    content: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Endpoint',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('Free'),
                                selected: endpoint == DeepLEndpoint.free,
                                onSelected: (v) {
                                  if (!v) return;
                                  setState(() => endpoint = DeepLEndpoint.free);
                                },
                              ),
                              ChoiceChip(
                                label: const Text('Pro'),
                                selected: endpoint == DeepLEndpoint.pro,
                                onSelected: (v) {
                                  if (!v) return;
                                  setState(() => endpoint = DeepLEndpoint.pro);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: apiKeyCtrl,
                            obscureText: obscure,
                            decoration: InputDecoration(
                              labelText: l10n.apiKey,
                              suffixIcon: IconButton(
                                tooltip: obscure ? l10n.show : l10n.hide,
                                icon: Icon(
                                  obscure
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () =>
                                    setState(() => obscure = !obscure),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Leave empty to clear saved API Key.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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

        Future<void> configureBaidu() async {
          final secrets = ref.read(translationAiSecretStoreProvider);
          final existing = await secrets.getBaiduCredentials();
          if (!context.mounted) return;

          final appIdCtrl = TextEditingController(text: existing?.appId ?? '');
          final appKeyCtrl = TextEditingController(
            text: existing?.appKey ?? '',
          );
          var obscure = true;
          var submitting = false;

          Future<void> submit(
            StateSetter setState,
            BuildContext dialogContext,
          ) async {
            if (submitting) return;
            final id = appIdCtrl.text.trim();
            final key = appKeyCtrl.text;

            setState(() => submitting = true);
            try {
              if (id.isEmpty || key.isEmpty) {
                await secrets.deleteBaiduCredentials();
              } else {
                await secrets.setBaiduCredentials(appId: id, appKey: key);
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
                    title: const Text('百度翻译（API）'),
                    content: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: appIdCtrl,
                            decoration: const InputDecoration(
                              labelText: 'App ID',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: appKeyCtrl,
                            obscureText: obscure,
                            decoration: InputDecoration(
                              labelText: 'App Key',
                              suffixIcon: IconButton(
                                tooltip: obscure ? l10n.show : l10n.hide,
                                icon: Icon(
                                  obscure
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () =>
                                    setState(() => obscure = !obscure),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Leave empty to clear saved credentials.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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

        Future<void> addAiService() async {
          final picked = await showModalBottomSheet<AiServiceTemplate>(
            context: context,
            showDragHandle: true,
            builder: (context) {
              return SafeArea(
                top: false,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Text(
                        l10n.addAiService,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    ...aiServiceTemplates.map(
                      (t) => ListTile(
                        leading: Icon(apiTypeIcon(t.apiType)),
                        title: Text(t.name),
                        subtitle: Text(apiTypeLabel(t.apiType)),
                        onTap: () => Navigator.of(context).pop(t),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
          if (picked == null) return;
          if (!context.mounted) return;
          await showAiServiceEditorDialog(context, ref, template: picked);
        }

        Future<void> editAiService(AiServiceConfig service) async {
          await showAiServiceEditorDialog(
            context,
            ref,
            template: null,
            existing: service,
          );
        }

        Future<void> confirmDeleteAiService(AiServiceConfig service) async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text(l10n.delete),
                content: Text('${l10n.delete} "${service.name}"?'),
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
              .read(translationAiSettingsProvider.notifier)
              .deleteAiService(service.id);
          if (!context.mounted) return;
          context.showSuccess(l10n.done);
        }

        final translationLabel = _translationProviderLabel(
          l10n,
          settings.translationProvider,
          settings,
        );

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
                    if (showPageTitle)
                      SectionHeader(title: l10n.translationAndAiServices),

                    SectionHeader(title: l10n.translation),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusCard,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.translate),
                            title: Text(l10n.translationProvider),
                            subtitle: Text(translationLabel),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: pickTranslationProvider,
                          ),
                          const Divider(height: 1),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('百度翻译（API）'),
                            subtitle: const Text('配置 App ID / App Key'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: configureBaidu,
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('DeepL（API）'),
                            subtitle: Text(
                              'Endpoint: ${settings.deepL.endpoint.name.toUpperCase()} · ${l10n.apiKey}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: configureDeepL,
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('DeepLX'),
                            subtitle: Text(
                              settings.deepLX.baseUrl.trim().isEmpty
                                  ? l10n.baseUrl
                                  : settings.deepLX.baseUrl.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: setDeepLXBaseUrl,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.aiServices,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: addAiService,
                          icon: const Icon(Icons.add),
                          label: Text(l10n.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusCard,
                        ),
                      ),
                      child: settings.aiServices.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                '还没有添加任何 AI 服务。',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: settings.aiServices.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final s = settings.aiServices[index];
                                final isDefault =
                                    s.id == settings.defaultAiServiceId;

                                return ListTile(
                                  leading: Icon(apiTypeIcon(s.apiType)),
                                  title: Row(
                                    children: [
                                      Expanded(child: Text(s.name)),
                                      if (isDefault)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 8),
                                          child: Icon(Icons.star, size: 18),
                                        ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    [
                                      apiTypeLabel(s.apiType),
                                      if (s.baseUrl.trim().isNotEmpty)
                                        s.baseUrl.trim(),
                                      if (s.defaultModel.trim().isNotEmpty)
                                        'Model: ${s.defaultModel.trim()}',
                                    ].join(' · '),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Switch(
                                        value: s.enabled,
                                        onChanged: (v) => ref
                                            .read(
                                              translationAiSettingsProvider
                                                  .notifier,
                                            )
                                            .setAiServiceEnabled(s.id, v),
                                      ),
                                      PopupMenuButton<_AiServiceAction>(
                                        tooltip: l10n.more,
                                        onSelected: (action) async {
                                          switch (action) {
                                            case _AiServiceAction.setDefault:
                                              await ref
                                                  .read(
                                                    translationAiSettingsProvider
                                                        .notifier,
                                                  )
                                                  .setDefaultAiService(s.id);
                                              if (!context.mounted) return;
                                              context.showSuccess(l10n.done);
                                              return;
                                            case _AiServiceAction.edit:
                                              await editAiService(s);
                                              return;
                                            case _AiServiceAction.delete:
                                              await confirmDeleteAiService(s);
                                              return;
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: _AiServiceAction.setDefault,
                                            child: Text(
                                              isDefault ? '默认（已设置）' : '设为默认',
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: _AiServiceAction.edit,
                                            child: Text(l10n.edit),
                                          ),
                                          PopupMenuItem(
                                            value: _AiServiceAction.delete,
                                            child: Text(l10n.delete),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  onTap: () => unawaited(editAiService(s)),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

String _translationProviderLabel(
  AppLocalizations l10n,
  TranslationProviderSelection selection,
  TranslationAiSettings settings,
) {
  return switch (selection.kind) {
    TranslationProviderKind.googleWeb => 'Google 翻译（网页）',
    TranslationProviderKind.bingWeb => 'Bing 翻译（网页）',
    TranslationProviderKind.baiduApi => '百度翻译（API）',
    TranslationProviderKind.deepLApi => 'DeepL（API）',
    TranslationProviderKind.deepLX => 'DeepLX',
    TranslationProviderKind.aiService => _aiServiceTranslationLabel(
      l10n,
      settings,
      selection.aiServiceId,
    ),
  };
}

String _aiServiceTranslationLabel(
  AppLocalizations l10n,
  TranslationAiSettings settings,
  String? serviceId,
) {
  final id = (serviceId ?? '').trim();
  if (id.isEmpty) return l10n.aiService;
  for (final s in settings.aiServices) {
    if (s.id == id) return 'AI：${s.name}';
  }
  return l10n.aiService;
}
