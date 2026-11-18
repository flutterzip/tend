import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../config/motion.dart';
import '../config/palette.dart';

/// One heartbeat as a monitor draws it, for [phase] 0..1: a small P wave,
/// the sharp QRS spike, then the rounded T wave. Returns -1..1 (up is +).
double ecg(double phase) {
  double bump(double c, double w, double h) => h * math.exp(-math.pow((phase - c) / w, 2));
  return bump(0.12, 0.035, 0.14) -
      bump(0.255, 0.012, 0.18) +
      bump(0.28, 0.014, 1.0) -
      bump(0.305, 0.014, 0.32) +
      bump(0.5, 0.06, 0.26);
}

/// A live heart monitor line. A bright head sweeps left to right drawing
/// the trace at [bpm]; what it drew last time fades behind it and a small
/// gap ahead erases the old sweep, the way a bedside monitor does.
class Heartbeat extends StatefulWidget {
  const Heartbeat({super.key, this.bpm = 72, this.height = 64, this.window = 3.2, this.color, this.strokeWidth = 2.6});

  final double bpm;
  final double height;

  /// Seconds across the full width.
  final double window;
  final Color? color;
  final double strokeWidth;

  @override
  State<Heartbeat> createState() => _HeartbeatState();
}

class _HeartbeatState extends State<Heartbeat> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final _frame = ValueNotifier<double>(0);
  Duration _last = Duration.zero;
  double _t = 1.4;

  // The beat phase is integrated, so changing bpm speeds the heart up
  // smoothly instead of jumping to a different point in the beat.
  double _beat = 0;
  double _bpm = 72;
  final _history = <({double t, double beat})>[];

  @override
  void initState() {
    super.initState();
    _bpm = widget.bpm;
    // Prefill one window so the line is already there on the first frame.
    for (var i = 0; i <= 240; i++) {
      final t = _t - widget.window + widget.window * i / 240;
      _history.add((t: t, beat: t * _bpm / 60));
    }
    _beat = _t * _bpm / 60;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.loops(context)) {
      if (!_ticker.isActive) _ticker.start();
    } else {
      _ticker.stop();
    }
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero ? 1 / 60 : ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    _bpm += (widget.bpm - _bpm) * (1 - math.exp(-dt * 2.5));
    _t += dt;
    _beat += dt * _bpm / 60;
    _history.add((t: _t, beat: _beat));
    while (_history.length > 2 && _history.first.t < _t - widget.window * 1.05) {
      _history.removeAt(0);
    }
    _frame.value = _t;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ExcludeSemantics(
      child: SizedBox(
        height: widget.height,
        child: CustomPaint(
          painter: _MonitorPainter(
            frame: _frame,
            history: _history,
            now: () => _t,
            window: widget.window,
            color: widget.color ?? p.accent,
            stroke: widget.strokeWidth,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _MonitorPainter extends CustomPainter {
  _MonitorPainter({
    required this.frame,
    required this.history,
    required this.now,
    required this.window,
    required this.color,
    required this.stroke,
  }) : super(repaint: frame);

  final ValueNotifier<double> frame;
  final List<({double t, double beat})> history;
  final double Function() now;
  final double window;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas c, Size s) {
    if (history.length < 2) return;
    final t = now();
    final mid = s.height * 0.6;
    final amp = s.height * 0.5;
    final headX = (t % window) / window * s.width;
    final gap = s.width * 0.06;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Offset? prev;
    double? prevAge;
    for (final h in history) {
      final age = t - h.t; // 0 at the head, window at the far tail
      if (age > window) continue;
      // Where this moment sits on the sweep: just behind the head, wrapping.
      var x = headX - age / window * s.width;
      if (x < 0) x += s.width;
      final ahead = (x - headX) % s.width;
      final y = mid - ecg(h.beat % 1) * amp;
      final pt = Offset(x, y);
      if (prev != null && (pt.dx - prev.dx).abs() < s.width / 2 && ahead > gap) {
        final fade = 1 - (prevAge! / window);
        paint.color = color.withValues(alpha: (0.15 + 0.85 * fade * fade).clamp(0.0, 1.0));
        c.drawLine(prev, pt, paint);
      }
      prev = pt;
      prevAge = age;
    }
    // The bright head.
    final headY = mid - ecg(history.last.beat % 1) * amp;
    c.drawCircle(Offset(headX, headY), stroke * 3.2, Paint()..color = color.withValues(alpha: 0.25));
    c.drawCircle(Offset(headX, headY), stroke * 1.4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_MonitorPainter old) => old.color != color;
}

/// A heart that beats lub-dub at [bpm], with a soft glow on each beat.
class BeatingHeart extends StatefulWidget {
  const BeatingHeart({super.key, this.bpm = 72, this.size = 64, this.color});

  final double bpm;
  final double size;
  final Color? color;

  @override
  State<BeatingHeart> createState() => _BeatingHeartState();
}

class _BeatingHeartState extends State<BeatingHeart> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final _scale = ValueNotifier<double>(1);
  Duration _last = Duration.zero;
  double _beat = 0, _bpm = 72;

  @override
  void initState() {
    super.initState();
    _bpm = widget.bpm;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.loops(context)) {
      if (!_ticker.isActive) _ticker.start();
    } else {
      _ticker.stop();
      _scale.value = 1;
    }
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero ? 1 / 60 : ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    _bpm += (widget.bpm - _bpm) * (1 - math.exp(-dt * 2.5));
    _beat += dt * _bpm / 60;
    final ph = _beat % 1;
    double pulse(double c, double h) => h * math.exp(-math.pow((ph - c) / 0.05, 2));
    _scale.value = 1 + pulse(0.1, 0.14) + pulse(0.3, 0.08);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = widget.color ?? p.accent;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: widget.size,
        child: ValueListenableBuilder<double>(
          valueListenable: _scale,
          builder: (_, s, _) => Transform.scale(
            scale: s,
            child: CustomPaint(painter: HeartPainter(color: color, glow: (s - 1) * 6, light: p.accentGlow)),
          ),
        ),
      ),
    );
  }
}

