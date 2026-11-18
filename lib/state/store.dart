import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/motion.dart';
import '../config/timing.dart';
import '../data/models.dart';

/// The bundled seed: doctors and the demo person with their appointments
/// (given as days from today, so the demo never goes stale).
class Seed {
  const Seed({required this.doctors, required this.profile, required this.appointments});

  final List<Doctor> doctors;
  final Profile profile;

  /// (doctor, days from today, time, reason)
  final List<({String id, String doctorId, int days, Slot time, Reason reason})> appointments;

  Doctor doctor(String id) => doctors.firstWhere((d) => d.id == id);

  List<String> get specialties => {for (final d in doctors) d.specialty}.toList();

  static Future<Seed> load([AssetBundle? bundle]) async {
    final b = bundle ?? rootBundle;
    final doctors = jsonDecode(await b.loadString('assets/data/doctors.json')) as List;
    final p = jsonDecode(await b.loadString('assets/data/profile.json')) as Map<String, Object?>;
    return Seed(
      doctors: [for (final d in doctors) Doctor.fromJson(d as Map<String, Object?>)],
      profile: Profile(
        name: p['name'] as String,
        email: p['email'] as String,
        avatar: p['avatar'] as String?,
        bloodType: p['bloodType'] as String,
        heartRate: p['heartRate'] as int,
        allergies: [for (final a in p['allergies'] as List) a as String],
      ),
      appointments: [
        for (final a in p['appointments'] as List)
          (
            id: (a as Map<String, Object?>)['id'] as String,
            doctorId: a['doctorId'] as String,
            days: a['daysFromNow'] as int,
            time: Slot.parse(a['time'] as String),
            reason: Reason.values.firstWhere((r) => r.label == a['reason'], orElse: () => Reason.checkUp),
          ),
      ],
    );
  }
}

final seedProvider = Provider<Seed>((_) => throw UnimplementedError());
final prefsProvider = Provider<SharedPreferences>((_) => throw UnimplementedError());
final clockProvider = Provider<DateTime Function()>((_) => DateTime.now);

/// Ticks every 30 seconds while ambient motion is on, for countdowns.
final tickProvider = StreamProvider<int>((ref) {
  if (!Motion.ambient) return const Stream.empty();
  return Stream.periodic(const Duration(seconds: 30), (i) => i);
});

final nowProvider = Provider<DateTime>((ref) {
  ref.watch(tickProvider);
  return ref.watch(clockProvider)();
});

int _ids = 0;

// ------------------------------------------------------------- session

/// Signed in or not, saved so a relaunch resumes in the right place.
final signedInProvider = NotifierProvider<SignedInNotifier, bool>(SignedInNotifier.new);

class SignedInNotifier extends Notifier<bool> {
  static const _key = 'tend.signedIn.v1';

  @override
  bool build() => ref.read(prefsProvider).getBool(_key) ?? false;

  Future<void> signIn() async {
    await AppTiming.wait(AppTiming.signIn);
    state = true;
    await ref.read(prefsProvider).setBool(_key, true);
  }

  Future<void> signOut() async {
    state = false;
    await ref.read(prefsProvider).setBool(_key, false);
  }
}

// ------------------------------------------------------------- appointments

final appointmentsProvider = NotifierProvider<AppointmentsNotifier, List<Appointment>>(AppointmentsNotifier.new);

class AppointmentsNotifier extends Notifier<List<Appointment>> {
  static const _key = 'tend.appointments.v1';

  SharedPreferences get _prefs => ref.read(prefsProvider);

  @override
  List<Appointment> build() {
    final raw = _prefs.getString(_key);
    if (raw != null) {
      try {
        return [for (final a in jsonDecode(raw) as List) Appointment.fromJson(a as Map<String, Object?>)];
      } catch (_) {}
    }
    final today = dateOnly(ref.read(clockProvider)());
    return [
      for (final a in ref.read(seedProvider).appointments)
        Appointment(
          id: a.id,
          doctorId: a.doctorId,
          start: today.add(Duration(days: a.days, minutes: a.time.minutes)),
          reason: a.reason,
        ),
    ];
  }

  void _save(List<Appointment> next) {
    state = next;
    _prefs.setString(_key, jsonEncode([for (final a in next) a.toJson()]));
  }

