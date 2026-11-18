import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/store.dart';
import '../../widgets/widgets.dart';
import '../confirm/confirm_screen.dart';

/// A doctor, and the calendar to book them. Given [moving], it picks a new
/// time for an existing appointment instead.
class DoctorScreen extends ConsumerStatefulWidget {
  const DoctorScreen({super.key, required this.doctor, this.moving});

  final Doctor doctor;
  final Appointment? moving;

  @override
  ConsumerState<DoctorScreen> createState() => _DoctorScreenState();
}

class _DoctorScreenState extends ConsumerState<DoctorScreen> {
  late final DateTime today = dateOnly(ref.read(clockProvider)());
  late DateTime day = firstOpenDay(ref, widget.doctor.id, today, ignoring: widget.moving?.id);
  Slot? slot;

  Doctor get doctor => widget.doctor;

  Set<Slot> freeOn(DateTime d) => ref.read(freeSlotsProvider((doctorId: doctor.id, day: d, ignoring: widget.moving?.id)));

  void pickDay(DateTime d) => setState(() {
        day = d;
        slot = null;
      });

  void book() => context.open(ConfirmScreen(doctor: doctor, day: day, slot: slot!, moving: widget.moving));

  @override
  Widget build(BuildContext context) {
    final free = ref.watch(freeSlotsProvider((doctorId: doctor.id, day: day, ignoring: widget.moving?.id)));
    final text = Theme.of(context).textTheme;
    final p = context.palette;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(Tokens.gutter, MediaQuery.paddingOf(context).top + 8, Tokens.gutter, 200),
            children: [
              Row(children: [RoundButton(icon: Icons.arrow_back_rounded, label: 'Back', onTap: () => Navigator.of(context).pop())]),
              const SizedBox(height: 6),
              Center(child: Hero(tag: 'doctor-${doctor.id}', child: DoctorPortrait(doctor: doctor, size: 132, ring: true))),
              const SizedBox(height: 16),
              Entrance(
                spacing: 20,
                children: [
                  Column(
                    children: [
                      Text(doctor.name, style: text.headlineSmall, textAlign: TextAlign.center),
                      const SizedBox(height: 4),
                      Text('${doctor.specialty} · ${doctor.focus}', style: text.bodyMedium!.copyWith(color: p.accentDeep), textAlign: TextAlign.center),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: Stat(value: '${doctor.reviews}+', label: 'patients', icon: Icons.people_alt_outlined)),
                      const SizedBox(width: 10),
                      Expanded(child: Stat(value: '${doctor.years}', label: 'years', icon: Icons.workspace_premium_outlined)),
                      const SizedBox(width: 10),
                      Expanded(child: Stat(value: '${doctor.rating}', label: 'rating', icon: Icons.star_rounded)),
                    ],
                  ),
                  Text(doctor.about, style: text.bodyMedium),
                  DateStrip(start: today, selected: day, onSelect: pickDay, isOpen: (d) => freeOn(d).isNotEmpty),
                  SlotGrid(free: free, selected: slot, onSelect: (s) => setState(() => slot = s)),
                ],
              ),
            ],
          ),
          Positioned(
            left: Tokens.gutter - 6,
            right: Tokens.gutter - 6,
            bottom: MediaQuery.paddingOf(context).bottom + 88,
            child: ActionDock(
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(money(doctor.fee), style: text.titleLarge),
                      Text('per visit', style: text.labelSmall),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TendButton(
                      label: slot == null ? 'Pick a time' : '${widget.moving == null ? 'Book' : 'Move to'} ${slot!.label}',
                      icon: Icons.event_available_rounded,
                      onPressed: slot == null ? null : book,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
