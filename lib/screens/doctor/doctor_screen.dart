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
  final scroll = ScrollController();

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

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
    // The device's own inset: the tab bar slides away on this page, so the
    // padding the shell reserves for it does not apply.
    final safe = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          ListView(
            controller: scroll,
            padding: EdgeInsets.fromLTRB(Tokens.gutter, TopChrome.extent(context), Tokens.gutter, safe + 120),
            children: [
              Center(
                child: Hero(
                  tag: 'doctor-${doctor.id}',
                  child: DoctorPortrait(doctor: doctor, size: 132, ring: true),
                ),
              ),
              const SizedBox(height: 16),
              Entrance(
                spacing: 20,
                children: [
                  Column(
                    children: [
                      Text(doctor.name, style: text.headlineSmall, textAlign: TextAlign.center),
                      const SizedBox(height: 4),
                      Text(
                        '${doctor.specialty} · ${doctor.focus}',
                        style: text.bodyMedium!.copyWith(color: p.accentDeep),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Stat(value: '${doctor.reviews}+', label: 'patients', icon: Icons.people_alt_outlined),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Stat(value: '${doctor.years}', label: 'years', icon: Icons.workspace_premium_outlined),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Stat(value: '${doctor.rating}', label: 'rating', icon: Icons.star_rounded),
                      ),
                    ],
                  ),
                  Text(doctor.about, style: text.bodyMedium),
                  DateStrip(start: today, selected: day, onSelect: pickDay, isOpen: (d) => freeOn(d).isNotEmpty),
                  SlotGrid(free: free, selected: slot, onSelect: (s) => setState(() => slot = s)),
                ],
              ),
            ],
          ),
          // The page fades into the paper under the dock.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: safe + 110,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [p.paper.withValues(alpha: 0), p.paper.withValues(alpha: 0.9), p.paper],
                    stops: const [0, 0.5, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: Tokens.gutter - 6,
            right: Tokens.gutter - 6,
            bottom: safe + 12,
            child: ActionDock(
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(money(doctor.fee), style: text.titleLarge),
                      // Once a time is chosen, the day it books.
                      Text(slot == null ? 'per visit' : dayLabel(day), style: text.labelSmall!.copyWith(color: slot == null ? null : p.accentDeep)),
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
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: TopChrome(
              controller: scroll,
              title: doctor.name,
              titleAfter: 180,
              leading: RoundButton(icon: Icons.arrow_back_rounded, label: 'Back', onTap: () => Navigator.of(context).pop()),
            ),
          ),
        ],
      ),
    );
  }
}
