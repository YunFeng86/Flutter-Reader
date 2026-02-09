import 'package:flutter/material.dart';

/// A lightweight "play once" insertion effect (fade + slight slide).
///
/// Use this for incremental list updates (e.g. new RSS items arriving) rather
/// than for every rebuild, otherwise it quickly becomes distracting.
class Appear extends StatelessWidget {
  const Appear({
    super.key,
    required this.enabled,
    required this.child,
    this.duration = const Duration(milliseconds: 220),
    this.offset = const Offset(0, -12),
  });

  final bool enabled;
  final Widget child;
  final Duration duration;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    if (MediaQuery.maybeOf(context)?.accessibleNavigation ?? false) {
      return child;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        final o = offset * (1 - t);
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: o, child: child),
        );
      },
      child: child,
    );
  }
}
