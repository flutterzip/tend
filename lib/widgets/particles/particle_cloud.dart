// From flutterzip_kit (MIT, SiteOwnr LLC), lib/src/particles.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'widget_capture.dart';

/// Thousands of fragments cut from a picture of a widget.
///
/// Motion is a pure function of progress, so the same cloud plays forwards
/// to blow a widget away and backwards to bring it back. Everything is drawn
/// in one or two atlas calls.
class ParticleCloud {
  ParticleCloud._(
    this.from,
    this.to,
    this.count,
    this._a,
    this._b,
    this._rand,
    this._rectsA,
    this._rectsB,
    this._cellPx,
    this._wind,
  ) : _xf = Float32List(count * 4),
      _colA = Int32List(count),
      _colB = Int32List(count),
      _colGlow = Int32List(count);

  final WidgetCapture from;
  final WidgetCapture? to;
  final int count;

  final Float32List _a; // centre of each fragment in [from], logical px
  final Float32List _b; // where it lands in [to]
  final Float32List _rand; // four random numbers per fragment
  final Float32List _rectsA;
  final Float32List _rectsB;
  final Float32List _xf;
  final Int32List _colA;
  final Int32List _colB;
  final Int32List _colGlow;
  final int _cellPx;
  final ui.Offset _wind;

  final ui.Paint _paint = ui.Paint()..filterQuality = ui.FilterQuality.low;
  final ui.Paint _glowPaint = ui.Paint()
    ..filterQuality = ui.FilterQuality.low
    ..blendMode = ui.BlendMode.plus;

  bool get isMorph => to != null;

  /// Cuts [from] into fragments about [cell] logical pixels wide, skipping
  /// transparent areas. With [to], each fragment also gets a destination.
  static ParticleCloud build({
    required WidgetCapture from,
    WidgetCapture? to,
    double cell = 2.5,
    int maxParticles = 22000,
    int seed = 7,
    ui.Offset wind = const ui.Offset(0.9, -0.45),
  }) {
    final dpr = from.pixelRatio;
    var cellPx = math.max(1, (cell * dpr).round());

    List<int> cells(WidgetCapture c) {
      final cols = (c.image.width / cellPx).ceil();
      final rows = (c.image.height / cellPx).ceil();
      final out = <int>[];
      for (var x = 0; x < cols; x++) {
        for (var y = 0; y < rows; y++) {
          final px = math.min(x * cellPx + cellPx ~/ 2, c.image.width - 1);
          final py = math.min(y * cellPx + cellPx ~/ 2, c.image.height - 1);
          if (c.alphaAt(px, py) > 28) out.add(x << 16 | y);
        }
      }
      return out;
    }

    var cellsA = cells(from);
    var cellsB = to == null ? const <int>[] : cells(to);
    while (math.max(cellsA.length, cellsB.length) > maxParticles) {
      cellPx += 1;
      cellsA = cells(from);
      cellsB = to == null ? const <int>[] : cells(to);
    }

    final n = math.max(math.max(cellsA.length, cellsB.length), 1);
    final a = Float32List(n * 2);
    final b = Float32List(n * 2);
    final rand = Float32List(n * 4);
    final rectsA = Float32List(n * 4);
    final rectsB = Float32List(n * 4);
    final random = math.Random(seed);
    final step = cellPx / dpr;

    void place(
      List<int> source,
      Float32List centres,
      Float32List rects,
      int i,
    ) {
      if (source.isEmpty) return;
      // Cells are ordered left to right, so fragments keep their neighbours
      // and the cloud flows instead of scrambling.
      final c = source[(i * source.length / n).floor()];
      final x = c >> 16;
      final y = c & 0xFFFF;
      centres[i * 2] = (x + 0.5) * step;
      centres[i * 2 + 1] = (y + 0.5) * step;
      rects[i * 4] = (x * cellPx).toDouble();
      rects[i * 4 + 1] = (y * cellPx).toDouble();
      rects[i * 4 + 2] = ((x + 1) * cellPx).toDouble();
      rects[i * 4 + 3] = ((y + 1) * cellPx).toDouble();
    }

    for (var i = 0; i < n; i++) {
      place(cellsA, a, rectsA, i);
      place(cellsB, b, rectsB, i);
      for (var k = 0; k < 4; k++) {
        rand[i * 4 + k] = random.nextDouble();
      }
    }

    final length = wind.distance == 0 ? 1.0 : wind.distance;
    return ParticleCloud._(
      from,
      to,
      n,
      a,
      b,
      rand,
      rectsA,
      rectsB,
      cellPx,
      wind / length,
    );
  }

