import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/brand.dart';
import '../../state/store.dart';
import '../../widgets/widgets.dart';
import '../shell/shell.dart';

/// Sign in. The heart races while you type and settles when you stop.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  String? emailError, passwordError;
  bool busy = false, done = false;
  double bpm = 72;
  Timer? calm;

  void typed(String _) {
    calm?.cancel();
    setState(() => bpm = 118);
    calm = Timer(const Duration(milliseconds: 1400), () => setState(() => bpm = 72));
  }

  Future<void> signIn() async {
    setState(() {
      emailError = Check.emailError(email.text);
      passwordError = password.text.isEmpty ? 'Enter your password' : null;
    });
    if (emailError != null || passwordError != null) return;

    FocusScope.of(context).unfocus();
    setState(() => busy = true);
    await ref.read(signedInProvider.notifier).signIn();
    setState(() {
      busy = false;
      done = true;
      bpm = 96;
    });
    await AppTiming.wait(AppTiming.successBeat);
    if (mounted) context.restart(const Shell());
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(Tokens.gutter, MediaQuery.paddingOf(context).top + 28, Tokens.gutter, 40),
        children: [
          Center(child: BeatingHeart(bpm: bpm, size: 96)),
          Heartbeat(bpm: bpm, height: 70),
          Center(
            child: AnimatedSwitcher(
              duration: Motion.short,
              child: Text('${bpm.round()} bpm', key: ValueKey(bpm.round()), style: text.labelMedium!.copyWith(color: p.accentDeep)),
            ),
          ),
          const SizedBox(height: 22),
          Entrance(
            spacing: 18,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome to ${AppBrand.name}', style: text.headlineSmall),
                  const SizedBox(height: 6),
                  Text('Sign in to see your doctors and appointments.', style: text.bodyMedium),
                ],
              ),
              TendField.email(controller: email, error: emailError, onChanged: typed),
              TendField.password(controller: password, error: passwordError, onChanged: typed, onSubmitted: (_) => signIn()),
              TendButton(label: 'Sign in', busy: busy, done: done, onPressed: signIn),
              Center(
                child: TextButton(
                  onPressed: () {
                    email.text = ref.read(seedProvider).profile.email;
                    password.text = 'tend1234';
                    typed('');
                  },
                  child: Text('Use the demo account', style: text.labelMedium!.copyWith(color: p.accentDeep)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    calm?.cancel();
    email.dispose();
    password.dispose();
    super.dispose();
  }
}
