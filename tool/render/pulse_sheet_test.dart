import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tend/config/motion.dart';
import 'package:tend/config/theme.dart';
import 'package:tend/widgets/pulse.dart';

void main() {
  testWidgets('pulse sheet', (tester) async {
    Motion.ambient = false;
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: RepaintBoundary(
        key: key,
        child: Container(
          color: const Color(0xFFFAF6F4),
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            const Heartbeat(height: 90),
            const SizedBox(height: 20),
            Wrap(spacing: 20, children: [
              for (final t in [0.3, 0.6, 0.8, 1.0]) PulseMark(progress: t, width: 200),
            ]),
            const SizedBox(height: 20),
            const Row(children: [BeatingHeart(size: 80), PulseCheck(size: 90)]),
          ]),
        ),
      ),
    ));
    await tester.pump(const Duration(seconds: 2));
    final img = (key.currentContext!.findRenderObject()! as dynamic).toImageSync(pixelRatio: 1.0) as ui.Image;
    final bytes = await tester.runAsync(() => img.toByteData(format: ui.ImageByteFormat.png));
    File('build/pulse_sheet.png')..createSync(recursive: true)..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
