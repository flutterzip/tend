import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tend/app.dart';
import 'package:tend/config/motion.dart';
import 'package:tend/config/timing.dart';
import 'package:tend/screens/home/home_screen.dart';
import 'package:tend/screens/sign_in/sign_in_screen.dart';
import 'package:tend/screens/splash/splash.dart';
import 'package:tend/state/store.dart';

import 'helpers.dart';

Future<ProviderContainer> pumpApp(WidgetTester tester, {bool splash = true, Map<String, Object> prefs = const {}}) async {
  Motion.ambient = false;
  AppTiming.scale = splash ? 1 : 0;
  addTearDown(() => AppTiming.scale = 0);
  tester.view.physicalSize = const Size(1320, 2868);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [
    prefsProvider.overrideWithValue(sp),
    seedProvider.overrideWithValue(testSeed),
    clockProvider.overrideWithValue(() => testNow),
  ]);
  addTearDown(c.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(container: c, child: TendApp(splash: splash)));
  return c;
}

void main() {
  testWidgets('the splash beats, then leaves sign in without rebuilding it', (tester) async {
    await pumpApp(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(Splash), findsOneWidget);
    final before = tester.state(find.byType(SignInScreen));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pumpAndSettle();
    expect(find.byType(Splash), findsNothing);
    expect(identical(tester.state(find.byType(SignInScreen)), before), isTrue);
  });

  testWidgets('signed in opens Home', (tester) async {
    await pumpApp(tester, splash: false, prefs: {'tend.signedIn.v1': true});
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('signing out goes back to sign in', (tester) async {
    final c = await pumpApp(tester, splash: false, prefs: {'tend.signedIn.v1': true});
    await tester.pumpAndSettle();
    await tester.tap(find.text('Me').evaluate().isEmpty ? find.byIcon(Icons.favorite_border_rounded) : find.text('Me'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sign out'));
    await tester.pump();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(c.read(signedInProvider), isFalse);
  });

  testWidgets('Demo settings switches to dark', (tester) async {
    await pumpApp(tester, splash: false, prefs: {'tend.signedIn.v1': true});
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Demo settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(HomeScreen))).brightness, Brightness.dark);
  });
}
