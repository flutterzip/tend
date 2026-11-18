import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/brand.dart';
import 'config/theme.dart';
import 'demo/demo_control.dart';
import 'demo/launch_hooks.dart';
import 'screens/shell/shell.dart';
import 'screens/sign_in/sign_in_screen.dart';
import 'screens/splash/splash.dart';
import 'state/store.dart';
import 'widgets/backdrop.dart';
import 'widgets/routes.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class TendApp extends ConsumerStatefulWidget {
  const TendApp({super.key, this.splash = true});

  /// Tests start without the splash.
  final bool splash;

  @override
  ConsumerState<TendApp> createState() => _TendAppState();
}

class _TendAppState extends ConsumerState<TendApp> {
  late bool _splash = widget.splash;
  final _ready = Completer<void>();
  final _appKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ready.complete());
    if (!_splash) Splash.showing.value = false;
  }

  void _splashGone() {
    setState(() => _splash = false);
    runLaunchHooks(ref);
  }

  Route<void> _first() => TendRoute<void>(ref.read(signedInProvider) ? const Shell() : const SignInScreen());

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(demoSettingsProvider);
    return MaterialApp(
      title: AppBrand.name,
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.theme,
      onGenerateInitialRoutes: (_) => [_first()],
      onGenerateRoute: (_) => _first(),
      builder: (context, child) => PaperBackdrop(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          // The stack keeps its shape for the app's whole life, so the first
          // screen is never rebuilt when the splash leaves.
          child: Stack(
            children: [
              KeyedSubtree(key: _appKey, child: child!),
              if (_splash) Positioned.fill(child: Splash(ready: _ready.future, onGone: _splashGone)),
              DemoControl(key: const ValueKey('demo'), navigatorKey: navigatorKey),
            ],
          ),
        ),
      ),
    );
  }
}