  static double _smooth(double lo, double hi, double x) {
    final t = ((x - lo) / (hi - lo)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  /// Draws the cloud at [progress] between 0 and 1.
  ///
  /// [originFrom] and [originTo] are where the two widgets' top left corners
  /// sit on the canvas.
  void paint(
    ui.Canvas canvas,
    double progress, {
    ui.Offset originFrom = ui.Offset.zero,
    ui.Offset originTo = ui.Offset.zero,
  }) {
    if (isMorph) {
      _layoutMorph(progress, originFrom, originTo);
      canvas.drawRawAtlas(
        from.image,
        _xf,
        _rectsA,
        _colA,
        ui.BlendMode.modulate,
        null,
        _paint,
      );
      canvas.drawRawAtlas(
        to!.image,
        _xf,
        _rectsB,
        _colB,
        ui.BlendMode.modulate,
        null,
        _paint,
      );
    } else {
      _layoutDissolve(progress, originFrom);
      canvas.drawRawAtlas(
        from.image,
        _xf,
        _rectsA,
        _colA,
        ui.BlendMode.modulate,
        null,
        _paint,
      );
      // Fragments flare as they tear free.
      canvas.drawRawAtlas(
        from.image,
        _xf,
        _rectsA,
        _colGlow,
        ui.BlendMode.modulate,
        null,
        _glowPaint,
      );
    }
  }

  void _write(int i, double cx, double cy, double scale, double rot) {
    final s = scale / from.pixelRatio;
    final scos = math.cos(rot) * s;
    final ssin = math.sin(rot) * s;
    final half = _cellPx / 2;
    _xf[i * 4] = scos;
    _xf[i * 4 + 1] = ssin;
    _xf[i * 4 + 2] = cx - scos * half + ssin * half;
    _xf[i * 4 + 3] = cy - ssin * half - scos * half;
  }

  void _layoutDissolve(double t, ui.Offset origin) {
    final w = from.size.width;
    final h = from.size.height;
    // Project every fragment onto the wind, so the downwind edge goes first.
    final minP = math.min(0.0, _wind.dx * w) + math.min(0.0, _wind.dy * h);
    final maxP = math.max(0.0, _wind.dx * w) + math.max(0.0, _wind.dy * h);
    final span = math.max(maxP - minP, 1.0);
    const stagger = 0.58;
    const life = 1 - stagger - 0.1;

    for (var i = 0; i < count; i++) {
      final hx = _a[i * 2];
      final hy = _a[i * 2 + 1];
      final r1 = _rand[i * 4];
      final r2 = _rand[i * 4 + 1];
      final r3 = _rand[i * 4 + 2];
      final r4 = _rand[i * 4 + 3];
      final along = (hx * _wind.dx + hy * _wind.dy - minP) / span;
      final delay = (1 - along) * stagger + r4 * 0.1;
      final ti = ((t - delay) / life).clamp(0.0, 1.0);
      if (ti <= 0) {
        _write(i, origin.dx + hx, origin.dy + hy, 1.02, 0);
        _colA[i] = 0xFFFFFFFF;
        _colGlow[i] = 0;
        continue;
      }
      final e = ti * ti;
      final travel = 70 + 190 * r1;
      final x =
          hx +
          _wind.dx * travel * e +
          math.sin(ti * 6 + r2 * 6.283) * (8 + 22 * r3) * ti;
      final y =
          hy +
          _wind.dy * travel * e -
          34 * r3 * e +
          math.cos(ti * 5 + r1 * 6.283) * (6 + 16 * r2) * ti;
      final scale = (1 - _smooth(0.3, 1, ti)) * (0.9 + 0.5 * r4);
      final alpha = 1 - _smooth(0.45, 1, ti);
      _write(i, origin.dx + x, origin.dy + y, scale, ti * (r2 - 0.5) * 7);
      _colA[i] = (alpha * 255).round() << 24 | 0xFFFFFF;
      final flare = _smooth(0, 0.12, ti) * (1 - _smooth(0.12, 0.5, ti));
      _colGlow[i] = (flare * 210).round() << 24 | 0xFFFFFF;
    }
  }

  void _layoutMorph(double t, ui.Offset originA, ui.Offset originB) {
    for (var i = 0; i < count; i++) {
      final r1 = _rand[i * 4];
      final r2 = _rand[i * 4 + 1];
      final r3 = _rand[i * 4 + 2];
      final r4 = _rand[i * 4 + 3];
      final ti = ((t - r4 * 0.28) / 0.72).clamp(0.0, 1.0);
      final e = ti < 0.5 ? 4 * ti * ti * ti : 1 - math.pow(-2 * ti + 2, 3) / 2;
      final ax = originA.dx + _a[i * 2];
      final ay = originA.dy + _a[i * 2 + 1];
      final bx = originB.dx + _b[i * 2];
      final by = originB.dy + _b[i * 2 + 1];
      // Burst outwards mid flight, then fall into place.
      final burst = math.sin(math.pi * ti);
      final angle = r1 * 6.283 + ti * 2.4 * (r3 - 0.5);
      final reach = (22 + 64 * r2) * burst;
      final x = ax + (bx - ax) * e + math.cos(angle) * reach;
      final y = ay + (by - ay) * e + math.sin(angle) * reach * 0.8;
      _write(i, x, y, 1.02 - 0.4 * burst, burst * (r3 - 0.5) * 3);
      final toB = _smooth(0.3, 0.7, ti);
      _colA[i] = ((1 - toB) * 255).round() << 24 | 0xFFFFFF;
      _colB[i] = (toB * 255).round() << 24 | 0xFFFFFF;
    }
  }

  void dispose() {
    from.dispose();
    to?.dispose();
  }
}
