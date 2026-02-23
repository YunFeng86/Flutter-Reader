import 'dart:async';

import 'package:flutter/material.dart';

/// Reveals [child] after the current route transition completes (then [delay]).
///
/// This is handy when you want motion to feel *sequenced* rather than everything
/// animating at once (e.g. list pane shifts first, then a header drops in).
class StaggeredReveal extends StatefulWidget {
  const StaggeredReveal({
    super.key,
    required this.child,
    this.enabled = true,
    this.delay = const Duration(milliseconds: 60),
    this.duration = const Duration(milliseconds: 220),
    this.slideBegin = const Offset(0, -0.06),
  });

  final Widget child;
  final bool enabled;
  final Duration delay;
  final Duration duration;
  final Offset slideBegin;

  @override
  State<StaggeredReveal> createState() => _StaggeredRevealState();
}

class _StaggeredRevealState extends State<StaggeredReveal> {
  bool _show = false;
  bool _scheduled = false;
  Animation<double>? _routeAnimation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;

    final reduceMotion =
        MediaQuery.maybeOf(context)?.accessibleNavigation ?? false;
    if (reduceMotion || !widget.enabled) {
      _show = true;
      return;
    }

    _routeAnimation = ModalRoute.of(context)?.animation;
    final anim = _routeAnimation;

    if (anim == null || anim.status == AnimationStatus.completed) {
      // If there's no route transition (or it's already finished), reveal on the
      // next frame to keep build/layout stable.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_revealLater());
      });
      return;
    }

    anim.addStatusListener(_onRouteStatusChanged);
  }

  void _onRouteStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    final anim = _routeAnimation;
    anim?.removeStatusListener(_onRouteStatusChanged);
    _routeAnimation = null;
    unawaited(_revealLater());
  }

  Future<void> _revealLater() async {
    if (widget.delay > Duration.zero) {
      await Future<void>.delayed(widget.delay);
    }
    if (!mounted) return;
    setState(() => _show = true);
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onRouteStatusChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.accessibleNavigation ?? false;
    if (reduceMotion || !widget.enabled) return widget.child;

    return AnimatedSwitcher(
      duration: widget.duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (child, animation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final slide = Tween<Offset>(
          begin: widget.slideBegin,
          end: Offset.zero,
        ).animate(curved);

        return FadeTransition(
          opacity: curved,
          child: ClipRect(
            child: SizeTransition(
              sizeFactor: curved,
              axisAlignment: -1,
              child: SlideTransition(position: slide, child: child),
            ),
          ),
        );
      },
      child: _show
          ? KeyedSubtree(key: const ValueKey('reveal'), child: widget.child)
          : const SizedBox.shrink(key: ValueKey('empty')),
    );
  }
}