/// A plump heart filling its box, lit from the top left.
class HeartPainter extends CustomPainter {
  HeartPainter({required this.color, required this.light, this.glow = 0, this.fill = 1, this.outline});

  final Color color, light;

  /// 0..1 halo around the heart (on a beat).
  final double glow;

  /// 0..1 how much of the heart is filled, bottom up.
  final double fill;
  final Color? outline;

  static Path shape(Size s) {
    final w = s.width, h = s.height;
    return Path()
      ..moveTo(w * 0.5, h * 0.9)
      ..cubicTo(w * 0.12, h * 0.66, w * 0.02, h * 0.42, w * 0.1, h * 0.26)
      ..cubicTo(w * 0.2, h * 0.07, w * 0.44, h * 0.08, w * 0.5, h * 0.26)
      ..cubicTo(w * 0.56, h * 0.08, w * 0.8, h * 0.07, w * 0.9, h * 0.26)
      ..cubicTo(w * 0.98, h * 0.42, w * 0.88, h * 0.66, w * 0.5, h * 0.9)
      ..close();
  }

  @override
  void paint(Canvas c, Size s) {
    final heart = shape(s);
    if (glow > 0) {
      c.drawPath(heart, Paint()
        ..color = color.withValues(alpha: (glow * 0.5).clamp(0.0, 0.5))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s.width * 0.12));
    }
    if (fill > 0) {
      c.save();
      c.clipRect(Rect.fromLTRB(0, s.height * (1 - fill), s.width, s.height));
      c.drawPath(heart, Paint()..shader = ui.Gradient.linear(Offset(s.width * 0.2, 0), Offset(s.width * 0.8, s.height), [light, color]));
      c.drawOval(
        Rect.fromLTWH(s.width * 0.2, s.height * 0.2, s.width * 0.18, s.height * 0.12),
        Paint()..color = const Color(0x66FFFFFF),
      );
      c.restore();
    }
    if (outline != null) {
      c.drawPath(heart, Paint()
        ..color = outline!
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.width * 0.05
        ..strokeJoin = StrokeJoin.round);
    }
  }

  @override
  bool shouldRepaint(HeartPainter old) => old.glow != glow || old.fill != fill || old.color != color;
}

/// The splash's mark: a flat line that kicks up into one heartbeat and then
/// draws the outline of a heart, which fills. [progress] 0..1.
class PulseMark extends StatelessWidget {
  const PulseMark({super.key, required this.progress, this.width = 260});

  final double progress;
  final double width;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size(width, width * 0.5),
        painter: _PulseMarkPainter(progress, p.accent, p.accentGlow),
      ),
    );
  }
}

class _PulseMarkPainter extends CustomPainter {
  _PulseMarkPainter(this.t, this.color, this.light);

