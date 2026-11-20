import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/widgets.dart';
import '../appointments/appointments_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';

final tabProvider = StateProvider<int>((_) => 0);

/// The Home tab's own navigator: a doctor opens inside the tab, and the bar
/// slides away while it is open so the page's own action can sit at the
/// bottom.
final homeNavigator = GlobalKey<NavigatorState>(debugLabel: 'home');

/// Whether the Home tab has a page open over its home.
class _Depth extends NavigatorObserver {
  final deep = ValueNotifier(false);
  var _n = 0;

  void _set(int n) {
    _n = n;
    deep.value = _n > 1;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _set(_n + 1);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _set(_n - 1);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => _set(_n - 1);
}

class Shell extends ConsumerStatefulWidget {
  const Shell({super.key});

  @override
  ConsumerState<Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<Shell> {
  final _heroes = HeroController();
  final _depth = _Depth();
  final _built = <int>{0};

  @override
  void dispose() {
    _depth.deep.dispose();
    super.dispose();
  }

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
              child: Navigator(key: homeNavigator, observers: [_heroes, _depth], onGenerateRoute: (_) => TendRoute<void>(const HomeScreen())),
            ),
          ),
          _built.contains(1) ? const AppointmentsScreen() : const SizedBox(),
          _built.contains(2) ? const StatusFrost(child: ProfileScreen()) : const SizedBox(),
        ],
      ),
      bottomNavigationBar: ValueListenableBuilder(
        valueListenable: _depth.deep,
        builder: (context, deep, bar) {
          final hide = deep && tab == 0;
          return IgnorePointer(
            ignoring: hide,
            child: AnimatedSlide(offset: Offset(0, hide ? 1.2 : 0), duration: Motion.medium, curve: Motion.spring, child: bar),
          );
        },
        child: GlassTabBar(
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
      ),
    );
  }
}

/// Opens a page inside the Home tab, from anywhere.
void openInHome(WidgetRef ref, Widget page) {
  ref.read(tabProvider.notifier).state = 0;
  homeNavigator.currentState?.push(TendRoute<void>(page));
}
