import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/motion.dart';
import '../config/palette.dart';
import '../config/theme.dart';

/// Squeezes its child while pressed.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, required this.onTap, this.label});

  final Widget child;
  final VoidCallback? onTap;
  final String? label;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: widget.onTap == null
            ? null
            : (_) {
                setState(() => _down = false);
                HapticFeedback.lightImpact();
                widget.onTap!();
              },
        child: AnimatedScale(
          scale: _down ? 0.965 : 1,
          duration: Duration(milliseconds: _down ? 90 : 300),
          curve: _down ? Curves.easeOut : Motion.spring,
          child: widget.child,
        ),
      ),
    );
  }
}

/// A heading with an optional action at the right.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis)),
        if (action != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(foregroundColor: p.accentDeep),
            child: Text(action!, style: Theme.of(context).textTheme.labelMedium!.copyWith(color: p.accentDeep, fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }
}

/// The person's photo, or their initial.
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.name, this.image, this.size = 44});

  final String name;
  final String? image;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final initial = Container(
      color: p.accent,
      alignment: Alignment.center,
      child: Text(name.isEmpty ? '?' : name[0], style: Theme.of(context).textTheme.titleMedium!.copyWith(color: p.onAccent)),
    );
    return Semantics(
      label: 'Profile photo',
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: p.accent, width: 2)),
        child: ClipOval(
          child: image != null && image!.startsWith('asset:')
              ? Image.asset('assets/images/${image!.substring(6)}', fit: BoxFit.cover, errorBuilder: (_, _, _) => initial)
              : initial,
        ),
      ),
    );
  }
}

/// A frosted round icon button.
class RoundButton extends StatelessWidget {
  const RoundButton({super.key, required this.icon, required this.label, required this.onTap, this.size = 46});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      label: label,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: p.card.withValues(alpha: 0.8), border: Border.all(color: p.line)),
        child: Icon(icon, size: 21, color: p.ink),
      ),
    );
  }
}

/// A short empty state: a picture, a line and an action.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.art, required this.title, required this.message, this.action});

  final Widget art;
  final String title, message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter * 1.5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          art,
          const SizedBox(height: 18),
          Text(title, style: text.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(message, style: text.bodyMedium, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 24), action!],
        ],
      ),
    );
  }
}

/// A frosted dock for actions pinned over scrolling content (price and
/// Add to bag), so what scrolls underneath never collides with them.
class ActionDock extends StatelessWidget {
  const ActionDock({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 10, 10),
          decoration: BoxDecoration(
            color: p.card.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: p.line),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A rounded search box.
class SearchField extends StatelessWidget {
  const SearchField({super.key, required this.controller, required this.onChanged, this.hint = 'Search the menu'});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: p.card.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(18), border: Border.all(color: p.line)),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: p.muted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: p.ink),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(color: p.muted),
              ),
            ),
          ),
          ListenableBuilder(
            listenable: controller,
            builder: (_, _) => controller.text.isEmpty
                ? const SizedBox.shrink()
                : GestureDetector(
                    onTap: () {
                      controller.clear();
                      onChanged('');
                    },
                    child: Semantics(label: 'Clear search', button: true, child: Icon(Icons.close_rounded, color: p.muted, size: 20)),
                  ),
          ),
        ],
      ),
    );
  }
}

/// What is revealed behind a visit being swiped away.
class SwipeToCancel extends StatelessWidget {
  const SwipeToCancel({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(color: p.accentWash, borderRadius: BorderRadius.circular(Tokens.cardRadius - 4)),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Cancel visit', style: Theme.of(context).textTheme.labelMedium!.copyWith(color: p.accentDeep)),
          const SizedBox(width: 8),
          Icon(Icons.event_busy_rounded, color: p.accentDeep),
        ],
      ),
    );
  }
}
