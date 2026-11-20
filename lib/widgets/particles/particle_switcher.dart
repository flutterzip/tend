// From flutterzip_kit (MIT, SiteOwnr LLC), lib/src/particles.
import 'package:flutter/widgets.dart';

import 'particle_cloud.dart';
import 'widget_capture.dart';

/// Like [AnimatedSwitcher], but the old child breaks into fragments that fly
/// off and reassemble as the new one.
///
/// Give each child a different [Key] so a change is noticed.
///
/// ```dart
/// ParticleSwitcher(
///   child: paid ? PaidBadge(key: ValueKey('paid')) : PayButton(key: ValueKey('pay')),
/// )
/// ```
class ParticleSwitcher extends StatefulWidget {
  const ParticleSwitcher({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1100),
    this.cell = 2.0,
  });

  final Widget child;
  final Duration duration;
  final double cell;

  @override
  State<ParticleSwitcher> createState() => _ParticleSwitcherState();
}

class _ParticleSwitcherState extends State<ParticleSwitcher>
    with SingleTickerProviderStateMixin {
  final _boundary = GlobalKey();
  late final AnimationController _t;

  /// The outgoing child's picture, shown until the fragments are ready.
  WidgetCapture? _outgoing;
  ParticleCloud? _cloud;
  bool _covering = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _t = AnimationController(vsync: this, duration: widget.duration);
  }

  @override
  void didUpdateWidget(ParticleSwitcher old) {
    super.didUpdateWidget(old);
    _t.duration = widget.duration;
    if (Widget.canUpdate(old.child, widget.child)) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return;
    _begin();
  }

  void _begin() {
    final generation = ++_generation;
    _t.stop();
    _cloud?.dispose();
    _cloud = null;
    _outgoing?.dispose();
    // The boundary still holds last frame's picture of the old child.
    final dpr = MediaQuery.devicePixelRatioOf(context);
    _outgoing = WidgetCapture.grab(_boundary, dpr);
    if (_outgoing == null) return;
    _covering = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || generation != _generation) return;
      final from = _outgoing;
      final to = WidgetCapture.grab(_boundary, dpr);
      if (from == null || to == null) {
        _finish(generation);
        return;
      }
      await Future.wait([from.loadPixels(), to.loadPixels()]);
      if (!mounted || generation != _generation) {
        to.dispose();
        return;
      }
      setState(() {
        _outgoing = null; // now owned by the cloud
        _cloud = ParticleCloud.build(from: from, to: to, cell: widget.cell);
      });
      await _t.forward(from: 0);
      _finish(generation);
    });
  }

  void _finish(int generation) {
    if (!mounted || generation != _generation) return;
    setState(() {
      _cloud?.dispose();
      _cloud = null;
      _outgoing?.dispose();
      _outgoing = null;
      _covering = false;
    });
  }

  @override
  void dispose() {
    _generation++;
    _t.dispose();
    _cloud?.dispose();
    _outgoing?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _covering
          ? _MorphPainter(_cloud, _outgoing, _t)
          : null,
      // While covered the new child is laid out and painted, so it can be
      // photographed, but clipped to nothing so it cannot be seen or tapped.
      child: ClipRect(
        clipper: _covering ? const _ClipAll() : null,
        clipBehavior: _covering ? Clip.hardEdge : Clip.none,
        child: RepaintBoundary(key: _boundary, child: widget.child),
      ),
    );
  }
}

class _ClipAll extends CustomClipper<Rect> {
  const _ClipAll();

  @override
  Rect getClip(Size size) => Rect.zero;

  @override
  bool shouldReclip(_ClipAll oldClipper) => false;
}

class _MorphPainter extends CustomPainter {
  _MorphPainter(this.cloud, this.outgoing, this.progress)
    : super(repaint: progress);

  final ParticleCloud? cloud;
  final WidgetCapture? outgoing;
  final Animation<double> progress;

  static Offset _centred(Size box, Size child) =>
      Offset((box.width - child.width) / 2, (box.height - child.height) / 2);

  @override
  void paint(Canvas canvas, Size size) {
    final cloud = this.cloud;
    if (cloud != null) {
      cloud.paint(
        canvas,
        progress.value,
        originFrom: _centred(size, cloud.from.size),
        originTo: _centred(size, cloud.to!.size),
      );
      return;
    }
    final still = outgoing;
    if (still == null) return;
    final at = _centred(size, still.size);
    canvas.drawImageRect(
      still.image,
      Offset.zero &
          Size(still.image.width.toDouble(), still.image.height.toDouble()),
      at & still.size,
      Paint(),
    );
  }

  @override
  bool shouldRepaint(_MorphPainter old) =>
      old.cloud != cloud || old.outgoing != outgoing;
}
