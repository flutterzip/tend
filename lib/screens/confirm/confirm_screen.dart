import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/store.dart';
import '../../widgets/widgets.dart';
import '../shell/shell.dart';

/// Check the booking, say why you are coming, book. Then a pulse, a tick
/// and the ticket tearing off its stub.
class ConfirmScreen extends ConsumerStatefulWidget {
  const ConfirmScreen({super.key, required this.doctor, required this.day, required this.slot, this.moving});

  final Doctor doctor;
  final DateTime day;
  final Slot slot;

  /// An appointment being moved to this time.
  final Appointment? moving;

  @override
  ConsumerState<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends ConsumerState<ConfirmScreen> with SingleTickerProviderStateMixin {
  late Reason reason = widget.moving?.reason ?? Reason.checkUp;
  late final tear = AnimationController(vsync: this, duration: Motion.tear);
  final scroll = ScrollController();
  bool busy = false, booked = false;

  Appointment get draft => Appointment(
        id: widget.moving?.id ?? 'TEND${widget.day.day}${widget.slot.minutes}',
        doctorId: widget.doctor.id,
        start: dateOnly(widget.day).add(Duration(minutes: widget.slot.minutes)),
        reason: reason,
      );

  Future<void> book() async {
    setState(() => busy = true);
    final appointments = ref.read(appointmentsProvider.notifier);
    if (widget.moving != null) {
      await appointments.reschedule(widget.moving!.id, widget.day, widget.slot);
    } else {
      await appointments.book(widget.doctor.id, widget.day, widget.slot, reason);
    }
    setState(() {
      busy = false;
      booked = true;
    });
    tear.forward();
  }

  void finish() {
    ref.read(tabProvider.notifier).state = 1;
    homeNavigator.currentState?.popUntil((r) => r.isFirst);
  }

  @override
  void dispose() {
    tear.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final moving = widget.moving != null;
    // The tab bar slides away on this page, so only the device's own inset.
    final safe = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          ListView(
            controller: scroll,
            padding: EdgeInsets.fromLTRB(Tokens.gutter, TopChrome.extent(context) + 4, Tokens.gutter, safe + 40),
            children: [
              AnimatedSwitcher(
                duration: Motion.medium,
                child: booked
                    ? Column(
                        key: const ValueKey('done'),
                        children: [
                          const PulseCheck(size: 96),
                          Text(moving ? 'Moved' : 'You are booked', style: text.headlineSmall),
                          const SizedBox(height: 4),
                          Text('We will remind you the day before.', style: text.bodyMedium),
                        ],
                      )
                    : Column(
                        key: const ValueKey('check'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(moving ? 'Your new time' : 'Your visit', style: text.headlineSmall),
                          const SizedBox(height: 4),
                          Text('Check the details, then book.', style: text.bodyMedium),
                        ],
                      ),
              ),
              const SizedBox(height: 22),
              AnimatedBuilder(
                animation: tear,
                builder: (context, _) => BookingTicket(doctor: widget.doctor, appointment: draft, tear: Curves.easeOutBack.transform(tear.value)),
              ),
              const SizedBox(height: 40),
              // Folds away once booked. It stays in the list (as nothing) so
              // the button below keeps its place and can morph.
              if (!moving)
                AnimatedSize(
                  duration: Motion.medium,
                  curve: Motion.settle,
                  alignment: Alignment.topCenter,
                  child: booked
                      ? const SizedBox(width: double.infinity)
                      : OptionSection(
                          title: 'Reason for the visit',
                          child: Choices<Reason>(values: Reason.values, value: reason, label: (r) => r.label, onChanged: (r) => setState(() => reason = r)),
                        ),
                ),
              const SizedBox(height: 24),
              // Booking breaks the button apart and it flies together as the way
              // to your visits.
              ParticleMorph(
                child: booked
                    ? TendButton(key: const ValueKey('visits'), label: 'See my visits', icon: Icons.event_note_rounded, onPressed: finish)
                    : TendButton(key: const ValueKey('book'), label: moving ? 'Move it' : 'Book for ${money(widget.doctor.fee)}', icon: Icons.lock_rounded, busy: busy, onPressed: book),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: TopChrome(
              controller: scroll,
              leading: booked ? null : RoundButton(icon: Icons.arrow_back_rounded, label: 'Back', onTap: () => Navigator.of(context).pop()),
              trailing: booked ? null : Text(moving ? 'Move appointment' : 'Confirm', style: text.titleMedium),
            ),
          ),
        ],
      ),
    );
  }
}