  final double t;
  final Color color, light;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final mid = h * 0.62;
    final heartBox = Rect.fromCenter(center: Offset(w * 0.72, h * 0.5), width: h * 0.92, height: h * 0.92);
    // The line: flat, one beat, flat into the bottom tip of the heart.
    final line = Path()..moveTo(0, mid);
    for (var x = 0.0; x <= w * 0.5; x += 1) {
      line.lineTo(x, mid - ecg((x / (w * 0.5)) * 0.9 + 0.05) * h * 0.42);
    }
    final tip = Offset(heartBox.center.dx, heartBox.top + heartBox.height * 0.9);
    line.lineTo(w * 0.56, mid);
    line.lineTo(tip.dx, tip.dy);
    final heart = HeartPainter.shape(heartBox.size).shift(heartBox.topLeft);
    final draw = (t / 0.75).clamp(0.0, 1.0);
    final metrics = [...line.computeMetrics(), ...heart.computeMetrics()];
    final total = metrics.fold(0.0, (n, m) => n + m.length);
    var left = total * Curves.easeInOutSine.transform(draw);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Offset? head;
    for (final m in metrics) {
      if (left <= 0) break;
      final len = math.min(left, m.length);
      c.drawPath(m.extractPath(0, len), paint);
      head = m.getTangentForOffset(len)?.position;
      left -= len;
    }
    final fill = ((t - 0.7) / 0.3).clamp(0.0, 1.0);
    if (fill > 0) {
      c.save();
      c.translate(heartBox.left, heartBox.top);
      HeartPainter(color: color, light: light, fill: Curves.easeOutCubic.transform(fill), glow: fill > 0.9 ? (1 - fill) * 8 : 0).paint(c, heartBox.size);
      c.restore();
    }
    if (head != null && draw < 1) {
      c.drawCircle(head, 9, Paint()..color = color.withValues(alpha: 0.25));
      c.drawCircle(head, 4.5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_PulseMarkPainter old) => old.t != t || old.color != color;
}

/// Success: a check drawn inside a filled circle, with pulse rings spreading
/// out from it.
class PulseCheck extends StatefulWidget {
  const PulseCheck({super.key, this.size = 120});

  final double size;

  @override
  State<PulseCheck> createState() => _PulseCheckState();
}

class _PulseCheckState extends State<PulseCheck> with TickerProviderStateMixin {
  late final _in = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final _rings = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _in.value = 1;
      return;
    }
    if (_in.value == 0) _in.forward();
    if (Motion.loops(context)) {
      if (!_rings.isAnimating) _rings.repeat();
    } else {
      _rings.value = 0.5;
    }
  }

  @override
  void dispose() {
    _in.dispose();
    _rings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: Listenable.merge([_in, _rings]),
        builder: (_, _) => CustomPaint(
          size: Size.square(widget.size * 1.8),
          painter: _CheckPainter(_in.value, _rings.value, p.accent, p.onAccent, widget.size),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.t, this.ring, this.color, this.mark, this.core);

  final double t, ring;
  final Color color, mark;
  final double core;

  @override
  void paint(Canvas c, Size s) {
    final ctr = s.center(Offset.zero);
    final grow = Curves.easeOutBack.transform((t / 0.5).clamp(0.0, 1.0));
    for (var i = 0; i < 2; i++) {
      final r = (ring + i * 0.5) % 1;
      c.drawCircle(ctr, core / 2 * (1 + r * 0.75), Paint()
        ..color = color.withValues(alpha: 0.35 * (1 - r) * grow.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3);
    }
    c.drawCircle(ctr, core / 2 * grow, Paint()..color = color);
    final tick = Path()
      ..moveTo(ctr.dx - core * 0.2, ctr.dy + core * 0.02)
      ..lineTo(ctr.dx - core * 0.05, ctr.dy + core * 0.16)
      ..lineTo(ctr.dx + core * 0.22, ctr.dy - core * 0.14);
    final m = tick.computeMetrics().first;
    final draw = ((t - 0.45) / 0.55).clamp(0.0, 1.0);
    if (draw > 0) {
      c.drawPath(m.extractPath(0, m.length * Curves.easeOutCubic.transform(draw)), Paint()
        ..color = mark
        ..style = PaintingStyle.stroke
        ..strokeWidth = core * 0.08
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round);
    }
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.t != t || old.ring != ring;
}
