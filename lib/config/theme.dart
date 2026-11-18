import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'palette.dart';

/// Spacing, radii and the type scale. Colours live in `palette.dart`.
abstract final class Tokens {
  static const gutter = 24.0;
  static const gap = 16.0;
  static const fieldRadius = 18.0;
  static const buttonRadius = 20.0;
  static const cardRadius = 30.0;
  static const fieldHeight = 58.0;
  static const buttonHeight = 58.0;
}

abstract final class AppTheme {
  static const font = 'Bricolage';

  static ThemeData light() => _build(Palette.light, Brightness.light);
  static ThemeData dark() => _build(Palette.dark, Brightness.dark);

  static ThemeData _build(Palette p, Brightness b) {
    final scheme = ColorScheme.fromSeed(
      seedColor: p.accent,
      brightness: b,
    ).copyWith(
      primary: p.accent,
      onPrimary: p.onAccent,
      surface: p.paper,
      onSurface: p.ink,
      error: p.error,
    );
    TextStyle s(double size, FontWeight w, Color c,
            {double tracking = 0, double height = 1.3}) =>
        TextStyle(
          fontFamily: font,
          fontSize: size,
          fontWeight: w,
          color: c,
          letterSpacing: tracking,
          height: height,
        );
    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      fontFamily: font,
      scaffoldBackgroundColor: p.paper,
      splashFactory: InkSparkle.splashFactory,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.accentDeep,
        selectionColor: p.accent.withValues(alpha: 0.3),
        selectionHandleColor: p.accentDeep,
      ),
      textTheme: TextTheme(
        displaySmall: s(36, FontWeight.w800, p.ink,
            tracking: -1.2, height: 1.05),
        headlineSmall: s(28, FontWeight.w800, p.ink,
            tracking: -0.8, height: 1.1),
        titleLarge: s(21, FontWeight.w700, p.ink, tracking: -0.3),
        titleMedium: s(17, FontWeight.w600, p.ink),
        bodyLarge: s(16, FontWeight.w400, p.inkSoft, height: 1.45),
        bodyMedium: s(14.5, FontWeight.w400, p.inkSoft, height: 1.45),
        bodySmall: s(13, FontWeight.w400, p.muted, height: 1.4),
        labelLarge: s(16, FontWeight.w700, p.ink, tracking: 0.1),
        labelMedium: s(13.5, FontWeight.w600, p.ink),
        labelSmall: s(12, FontWeight.w600, p.muted, tracking: 0.2),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: b == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      extensions: [p],
    );
  }
}
