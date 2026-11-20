// From flutterzip_kit (MIT, SiteOwnr LLC), lib/src/particles.
import 'package:flutter/widgets.dart';

import 'particle_cloud.dart';
import 'widget_capture.dart';

/// Drives a [Disintegrable].
class DisintegrateController {
  _DisintegrableState? _state;

  /// True once the child has blown away.
  bool get isGone => _state?._hidden ?? false;

  /// Breaks the child into fragments and blows them away.
  Future<void> disintegrate() async => _state?._disintegrate();

  /// Plays the same fragments backwards until the child is whole again.
  Future<void> reform() async => _state?._reform();
}

/// Lets its child be blown away as dust, and brought back.
///
/// ```dart
/// final dust = DisintegrateController();
/// Disintegrable(controller: dust, child: card);
/// await dust.disintegrate();
/// ```
class Disintegrable extends StatefulWidget {
  const Disintegrable({
    super.key,
    required this.controller,
    required this.child,
    this.duration = const Duration(milliseconds: 1300),
    this.cell = 2.5,
    this.wind = const Offset(0.9, -0.45),
  });

  final DisintegrateController controller;
  final Widget child;
  final Duration duration;

  /// Fragment size in logical pixels. Smaller means more fragments.
  final double cell;

  /// Direction the dust is carried in.
  final Offset wind;

  @override
  State<Disintegrable> createState() => _DisintegrableState();
}

class _DisintegrableState extends State<Disintegrable>
    with SingleTickerProviderStateMixin {
  final _boundary = GlobalKey();
  late final AnimationController _t;
  ParticleCloud? _cloud;
  bool _hidden = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _t = AnimationController(vsync: this, duration: widget.duration);
    widget.controller._state = this;
  }

  @override
  void didUpdateWidget(Disintegrable old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller._state = null;
      widget.controller._state = this;
    }
    _t.duration = widget.duration;
  }

  @override
  void dispose() {
    if (widget.controller._state == this) widget.controller._state = null;
    _t.dispose();
    _cloud?.dispose();
    super.dispose();
  }

  Future<void> _disintegrate() async {
    if (_busy || _hidden) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      setState(() => _hidden = true);
      return;
    }
    _busy = true;
    final capture = WidgetCapture.grab(
      _boundary,
      MediaQuery.devicePixelRatioOf(context),
    );
    if (capture == null) {
      _busy = false;
      setState(() => _hidden = true);
      return;
    }
    await capture.loadPixels();
    if (!mounted) {
      capture.dispose();
      return;
    }
    _cloud?.dispose();
    _cloud = ParticleCloud.build(
      from: capture,
      cell: widget.cell,
      wind: widget.wind,
    );
    setState(() => _hidden = true);
    await _t.forward(from: 0);
    _busy = false;
  }

  Future<void> _reform() async {
    if (_busy || !_hidden) return;
    if (_cloud == null) {
      setState(() => _hidden = false);
      return;
    }
    _busy = true;
    await _t.reverse(from: 1);
    if (!mounted) return;
    _cloud?.dispose();
    setState(() {
      _cloud = null;
      _hidden = false;
    });
    _busy = false;
  }

  @override
  Widget build(BuildContext context) {
    final cloud = _cloud;
    return CustomPaint(
      foregroundPainter: cloud == null ? null : _CloudPainter(cloud, _t),
      child: IgnorePointer(
        ignoring: _hidden,
        child: Opacity(
          opacity: _hidden ? 0 : 1,
          child: RepaintBoundary(key: _boundary, child: widget.child),
        ),
      ),
    );
  }
}

class _CloudPainter extends CustomPainter {
  _CloudPainter(this.cloud, this.progress) : super(repaint: progress);

  final ParticleCloud cloud;
  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) => cloud.paint(canvas, progress.value);

  @override
  bool shouldRepaint(_CloudPainter old) => old.cloud != cloud;
}
