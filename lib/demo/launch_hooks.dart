import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app.dart';
import '../data/models.dart';
import '../screens/confirm/confirm_screen.dart';
import '../screens/doctor/doctor_screen.dart';
import '../screens/shell/shell.dart';
import '../state/store.dart';
import '../widgets/routes.dart';

/// Opens a screen straight after the splash, for screenshots and
/// recordings: `--dart-define=startRoute=doctor`. Off by default, so a
/// release build is unaffected. Any route but signIn signs the demo in.
///
/// signIn, doctor, confirm, visits, me.
const startRoute = String.fromEnvironment('startRoute');

Future<void> runLaunchHooks(WidgetRef ref) async {
  if (startRoute.isEmpty || startRoute == 'signIn') return;
  if (!ref.read(signedInProvider)) {
    await ref.read(signedInProvider.notifier).signIn();
    navigatorKey.currentState?.pushReplacement(TendRoute(const Shell()));
    await Future<void>.delayed(const Duration(milliseconds: 800));
  }
  final doctor = ref.read(seedProvider).doctor('adaeze-okoro');
  switch (startRoute) {
    case 'doctor':
      homeNavigator.currentState?.push(TendRoute(DoctorScreen(doctor: doctor)));
    case 'confirm':
      final day = dateOnly(ref.read(clockProvider)()).add(const Duration(days: 3));
      homeNavigator.currentState?.push(TendRoute(ConfirmScreen(doctor: doctor, day: day, slot: const Slot(630))));
    case 'visits':
      ref.read(tabProvider.notifier).state = 1;
    case 'me':
      ref.read(tabProvider.notifier).state = 2;
  }
}
