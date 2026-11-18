import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/widgets.dart';
import '../appointments/appointments_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';

final tabProvider = StateProvider<int>((_) => 0);

/// The Home tab's own navigator: a doctor opens inside the tab and the bar
/// stays.
final homeNavigator = GlobalKey<NavigatorState>(debugLabel: 'home');

class Shell extends ConsumerStatefulWidget {
  const Shell({super.key});

  @override
  ConsumerState<Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<Shell> {
  final _heroes = HeroController();
  final _built = <int>{0};

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(tabProvider);
    _built.add(tab);
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: IndexedStack(
        index: tab,
        children: [
          HeroMode(
            enabled: tab == 0,
            child: NavigatorPopHandler(
              onPopWithResult: (_) => homeNavigator.currentState?.maybePop(),
              child: Navigator(
                key: homeNavigator,
                observers: [_heroes],
                onGenerateRoute: (_) => TendRoute<void>(const HomeScreen()),
              ),
            ),
          ),
          _built.contains(1) ? const AppointmentsScreen() : const SizedBox(),
          _built.contains(2) ? const ProfileScreen() : const SizedBox(),
        ],
      ),
      bottomNavigationBar: GlassTabBar(
        index: tab,
        onTap: (i) {
          if (i == tab && i == 0) homeNavigator.currentState?.popUntil((r) => r.isFirst);
          ref.read(tabProvider.notifier).state = i;
        },
        items: const [
          TabItem('Home', Icons.home_outlined, Icons.home_rounded),
          TabItem('Visits', Icons.event_note_outlined, Icons.event_note_rounded),
          TabItem('Me', Icons.favorite_border_rounded, Icons.favorite_rounded),
        ],
      ),
    );
  }
}

/// Opens a page inside the Home tab, from anywhere.
void openInHome(WidgetRef ref, Widget page) {
  ref.read(tabProvider.notifier).state = 0;
  homeNavigator.currentState?.push(TendRoute<void>(page));
}
