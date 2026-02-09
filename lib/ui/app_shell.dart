import 'package:flutter/material.dart';

import '../utils/platform.dart';
import '../widgets/global_nav_bar.dart';
import '../widgets/global_nav_rail.dart';
import 'global_nav.dart';
import 'layout.dart';
import 'layout_spec.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.currentUri, required this.child});

  final Uri currentUri;
  final Widget child;

  bool _isArticleRoute(Uri uri) => uri.pathSegments.contains('article');

  double _listWidthForArticleUri(Uri uri) {
    final seg0 = uri.pathSegments.isEmpty ? '' : uri.pathSegments.first;
    return switch (seg0) {
      'saved' || 'search' => kDesktopListWidth,
      _ => kHomeListWidth,
    };
  }

  bool _isReaderEmbedded({required LayoutSpec spec, required Uri uri}) {
    if (!_isArticleRoute(uri)) return true;
    if (isDesktop) {
      return spec.desktopEmbedsReader;
    }
    return spec.canEmbedReader(listWidth: _listWidthForArticleUri(uri));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final spec = LayoutSpec.fromTotalSize(
      totalWidth: size.width,
      totalHeight: size.height,
    );
    final hideNavForReaderPage =
        _isArticleRoute(currentUri) &&
        !_isReaderEmbedded(spec: spec, uri: currentUri);

    if (hideNavForReaderPage) {
      // Dedicated reader pages should maximize content; they have their own
      // back button (ReaderView/ReaderScreen).
      return GlobalNavScope(hasGlobalNav: false, child: child);
    }

    final mode = spec.globalNavMode;

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
            const SizedBox(width: kPaneGap),
            Expanded(child: child),
          ],
        ),
      ),
      GlobalNavMode.bottom => GlobalNavScope(
        hasGlobalNav: true,
        child: Column(
          children: [
            // When we render our own bottom nav outside the page Scaffold, the
            // default MediaQuery bottom padding (safe area) can create an extra
            // blank region above the nav bar on iOS. Remove it so the page body
            // uses the full height that's already constrained by this Column.
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeBottom: true,
                child: child,
              ),
            ),
            // NavigationBar includes its own SafeArea internally. When used
            // outside Scaffold.bottomNavigationBar, we must remove the *top*
            // system padding from MediaQuery, otherwise NavigationBar's internal
            // SafeArea will add status-bar padding and create a large blank
            // region above the icons/labels (notably on iOS).
            MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: GlobalNavBar(currentUri: currentUri),
            ),
          ],
        ),
      ),
    };
  }
}
