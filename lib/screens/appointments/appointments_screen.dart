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
  final scroll = ScrollController();

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  void cancel(Appointment a) {
    final undo = ref.read(appointmentsProvider.notifier).cancel(a.id);
    if (undo == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Visit with ${ref.read(seedProvider).doctor(a.doctorId).shortName} cancelled'),
          action: SnackBarAction(label: 'Undo', onPressed: () => ref.read(appointmentsProvider.notifier).restore(undo)),
        ),
      );
  }

  void move(Appointment a) => openInHome(ref, DoctorScreen(doctor: ref.read(seedProvider).doctor(a.doctorId), moving: a));

  @override
  Widget build(BuildContext context) {
    final seed = ref.watch(seedProvider);
    final now = ref.watch(nowProvider);
    final list = ref.watch(past ? pastProvider : upcomingProvider);
    final text = Theme.of(context).textTheme;
    final p = context.palette;

    // The heading stays put; Upcoming and Past slide away while you read
    // down and come back the moment you scroll up.
    return Stack(
      children: [
        ListView(
          controller: scroll,
          padding: EdgeInsets.fromLTRB(Tokens.gutter, TopChrome.extent(context, bottomHeight: _segmentsHeight) + 4, Tokens.gutter, 130),
          children: [
            Text(past ? 'Everything you have been to.' : 'Swipe a visit away to cancel it.', style: text.bodyMedium),
            const SizedBox(height: 14),
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
                            Expanded(
                              child: TendButton.ghost(label: 'Move', icon: Icons.edit_calendar_rounded, onPressed: () => move(a)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TendButton.ghost(label: 'Cancel', icon: Icons.close_rounded, onPressed: () => cancel(a)),
                            ),
                          ],
                        ),
                      ),
                    ),
              const SizedBox(height: 14),
            ],
          ],
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: TopChrome(
            controller: scroll,
            row: Align(
              alignment: Alignment.centerLeft,
              child: Text('Your visits', style: text.headlineSmall),
            ),
            bottomHeight: _segmentsHeight,
            bottom: Padding(
              padding: const EdgeInsets.fromLTRB(Tokens.gutter, 2, Tokens.gutter, 12),
              child: Segments<bool>(values: const [false, true], value: past, label: (v) => v ? 'Past' : 'Upcoming', onChanged: (v) => setState(() => past = v)),
            ),
          ),
        ),
      ],
    );
  }

  static const _segmentsHeight = 2 + 52 + 12.0;
}
