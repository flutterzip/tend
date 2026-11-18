import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/store.dart';
import '../../widgets/widgets.dart';
import '../doctor/doctor_screen.dart';
import '../shell/shell.dart';

/// Upcoming and past visits. Swipe one away to cancel (with undo), or move
/// it to another time.
class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  bool past = false;

  void cancel(Appointment a) {
    final undo = ref.read(appointmentsProvider.notifier).cancel(a.id);
    if (undo == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Visit with ${ref.read(seedProvider).doctor(a.doctorId).shortName} cancelled'),
        action: SnackBarAction(label: 'Undo', onPressed: () => ref.read(appointmentsProvider.notifier).restore(undo)),
      ));
  }

  void move(Appointment a) => openInHome(ref, DoctorScreen(doctor: ref.read(seedProvider).doctor(a.doctorId), moving: a));

  @override
  Widget build(BuildContext context) {
    final seed = ref.watch(seedProvider);
    final now = ref.watch(nowProvider);
    final list = ref.watch(past ? pastProvider : upcomingProvider);
    final text = Theme.of(context).textTheme;
    final p = context.palette;

    return ListView(
      padding: EdgeInsets.fromLTRB(Tokens.gutter, MediaQuery.paddingOf(context).top + 12, Tokens.gutter, 130),
      children: [
        Text('Your visits', style: text.headlineSmall),
        Text(past ? 'Everything you have been to.' : 'Swipe a visit away to cancel it.', style: text.bodyMedium),
        const SizedBox(height: 18),
        Segments<bool>(
          values: const [false, true],
          value: past,
          label: (v) => v ? 'Past' : 'Upcoming',
          onChanged: (v) => setState(() => past = v),
        ),
        const SizedBox(height: 18),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: EmptyState(
              art: BeatingHeart(size: 72, color: p.accentGlow),
              title: past ? 'Nothing yet' : 'No visits coming up',
              message: past ? 'Visits you have been to will show here.' : 'Book a doctor from Home and it will wait for you here.',
              action: past ? null : TendButton(label: 'Find a doctor', onPressed: () => ref.read(tabProvider.notifier).state = 0),
            ),
          ),
        for (final a in list) ...[
          past
              ? AppointmentCard(doctor: seed.doctor(a.doctorId), appointment: a, now: now)
              : Dismissible(
                  key: ValueKey(a.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => cancel(a),
                  background: const SwipeToCancel(),
                  child: AppointmentCard(
                    doctor: seed.doctor(a.doctorId),
                    appointment: a,
                    now: now,
                    trailing: Row(
                      children: [
                        Expanded(child: TendButton.ghost(label: 'Move', icon: Icons.edit_calendar_rounded, onPressed: () => move(a))),
                        const SizedBox(width: 10),
                        Expanded(child: TendButton.ghost(label: 'Cancel', icon: Icons.close_rounded, onPressed: () => cancel(a))),
                      ],
                    ),
                  ),
                ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}
