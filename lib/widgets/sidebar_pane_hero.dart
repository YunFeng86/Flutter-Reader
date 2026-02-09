import 'package:flutter/material.dart';

import '../ui/hero_tags.dart';

/// A visual "pane" that can Hero between sections.
///
/// We intentionally only Hero a plain surface (not the full Sidebar content),
/// so the panel feels like it closes/opens instead of squishing text/icons.
class SidebarPaneHero extends StatelessWidget {
  const SidebarPaneHero({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget surface({double elevation = 0}) {
      return Material(
        color: cs.surfaceContainer,
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
            final cs = Theme.of(context).colorScheme;
            return Material(
              color: cs.surfaceContainer,
              elevation: 2,
              child: const SizedBox.expand(),
            );
          },
      child: surface(),
    );
  }
}
