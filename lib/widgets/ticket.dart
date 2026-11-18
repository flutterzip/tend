import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/palette.dart';
import '../config/theme.dart';
import '../data/models.dart';
import 'doctor.dart';

/// "In 2 days", "Tomorrow at 10:30 AM", "In 40 min", "Now"
String until(DateTime start, DateTime now) {
  final d = start.difference(now);
  final days = dateOnly(start).difference(dateOnly(now)).inDays;
  final time = Slot(start.hour * 60 + start.minute).label;
  if (d.isNegative) return 'Now';
  if (d.inMinutes < 60) return 'In ${d.inMinutes} min';
  if (days == 0) return 'Today at $time';
  if (days == 1) return 'Tomorrow at $time';
  return 'In $days days';
}

/// The booking as a ticket: the doctor on top, a perforated line with
/// notches, and a stub with the day, time, place and a barcode. [tear]
/// (0..1) pulls the stub down and away, as if torn off.
class BookingTicket extends StatelessWidget {
  const BookingTicket({super.key, required this.doctor, required this.appointment, this.tear = 0});

  final Doctor doctor;
  final Appointment appointment;
  final double tear;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    const paperInk = Color(0xFF241A1C);
    const soft = Color(0xFF7A6A6C);
    final start = appointment.start;
    final top = Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          DoctorPortrait(doctor: doctor, size: 58),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doctor.name, style: text.titleMedium!.copyWith(color: paperInk)),
                Text(doctor.specialty, style: text.bodySmall!.copyWith(color: p.accentDeep)),
                Text(appointment.reason.label, style: text.bodySmall!.copyWith(color: soft)),
              ],
            ),
          ),
        ],
      ),
    );
    final stub = Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _Field('Date', dayLabel(start))),
              Expanded(child: _Field('Time', Slot(start.hour * 60 + start.minute).label)),
              Expanded(child: _Field('Fee', money(doctor.fee))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.place_outlined, size: 16, color: p.accentDeep),
              const SizedBox(width: 6),
              Expanded(child: Text(doctor.clinic, style: text.bodySmall!.copyWith(color: soft), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(height: 46, child: CustomPaint(painter: _BarcodePainter(appointment.id), size: const Size(double.infinity, 46))),
          const SizedBox(height: 4),
          Text(appointment.id.toUpperCase().replaceAll('-', '').padRight(10, '0').substring(0, 10), style: text.labelSmall!.copyWith(color: soft, letterSpacing: 3)),
        ],
      ),
    );
    return Semantics(
      label: 'Appointment with ${doctor.name}, ${dayLabel(start)} at ${Slot(start.hour * 60 + start.minute).label}',
      child: Column(
        children: [
          _Paper(color: p.eye, notches: _Notches.bottom, child: top),
          Transform.translate(
            offset: Offset(tear * 8, tear * 26),
            child: Transform.rotate(
              angle: tear * 0.06,
              alignment: Alignment.topLeft,
              child: _Paper(color: p.eye, notches: _Notches.top, dashed: true, child: stub),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value);

  final String label, value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: text.labelSmall!.copyWith(color: const Color(0xFF7A6A6C))),
        const SizedBox(height: 2),
        FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: text.titleMedium!.copyWith(color: const Color(0xFF241A1C)))),
      ],
    );
  }
}

enum _Notches { top, bottom }

/// A piece of ticket paper with half-circle notches cut at the tear line.
class _Paper extends StatelessWidget {
  const _Paper({required this.color, required this.notches, required this.child, this.dashed = false});

  final Color color;
  final _Notches notches;
  final Widget child;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return PhysicalShape(
      clipper: _TicketClipper(notches),
      color: color,
      elevation: 6,
      shadowColor: p.shadow,
      child: CustomPaint(
        foregroundPainter: dashed ? _DashPainter(p.line) : null,
        child: child,
      ),
    );
  }
}

class _TicketClipper extends CustomClipper<Path> {
  _TicketClipper(this.notches);

  final _Notches notches;

