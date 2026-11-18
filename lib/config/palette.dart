import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Every colour in Tend is defined in this file.
//
// To re-skin the app, edit [Palette.light] and [Palette.dark] below. Every
// screen, the heartbeat line, the calendar, the slots and the ticket read
// their colours from here through `context.palette`.
//
// The system: warm paper, soft ink and exactly one accent (pulse coral).
// Doctors' portraits are drawn in steps of that one hue.
// Ink is never pure black and paper is never pure white.
// ---------------------------------------------------------------------------

@immutable
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.paper,
    required this.card,
    required this.ink,
    required this.inkSoft,
    required this.muted,
    required this.line,
    required this.field,
    required this.accent,
    required this.accentDeep,
    required this.accentGlow,
    required this.onAccent,
    required this.accentWash,
    required this.error,
    required this.eye,
    required this.face,
    required this.shadow,
    required this.scrim,
  });

  /// The page ground.
  final Color paper;

  /// Raised surfaces: the form card, sheets, the keypad keys.
  final Color card;

  /// Headlines and primary type.
  final Color ink;

  /// Body copy.
  final Color inkSoft;

  /// Hints, captions, inactive icons.
  final Color muted;

  /// Hairlines and resting field borders.
  final Color line;

  /// The fill of a field at rest.
  final Color field;

  /// The one accent: the pulse. Buttons, the heartbeat, the chosen slot.
  final Color accent;

  /// Pressed and emphasised accent.
  final Color accentDeep;

  /// A lighter accent for glows and gradients.
  final Color accentGlow;

  /// Type and icons on top of [accent].
  final Color onAccent;

  /// A pale tint of the accent for selected states and notices.
  final Color accentWash;

  /// Errors stay in the family: a deeper, redder neighbour of the accent.
  final Color error;

  /// The brightest highlight (paper of the booking ticket).
  final Color eye;

  /// The darkest ink, the same in both modes (text on the ticket).
  final Color face;

  /// Shadows under raised surfaces.
  final Color shadow;

  /// Behind sheets.
  final Color scrim;

  static const light = Palette(
    paper: Color(0xFFFAF6F4),
    card: Color(0xFFFFFCFB),
    ink: Color(0xFF241A1C),
    inkSoft: Color(0xFF5A4A4D),
    muted: Color(0xFF98898B),
    line: Color(0xFFEDE2DF),
    field: Color(0xFFF4EBE8),
    accent: Color(0xFFE5604A),
    accentDeep: Color(0xFFC0432F),
    accentGlow: Color(0xFFF59A85),
    onAccent: Color(0xFFFFF8F6),
    accentWash: Color(0xFFFCE6E0),
    error: Color(0xFFB3324F),
    eye: Color(0xFFFFFDFB),
    face: Color(0xFF241A1C),
    shadow: Color(0x2E5C2A20),
    scrim: Color(0x66241A1C),
  );

  static const dark = Palette(
    paper: Color(0xFF141012),
    card: Color(0xFF1E181A),
    ink: Color(0xFFF6ECEA),
    inkSoft: Color(0xFFD1C2C0),
    muted: Color(0xFF8F8183),
    line: Color(0xFF2E2427),
    field: Color(0xFF261E20),
    accent: Color(0xFFFF8A72),
    accentDeep: Color(0xFFE5674F),
    accentGlow: Color(0xFFFFB5A4),
    onAccent: Color(0xFF2B0E08),
    accentWash: Color(0xFF3A211C),
    error: Color(0xFFF58FA3),
    eye: Color(0xFFFFFDFB),
    face: Color(0xFF241A1C),
    shadow: Color(0x66000000),
    scrim: Color(0x99000000),
  );

  @override
  Palette copyWith() => this;

  @override
  Palette lerp(Palette? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return Palette(
      paper: c(paper, other.paper),
      card: c(card, other.card),
      ink: c(ink, other.ink),
      inkSoft: c(inkSoft, other.inkSoft),
      muted: c(muted, other.muted),
      line: c(line, other.line),
      field: c(field, other.field),
      accent: c(accent, other.accent),
      accentDeep: c(accentDeep, other.accentDeep),
      accentGlow: c(accentGlow, other.accentGlow),
      onAccent: c(onAccent, other.onAccent),
      accentWash: c(accentWash, other.accentWash),
      error: c(error, other.error),
      eye: c(eye, other.eye),
      face: c(face, other.face),
      shadow: c(shadow, other.shadow),
      scrim: c(scrim, other.scrim),
    );
  }
}

extension PaletteContext on BuildContext {
  Palette get palette => Theme.of(this).extension<Palette>()!;
}
