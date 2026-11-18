import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/motion.dart';
import '../config/palette.dart';
import '../data/models.dart';

/// A doctor's portrait, drawn: a disc in their step of the accent ramp, a
/// soft shoulder silhouette, a stethoscope curve and their initials.
class DoctorPortrait extends StatelessWidget {
  const DoctorPortrait({super.key, required this.doctor, this.size = 56, this.ring = false});

  final Doctor doctor;
  final double size;

  /// An accent ring around it (selected, or on the doctor's own page).
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: doctor.name,
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(ring ? size * 0.04 : 0),
        decoration: ring ? BoxDecoration(shape: BoxShape.circle, border: Border.all(color: p.accent, width: size * 0.025)) : null,
        child: CustomPaint(
          painter: _PortraitPainter(
            hue: doctor.hue,
            initials: doctor.initials,
            deep: p.accentDeep,
            mid: p.accent,
            light: p.accentGlow,
            wash: p.accentWash,
            text: p.onAccent,
          ),
        ),
      ),
    );
  }
}

class _PortraitPainter extends CustomPainter {
  _PortraitPainter({
    required this.hue,
    required this.initials,
    required this.deep,
    required this.mid,
    required this.light,
    required this.wash,
    required this.text,
  });

  final int hue;
  final String initials;
  final Color deep, mid, light, wash, text;

  @override
  void paint(Canvas c, Size s) {
    final r = s.width / 2;
    final ctr = Offset(r, r);
    final t = (hue % 4) / 3;
    final base = Color.lerp(Color.lerp(light, mid, 0.4)!, deep, t)!;
    c.save();
    c.clipPath(Path()..addOval(Offset.zero & s));
    c.drawCircle(ctr, r, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(s.width, s.height), [Color.lerp(base, light, 0.35)!, base]));
    // Shoulders and a white coat collar.
    final body = Path()
      ..moveTo(s.width * 0.1, s.height)
      ..quadraticBezierTo(s.width * 0.15, s.height * 0.72, s.width * 0.5, s.height * 0.7)
      ..quadraticBezierTo(s.width * 0.85, s.height * 0.72, s.width * 0.9, s.height)
      ..close();
    c.drawPath(body, Paint()..color = wash.withValues(alpha: 0.9));
    final collar = Path()
      ..moveTo(s.width * 0.38, s.height * 0.71)
      ..lineTo(s.width * 0.5, s.height * 0.86)
      ..lineTo(s.width * 0.62, s.height * 0.71);
    c.drawPath(collar, Paint()
      ..color = base
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.width * 0.03);
    // The stethoscope round the neck.
    c.drawArc(Rect.fromCenter(center: Offset(s.width * 0.5, s.height * 0.78), width: s.width * 0.42, height: s.height * 0.3), 0.2, math.pi - 0.4, false,
        Paint()
          ..color = deep
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.width * 0.025
          ..strokeCap = StrokeCap.round);
    c.drawCircle(Offset(s.width * 0.62, s.height * 0.92), s.width * 0.04, Paint()..color = deep);
    c.restore();
    final tp = TextPainter(
      text: TextSpan(text: initials, style: TextStyle(fontFamily: 'Bricolage', fontSize: s.width * 0.3, fontWeight: FontWeight.w800, color: text, letterSpacing: -0.5)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(r - tp.width / 2, s.height * 0.38 - tp.height / 2));
  }

  @override
  bool shouldRepaint(_PortraitPainter old) => old.hue != hue || old.mid != mid;
}

/// A doctor in a list: portrait, name, specialty, rating and fee.
class DoctorRow extends StatelessWidget {
  const DoctorRow({super.key, required this.doctor, required this.onTap, this.trailing});

  final Doctor doctor;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '${doctor.name}, ${doctor.specialty}',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: p.card.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(22), border: Border.all(color: p.line)),
          child: Row(
            children: [
              Hero(tag: 'doctor-${doctor.id}', child: DoctorPortrait(doctor: doctor, size: 60)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doctor.name, style: text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(doctor.specialty, style: text.bodySmall!.copyWith(color: p.accentDeep), maxLines: 1),
                    const SizedBox(height: 5),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Icon(Icons.star_rounded, size: 15, color: p.accent),
                          Text(' ${doctor.rating} (${doctor.reviews})', style: text.labelSmall),
                          const SizedBox(width: 10),
                          Icon(Icons.workspace_premium_outlined, size: 14, color: p.muted),
                          Text(' ${doctor.years} years', style: text.labelSmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ?? Text(money(doctor.fee), style: text.titleMedium!.copyWith(color: p.accentDeep)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A specialty as a round icon tile with its name; selected glows.
class SpecialtyTile extends StatelessWidget {
  const SpecialtyTile({super.key, required this.name, required this.selected, required this.onTap});

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: SizedBox(
          width: 78,
          child: Column(
            children: [
              AnimatedContainer(
                duration: Motion.medium,
                curve: Motion.spring,
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: selected ? p.accent : p.card.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: selected ? p.accent : p.line),
                  boxShadow: [BoxShadow(color: p.accent.withValues(alpha: selected ? 0.35 : 0), blurRadius: 16, offset: const Offset(0, 8))],
                ),
                child: AnimatedScale(
                  scale: selected ? 1.12 : 1,
                  duration: Motion.medium,
                  curve: Motion.spring,
                  child: Icon(specialtyIcon(name), color: selected ? p.onAccent : p.accentDeep, size: 26),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name.split(' ').first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall!.copyWith(color: selected ? p.accentDeep : p.inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An arc that fills to [value] (0..1) around [child].
class Ring extends StatelessWidget {
  const Ring({super.key, required this.value, this.size = 56, this.stroke = 6, this.child, this.color, this.track});

  final double value, size, stroke;
  final Widget? child;
  final Color? color, track;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.clamp(0.0, 1.0)),
      duration: Motion.ring,
      curve: Motion.settle,
      builder: (_, v, child) => CustomPaint(
        size: Size.square(size),
        painter: _RingPainter(v, stroke, color ?? p.accent, track ?? p.line),
        child: SizedBox.square(dimension: size, child: Center(child: child)),
      ),
      child: child,
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.v, this.stroke, this.color, this.track);

  final double v, stroke;
  final Color color, track;

  @override
  void paint(Canvas c, Size s) {
    final r = (Offset.zero & s).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    c.drawArc(r, 0, math.pi * 2, false, paint..color = track);
    if (v > 0) c.drawArc(r, -math.pi / 2, math.pi * 2 * v, false, paint..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.v != v || old.color != color;
}

/// A number with a label and an icon, in a small card.
class Stat extends StatelessWidget {
  const Stat({super.key, required this.value, required this.label, required this.icon});

  final String value, label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(color: p.card.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(20), border: Border.all(color: p.line)),
      child: Column(
        children: [
          Icon(icon, color: p.accent, size: 22),
          const SizedBox(height: 6),
          Text(value, style: text.titleLarge, maxLines: 1),
          Text(label, style: text.labelSmall, maxLines: 1),
        ],
      ),
    );
  }
}
