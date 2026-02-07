import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_settings_providers.dart';
import '../../providers/opml_providers.dart';
import '../../providers/query_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/service_providers.dart';
import '../../services/opml/opml_service.dart';
import '../../ui/dialogs/add_subscription_dialog.dart';
import '../../ui/dialogs/text_input_dialog.dart';
import '../../utils/context_extensions.dart';
import '../../utils/platform.dart';

class SubscriptionActions {
  static void _resetFeedBrowseFilters(WidgetRef ref) {
    ref.read(starredOnlyProvider.notifier).state = false;
    ref.read(readLaterOnlyProvider.notifier).state = false;
    ref.read(articleSearchQueryProvider.notifier).state = '';
  }

  /// Select a feed for browsing.
  ///
  /// When [resetFilters] is true (default), clears global filters/search that
  /// may not make sense after switching feeds.
  static void selectFeed(
    WidgetRef ref,
    int feedId, {
    bool resetFilters = true,
  }) {
    if (resetFilters) _resetFeedBrowseFilters(ref);
    ref.read(selectedFeedIdProvider.notifier).state = feedId;
    // Selecting a feed should exit category/tag browsing context.
    ref.read(selectedCategoryIdProvider.notifier).state = null;
    ref.read(selectedTagIdProvider.notifier).state = null;
  }

  static Future<int?> addFeed(
    BuildContext context,
    WidgetRef ref, {
    NavigatorState? navigator,
  }) {
    return showAddSubscriptionDialog(context, ref, navigator: navigator);
  }

  // Back-compat alias for old call sites.
  static Future<void> showAddFeedDialog(
    BuildContext context,
    WidgetRef ref, {
    NavigatorState? navigator,
  }) async {
    await addFeed(context, ref, navigator: navigator);
  }

  static Future<int?> addCategory(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final name = await showTextInputDialog(
      context,
      title: l10n.newCategory,
      labelText: l10n.name,
      confirmText: l10n.create,
    );
    if (name == null || name.trim().isEmpty) return null;
    return ref.read(categoryRepositoryProvider).upsertByName(name);
  }

  static Future<void> renameCategory(
    BuildContext context,
    WidgetRef ref, {
    required int categoryId,
    required String currentName,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final next = await showTextInputDialog(
      context,
      title: l10n.rename,
      labelText: l10n.name,
      initialText: currentName,
      confirmText: l10n.done,
    );
    if (next == null) return;
    try {
      await ref.read(categoryRepositoryProvider).rename(categoryId, next);
    } catch (e) {
      if (!context.mounted) return;
      final msg = e.toString().contains('already exists')
          ? l10n.nameAlreadyExists
          : e.toString();
      context.showErrorMessage(l10n.errorMessage(msg));
    }
  }

  static Future<bool> deleteCategory(
    BuildContext context,
    WidgetRef ref,
    int categoryId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.deleteCategoryConfirmTitle),
          content: Text(l10n.deleteCategoryConfirmContent),
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
    if (ok != true) return false;
    await ref.read(categoryRepositoryProvider).delete(categoryId);
    if (!context.mounted) return true;
    context.showSnack(l10n.categoryDeleted);
    return true;
  }

  static Future<void> editFeedTitle(
    BuildContext context,
    WidgetRef ref, {
    required int feedId,
    required String? currentTitle,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final next = await showTextInputDialog(
      context,
      title: l10n.edit,
      labelText: l10n.name,
      initialText: currentTitle ?? '',
      confirmText: l10n.done,
    );
    if (next == null) return;
    await ref
        .read(feedRepositoryProvider)
        .setUserTitle(feedId: feedId, userTitle: next);
  }

  static Future<bool> deleteFeed(
    BuildContext context,
    WidgetRef ref,
    int feedId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.deleteSubscriptionConfirmTitle),
          content: Text(l10n.deleteSubscriptionConfirmContent),
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
    if (ok != true) return false;
    await ref.read(feedRepositoryProvider).delete(feedId);
    if (!context.mounted) return true;
    context.showSnack(l10n.deleted);
    return true;
  }

