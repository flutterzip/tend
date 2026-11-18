import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/motion.dart';
import '../config/palette.dart';
import '../config/theme.dart';

enum FieldKind { text, name, email, password }

/// The one text field in Tend. Its title sits above the box and takes the
/// accent on focus; the box glows; a wrong answer shakes it.
///
/// It reports where its caret is ([onCaret], 0 at the start of the box and
/// 1 at the end) and whether a password is being shown ([onReveal]), for
/// anything on screen that reacts to typing.
class TendField extends StatefulWidget {
  const TendField({
    super.key,
    required this.label,
    required this.controller,
    this.kind = FieldKind.text,
    this.hint,
    this.icon,
    this.error,
    this.action,
    this.onCaret,
    this.onFocus,
    this.onReveal,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction = TextInputAction.next,
    this.focusNode,
  });

  const TendField.name({
    Key? key,
    required TextEditingController controller,
    String label = 'Full name',
    String? error,
    ValueChanged<double>? onCaret,
    ValueChanged<bool>? onFocus,
    ValueChanged<String>? onChanged,
    FocusNode? focusNode,
  }) : this(
          key: key,
          label: label,
          controller: controller,
          kind: FieldKind.name,
          hint: 'Ada Lovelace',
          icon: Icons.person_outline_rounded,
          error: error,
          onCaret: onCaret,
          onFocus: onFocus,
          onChanged: onChanged,
          focusNode: focusNode,
        );

  const TendField.email({
    Key? key,
    required TextEditingController controller,
    String label = 'Email',
    String? error,
    ValueChanged<double>? onCaret,
    ValueChanged<bool>? onFocus,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    TextInputAction textInputAction = TextInputAction.next,
    FocusNode? focusNode,
  }) : this(
          key: key,
          label: label,
          controller: controller,
          kind: FieldKind.email,
          hint: 'you@example.com',
          icon: Icons.alternate_email_rounded,
          error: error,
          onCaret: onCaret,
          onFocus: onFocus,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          textInputAction: textInputAction,
          focusNode: focusNode,
        );

  const TendField.password({
    Key? key,
    required TextEditingController controller,
    String label = 'Password',
    String hint = 'At least 8 characters',
    String? error,
    Widget? action,
    ValueChanged<double>? onCaret,
    ValueChanged<bool>? onFocus,
    ValueChanged<bool>? onReveal,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    TextInputAction textInputAction = TextInputAction.done,
    FocusNode? focusNode,
  }) : this(
          key: key,
          label: label,
          controller: controller,
          kind: FieldKind.password,
          hint: hint,
          icon: Icons.lock_outline_rounded,
          error: error,
          action: action,
          onCaret: onCaret,
          onFocus: onFocus,
          onReveal: onReveal,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          textInputAction: textInputAction,
          focusNode: focusNode,
        );

  final String label;
  final TextEditingController controller;
  final FieldKind kind;
  final String? hint;
  final IconData? icon;

  /// Shown under the box. Setting it shakes the field.
  final String? error;

  /// A small action at the right of the title row (Forgot password?).
  final Widget? action;

  final ValueChanged<double>? onCaret;
  final ValueChanged<bool>? onFocus;
  final ValueChanged<bool>? onReveal;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction textInputAction;
  final FocusNode? focusNode;

  @override
  State<TendField> createState() => _TendFieldState();
}

