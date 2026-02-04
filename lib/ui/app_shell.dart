import 'package:flutter/material.dart';

import '../utils/platform.dart';
import '../widgets/global_nav_bar.dart';
import '../widgets/global_nav_rail.dart';
import 'global_nav.dart';
import 'layout.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.currentUri, required this.child});

  final Uri currentUri;
  final Widget child;

  bool _isArticleRoute(Uri uri) => uri.pathSegments.contains('article');

  String _sectionKeyForUri(Uri uri) {
    if (uri.pathSegments.isEmpty) return 'home';
    final seg = uri.pathSegments.first;
    if (seg == 'article') return 'home';
    return switch (seg) {
      'dashboard' || 'saved' || 'search' || 'settings' => seg,
      _ => 'home',
    };
  }

  bool _isReaderEmbedded({required double totalWidth, required Uri uri}) {
    if (!_isArticleRoute(uri)) return true;
    final contentWidth = effectiveContentWidth(totalWidth);
    if (isDesktop) {
      return desktopReaderEmbedded(desktopModeForWidth(contentWidth));
    }
    return contentWidth >= kCompactWidth;
  }

  @override
  Widget build(BuildContext context) {
    final totalWidth = MediaQuery.sizeOf(context).width;
    final hideNavForReaderPage =
        _isArticleRoute(currentUri) &&
        !_isReaderEmbedded(totalWidth: totalWidth, uri: currentUri);

    if (hideNavForReaderPage) {
      // Dedicated reader pages should maximize content; they have their own
      // back button (ReaderView/ReaderScreen).
      return GlobalNavScope(hasGlobalNav: false, child: child);
    }

    final mode = globalNavModeForWidth(totalWidth);
    final sectionKey = _sectionKeyForUri(currentUri);
    final animatedChild = AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.02, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(key: ValueKey(sectionKey), child: child),
    );
    return switch (mode) {
      GlobalNavMode.rail => GlobalNavScope(
        hasGlobalNav: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: kGlobalNavRailWidth,
              child: GlobalNavRail(currentUri: currentUri),
            ),
            const VerticalDivider(width: kDividerWidth, thickness: 1),
            Expanded(child: animatedChild),
          ],
        ),
      ),
      GlobalNavMode.bottom => GlobalNavScope(
        hasGlobalNav: true,
        child: Column(
          children: [
            Expanded(child: animatedChild),
            const Divider(height: 1),
            SafeArea(top: false, child: GlobalNavBar(currentUri: currentUri)),
          ],
        ),
      ),
    };
  }
}
