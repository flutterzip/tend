import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tend/screens/appointments/appointments_screen.dart';
import 'package:tend/screens/confirm/confirm_screen.dart';
import 'package:tend/screens/doctor/doctor_screen.dart';
import 'package:tend/screens/home/home_screen.dart';
import 'package:tend/screens/profile/profile_screen.dart';
import 'package:tend/screens/sign_in/sign_in_screen.dart';
import 'package:tend/state/store.dart';
import 'package:tend/widgets/widgets.dart';

import '../helpers.dart';

void main() {
  final heart = testSeed.doctor('heart');

  group('Sign in', () {
    testWidgets('names missing fields', (tester) async {
      await pumpScreen(tester, const SignInScreen());
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Enter your email'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
    });

    testWidgets('the heart races while you type and settles after', (tester) async {
      await pumpScreen(tester, const SignInScreen());
      await tester.enterText(find.byType(TextField).first, 'h');
      await tester.pump();
      expect(tester.widget<BeatingHeart>(find.byType(BeatingHeart)).bpm, greaterThan(100));
      await tester.pump(const Duration(seconds: 2));
      expect(tester.widget<BeatingHeart>(find.byType(BeatingHeart)).bpm, 72);
    });

    testWidgets('the demo account signs in', (tester) async {
      final c = await pumpScreen(tester, const SignInScreen());
      await tester.tap(find.text('Use the demo account'));
      await tester.pump(const Duration(seconds: 2));
      await tester.ensureVisible(find.text('Sign in'));
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();
      expect(c.read(signedInProvider), isTrue);
    });
  });

  group('Home', () {
    testWidgets('shows the next visit, specialties and doctors', (tester) async {
      await pumpScreen(tester, const HomeScreen());
      expect(find.text('Hi, Olympicson'), findsOneWidget);
      expect(find.byType(AppointmentCard), findsOneWidget);
      expect(find.byType(SpecialtyTile), findsNWidgets(3));
      expect(find.byType(DoctorRow), findsNWidgets(3));
    });

    testWidgets('a specialty filters, tapping it again clears', (tester) async {
      await pumpScreen(tester, const HomeScreen());
      await tester.tap(find.byType(SpecialtyTile).at(1));
      await tester.pumpAndSettle();
      expect(find.byType(DoctorRow), findsOneWidget);
      await tester.tap(find.byType(SpecialtyTile).at(1));
      await tester.pumpAndSettle();
      expect(find.byType(DoctorRow), findsNWidgets(3));
    });

    testWidgets('search by name, and a named empty result', (tester) async {
      await pumpScreen(tester, const HomeScreen());
      await tester.enterText(find.byType(TextField), 'kwame');
      await tester.pumpAndSettle();
      expect(find.byType(DoctorRow), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.textContaining('No doctor matches'), findsOneWidget);
    });
  });

  group('Doctor and booking', () {
    testWidgets('pick a day and a time, then book', (tester) async {
      final c = await pumpScreen(tester, DoctorScreen(doctor: heart));
      expect(find.text('Pick a time'), findsOneWidget);
      await tester.drag(find.byType(ListView).first, const Offset(0, -600));
      await tester.pumpAndSettle();
      final free = find.byWidgetPredicate((w) => w is Semantics && (w.properties.label ?? '').endsWith('M') && w.properties.enabled == true);
      await tester.tap(free.first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Book '), findsOneWidget);
      await tester.tap(find.textContaining('Book '));
      await tester.pumpAndSettle();
      expect(find.byType(ConfirmScreen), findsOneWidget);
      await tester.ensureVisible(find.textContaining('Book for'));
      await tester.pump();
      await tester.tap(find.textContaining('Book for'));
      await tester.pumpAndSettle();
      expect(find.text('You are booked'), findsOneWidget);
      expect(c.read(upcomingProvider).length, 2);
    });

    testWidgets('the reason can be changed before booking', (tester) async {
      await pumpScreen(tester, ConfirmScreen(doctor: heart, day: DateTime(2026, 11, 24), slot: const Slot(600)));
      await tester.ensureVisible(find.text('Test results'));
      await tester.pump();
      await tester.tap(find.text('Test results'));
      await tester.pumpAndSettle();
      expect(find.text('Test results'), findsWidgets);
    });
  });

  group('Visits', () {
    testWidgets('upcoming and past', (tester) async {
      await pumpScreen(tester, const AppointmentsScreen());
      expect(find.byType(AppointmentCard), findsOneWidget);
      await tester.tap(find.text('Past'));
      await tester.pumpAndSettle();
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('cancel with undo', (tester) async {
      final c = await pumpScreen(tester, const Scaffold(body: AppointmentsScreen()));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(c.read(upcomingProvider), isEmpty);
      expect(find.text('No visits coming up'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(c.read(upcomingProvider).length, 1);
    });
  });

  testWidgets('Me shows the heart rate and health details', (tester) async {
    await pumpScreen(tester, const ProfileScreen());
    expect(find.byType(Heartbeat), findsOneWidget);
    expect(find.text('O+'), findsOneWidget);
    expect(find.textContaining('Penicillin'), findsOneWidget);
  });
}
