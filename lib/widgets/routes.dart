import 'package:flutter/material.dart';

import '../config/motion.dart';

/// Moving between auth screens. The backdrop lives under the navigator, so
/// routes are see-through: the old screen fades and sinks a little, the new
/// one rises in, and the keeper flies between their headers.
class TendRoute<T> extends PageRouteBuilder<T> {
  TendRoute(Widget page)
      : super(
          opaque: false,
          transitionDuration: Motion.route,
          reverseTransitionDuration: Motion.route,
          pageBuilder: (_, _, _) => Material(type: MaterialType.transparency, child: page),
          transitionsBuilder: (context, animation, secondary, child) {
            final inT = CurvedAnimation(
              parent: animation,
              curve: const Interval(0.25, 1, curve: Motion.enter),
              reverseCurve: const Interval(0.0, 0.7, curve: Motion.exit),
            );
            final outT = CurvedAnimation(
              parent: secondary,
              curve: const Interval(0, 0.55, curve: Motion.exit),
            );
            return FadeTransition(
              opacity: ReverseAnimation(outT),
              child: SlideTransition(
                position: Tween(begin: Offset.zero, end: const Offset(0, 0.03))
                    .animate(outT),
                child: FadeTransition(
                  opacity: inT,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0, 0.06), end: Offset.zero)
                        .animate(inT),
                    child: child,
                  ),
                ),
              ),
            );
          },
        );
}

extension Go on BuildContext {
  /// Opens [page] on top of this one.
  Future<T?> open<T>(Widget page) => Navigator.of(this).push<T>(TendRoute(page));

  /// Replaces this page with [page].
  Future<void> swap(Widget page) => Navigator.of(this).pushReplacement(TendRoute(page));

  /// Starts again at [page] (signed in, signed out). The current page stays
  /// alive for the hand-off; the pages under it go once the new one has
  /// arrived, so nothing blanks mid-flight.
  void restart(Widget page) {
    final nav = Navigator.of(this);
    final route = TendRoute<void>(page);
    nav.pushReplacement(route);
    void clear(AnimationStatus status) {
      if (status != AnimationStatus.completed) return;
      route.animation?.removeStatusListener(clear);
      while (route.isActive && !route.isFirst) {
        nav.removeRouteBelow(route);
      }
    }

    route.animation?.addStatusListener(clear);
  }
}
