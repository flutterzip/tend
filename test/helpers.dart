import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tend/config/motion.dart';
import 'package:tend/config/theme.dart';
import 'package:tend/config/timing.dart';
import 'package:tend/data/models.dart';
import 'package:tend/state/store.dart';
import 'package:tend/widgets/backdrop.dart';

/// A Wednesday morning.
final testNow = DateTime(2026, 11, 18, 9, 5);

Doctor doctor(String id, String name, String specialty, int hue) => Doctor(
      id: id,
      name: name,
      specialty: specialty,
      focus: '$specialty focus',
      years: 10,
      rating: 4.8 + hue / 100,
      reviews: 100,
      fee: 5000,
      clinic: 'Clinic',
      about: 'About $name.',
      hue: hue,
    );

final testSeed = Seed(
  doctors: [
    doctor('heart', 'Dr. Ada Okoro', 'Cardiology', 0),
    doctor('skin', 'Dr. Mei Tanaka', 'Dermatology', 1),
    doctor('kids', 'Dr. Kwame Asante', 'Pediatrics', 2),
  ],
  profile: const Profile(name: 'Olympicson', email: 'hello@flutterzip.com', bloodType: 'O+', heartRate: 72, allergies: ['Penicillin']),
  appointments: const [
    (id: 'up', doctorId: 'heart', days: 2, time: Slot(630), reason: Reason.followUp),
    (id: 'old', doctorId: 'skin', days: -10, time: Slot(540), reason: Reason.checkUp),
  ],
);

Future<ProviderContainer> pumpScreen(WidgetTester tester, Widget screen, {Map<String, Object> prefs = const {}}) async {
  Motion.ambient = false;
  AppTiming.scale = 0;
  tester.view.physicalSize = const Size(1320, 2868);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [
    prefsProvider.overrideWithValue(sp),
    seedProvider.overrideWithValue(testSeed),
    clockProvider.overrideWithValue(() => testNow),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light(),
      builder: (context, child) => PaperBackdrop(child: child!),
      home: Material(type: MaterialType.transparency, child: screen),
    ),
  ));
  await tester.pumpAndSettle();
  return container;
}
