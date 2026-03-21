import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../models/category.dart';
import '../../models/feed.dart';
import '../../providers/query_providers.dart';
import '../../providers/repository_providers.dart';
import '../../utils/context_extensions.dart';
import '../actions/subscription_actions.dart';
import 'sidebar_selection_actions.dart';

typedef SidebarDialogPresenter =
    Future<T?> Function<T>({required WidgetBuilder builder});

class SidebarManagementActions {
  const SidebarManagementActions({
    required BuildContext context,
    required WidgetRef ref,
    required SidebarSelectionActions selectionActions,
    required NavigatorState navigator,
    required SidebarDialogPresenter showDialogRoute,
    GoRouter? router,
  }) : _context = context,
       _ref = ref,
       _selectionActions = selectionActions,
       _navigator = navigator,
       _showDialogRoute = showDialogRoute,
       _router = router;

  final BuildContext _context;
  final WidgetRef _ref;
  final SidebarSelectionActions _selectionActions;
  final NavigatorState _navigator;
  final SidebarDialogPresenter _showDialogRoute;
  final GoRouter? _router;

  Future<T?> _showDialog<T>({required WidgetBuilder builder}) {
    return _showDialogRoute<T>(builder: builder);
  }

  Future<void> openSettings() async {
    final target = _router ?? GoRouter.maybeOf(_context);
    if (target == null) return;
    await target.push('/settings');
  }

  Future<void> addFeed() async {
    final id = await SubscriptionActions.addFeed(
      _context,
      _ref,
      navigator: _navigator,
    );
    if (id == null) return;
    _selectionActions.selectFeed(id);
  }

  Future<int?> addCategory() async {
    final l10n = AppLocalizations.of(_context)!;
    final controller = TextEditingController();
    try {
      final name = await _showDialog<String?>(
        builder: (context) {
          return AlertDialog(
            title: Text(l10n.newCategory),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(labelText: l10n.name),
              autofocus: true,
              onSubmitted: (value) => Navigator.of(context).pop(value),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(controller.text),
                child: Text(l10n.create),
              ),
            ],
          );
        },
      );
      if (name == null || name.trim().isEmpty) return null;
      return _ref.read(categoryRepositoryProvider).upsertByName(name);
    } finally {
      controller.dispose();
    }
  }

  Future<void> renameCategory(Category category) async {
    final l10n = AppLocalizations.of(_context)!;
    final controller = TextEditingController(text: category.name);
    try {
      final next = await _showDialog<String?>(
        builder: (context) {
          return AlertDialog(
            title: Text(l10n.rename),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(labelText: l10n.name),
              autofocus: true,
              onSubmitted: (value) => Navigator.of(context).pop(value),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(controller.text),
                child: Text(l10n.done),
              ),
            ],
          );
        },
      );
      if (next == null) return;
      try {
        await _ref.read(categoryRepositoryProvider).rename(category.id, next);
      } catch (error) {
        if (!_context.mounted) return;
        final message = error.toString().contains('already exists')
            ? l10n.nameAlreadyExists
            : error.toString();
        _context.showErrorMessage(l10n.errorMessage(message));
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> deleteCategory(Category category) async {
    final l10n = AppLocalizations.of(_context)!;
    final confirmed = await _showDialog<bool>(
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
    if (confirmed != true) return;
    await _ref.read(categoryRepositoryProvider).delete(category.id);
    if (!_context.mounted) return;
    if (_ref.read(selectedCategoryIdProvider) == category.id) {
      _selectionActions.selectAll();
    }
    _context.showSnack(l10n.categoryDeleted);
  }

  Future<void> editFeedTitle(Feed feed) async {
    final l10n = AppLocalizations.of(_context)!;
    final controller = TextEditingController(text: feed.userTitle ?? '');
    try {
      final next = await _showDialog<String?>(
        builder: (context) {
          return AlertDialog(
            title: Text(l10n.edit),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(labelText: l10n.name),
              autofocus: true,
              onSubmitted: (value) => Navigator.of(context).pop(value),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(''),
                child: Text(l10n.delete),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(controller.text),
                child: Text(l10n.done),
              ),
            ],
          );
        },
      );
      if (next == null) return;
      await _ref
          .read(feedRepositoryProvider)
          .setUserTitle(feedId: feed.id, userTitle: next);
    } finally {
      controller.dispose();
    }
  }

  Future<void> refreshFeed(Feed feed) {
    return SubscriptionActions.refreshFeed(_context, _ref, feed.id);
  }

  Future<void> cacheFeedOffline(Feed feed) {
    return SubscriptionActions.cacheFeedOffline(_context, _ref, feed.id);
  }

  Future<void> moveFeedToCategory(Feed feed) async {
    final l10n = AppLocalizations.of(_context)!;
    final categories = await _ref.read(categoryRepositoryProvider).getAll();
    if (!_context.mounted) return;
    final selected = await _showDialog<int?>(
      builder: (context) {
        final currentCategoryId = feed.categoryId;
        return SimpleDialog(
          title: Text(l10n.moveToCategory),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(null),
              child: Row(
                children: [
                  Icon(currentCategoryId == null ? Icons.check : Icons.clear),
                  const SizedBox(width: 8),
                  Text(l10n.uncategorized),
                ],
              ),
            ),
            for (final category in categories)
              SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(category.id),
                child: Row(
                  children: [
                    Icon(
                      currentCategoryId == category.id
                          ? Icons.check
                          : Icons.clear,
                    ),
                    const SizedBox(width: 8),
                    Text(category.name),
                  ],
                ),
              ),
          ],
        );
      },
    );
    if (selected == feed.categoryId) return;
    await _ref
        .read(feedRepositoryProvider)
        .setCategory(feedId: feed.id, categoryId: selected);
  }

  Future<void> deleteFeed(Feed feed) async {
    final l10n = AppLocalizations.of(_context)!;
    final confirmed = await _showDialog<bool>(
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
    if (confirmed != true) return;
    await _ref.read(feedRepositoryProvider).delete(feed.id);
    if (!_context.mounted) return;
    if (_ref.read(selectedFeedIdProvider) == feed.id) {
      _selectionActions.selectAll();
    }
    _context.showSnack(l10n.deleted);
  }

  Future<void> refreshAll() {
    return SubscriptionActions.refreshAll(_context, _ref);
  }

  Future<void> importOpml() {
    return SubscriptionActions.importOpml(_context, _ref);
  }

  Future<void> exportOpml() {
    return SubscriptionActions.exportOpml(_context, _ref);
  }
}
