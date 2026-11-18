import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../config/motion.dart';
import '../config/palette.dart';

/// The paper every screen sits on. It lives under the navigator, so it
/// never cuts between screens: soft pools of light drift on a slow loop and
/// a fine grain keeps the gradients from banding.
class PaperBackdrop extends StatefulWidget {
  const PaperBackdrop({super.key, required this.child});

  final Widget child;

  @override
  State<PaperBackdrop> createState() => _PaperBackdropState();
}

class _PaperBackdropState extends State<PaperBackdrop>
    with SingleTickerProviderStateMixin {
  late final _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.loops(context)) {
      if (!_loop.isAnimating) _loop.repeat();
    } else {
      _loop.stop();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return CustomPaint(
      painter: _LampsPainter(
        t: _loop,
        paper: p.paper,
        lamp: p.accentWash,
        warm: p.accentGlow,
        dark: p.paper.computeLuminance() < 0.2,
      ),
      foregroundPainter: _GrainPainter(p.ink),
      child: widget.child,
    );
  }
}

class _LampsPainter extends CustomPainter {
  _LampsPainter({
    required this.t,
    required this.paper,
    required this.lamp,
    required this.warm,
    required this.dark,
  }) : super(repaint: t);

  final Animation<double> t;
  final Color paper, lamp, warm;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = paper);
    final a = t.value * math.pi * 2;
    final w = size.width, h = size.height;
    final strength = dark ? 0.5 : 0.9;
    void lamp0(Offset c, double r, Color color, double alpha) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = ui.Gradient.radial(c, r, [
            color.withValues(alpha: alpha),
            color.withValues(alpha: 0),
          ]),
      );
    }

    // The main lamp sits behind the keeper, high and centred.
    lamp0(Offset(w * (0.75 + 0.06 * math.sin(a)), h * (0.08 + 0.02 * math.cos(a))),
        w * 0.9, lamp, strength);
    lamp0(Offset(w * (0.05 + 0.08 * math.cos(a + 1.3)), h * (0.42 + 0.05 * math.sin(a * 2))),
        w * 0.6, warm, strength * 0.35);
    lamp0(Offset(w * (0.98 + 0.05 * math.sin(a + 2.1)), h * (0.7 + 0.06 * math.cos(a))),
        w * 0.7, lamp, strength * 0.4);
  }

  @override
  bool shouldRepaint(_LampsPainter old) =>
      old.paper != paper || old.lamp != lamp || old.warm != warm;
}

/// A fixed sprinkle of specks, recorded once per size.
class _GrainPainter extends CustomPainter {
  _GrainPainter(this.ink);

  final Color ink;
  ui.Picture? _picture;
  Size? _for;

  @override
  void paint(Canvas canvas, Size size) {
    if (_picture == null || _for != size) {
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      final rng = math.Random(7);
      final paint = Paint()..color = ink.withValues(alpha: 0.035);
      final n = (size.width * size.height / 90).round();
      final points = <Offset>[
        for (var i = 0; i < n; i++)
          Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
      ];
      c.drawPoints(ui.PointMode.points, points, paint..strokeWidth = 1);
      _picture = rec.endRecording();
      _for = size;
    }
    canvas.drawPicture(_picture!);
  }

  @override
  bool shouldRepaint(_GrainPainter old) => old.ink != ink;
}
