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
/// stretching as it travels.
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

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        28,
        0,
        28,
        MediaQuery.paddingOf(context).bottom + 10,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            height: 66,
            decoration: BoxDecoration(
              color: p.card.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: p.line),
            ),
            padding: const EdgeInsets.all(7),
            child: LayoutBuilder(
              builder: (context, box) {
                final w = box.maxWidth / items.length;
                return Stack(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: index.toDouble()),
                      duration: Motion.medium,
                      curve: Motion.spring,
                      builder: (_, v, _) {
                        // Stretch while moving, by how far from a whole tab it is.
                        final stretch =
                            1 - ((v - v.round()).abs() * 2 - 1).abs();
                        return Positioned(
                          left: v * w - stretch * 8,
                          width: w + stretch * 16,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: p.accent,
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                        );
                      },
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < items.length; i++)
                          Expanded(
                            child: _Tab(
                              item: items[i],
                              active: i == index,
                              onTap: () => onTap(i),
                            ),
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
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.item, required this.active, required this.onTap});

  final TabItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = active ? p.onAccent : p.inkSoft;
    final icon = Icon(
      active ? item.activeIcon : item.icon,
      color: color,
      size: 23,
    );
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                icon,
                if (item.badge > 0)
                  Positioned(
                    right: -9,
                    top: -6,
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey(item.badge),
                      tween: Tween(begin: 0.4, end: 1),
                      duration: Motion.medium,
                      curve: Motion.spring,
                      builder: (_, s, child) =>
                          Transform.scale(scale: s, child: child),
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18),
                        height: 18,
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          color: active ? p.onAccent : p.accent,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: p.card, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${item.badge}',
                          style: TextStyle(
                            fontFamily: 'Bricolage',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: active ? p.accentDeep : p.onAccent,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Flexible(
              child: AnimatedSize(
                duration: Motion.medium,
                curve: Motion.settle,
                child: active
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium!
                              .copyWith(
                                color: color,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
