import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../config/motion.dart';
import '../config/palette.dart';
import '../config/theme.dart';

/// The top of a page, laid over its scrolling content.
///
/// The row (back or close, a title, actions) never scrolls away. It starts
/// clear, and once content runs under it the bar turns to frosted paper with
/// a hairline and the [title] fades in. A [bottom] (search, filters) slides
/// away while you read down and comes straight back the moment you scroll up.
/// With nothing but a [controller], it frosts the status bar so content never
/// shows through behind the clock.
///
/// Give the scroll view [TopChrome.extent] of top padding.
class TopChrome extends StatefulWidget {
  const TopChrome({
    super.key,
    required this.controller,
    this.leading,
    this.trailing,
    this.row,
    this.title,
    this.bottom,
    this.bottomHeight = 0,
    this.titleAfter = 160,
  });

  final ScrollController controller;
  final Widget? leading, trailing;

  /// A whole custom row, in place of [leading] and [trailing].
  final Widget? row;
  final String? title;

  /// Shown under the row; hides on the way down, returns on the way up.
  final Widget? bottom;
  final double bottomHeight;

  /// How far to scroll before the [title] appears (usually past the page's
  /// own big heading).
  final double titleAfter;

  static const rowHeight = 62.0;

  /// The top padding the content needs so nothing starts under the bar.
  static double extent(BuildContext context, {bool row = true, double bottomHeight = 0}) =>
      MediaQuery.paddingOf(context).top + (row ? rowHeight : 0) + bottomHeight;

  bool get _hasRow => leading != null || trailing != null || title != null || row != null;

  @override
  State<TopChrome> createState() => _TopChromeState();
}

class _TopChromeState extends State<TopChrome> with SingleTickerProviderStateMixin {
  // Made in initState, not lazily: a page without a bottom would otherwise
  // first build it inside dispose.
  late final AnimationController _shown;
  bool _frosted = false, _titled = false;
  double _last = 0, _travel = 0;

  @override
  void initState() {
    super.initState();
    _shown = AnimationController(vsync: this, duration: Motion.medium, value: 1);
    widget.controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(TopChrome old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    _shown.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.controller.hasClients) return;
    final pos = widget.controller.position;
    final o = pos.pixels;
    final frosted = o > 2;
    final titled = o > widget.titleAfter;
    if (frosted != _frosted || titled != _titled) {
      setState(() {
        _frosted = frosted;
        _titled = titled;
      });
    }
    if (widget.bottom == null) return;
    final d = o - _last;
    _last = o;
    // Rubber-banding past either end is not a change of direction.
    if (o < 0 || o > pos.maxScrollExtent) return;
    if (o <= widget.bottomHeight) {
      _show(true);
      return;
    }
    _travel = d > 0 ? math.max(0, _travel) + d : math.min(0, _travel) + d;
    if (_travel > 24) _show(false);
    if (_travel < -6) _show(true);
  }

  void _show(bool show) {
    if (show && (_shown.status == AnimationStatus.forward || _shown.value == 1)) return;
    if (!show && (_shown.status == AnimationStatus.reverse || _shown.value == 0)) return;
    if (Motion.reduced(context)) {
      _shown.value = show ? 1 : 0;
    } else {
      show ? _shown.animateTo(1, curve: Motion.enter) : _shown.animateTo(0, curve: Motion.exit);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = widget.bottom;

    final frost = Positioned.fill(
      child: IgnorePointer(
        child: AnimatedOpacity(
          duration: Motion.short,
          opacity: _frosted ? 1 : 0,
          child: ClipRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: p.paper.withValues(alpha: 0.8),
                  border: Border(bottom: BorderSide(color: p.line)),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Stack(
      children: [
        frost,
        Padding(
          padding: EdgeInsets.only(top: top),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget._hasRow)
                SizedBox(
                  height: TopChrome.rowHeight,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (widget.title != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter + 58),
                          child: AnimatedOpacity(
                            duration: Motion.short,
                            opacity: _titled ? 1 : 0,
                            child: AnimatedSlide(
                              duration: Motion.medium,
                              curve: Motion.enter,
                              offset: Offset(0, _titled ? 0 : 0.4),
                              child: Text(widget.title!, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: text.titleMedium),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
                        child: widget.row ??
                            Row(
                              children: [
                                if (widget.leading != null) widget.leading!,
                                const Spacer(),
                                if (widget.trailing != null) widget.trailing!,
                              ],
                            ),
                      ),
                    ],
                  ),
                ),
              if (bottom != null)
                SizeTransition(
                  sizeFactor: _shown,
                  axisAlignment: 1,
                  child: FadeTransition(
                    opacity: _shown,
                    child: SizedBox(height: widget.bottomHeight, child: bottom),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// For a tab's own page, which has no bar: once its list scrolls, the strip
/// behind the status bar frosts over so content never runs under the clock.
class StatusFrost extends StatefulWidget {
  const StatusFrost({super.key, required this.child});

  final Widget child;

  @override
  State<StatusFrost> createState() => _StatusFrostState();
}

class _StatusFrostState extends State<StatusFrost> {
  bool _frosted = false;

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    final frosted = n.metrics.pixels > 2;
    if (frosted != _frosted) setState(() => _frosted = frosted);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(onNotification: _onScroll, child: widget.child),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: MediaQuery.paddingOf(context).top,
          child: IgnorePointer(
            child: AnimatedOpacity(
              duration: Motion.short,
              opacity: _frosted ? 1 : 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                  child: ColoredBox(color: p.paper.withValues(alpha: 0.8)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
