// From flutterzip_kit (MIT, SiteOwnr LLC), lib/src/particles.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A picture of a widget, plus its pixels once [loadPixels] has run.
class WidgetCapture {
  WidgetCapture._(this.image, this.size, this.pixelRatio);

  final ui.Image image;

  /// Size of the widget in logical pixels.
  final Size size;
  final double pixelRatio;
  Uint8List? _rgba;

  /// Captures the [RepaintBoundary] that [boundaryKey] is attached to.
  ///
  /// Returns null if it has not been painted yet.
  static WidgetCapture? grab(GlobalKey boundaryKey, double pixelRatio) {
    final ro = boundaryKey.currentContext?.findRenderObject();
    if (ro is! RenderRepaintBoundary || !ro.hasSize || ro.size.isEmpty) {
      return null;
    }
    try {
      final image = ro.toImageSync(pixelRatio: pixelRatio);
      return WidgetCapture._(image, ro.size, pixelRatio);
    } on Object {
      return null;
    }
  }

  Future<void> loadPixels() async {
    if (_rgba != null) return;
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    _rgba = data?.buffer.asUint8List();
  }

  /// Opacity at a pixel, 0 to 255. Fully opaque when pixels are unavailable.
  int alphaAt(int x, int y) {
    final rgba = _rgba;
    if (rgba == null) return 255;
    final i = (y * image.width + x) * 4 + 3;
    return i < rgba.length ? rgba[i] : 0;
  }

  void dispose() => image.dispose();
}
