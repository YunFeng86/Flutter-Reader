import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/platform/shell_service.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/context_extensions.dart';
import '../../../utils/path_manager.dart';
import '../widgets/section_header.dart';

class AboutTab extends StatefulWidget {
  const AboutTab({super.key});

  @override
  State<AboutTab> createState() => _AboutTabState();
}

class _AboutTabState extends State<AboutTab> {
  late final Future<String> _appDataPathFuture;

  @override
  void initState() {
    super.initState();
    _appDataPathFuture = PathManager.getSupportPath();
  }

  Future<void> _openFolder(String path) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return;
    try {
      await ShellService.openPath(trimmed);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      String message;
      if (e is FileSystemException) {
        final isNotFound =
            (e.osError?.errorCode == 2) || e.message == 'Path does not exist';
        if (isNotFound) {
          final missingPath = e.path ?? trimmed;
          message = l10n.errorMessage(l10n.pathNotFound(missingPath));
        } else {
          message = l10n.errorMessage(l10n.openFailedGeneral);
        }
      } else {
        // In sandboxed environments, open/launch failures are frequently caused
        // by permission issues rather than the path being missing.
        message = l10n.errorMessage(l10n.openFailedGeneral);
      }
      context.showErrorMessage(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

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
                SectionHeader(title: l10n.about),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.appTitle, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      FutureBuilder<String>(
                        future: _appDataPathFuture,
                        builder: (context, snapshot) {
                          final path = snapshot.data;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.dataDirectory,
                                style: theme.textTheme.labelLarge,
                              ),
                              const SizedBox(height: 4),
                              SelectableText(path ?? '...'),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  OutlinedButton(
                                    onPressed: path == null
                                        ? null
                                        : () async {
                                            await Clipboard.setData(
                                              ClipboardData(text: path),
                                            );
                                            if (!context.mounted) return;
                                            context.showSnack(l10n.done);
                                          },
                                    child: Text(l10n.copyPath),
                                  ),
                                  const SizedBox(width: 12),
                                  OutlinedButton(
                                    onPressed: path == null
                                        ? null
                                        : () {
                                            unawaited(_openFolder(path));
                                          },
                                    child: Text(l10n.openFolder),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SectionHeader(title: l10n.keyboardShortcuts),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  ),
                  child: DefaultTextStyle(
                    style: theme.textTheme.bodyMedium!,
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('J / K: Next / previous article'),
                        Text('R: Refresh (current selection)'),
                        Text('U: Toggle unread-only'),
                        Text('M: Toggle read/unread for selected article'),
                        Text('S: Toggle star for selected article'),
                        Text('Ctrl+F: Search articles'),
                      ],
                    ),
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
