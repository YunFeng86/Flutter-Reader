import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;

import '../../../l10n/app_localizations.dart';
import '../../../services/logging/app_logger.dart';
import '../../../services/platform/shell_service.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/context_extensions.dart';
import '../../../utils/path_manager.dart';
import '../../../utils/platform.dart';
import '../widgets/section_header.dart';

class AboutTab extends StatefulWidget {
  const AboutTab({super.key, this.showPageTitle = true});

  final bool showPageTitle;

  @override
  State<AboutTab> createState() => _AboutTabState();
}

class _AboutTabState extends State<AboutTab> {
  late final Future<String> _appDataPathFuture;
  late final Future<String> _logsPathFuture;
  late final Future<PackageInfo> _packageInfoFuture;

  @override
  void initState() {
    super.initState();
    _appDataPathFuture = PathManager.getSupportPath();
    _logsPathFuture = PathManager.getLogsPath();
    _packageInfoFuture = PackageInfo.fromPlatform();
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

  Future<void> _openLatestLog() async {
    final file = await AppLogger.getLatestLogFile();
    if (file == null) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      context.showSnack(l10n.noLogsFound);
      return;
    }
    await _openFolder(file.path);
  }

  Future<void> _exportLogs() async {
    final l10n = AppLocalizations.of(context)!;

    File archive;
    try {
      archive = await AppLogger.createLogsArchive();
    } catch (e) {
      if (!mounted) return;
      context.showErrorMessage(l10n.errorMessage(e.toString()));
      return;
    }

    // file_selector_ios may throw UnimplementedError for save dialogs.
    // On iOS we export via the system share sheet so users can "Save to Files".
    if (isIOS) {
      try {
        await IosShareBridge.shareFile(
          path: archive.path,
          mimeType: 'application/zip',
          name: p.basename(archive.path),
        );
      } catch (e) {
        if (!mounted) return;
        context.showErrorMessage(l10n.errorMessage(e.toString()));
        return;
      }
      if (!mounted) return;
      context.showSnack(l10n.exportedLogs);
      return;
    }

    const group = XTypeGroup(
      label: 'ZIP',
      extensions: ['zip'],
      mimeTypes: ['application/zip'],
      uniformTypeIdentifiers: ['public.zip-archive'],
    );

    FileSaveLocation? loc;
    try {
      loc = await getSaveLocation(
        suggestedName: p.basename(archive.path),
        acceptedTypeGroups: [group],
      );
    } catch (e) {
      if (!mounted) return;
      context.showErrorMessage(l10n.errorMessage(e.toString()));
      return;
    }
    if (loc == null) return;

    try {
      await archive.copy(loc.path);
    } catch (e) {
      if (!mounted) return;
      context.showErrorMessage(l10n.errorMessage(e.toString()));
      return;
    }
    if (!mounted) return;
    context.showSnack(l10n.exportedLogs);
  }

  Future<void> _showLicenseDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    try {
      final licenseText = await rootBundle.loadString('LICENSE');
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.openSourceLicense),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 400),
            child: Scrollbar(
              child: SingleChildScrollView(
                child: SelectableText(
                  licenseText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      context.showErrorMessage(l10n.errorMessage('Failed to load license'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return FutureBuilder<PackageInfo>(
      future: _packageInfoFuture,
      builder: (context, packageSnapshot) {
        final packageInfo = packageSnapshot.data;

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
                    if (widget.showPageTitle) SectionHeader(title: l10n.about),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusCard,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.appTitle,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          // Version and build number
                          if (packageInfo != null) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.version,
                                        style: theme.textTheme.labelLarge,
                                      ),
                                      const SizedBox(height: 4),
                                      SelectableText(packageInfo.version),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.buildNumber,
                                        style: theme.textTheme.labelLarge,
                                      ),
                                      const SizedBox(height: 4),
                                      SelectableText(packageInfo.buildNumber),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
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
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
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
                          const SizedBox(height: 16),
                          FutureBuilder<String>(
                            future: _logsPathFuture,
                            builder: (context, snapshot) {
                              final path = snapshot.data;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.logDirectory,
                                    style: theme.textTheme.labelLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  SelectableText(path ?? '...'),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
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
                                      OutlinedButton(
                                        onPressed: path == null
                                            ? null
                                            : () {
                                                unawaited(_openFolder(path));
                                              },
                                        child: Text(l10n.openLogFolder),
                                      ),
                                      OutlinedButton(
                                        onPressed: () {
                                          unawaited(_openLatestLog());
                                        },
                                        child: Text(l10n.openLog),
                                      ),
                                      FilledButton(
                                        onPressed: () {
                                          unawaited(_exportLogs());
                                        },
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.download_outlined,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(l10n.exportLogs),
                                            ),
                                          ],
                                        ),
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
                    SectionHeader(title: l10n.openSourceLicense),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusCard,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MIT License',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _showLicenseDialog,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.description_outlined,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Flexible(child: Text(l10n.viewLicense)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SectionHeader(title: l10n.thirdPartyLicenses),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusCard,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.viewThirdPartyLicenses,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () {
                              showLicensePage(
                                context: context,
                                applicationName: l10n.appTitle,
                                applicationVersion: packageInfo?.version,
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.article_outlined, size: 18),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(l10n.viewThirdPartyLicenses),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SectionHeader(title: l10n.keyboardShortcuts),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusCard,
                        ),
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
      },
    );
  }
}