class _TendFieldState extends State<TendField>
    with SingleTickerProviderStateMixin {
  late final _shake = AnimationController(vsync: this, duration: Motion.shake);
  FocusNode? _ownFocus;
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());
  bool _focused = false;
  bool _shown = false;

  /// The person has edited the field since [TendField.error] arrived, so
  /// the error is out of date and hidden until the next check.
  bool _dismissed = false;
  String _lastText = '';
  double _textWidth = 1;

  bool get _isPassword => widget.kind == FieldKind.password;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
    widget.controller.addListener(_reportCaret);
    widget.controller.addListener(_onText);
    _lastText = widget.controller.text;
  }

  void _onText() {
    final text = widget.controller.text;
    if (text == _lastText) return;
    _lastText = text;
    if (widget.error != null && !_dismissed) setState(() => _dismissed = true);
  }

  @override
  void didUpdateWidget(TendField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_reportCaret);
      old.controller.removeListener(_onText);
      widget.controller.addListener(_reportCaret);
      widget.controller.addListener(_onText);
    }
    final fresh = widget.error != null && (old.error != widget.error || _dismissed);
    if (fresh) {
      _dismissed = false;
      if (!Motion.reduced(context)) _shake.forward(from: 0);
      HapticFeedback.mediumImpact();
    } else if (widget.error == null) {
      _dismissed = false;
    }
  }

  void _onFocus() {
    if (_focus.hasFocus == _focused) return;
    setState(() => _focused = _focus.hasFocus);
    widget.onFocus?.call(_focused);
    if (_focused) _reportCaret();
  }

  void _reportCaret() {
    if (!_focused || widget.onCaret == null) return;
    final value = widget.controller.value;
    final caret = value.selection.baseOffset.clamp(0, value.text.length);
    var before = value.text.substring(0, caret);
    if (_isPassword && !_shown) before = '•' * before.length;
    final painter = TextPainter(
      text: TextSpan(text: before, style: _style(context)),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    widget.onCaret!(math.min(1.0, painter.width / math.max(_textWidth, 1)));
  }

  void _toggleShown() {
    setState(() => _shown = !_shown);
    HapticFeedback.selectionClick();
    widget.onReveal?.call(_shown);
  }

  TextStyle _style(BuildContext context) => TextStyle(
        fontFamily: 'Bricolage',
        fontSize: 16.5,
        fontWeight: FontWeight.w500,
        color: context.palette.ink,
        letterSpacing: _isPassword && !_shown ? 2 : 0,
      );

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    widget.controller.removeListener(_reportCaret);
    widget.controller.removeListener(_onText);
    _ownFocus?.dispose();
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hasError = widget.error != null && !_dismissed;
    final tone = hasError ? p.error : (_focused ? p.accentDeep : p.muted);
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final t = _shake.value;
        final dx = math.sin(t * math.pi * 5) * 9 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _TitleRow(
            label: widget.label,
            color: hasError ? p.error : (_focused ? p.accentDeep : p.ink),
            action: widget.action,
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: Motion.short,
            curve: Motion.settle,
            height: Tokens.fieldHeight,
            decoration: BoxDecoration(
              color: _focused ? p.card : p.field,
              borderRadius: BorderRadius.circular(Tokens.fieldRadius),
              border: Border.all(
                color: hasError ? p.error : (_focused ? p.accent : p.line),
                width: _focused || hasError ? 1.6 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (hasError ? p.error : p.accent)
                      .withValues(alpha: _focused ? 0.22 : 0),
                  blurRadius: 22,
                  spreadRadius: -2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                if (widget.icon != null) ...[
                  TweenAnimationBuilder<Color?>(
                    duration: Motion.short,
                    tween: ColorTween(end: tone),
                    builder: (_, c, _) => Icon(widget.icon, size: 21, color: c),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: LayoutBuilder(builder: (context, box) {
                    _textWidth = box.maxWidth;
                    return TextField(
                      controller: widget.controller,
                      focusNode: _focus,
                      obscureText: _isPassword && !_shown,
                      obscuringCharacter: '•',
                      style: _style(context),
                      keyboardType: switch (widget.kind) {
                        FieldKind.email => TextInputType.emailAddress,
                        FieldKind.name => TextInputType.name,
                        _ => TextInputType.text,
                      },
                      textCapitalization: widget.kind == FieldKind.name
                          ? TextCapitalization.words
                          : TextCapitalization.none,
                      autocorrect: false,
                      enableSuggestions: !_isPassword,
                      autofillHints: switch (widget.kind) {
                        FieldKind.email => const [AutofillHints.email],
                        FieldKind.name => const [AutofillHints.name],
                        FieldKind.password => const [AutofillHints.password],
                        FieldKind.text => null,
                      },
                      textInputAction: widget.textInputAction,
                      onChanged: widget.onChanged,
                      onSubmitted: widget.onSubmitted,
                      onTap: _reportCaret,
                      cursorWidth: 2,
                      cursorRadius: const Radius.circular(2),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: widget.hint,
                        hintStyle: TextStyle(
                          fontFamily: 'Bricolage',
                          fontSize: 16,
                          color: p.muted.withValues(alpha: 0.8),
                          letterSpacing: 0,
                        ),
                      ),
                    );
                  }),
                ),
                if (_isPassword)
                  _RevealButton(shown: _shown, onTap: _toggleShown)
                else
                  const SizedBox(width: 16),
              ],
            ),
          ),
          AnimatedSize(
            duration: Motion.short,
            curve: Motion.settle,
            alignment: Alignment.topLeft,
            child: hasError
                ? Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded,
                            size: 16, color: p.error),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.error!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(color: p.error),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.label, required this.color, this.action});

  final String label;
  final Color color;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    // The action floats over the row so its 48dp touch target does not
    // make the row taller than the label.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: AnimatedDefaultTextStyle(
            duration: Motion.short,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(color: color),
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
        if (action != null)
          Positioned(right: -8, top: -14, bottom: -14, child: Center(child: action!)),
      ],
    );
  }
}

/// An eye that opens and closes with the password.
class _RevealButton extends StatelessWidget {
  const _RevealButton({required this.shown, required this.onTap});

  final bool shown;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: shown ? 'Hide password' : 'Show password',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 54,
          height: Tokens.fieldHeight,
          child: Center(
            child: AnimatedSwitcher(
              duration: Motion.short,
              transitionBuilder: (child, a) => ScaleTransition(
                scale: Tween(begin: 0.6, end: 1.0).animate(a),
                child: FadeTransition(opacity: a, child: child),
              ),
              child: Icon(
                shown ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                key: ValueKey(shown),
                size: 21,
                color: shown ? p.accentDeep : p.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