  @override
  Path getClip(Size s) {
    const r = Tokens.cardRadius - 6;
    const n = 12.0;
    final top = notches == _Notches.top;
    final shape = Path()
      ..addRRect(RRect.fromRectAndCorners(
        Offset.zero & s,
        topLeft: Radius.circular(top ? 6 : r),
        topRight: Radius.circular(top ? 6 : r),
        bottomLeft: Radius.circular(top ? r : 6),
        bottomRight: Radius.circular(top ? r : 6),
      ));
    final y = top ? 0.0 : s.height;
    final cut = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, y), radius: n))
      ..addOval(Rect.fromCircle(center: Offset(s.width, y), radius: n));
    return Path.combine(PathOperation.difference, shape, cut);
  }

  @override
  bool shouldReclip(_TicketClipper old) => old.notches != notches;
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas c, Size s) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var x = 20.0; x < s.width - 20; x += 10) {
      c.drawLine(Offset(x, 1), Offset(x + 5, 1), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

class _BarcodePainter extends CustomPainter {
  _BarcodePainter(this.seed);

  final String seed;

  @override
  void paint(Canvas c, Size s) {
    final rng = math.Random(seed.hashCode);
    final paint = Paint()..color = const Color(0xFF241A1C);
    var x = 0.0;
    while (x < s.width) {
      final w = 1.0 + rng.nextInt(3) * 1.2;
      if (rng.nextBool()) c.drawRect(Rect.fromLTWH(x, 0, w, s.height), paint);
      x += w + 1.4;
    }
  }

  @override
  bool shouldRepaint(_BarcodePainter old) => old.seed != seed;
}

/// An appointment in a list: the doctor, when, and a ring that fills as it
/// gets closer (a full ring is today). [prominent] makes it the accent card
/// on Learn.
class AppointmentCard extends StatelessWidget {
  const AppointmentCard({super.key, required this.doctor, required this.appointment, required this.now, this.onTap, this.trailing, this.prominent = false});

  final Doctor doctor;
  final Appointment appointment;
  final DateTime now;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final start = appointment.start;
    final past = !appointment.end.isAfter(now);
    final daysAway = start.difference(now).inMinutes / (60 * 24);
    final closeness = (1 - daysAway / 14).clamp(0.0, 1.0);
    final fg = prominent ? p.onAccent : p.ink;
    final soft = prominent ? p.onAccent.withValues(alpha: 0.8) : p.inkSoft;
    final label = appointment.cancelled ? 'Cancelled' : (past ? 'Done' : until(start, now));
    return Semantics(
      button: onTap != null,
      label: '${doctor.name}, ${dayLabel(start)}, $label',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(Tokens.cardRadius - 4),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: prominent ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [p.accent, p.accentDeep]) : null,
            color: prominent ? null : p.card.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(Tokens.cardRadius - 4),
            border: prominent ? null : Border.all(color: p.line),
            boxShadow: prominent ? [BoxShadow(color: p.accent.withValues(alpha: 0.35), blurRadius: 26, offset: const Offset(0, 12))] : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DoctorPortrait(doctor: doctor, size: 50, ring: prominent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doctor.name, style: text.titleMedium!.copyWith(color: fg), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('${doctor.specialty} · ${appointment.reason.label}', style: text.bodySmall!.copyWith(color: soft), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  if (!past && !appointment.cancelled)
                    Ring(
                      value: closeness,
                      size: 44,
                      stroke: 4,
                      color: prominent ? p.onAccent : p.accent,
                      track: prominent ? p.onAccent.withValues(alpha: 0.25) : p.line,
                      child: Icon(Icons.schedule_rounded, size: 18, color: prominent ? p.onAccent : p.accentDeep),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: prominent ? p.onAccent.withValues(alpha: 0.16) : p.field,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 15, color: soft),
                    const SizedBox(width: 6),
                    Text(dayLabel(start), style: text.labelMedium!.copyWith(color: fg)),
                    const SizedBox(width: 14),
                    Icon(Icons.access_time_rounded, size: 15, color: soft),
                    const SizedBox(width: 6),
                    Text(Slot(start.hour * 60 + start.minute).label, style: text.labelMedium!.copyWith(color: fg)),
                    const Spacer(),
                    Flexible(
                      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.labelMedium!.copyWith(color: prominent ? p.onAccent : p.accentDeep, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(height: 12), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}