  static Future<void> updateFeedSettings(
    BuildContext context,
    WidgetRef ref, {
    required int feedId,
    bool? filterEnabled,
    bool updateFilterEnabled = false,
    String? filterKeywords,
    bool updateFilterKeywords = false,
    bool? syncEnabled,
    bool updateSyncEnabled = false,
    bool? syncImages,
    bool updateSyncImages = false,
    bool? syncWebPages,
    bool updateSyncWebPages = false,
    bool? showAiSummary,
    bool updateShowAiSummary = false,
  }) async {
    await ref
        .read(feedRepositoryProvider)
        .updateSettings(
          id: feedId,
          filterEnabled: filterEnabled,
          updateFilterEnabled: updateFilterEnabled,
          filterKeywords: filterKeywords,
          updateFilterKeywords: updateFilterKeywords,
          syncEnabled: syncEnabled,
          updateSyncEnabled: updateSyncEnabled,
          syncImages: syncImages,
          updateSyncImages: updateSyncImages,
          syncWebPages: syncWebPages,
          updateSyncWebPages: updateSyncWebPages,
          showAiSummary: showAiSummary,
          updateShowAiSummary: updateShowAiSummary,
        );
  }

  static Future<void> updateCategorySettings(
    BuildContext context,
    WidgetRef ref, {
    required int categoryId,
    bool? filterEnabled,
    bool updateFilterEnabled = false,
    String? filterKeywords,
    bool updateFilterKeywords = false,
    bool? syncEnabled,
    bool updateSyncEnabled = false,
    bool? syncImages,
    bool updateSyncImages = false,
    bool? syncWebPages,
    bool updateSyncWebPages = false,
    bool? showAiSummary,
    bool updateShowAiSummary = false,
  }) async {
    await ref
        .read(categoryRepositoryProvider)
        .updateSettings(
          id: categoryId,
          filterEnabled: filterEnabled,
          updateFilterEnabled: updateFilterEnabled,
          filterKeywords: filterKeywords,
          updateFilterKeywords: updateFilterKeywords,
          syncEnabled: syncEnabled,
          updateSyncEnabled: updateSyncEnabled,
          syncImages: syncImages,
          updateSyncImages: updateSyncImages,
          syncWebPages: syncWebPages,
          updateSyncWebPages: updateSyncWebPages,
          showAiSummary: showAiSummary,
          updateShowAiSummary: updateShowAiSummary,
        );
  }

