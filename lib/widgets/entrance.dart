import 'dart:async';

import 'package:flutter/widgets.dart';

import '../config/motion.dart';

/// A column whose children rise into place one after another, from one
/// controller sliced into overlapping intervals so the steps can never
/// drift apart.
///
/// ```dart
/// Entrance(children: [title, emailField, passwordField, button])
/// ```
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.children,
    this.delay = Duration.zero,
    this.spacing = 0,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  final List<Widget> children;

  /// Waits this long before the first child moves (lets a route settle).
  final Duration delay;

  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: Motion.entrance);

  Timer? _start;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      _start = Timer(widget.delay, _c.forward);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) _c.value = 1;
  }

  @override
  void dispose() {
    _start?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.children.length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: widget.crossAxisAlignment,
      children: [
        for (var i = 0; i < n; i++) ...[
          if (i > 0 && widget.spacing > 0) SizedBox(height: widget.spacing),
          Rise(
            animation: CurvedAnimation(
              parent: _c,
              curve: Interval(
                (i / n) * 0.55,
                ((i / n) * 0.55 + 0.45).clamp(0.0, 1.0),
                curve: Motion.enter,
              ),
            ),
            child: widget.children[i],
          ),
        ],
      ],
    );
  }
}

/// Fades a child in while it rises [distance] into place.
class Rise extends StatelessWidget {
  const Rise({
    super.key,
    required this.animation,
    required this.child,
    this.distance = 22,
  });

  final Animation<double> animation;
  final Widget child;
  final double distance;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = animation.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * distance),
            child: child,
          ),
        );
      },
    );
  }
}
