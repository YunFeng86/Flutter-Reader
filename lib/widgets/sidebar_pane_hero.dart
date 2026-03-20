import 'package:flutter/material.dart';

import '../theme/fleur_theme_extensions.dart';
import '../ui/hero_tags.dart';

/// A visual "pane" that can Hero between sections.
///
/// We intentionally only Hero a plain surface (not the full Sidebar content),
/// so the panel feels like it closes/opens instead of squishing text/icons.
class SidebarPaneHero extends StatelessWidget {
  const SidebarPaneHero({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.fleurSurface;

    Widget surface({double elevation = 0}) {
      return Material(
        color: surfaces.sidebar,
        elevation: elevation,
        child: const SizedBox.expand(),
      );
    }

    return Hero(
      tag: kHeroSidebarPane,
      flightShuttleBuilder:
          (
            context,
            animation,
            flightDirection,
            fromHeroContext,
            toHeroContext,
          ) {
            // Add a tiny elevation during flight so the shrinking edge is readable.
            return Material(
              color: Theme.of(context).fleurSurface.sidebar,
              elevation: 2,
              child: const SizedBox.expand(),
            );
          },
      child: surface(),
    );
  }
}
