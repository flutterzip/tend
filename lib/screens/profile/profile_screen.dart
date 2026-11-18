import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/store.dart';
import '../../widgets/widgets.dart';
import '../sign_in/sign_in_screen.dart';

/// You: a live heart monitor, your health details, and signing out.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seed = ref.watch(seedProvider);
    final profile = seed.profile;
    final visits = ref.watch(pastProvider).where((a) => !a.cancelled).length;
    final text = Theme.of(context).textTheme;
    final p = context.palette;

    return ListView(
      padding: EdgeInsets.fromLTRB(Tokens.gutter, MediaQuery.paddingOf(context).top + 18, Tokens.gutter, 130),
      children: [
        Entrance(
          spacing: 18,
          children: [
            Row(
              children: [
                Avatar(name: profile.name, image: profile.avatar, size: 64),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.name, style: text.headlineSmall),
                      Text(profile.email, style: text.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              decoration: BoxDecoration(color: p.card.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(Tokens.cardRadius), border: Border.all(color: p.line)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      BeatingHeart(bpm: profile.heartRate.toDouble(), size: 34),
                      const SizedBox(width: 10),
                      Text('Heart rate', style: text.titleMedium),
                      const Spacer(),
                      RollingNumber(profile.heartRate, style: text.headlineSmall!.copyWith(color: p.accentDeep)),
                      Text(' bpm', style: text.labelMedium),
                    ],
                  ),
                  Heartbeat(bpm: profile.heartRate.toDouble(), height: 70),
                  Text('Resting, from your watch', style: text.labelSmall),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(child: Stat(value: profile.bloodType, label: 'blood type', icon: Icons.bloodtype_outlined)),
                const SizedBox(width: 10),
                Expanded(child: Stat(value: '$visits', label: 'visits', icon: Icons.event_available_rounded)),
                const SizedBox(width: 10),
                Expanded(child: Stat(value: '${profile.allergies.length}', label: 'allergy', icon: Icons.warning_amber_rounded)),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: p.accentWash, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: p.accentDeep),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Allergic to ${profile.allergies.join(', ')}. Your doctors see this before every visit.', style: text.bodyMedium)),
                ],
              ),
            ),
            TendButton.ghost(
              label: 'Sign out',
              icon: Icons.logout_rounded,
              onPressed: () async {
                await ref.read(signedInProvider.notifier).signOut();
                if (context.mounted) context.restart(const SignInScreen());
              },
            ),
          ],
        ),
      ],
    );
  }
}
