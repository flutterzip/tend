import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/brand.dart';
import '../../config/motion.dart';
import '../../config/palette.dart';
import '../../config/timing.dart';
import '../../widgets/pulse.dart';

/// The first thing anyone sees: a flat line kicks into one heartbeat, then
/// draws a heart that fills; the name and tagline rise under it, then it all
/// dissolves into the app.
///
/// One controller, one timeline. [showing] goes false as it starts to
/// leave, so overlays and launch hooks can wait for it.
class Splash extends StatefulWidget {
  const Splash({super.key, required this.ready, required this.onGone});

  final Future<void> ready;
  final VoidCallback onGone;

  static final showing = ValueNotifier<bool>(true);

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with TickerProviderStateMixin {
  late final _in = AnimationController(vsync: this, duration: AppTiming.splashIn);
  late final _out = AnimationController(vsync: this, duration: AppTiming.splashOut);
  bool _dotted = false;

  @override
  void initState() {
    super.initState();
    Splash.showing.value = true;
    _in.addListener(() {
      if (!_dotted && _in.value > 0.7) {
        _dotted = true;
        HapticFeedback.lightImpact();
      }
    });
    _run();
  }

  Future<void> _run() async {
    if (AppTiming.scale == 0) {
      await widget.ready;
      return _gone();
    }
    await Future.wait([_in.forward().orCancel.catchError((_) {}), widget.ready]);
    await AppTiming.wait(AppTiming.splashHold);
    if (!mounted) return;
    Splash.showing.value = false;
    await _out.forward().orCancel.catchError((_) {});
    _gone();
  }

  void _gone() {
    Splash.showing.value = false;
    if (mounted) widget.onGone();
  }

  @override
  void dispose() {
    _in.dispose();
    _out.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final reduced = Motion.reduced(context);
    return AnimatedBuilder(
      animation: Listenable.merge([_in, _out]),
      builder: (context, _) {
        final t = reduced ? 1.0 : _in.value;
        final out = Motion.exit.transform(_out.value);
        final mark = (t / 0.8).clamp(0.0, 1.0);
        final name = Motion.enter.transform(((t - 0.62) / 0.25).clamp(0.0, 1.0));
        final tag = Motion.enter.transform(((t - 0.78) / 0.22).clamp(0.0, 1.0));
        return IgnorePointer(
          ignoring: _out.value > 0,
          child: Opacity(
            opacity: 1 - out,
            child: Material(
              color: p.paper,
              child: Center(
                child: Transform.scale(
                  scale: 1 + out * 0.08,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PulseMark(progress: mark, width: 280),
                      const SizedBox(height: 14),
                      Opacity(
                        opacity: name,
                        child: Transform.translate(offset: Offset(0, (1 - name) * 20), child: Text(AppBrand.name, style: text.displaySmall!.copyWith(fontSize: 46))),
                      ),
                      const SizedBox(height: 8),
                      Opacity(
                        opacity: tag,
                        child: Transform.translate(offset: Offset(0, (1 - tag) * 12), child: Text(AppBrand.tagline, style: text.bodyLarge)),
                      ),
                    ],
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
