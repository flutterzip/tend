// Screenshots of every screen on the simulator, light and dark:
//   tool/shots.sh
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tend/app.dart';
import 'package:tend/demo/demo_control.dart';
import 'package:tend/screens/confirm/confirm_screen.dart';
import 'package:tend/screens/doctor/doctor_screen.dart';
import 'package:tend/screens/shell/shell.dart';
import 'package:tend/state/store.dart';
import 'package:tend/widgets/widgets.dart';

const mode = String.fromEnvironment('mode', defaultValue: 'light');

Future<void> settle(WidgetTester t, [int ms = 1600]) async {
  final end = DateTime.now().add(Duration(milliseconds: ms));
  while (DateTime.now().isBefore(end)) {
    await t.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('shots $mode', (t) async {
    DemoControl.enabled = false;
    SharedPreferences.setMockInitialValues({'tend.theme.v1': mode});
    final prefs = await SharedPreferences.getInstance();
    final seed = await Seed.load();
    final c = ProviderContainer(overrides: [prefsProvider.overrideWithValue(prefs), seedProvider.overrideWithValue(seed)]);
    await t.pumpWidget(UncontrolledProviderScope(container: c, child: const TendApp(splash: false)));
    await settle(t, 2500);
    Future<void> shot(String name, [int ms = 1600]) async {
      await settle(t, ms);
      await binding.takeScreenshot('${name}_$mode');
    }

    await t.enterText(find.byType(TextField).first, 'hello@flutterzip.com');
    await shot('sign_in', 600);
    await c.read(signedInProvider.notifier).signIn();
    navigatorKey.currentState!.pushReplacement(TendRoute(const Shell()));
    await shot('home', 2200);

    final doctor = seed.doctor('adaeze-okoro');
    homeNavigator.currentState!.push(TendRoute(DoctorScreen(doctor: doctor)));
    await settle(t, 1500);
    await t.drag(find.byType(ListView).last, const Offset(0, -420));
    await settle(t, 800);
    // Tomorrow, so there are open morning slots whatever the time now.
    final days = find.byWidgetPredicate((w) => w is Semantics && w.properties.button == true && RegExp(r'^(Mon|Tue|Wed|Thu|Fri|Sat) ').hasMatch(w.properties.label ?? ''));
    await t.tap(days.at(1));
    await settle(t, 600);
    await t.tap(find.byWidgetPredicate((w) => w is Semantics && (w.properties.label ?? '').endsWith('AM') && w.properties.enabled == true).first);
    await shot('doctor', 1200);
    homeNavigator.currentState!.pop();
    await settle(t, 700);

    final day = dateOnly(DateTime.now()).add(const Duration(days: 3));
    homeNavigator.currentState!.push(TendRoute(ConfirmScreen(doctor: doctor, day: day, slot: const Slot(630))));
    await shot('confirm');
    await t.tap(find.textContaining('Book for'));
    await shot('booked', 3200);
    homeNavigator.currentState!.popUntil((r) => r.isFirst);
    c.read(tabProvider.notifier).state = 1;
    await shot('visits');
    c.read(tabProvider.notifier).state = 2;
    await shot('me');
  });
}
