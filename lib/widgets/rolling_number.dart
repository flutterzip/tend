import 'package:flutter/material.dart';

import '../config/motion.dart';

/// A number whose digits roll to the new value, each digit on its own
/// wheel (XP, scores, minutes learned).
class RollingNumber extends StatelessWidget {
  const RollingNumber(this.value, {super.key, this.style, this.prefix = '', this.suffix = ''});

  final int value;
  final TextStyle? style;
  final String prefix, suffix;

  @override
  Widget build(BuildContext context) {
    final s = style ?? Theme.of(context).textTheme.titleLarge!;
    final text = '$value';
    return Semantics(
      label: '$prefix$value$suffix',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (prefix.isNotEmpty) Text(prefix, style: s),
          for (var i = 0; i < text.length; i++)
            _Wheel(key: ValueKey(text.length - i), digit: int.parse(text[i]), style: s),
          if (suffix.isNotEmpty) Text(suffix, style: s),
        ],
      ),
    );
  }
}

class _Wheel extends StatelessWidget {
  const _Wheel({super.key, required this.digit, required this.style});

  final int digit;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final h = (style.fontSize ?? 20) * (style.height ?? 1.3);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: digit.toDouble()),
      duration: Motion.long,
      curve: Motion.settle,
      builder: (context, v, _) => ClipRect(
        child: SizedBox(
          height: h,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Opacity(opacity: 0, child: Text('0', style: style)),
              for (var n = 0; n <= 9; n++)
                if ((n - v).abs() < 1.2)
                  Positioned(
                    top: (n - v) * h,
                    left: 0,
                    right: 0,
                    child: Text('$n', style: style, textAlign: TextAlign.center),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