  // Back-compat alias.
  static Future<void> showAddCategoryDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await addCategory(context, ref);
  }

  static Future<void> refreshFeed(
    BuildContext context,
    WidgetRef ref,
    int feedId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final r = await ref.read(syncServiceProvider).refreshFeedSafe(feedId);
    if (!context.mounted) return;
    context.showSnack(
      r.ok ? l10n.refreshed : l10n.errorMessage(r.error.toString()),
    );
  }

  static Future<void> refreshAll(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final feeds = await ref.read(feedRepositoryProvider).getAll();
    if (feeds.isEmpty) return;

    final appSettings = ref.read(appSettingsProvider).valueOrNull;
    final concurrency = appSettings?.autoRefreshConcurrency ?? 2;

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

  static Future<void> moveFeedToCategory(
    BuildContext context,
    WidgetRef ref,
    int feedId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final cats = await ref.read(categoryRepositoryProvider).getAll();
    if (!context.mounted) return;

    // Returns -1 for Uncategorized, categoryId for category, null for Cancel.
    final selected = await showDialog<int?>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(l10n.moveToCategory),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(-1),
              child: Text(l10n.uncategorized),
            ),
            for (final c in cats)
              SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(c.id),
                child: Text(c.name),
              ),
          ],
        );
      },
    );

    if (selected == null) return;

    final categoryId = selected == -1 ? null : selected;
    await ref
        .read(feedRepositoryProvider)
        .setCategory(feedId: feedId, categoryId: categoryId);
  }

  static Future<void> importOpml(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final group = XTypeGroup(
      label: 'OPML',
      extensions: ['opml', 'xml'],
      mimeTypes: ['text/xml', 'application/xml'],
      // iPadOS: some .opml files are marked as public.data rather than public.xml.
      // Loosen UTI on iOS and validate after selection.
      uniformTypeIdentifiers: isIOS
          ? ['public.xml', 'public.text', 'public.data']
          : ['public.xml'],
    );

    XFile? file;
    try {
      file = await openFile(acceptedTypeGroups: [group]);
    } catch (e) {
      if (!context.mounted) return;
      context.showErrorMessage(l10n.errorMessage(e.toString()));
      return;
    }
    if (file == null) return;

    final nameOrPath = file.name.isNotEmpty ? file.name : file.path;
    final dot = nameOrPath.lastIndexOf('.');
    final ext = dot == -1 ? '' : nameOrPath.substring(dot).toLowerCase();
    // Allow files without extension (some providers do that).
    if (ext.isNotEmpty && ext != '.opml' && ext != '.xml') {
      if (!context.mounted) return;
      context.showErrorMessage(l10n.errorMessage(l10n.opmlParseFailed));
      return;
    }

    String xml;
    try {
      xml = await file.readAsString();
    } catch (e) {
      if (!context.mounted) return;
      context.showErrorMessage(l10n.errorMessage(e.toString()));
      return;
    }

    List<OpmlEntry> entries;
    try {
      entries = ref.read(opmlServiceProvider).parseEntries(xml);
    } catch (_) {
      if (!context.mounted) return;
      context.showErrorMessage(l10n.errorMessage(l10n.opmlParseFailed));
      return;
    }
    if (entries.isEmpty) {
      if (!context.mounted) return;
      context.showSnack(l10n.noFeedsFoundInOpml);
      return;
    }

    var added = 0;
    for (final e in entries) {
      final feedId = await ref.read(feedRepositoryProvider).upsertUrl(e.url);
      if (e.category != null && e.category!.trim().isNotEmpty) {
        final catId = await ref
            .read(categoryRepositoryProvider)
            .upsertByName(e.category!);
        await ref
            .read(feedRepositoryProvider)
            .setCategory(feedId: feedId, categoryId: catId);
      }
      added += 1;
    }
    if (!context.mounted) return;
    context.showSnack(l10n.importedFeeds(added));
  }

  static Future<void> exportOpml(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final feeds = await ref.read(feedRepositoryProvider).getAll();
    if (feeds.isEmpty) return;

    final cats = await ref.read(categoryRepositoryProvider).getAll();
    final names = {for (final c in cats) c.id: c.name};

    final xml = ref
        .read(opmlServiceProvider)
        .buildOpml(feeds: feeds, categoryNames: names);

    final bytes = Uint8List.fromList(utf8.encode(xml));
    // file_selector_ios may throw UnimplementedError for save dialogs.
    // On iOS we export via the system share sheet so users can "Save to Files".
    if (isIOS) {
      final xfile = XFile.fromData(
        bytes,
        mimeType: 'text/xml',
        name: 'subscriptions.opml',
      );
      final tmpDir = await getTemporaryDirectory();
      final tmpPath = '${tmpDir.path}/subscriptions.opml';
      try {
        await xfile.saveTo(tmpPath);
        await IosShareBridge.shareFile(
          path: tmpPath,
          mimeType: 'text/xml',
          name: 'subscriptions.opml',
        );
      } catch (e) {
        if (!context.mounted) return;
        context.showErrorMessage(l10n.errorMessage(e.toString()));
        return;
      }
      if (!context.mounted) return;
      context.showSnack(l10n.exportedOpml);
      return;
    }

    const group = XTypeGroup(
      label: 'OPML',
      extensions: ['opml', 'xml'],
      mimeTypes: ['text/xml', 'application/xml'],
      uniformTypeIdentifiers: ['public.xml'],
    );

    FileSaveLocation? loc;
    try {
      loc = await getSaveLocation(
        suggestedName: 'subscriptions.opml',
        acceptedTypeGroups: [group],
      );
    } catch (e) {
      if (!context.mounted) return;
      context.showErrorMessage(l10n.errorMessage(e.toString()));
      return;
    }
    if (loc == null) return;

    final file = XFile.fromData(bytes, mimeType: 'text/xml', name: loc.path);
    try {
      await file.saveTo(loc.path);
    } catch (e) {
      if (!context.mounted) return;
      context.showErrorMessage(l10n.errorMessage(e.toString()));
      return;
    }
    if (!context.mounted) return;
    context.showSnack(l10n.exportedOpml);
  }
}
