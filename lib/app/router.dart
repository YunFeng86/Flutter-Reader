import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_reader/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../screens/home_screen.dart';
import '../screens/reader_screen.dart';
import '../screens/settings_screen.dart';
import '../utils/platform.dart';
import '../ui/layout.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        pageBuilder: (context, state) {
          // Use a no-transition page so selecting articles in the 2/3-column
          // layout does not animate the whole page.
          return const NoTransitionPage(
            child: HomeScreen(selectedArticleId: null),
          );
        },
      ),
      GoRoute(
        path: '/article/:id',
        name: 'article',
        pageBuilder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) {
            return const NoTransitionPage(child: _NotFoundScreen());
          }

          final width = MediaQuery.sizeOf(context).width;
          if (isDesktop) {
            final mode = desktopModeForWidth(width);
            if (desktopReaderEmbedded(mode)) {
              return NoTransitionPage(child: HomeScreen(selectedArticleId: id));
            }
            // Medium-small / small desktop: reader is a secondary page.
            return MaterialPage(child: ReaderScreen(articleId: id));
          }

          // Width >= 600: use multi-column HomeScreen with selected article,
          // but keep the transition instant to avoid visual "page jumps".
          if (width >= 600) {
            return NoTransitionPage(child: HomeScreen(selectedArticleId: id));
          }

          // Narrow/mobile: dedicated reader screen with default Material route
          // transition.
          return MaterialPage(child: ReaderScreen(articleId: id));
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(body: Center(child: Text(l10n.notFound)));
  }
}
