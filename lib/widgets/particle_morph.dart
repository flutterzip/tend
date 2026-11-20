import 'package:flutter/widgets.dart';

import '../config/motion.dart';
import 'particles/particle_switcher.dart';

/// A moment of success: the old face breaks into fragments that fly
/// together as the new one. Give each face its own key.
///
/// Off in tests (with the ambient loops) and when the system asks for less
/// motion, where the new face simply takes the old one's place.
class ParticleMorph extends StatelessWidget {
  const ParticleMorph({super.key, required this.child, this.duration = const Duration(milliseconds: 1100)});

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) => Motion.loops(context) ? ParticleSwitcher(duration: duration, child: child) : child;
}
