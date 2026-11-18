import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/motion.dart';
import '../config/palette.dart';
import '../config/theme.dart';
import '../data/models.dart';

/// Two weeks of days in a scrolling strip. The chosen day is a tall accent
/// pill that slides between days; days with nothing free are struck through.
class DateStrip extends StatefulWidget {
  const DateStrip({super.key, required this.start, required this.selected, required this.onSelect, this.days = 14, this.isOpen});

  final DateTime start, selected;
  final ValueChanged<DateTime> onSelect;
  final int days;

  /// Whether a day has anything free (Sundays are closed, for example).
  final bool Function(DateTime)? isOpen;

  @override
  State<DateStrip> createState() => _DateStripState();
}

class _DateStripState extends State<DateStrip> {
  static const _w = 62.0, _gap = 10.0;
  final _scroll = ScrollController();

  int get _index => dateOnly(widget.selected).difference(dateOnly(widget.start)).inDays;

  @override
  void didUpdateWidget(DateStrip old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected && _scroll.hasClients) {
      final target = (_index * (_w + _gap) - (_scroll.position.viewportDimension - _w) / 2).clamp(0.0, _scroll.position.maxScrollExtent);
      _scroll.animateTo(target, duration: Motion.medium, curve: Motion.settle);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final days = [for (var i = 0; i < widget.days; i++) dateOnly(widget.start).add(Duration(days: i))];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: Motion.short,
          child: Text(
            '${_monthName(widget.selected)} ${widget.selected.year}',
            key: ValueKey(widget.selected.month),
            style: text.titleMedium,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 84,
          child: SingleChildScrollView(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: days.length * (_w + _gap),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: Motion.medium,
                    curve: Motion.spring,
                    left: _index * (_w + _gap),
                    top: 0,
                    bottom: 0,
                    width: _w,
                    child: Container(
                      decoration: BoxDecoration(
                        color: p.accent,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [BoxShadow(color: p.accent.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8))],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (final d in days)
                        Padding(
                          padding: const EdgeInsets.only(right: _gap),
                          child: _Day(
                            day: d,
                            selected: dateOnly(d) == dateOnly(widget.selected),
                            open: widget.isOpen?.call(d) ?? true,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              widget.onSelect(d);
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _monthName(DateTime d) => const [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ][d.month - 1];
}

class _Day extends StatelessWidget {
  const _Day({required this.day, required this.selected, required this.open, required this.onTap});

  final DateTime day;
  final bool selected, open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final fg = selected ? p.onAccent : (open ? p.ink : p.muted);
    return Semantics(
      button: true,
      selected: selected,
      label: '${dayLabel(day)}${open ? '' : ', closed'}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: open ? onTap : null,
        child: AnimatedContainer(
          duration: Motion.medium,
          width: 62,
          decoration: BoxDecoration(
            color: selected ? Colors.transparent : p.card.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: selected ? Colors.transparent : p.line),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(weekday(day), style: text.labelSmall!.copyWith(color: selected ? p.onAccent.withValues(alpha: 0.85) : p.muted)),
              const SizedBox(height: 4),
              Text(
                '${day.day}',
                style: text.titleLarge!.copyWith(color: fg, decoration: open ? null : TextDecoration.lineThrough),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The day's times in a grid, split into morning and afternoon. Taken times
/// are faded and struck through; the chosen one fills with the accent and
/// pops.
class SlotGrid extends StatelessWidget {
  const SlotGrid({super.key, required this.free, required this.selected, required this.onSelect});

  final Set<Slot> free;
  final Slot? selected;
  final ValueChanged<Slot> onSelect;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final morning = openSlots.where((s) => s.hour < 12).toList();
    final afternoon = openSlots.where((s) => s.hour >= 12).toList();
    Widget group(String title, IconData icon, List<Slot> slots) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: context.palette.muted),
                const SizedBox(width: 6),
                Text(title, style: text.labelMedium),
                const Spacer(),
                Text('${slots.where(free.contains).length} free', style: text.labelSmall),
              ],
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, box) {
                final w = (box.maxWidth - 2 * 10) / 3;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final s in slots)
                      SizedBox(
                        width: w,
                        child: _SlotChip(slot: s, free: free.contains(s), selected: s == selected, onTap: () => onSelect(s)),
                      ),
                  ],
                );
              },
            ),
          ],
        );
    if (free.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text('Nothing free this day. Try another.', style: text.bodyMedium, textAlign: TextAlign.center),
      );
    }
    return Column(
      children: [
        group('Morning', Icons.wb_twilight_rounded, morning),
        const SizedBox(height: 18),
        group('Afternoon', Icons.wb_sunny_outlined, afternoon),
      ],
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({required this.slot, required this.free, required this.selected, required this.onTap});

  final Slot slot;
  final bool free, selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      enabled: free,
      label: '${slot.label}${free ? '' : ', taken'}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: free
            ? () {
                HapticFeedback.selectionClick();
                onTap();
              }
            : null,
        child: AnimatedScale(
          scale: selected ? 1.06 : 1,
          duration: Motion.medium,
          curve: Motion.spring,
          child: AnimatedContainer(
            duration: Motion.medium,
            curve: Motion.settle,
            height: 46,
            decoration: BoxDecoration(
              color: selected ? p.accent : (free ? p.card : p.field.withValues(alpha: 0.6)),
              borderRadius: BorderRadius.circular(Tokens.fieldRadius - 4),
              border: Border.all(color: selected ? p.accent : (free ? p.line : Colors.transparent)),
              boxShadow: [BoxShadow(color: p.accent.withValues(alpha: selected ? 0.35 : 0), blurRadius: 14, offset: const Offset(0, 6))],
            ),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                slot.label,
                style: text.labelMedium!.copyWith(
                  color: selected ? p.onAccent : (free ? p.ink : p.muted.withValues(alpha: 0.7)),
                  decoration: free ? null : TextDecoration.lineThrough,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
