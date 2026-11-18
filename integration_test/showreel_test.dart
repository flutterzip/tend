// Drives the real app on the simulator at human speed, for recording and
// for judging motion frame by frame:   tool/rec.sh book
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tend/app.dart';
import 'package:tend/state/store.dart';
import 'package:tend/widgets/widgets.dart';

Future<void> pause(WidgetTester t, int ms) async {
  final end = DateTime.now().add(Duration(milliseconds: ms));
  while (DateTime.now().isBefore(end)) {
    await t.pump(const Duration(milliseconds: 16));
  }
}

Future<void> typeInto(WidgetTester t, Finder field, String text) async {
  await t.tap(field);
  await pause(t, 300);
  for (var i = 1; i <= text.length; i++) {
    await t.enterText(field, text.substring(0, i));
    await pause(t, 90);
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('showreel', (t) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final seed = await Seed.load();
    await t.pumpWidget(ProviderScope(
      overrides: [prefsProvider.overrideWithValue(prefs), seedProvider.overrideWithValue(seed)],
      child: const TendApp(),
    ));
    await pause(t, 4600);

    await typeInto(t, find.byType(TextField).at(0), 'hello@flutterzip.com');
    await typeInto(t, find.byType(TextField).at(1), 'tend1234');
    await pause(t, 1800);
    await t.tap(find.text('Sign in'));
    await pause(t, 3200);

    await t.tap(find.byType(SpecialtyTile).first);
    await pause(t, 1200);
    await t.tap(find.byType(DoctorRow).first);
    await pause(t, 1800);
    await t.drag(find.byType(ListView).last, const Offset(0, -380));
    await pause(t, 900);
    final days = find.byWidgetPredicate((w) => w is Semantics && w.properties.button == true && RegExp(r'^(Mon|Tue|Wed|Thu|Fri|Sat) ').hasMatch(w.properties.label ?? ''));
    await t.tap(days.at(2));
    await pause(t, 1100);
    await t.tap(days.at(3));
    await pause(t, 1100);
    final slot = find.byWidgetPredicate((w) => w is Semantics && (w.properties.label ?? '').endsWith('AM') && w.properties.enabled == true);
    await t.tap(slot.first);
    await pause(t, 900);
    await t.tap(find.textContaining('Book ').last);
    await pause(t, 1800);
    await t.tap(find.text('Something new'));
    await pause(t, 800);
    await t.tap(find.textContaining('Book for'));
    await pause(t, 4500);
    await t.tap(find.text('See my visits'));
    await pause(t, 1800);
    await t.tap(find.text('Cancel').first);
    await pause(t, 1600);
    await t.tap(find.text('Undo'));
    await pause(t, 1800);
  });
}
