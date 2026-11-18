import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/motion.dart';
import '../config/palette.dart';

class TabItem {
  const TabItem(this.label, this.icon, this.activeIcon, {this.badge = 0});

  final String label;
  final IconData icon, activeIcon;
  final int badge;
}

/// A floating frosted bar. A pill of accent slides under the current tab,
/// sized to fit its icon and label and stretching as it travels; the other
/// tabs share what is left. Content scrolling underneath fades out before
/// it reaches the bar.
class GlassTabBar extends StatelessWidget {
  const GlassTabBar({
    super.key,
    required this.items,
    required this.index,
    required this.onTap,
  });

  final List<TabItem> items;
  final int index;
  final ValueChanged<int> onTap;

  static const _height = 68.0, _inset = 7.0, _icon = 23.0, _gap = 8.0, _pad = 18.0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final label = Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w700);
    final scaler = MediaQuery.textScalerOf(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    // How wide each tab's pill needs to be to show its icon and label.
    final needs = [
      for (final item in items)
        _icon + _gap + _pad * 2 + (TextPainter(text: TextSpan(text: item.label, style: label), textDirection: TextDirection.ltr, textScaler: scaler, maxLines: 1)..layout()).width,
    ];

    return DecoratedBox(
      // Lists fade into the paper before they reach the bar.
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.paper.withValues(alpha: 0), p.paper.withValues(alpha: 0.85), p.paper],
          stops: const [0, 0.45, 1],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 22, 24, bottom + 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_height / 2),
            boxShadow: [BoxShadow(color: p.shadow, blurRadius: 24, offset: const Offset(0, 10))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_height / 2),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                height: _height,
                padding: const EdgeInsets.all(_inset),
                decoration: BoxDecoration(
                  color: p.card.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(_height / 2),
                  border: Border.all(color: p.line),
                ),
                child: LayoutBuilder(
                  builder: (context, box) => TweenAnimationBuilder<double>(
                    tween: Tween(end: index.toDouble()),
                    duration: Motion.medium,
                    curve: Motion.spring,
                    builder: (_, v, _) {
                      final n = items.length;
                      final w = box.maxWidth;
                      // How close each tab is to being the current one (they
                      // sum to one while the pill slides between two).
                      final near = [for (var i = 0; i < n; i++) (1 - (v - i).abs()).clamp(0.0, 1.0)];
                      final extra = [for (var i = 0; i < n; i++) math.max(0.0, (math.min(needs[i], w * 0.6) - w / n) * n / (n - 1))];
                      final grow = [for (var i = 0; i < n; i++) extra[i] * near[i]];
                      final base = (w - grow.fold(0.0, (a, b) => a + b)) / n;
                      final widths = [for (var i = 0; i < n; i++) base + grow[i]];
                      final k = v.floor().clamp(0, n - 1);
                      final f = (v - k).clamp(0.0, 1.0);
                      var left = 0.0;
                      for (var i = 0; i < k; i++) {
                        left += widths[i];
                      }
                      left += f * widths[k];
                      final width = k + 1 < n ? widths[k] + (widths[k + 1] - widths[k]) * f : widths[k];
                      // Stretch while moving, by how far from a whole tab it is.
                      final stretch = 1 - ((v - v.round()).abs() * 2 - 1).abs();
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Positioned(
                            left: left - stretch * 6,
                            width: width + stretch * 12,
                            top: 0,
                            bottom: 0,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(_height / 2),
                                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(p.accent, p.accentGlow, 0.18)!, p.accent]),
                                boxShadow: [BoxShadow(color: p.accent.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 5))],
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              for (var i = 0; i < n; i++)
                                SizedBox(
                                  width: widths[i],
                                  child: _Tab(item: items[i], active: i == index, label: label, onTap: () => onTap(i)),
                                ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.item, required this.active, required this.label, required this.onTap});

  final TabItem item;
  final bool active;
  final TextStyle label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = active ? p.onAccent : p.inkSoft;
    return Semantics(
      button: true,
      selected: active,
      label: item.badge > 0 ? '${item.label}, ${item.badge}' : item.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The icon gives a small spring when its tab is picked.
              TweenAnimationBuilder<double>(
                key: ValueKey(active),
                tween: Tween(begin: active ? 0.7 : 1, end: 1),
                duration: Motion.long,
                curve: Curves.elasticOut,
                builder: (_, s, child) => Transform.scale(scale: s, child: child),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(active ? item.activeIcon : item.icon, color: color, size: GlassTabBar._icon),
                    if (item.badge > 0)
                      Positioned(
                        right: -9,
                        top: -7,
                        child: TweenAnimationBuilder<double>(
                          key: ValueKey(item.badge),
                          tween: Tween(begin: 0.4, end: 1),
                          duration: Motion.medium,
                          curve: Motion.spring,
                          builder: (_, s, child) => Transform.scale(scale: s, child: child),
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 18),
                            height: 18,
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: active ? p.onAccent : p.accent,
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(color: active ? p.accent : p.card, width: 1.5),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${item.badge}',
                              style: TextStyle(fontFamily: 'Bricolage', fontSize: 10.5, fontWeight: FontWeight.w800, color: active ? p.accentDeep : p.onAccent),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Flexible(
                child: AnimatedSize(
                  duration: Motion.medium,
                  curve: Motion.settle,
                  child: active
                      ? Padding(
                          padding: const EdgeInsets.only(left: GlassTabBar._gap),
                          child: Text(item.label, maxLines: 1, overflow: TextOverflow.clip, softWrap: false, style: label.copyWith(color: color)),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
