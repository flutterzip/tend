import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/motion.dart';
import '../config/palette.dart';
import '../config/theme.dart';
import '../screens/splash/splash.dart';
import '../screens/shell/shell.dart';
import '../screens/sign_in/sign_in_screen.dart';
import '../widgets/routes.dart';
import '../state/store.dart';

/// A small floating button over every screen that opens Demo settings:
/// theme, demo hints and reset. Drag it anywhere; it springs to the nearer
/// edge. It hides during the splash and while its own sheet is open.
class DemoControl extends ConsumerStatefulWidget {
  const DemoControl({super.key, required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  /// Screenshot runs switch the button off.
  static bool enabled = true;

  @override
  ConsumerState<DemoControl> createState() => _DemoControlState();
}

class _DemoControlState extends ConsumerState<DemoControl> {
  Offset? _pos;
  bool _dragging = false;
  bool _open = false;

  static const _size = 46.0;

  Future<void> _openSheet() async {
    final context = widget.navigatorKey.currentContext;
    if (context == null) return;
    setState(() => _open = true);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: context.palette.scrim,
      builder: (_) => const _DemoSheet(),
    );
    if (mounted) setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final media = MediaQuery.of(context);
    final area = media.size;
    final pad = media.padding;
    final pos = _pos ?? Offset(area.width - _size - 10, area.height * 0.42);
    return ValueListenableBuilder<bool>(
      valueListenable: Splash.showing,
      builder: (context, splash, _) {
        final hidden = splash || _open || !DemoControl.enabled;
        return AnimatedPositioned(
          duration: _dragging ? Duration.zero : Motion.medium,
          curve: Motion.spring,
          left: pos.dx,
          top: pos.dy,
          child: IgnorePointer(
            ignoring: hidden,
            child: AnimatedOpacity(
              duration: Motion.short,
              opacity: hidden ? 0 : 1,
              child: GestureDetector(
                onTap: _openSheet,
                onPanStart: (_) => setState(() => _dragging = true),
                onPanUpdate: (d) => setState(() => _pos = pos + d.delta),
                onPanEnd: (_) {
                  final left = pos.dx + _size / 2 < area.width / 2;
                  setState(() {
                    _dragging = false;
                    _pos = Offset(
                      left ? 14 : area.width - _size - 14,
                      pos.dy.clamp(pad.top + 4, area.height - pad.bottom - _size - 8),
                    );
                  });
                },
                child: Semantics(
                  button: true,
                  label: 'Demo settings',
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        width: _size,
                        height: _size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.card.withValues(alpha: 0.7),
                          border: Border.all(color: p.line),
                        ),
                        child: Icon(Icons.tune_rounded, size: 21, color: p.ink),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DemoSheet extends ConsumerWidget {
  const _DemoSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final settings = ref.watch(demoSettingsProvider);
    final notifier = ref.read(demoSettingsProvider.notifier);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(Tokens.cardRadius)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          color: p.card.withValues(alpha: 0.92),
          padding: EdgeInsets.fromLTRB(Tokens.gutter, 12, Tokens.gutter, 24 + MediaQuery.paddingOf(context).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(color: p.line, borderRadius: BorderRadius.circular(3)),
                ),
              ),
              const SizedBox(height: 18),
              Text('Demo settings', style: text.titleLarge),
              const SizedBox(height: 18),
              Text('Theme', style: text.labelMedium),
              const SizedBox(height: 10),
              SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: p.accent,
                  selectedForegroundColor: p.onAccent,
                  foregroundColor: p.ink,
                  side: BorderSide(color: p.line),
                ),
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('Auto')),
                  ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                ],
                selected: {settings.theme},
                onSelectionChanged: (s) => notifier.setTheme(s.first),
              ),
              const SizedBox(height: 18),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: p.ink,
                  side: BorderSide(color: p.line),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tokens.buttonRadius)),
                ),
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Reset demo data'),
                onPressed: () async {
                  final nav = Navigator.of(context);
                  await resetDemo(ref);
                  ref.read(tabProvider.notifier).state = 0;
                  nav.pop();
                  // Back to the first page of everything, in the same shell.
                  // Reset signs out, so start again at sign in.
                  if (nav.mounted) nav.context.restart(const SignInScreen());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
