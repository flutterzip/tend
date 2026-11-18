// Draws the app icon to assets/brand/icon_1024.png from the same heart and
// heartbeat the app uses. Then: python3 tool/make_icons.py
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tend/config/palette.dart';
import 'package:tend/widgets/pulse.dart';

void main() {
  test('icon', () async {
    const s = 1024.0;
    const p = Palette.light;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.drawRect(const Rect.fromLTWH(0, 0, s, s), Paint()..shader = ui.Gradient.linear(Offset.zero, const Offset(s, s), [p.accentGlow, p.accentDeep]));
    const box = Rect.fromLTWH(212, 230, 600, 560);
    c.save();
    c.translate(box.left, box.top);
    HeartPainter(color: p.onAccent, light: const Color(0xFFFFFFFF)).paint(c, box.size);
    c.restore();
    final line = Path()..moveTo(150, 520);
    for (var x = 150.0; x <= 874; x += 2) {
      final ph = ((x - 150) / 724) * 0.9 + 0.05;
      line.lineTo(x, 520 - ecg(ph) * 210);
    }
    c.drawPath(line, Paint()
      ..color = p.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 34
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);
    final img = await rec.endRecording().toImage(s.toInt(), s.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    File('assets/brand/icon_1024.png')..createSync(recursive: true)..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