  Future<Appointment> book(String doctorId, DateTime day, Slot slot, Reason reason) async {
    await AppTiming.wait(AppTiming.book);
    final now = ref.read(clockProvider)();
    final a = Appointment(
      id: '${now.microsecondsSinceEpoch}-${_ids++}',
      doctorId: doctorId,
      start: dateOnly(day).add(Duration(minutes: slot.minutes)),
      reason: reason,
    );
    _save([...state, a]);
    return a;
  }

  /// Moves an appointment to a new day and time.
  Future<void> reschedule(String id, DateTime day, Slot slot) async {
    await AppTiming.wait(AppTiming.book);
    _save([for (final a in state) a.id == id ? a.copyWith(start: dateOnly(day).add(Duration(minutes: slot.minutes))) : a]);
  }

  /// Cancels, handing back what is needed to undo it.
  Appointment? cancel(String id) {
    final a = state.where((a) => a.id == id).firstOrNull;
    if (a == null) return null;
    _save([for (final x in state) x.id == id ? x.copyWith(cancelled: true) : x]);
    return a;
  }

  void restore(Appointment a) => _save([for (final x in state) x.id == a.id ? a : x]);
}

/// Upcoming (soonest first) and past (latest first), cancelled ones left out
/// of upcoming.
final upcomingProvider = Provider<List<Appointment>>((ref) {
  final now = ref.watch(nowProvider);
  return ref.watch(appointmentsProvider).where((a) => !a.cancelled && a.end.isAfter(now)).toList()..sort((a, b) => a.start.compareTo(b.start));
});

final pastProvider = Provider<List<Appointment>>((ref) {
  final now = ref.watch(nowProvider);
  return ref.watch(appointmentsProvider).where((a) => a.cancelled || !a.end.isAfter(now)).toList()..sort((a, b) => b.start.compareTo(a.start));
});

/// Whether a doctor has [slot] free on [day]. Some slots are always taken
/// (a stable pattern per doctor and day), plus anything you booked, plus
/// anything already past.
bool isFree(Ref ref, String doctorId, DateTime day, Slot slot, {String? ignoring}) {
  final d = dateOnly(day);
  final start = d.add(Duration(minutes: slot.minutes));
  if (!start.isAfter(ref.read(clockProvider)())) return false;
  if (d.weekday == DateTime.sunday) return false;
  final seedTaken = Object.hash(doctorId, d.year, d.month, d.day, slot.minutes).abs() % 3 == 0;
  if (seedTaken) return false;
  return !ref.read(appointmentsProvider).any((a) => !a.cancelled && a.id != ignoring && a.doctorId == doctorId && a.start == start);
}

/// Free slots for a doctor on a day, from a widget.
final freeSlotsProvider = Provider.family<Set<Slot>, ({String doctorId, DateTime day, String? ignoring})>((ref, q) {
  ref.watch(appointmentsProvider);
  ref.watch(nowProvider);
  return {for (final s in openSlots) if (isFree(ref, q.doctorId, q.day, s, ignoring: q.ignoring)) s};
});

/// The first day within two weeks of [today] with anything free.
DateTime firstOpenDay(WidgetRef ref, String doctorId, DateTime today, {String? ignoring}) {
  for (var i = 0; i < 14; i++) {
    final d = today.add(Duration(days: i));
    if (ref.read(freeSlotsProvider((doctorId: doctorId, day: d, ignoring: ignoring))).isNotEmpty) return d;
  }
  return today;
}

// ------------------------------------------------------------- settings

class DemoSettings {
  const DemoSettings({this.theme = ThemeMode.system});

  final ThemeMode theme;
}

final demoSettingsProvider = NotifierProvider<DemoSettingsNotifier, DemoSettings>(DemoSettingsNotifier.new);

class DemoSettingsNotifier extends Notifier<DemoSettings> {
  static const _theme = 'tend.theme.v1';

  @override
  DemoSettings build() =>
      DemoSettings(theme: ThemeMode.values.asNameMap()[ref.read(prefsProvider).getString(_theme)] ?? ThemeMode.system);

  Future<void> setTheme(ThemeMode mode) async {
    state = DemoSettings(theme: mode);
    await ref.read(prefsProvider).setString(_theme, mode.name);
  }
}

Future<void> resetDemo(WidgetRef ref) async {
  await ref.read(prefsProvider).clear();
  ref.invalidate(appointmentsProvider);
  ref.invalidate(signedInProvider);
  ref.invalidate(demoSettingsProvider);
}
