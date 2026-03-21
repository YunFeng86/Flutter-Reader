import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'home_scene_commands.dart';

class NextArticleIntent extends Intent {
  const NextArticleIntent();
}

class PreviousArticleIntent extends Intent {
  const PreviousArticleIntent();
}

class RefreshHomeIntent extends Intent {
  const RefreshHomeIntent();
}

class ToggleUnreadIntent extends Intent {
  const ToggleUnreadIntent();
}

class ToggleReadIntent extends Intent {
  const ToggleReadIntent();
}

class ToggleStarIntent extends Intent {
  const ToggleStarIntent();
}

class SearchIntent extends Intent {
  const SearchIntent();
}

Map<ShortcutActivator, Intent> homeSceneShortcutMap() => const {
  SingleActivator(LogicalKeyboardKey.keyJ): NextArticleIntent(),
  SingleActivator(LogicalKeyboardKey.keyK): PreviousArticleIntent(),
  SingleActivator(LogicalKeyboardKey.keyR): RefreshHomeIntent(),
  SingleActivator(LogicalKeyboardKey.keyU): ToggleUnreadIntent(),
  SingleActivator(LogicalKeyboardKey.keyM): ToggleReadIntent(),
  SingleActivator(LogicalKeyboardKey.keyS): ToggleStarIntent(),
  SingleActivator(LogicalKeyboardKey.keyF, control: true): SearchIntent(),
  SingleActivator(LogicalKeyboardKey.keyF, meta: true): SearchIntent(),
};

class HomeSceneShortcuts extends StatelessWidget {
  const HomeSceneShortcuts({
    super.key,
    required this.commands,
    required this.child,
    this.autofocus = true,
  });

  final HomeSceneCommands commands;
  final Widget child;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: homeSceneShortcutMap(),
      child: Actions(
        actions: {
          NextArticleIntent: CallbackAction<NextArticleIntent>(
            onInvoke: (intent) {
              commands.goToNextArticle();
              return null;
            },
          ),
          PreviousArticleIntent: CallbackAction<PreviousArticleIntent>(
            onInvoke: (intent) {
              commands.goToPreviousArticle();
              return null;
            },
          ),
          RefreshHomeIntent: CallbackAction<RefreshHomeIntent>(
            onInvoke: (intent) async {
              await commands.refreshAll();
              return null;
            },
          ),
          ToggleUnreadIntent: CallbackAction<ToggleUnreadIntent>(
            onInvoke: (intent) {
              commands.toggleUnreadOnly();
              return null;
            },
          ),
          ToggleReadIntent: CallbackAction<ToggleReadIntent>(
            onInvoke: (intent) async {
              await commands.toggleSelectedArticleRead();
              return null;
            },
          ),
          ToggleStarIntent: CallbackAction<ToggleStarIntent>(
            onInvoke: (intent) async {
              await commands.toggleSelectedArticleStar();
              return null;
            },
          ),
          SearchIntent: CallbackAction<SearchIntent>(
            onInvoke: (intent) {
              commands.goToSearch();
              return null;
            },
          ),
        },
        child: Focus(autofocus: autofocus, child: child),
      ),
    );
  }
}
