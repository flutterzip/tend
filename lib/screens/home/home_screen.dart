import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/store.dart';
import '../../widgets/widgets.dart';
import '../doctor/doctor_screen.dart';
import '../shell/shell.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final search = TextEditingController();
  String? specialty;
  String query = '';

  void open(Doctor doctor) => context.open(DoctorScreen(doctor: doctor));

  @override
  Widget build(BuildContext context) {
    final seed = ref.watch(seedProvider);
    final next = ref.watch(upcomingProvider).firstOrNull;
    final now = ref.watch(nowProvider);
    final text = Theme.of(context).textTheme;
    final q = query.toLowerCase();
    final doctors = seed.doctors
        .where((d) => specialty == null || d.specialty == specialty)
        .where((d) => d.name.toLowerCase().contains(q) || d.specialty.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));

    return ListView(
      padding: EdgeInsets.fromLTRB(0, MediaQuery.paddingOf(context).top + 12, 0, 130),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
          child: Entrance(
            spacing: 20,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hi, ${seed.profile.firstName}', style: text.headlineSmall),
                        Text('How are you feeling today?', style: text.bodyMedium),
                      ],
                    ),
                  ),
                  Avatar(name: seed.profile.name, image: seed.profile.avatar),
                ],
              ),
              if (next != null)
                AppointmentCard(
                  doctor: seed.doctor(next.doctorId),
                  appointment: next,
                  now: now,
                  prominent: true,
                  onTap: () => ref.read(tabProvider.notifier).state = 1,
                ),
              SearchField(controller: search, hint: 'Search doctors or specialties', onChanged: (v) => setState(() => query = v)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter - 8),
            children: [
              for (final s in seed.specialties)
                SpecialtyTile(
                  name: s,
                  selected: s == specialty,
                  onTap: () => setState(() => specialty = s == specialty ? null : s),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Tokens.gutter, 12, Tokens.gutter, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionTitle(specialty ?? 'Top doctors'),
              const SizedBox(height: 10),
              if (doctors.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Text('No doctor matches that. Try a specialty instead.', style: text.bodyMedium, textAlign: TextAlign.center),
                ),
              for (final d in doctors) ...[
                DoctorRow(doctor: d, onTap: () => open(d)),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }
}
