import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tend/config/timing.dart';
import 'package:tend/data/models.dart';
import 'package:tend/state/store.dart';

import '../helpers.dart';

Future<ProviderContainer> container([Map<String, Object> prefs = const {}]) async {
  AppTiming.scale = 0;
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [
    prefsProvider.overrideWithValue(sp),
    seedProvider.overrideWithValue(testSeed),
    clockProvider.overrideWithValue(() => testNow),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('seeded visits land relative to today', () async {
    final c = await container();
    final up = c.read(upcomingProvider).single;
    expect(up.start, DateTime(2026, 11, 20, 10, 30));
    expect(c.read(pastProvider).single.id, 'old');
  });

  test('slots: past, Sundays, the seeded pattern and your bookings are not free', () async {
    final c = await container();
    final today = dateOnly(testNow);
    final freeToday = c.read(freeSlotsProvider((doctorId: 'heart', day: today, ignoring: null)));
    expect(freeToday.contains(const Slot(540)), isFalse, reason: '9:00 has passed at 9:05');
    final sunday = DateTime(2026, 11, 22);
    expect(c.read(freeSlotsProvider((doctorId: 'heart', day: sunday, ignoring: null))), isEmpty);
    final tomorrow = today.add(const Duration(days: 1));
    final free = c.read(freeSlotsProvider((doctorId: 'kids', day: tomorrow, ignoring: null)));
    expect(free, isNotEmpty);
    expect(free.length, lessThan(openSlots.length), reason: 'some slots are always taken');
    final slot = free.first;
    await c.read(appointmentsProvider.notifier).book('kids', tomorrow, slot, Reason.checkUp);
    expect(c.read(freeSlotsProvider((doctorId: 'kids', day: tomorrow, ignoring: null))).contains(slot), isFalse);
  });

  test('booking, moving and cancelling with undo', () async {
    final c = await container();
    final notifier = c.read(appointmentsProvider.notifier);
    final day = DateTime(2026, 11, 24);
    final a = await notifier.book('skin', day, const Slot(900), Reason.newProblem);
    expect(c.read(upcomingProvider).map((x) => x.id), contains(a.id));
    await notifier.reschedule(a.id, day, const Slot(960));
    expect(c.read(appointmentsProvider).firstWhere((x) => x.id == a.id).start, DateTime(2026, 11, 24, 16));
    final undo = notifier.cancel(a.id)!;
    expect(c.read(upcomingProvider).map((x) => x.id), isNot(contains(a.id)));
    expect(c.read(pastProvider).first.cancelled, isTrue);
    notifier.restore(undo);
    expect(c.read(upcomingProvider).map((x) => x.id), contains(a.id));
  });

  test('visits and sign in survive a restart', () async {
    final c = await container();
    await c.read(signedInProvider.notifier).signIn();
    await c.read(appointmentsProvider.notifier).book('skin', DateTime(2026, 11, 25), const Slot(600), Reason.results);
    final prefs = c.read(prefsProvider);
    final c2 = await container({
      'tend.signedIn.v1': prefs.getBool('tend.signedIn.v1')!,
      'tend.appointments.v1': prefs.getString('tend.appointments.v1')!,
    });
    expect(c2.read(signedInProvider), isTrue);
    expect(c2.read(appointmentsProvider).length, 3);
  });

  test('labels', () {
    expect(const Slot(810).label, '1:30 PM');
    expect(dayLabel(DateTime(2026, 11, 24)), 'Tue 24 Nov');
    expect(money(6200), '\$62.00');
  });
}
