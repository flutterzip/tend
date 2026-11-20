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
  final scroll = ScrollController();
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
    final doctors = seed.doctors.where((d) => specialty == null || d.specialty == specialty).where((d) => d.name.toLowerCase().contains(q) || d.specialty.toLowerCase().contains(q)).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));

    // The greeting stays put; search and specialties slide away while you
    // read down the list and come back the moment you scroll up.
    final greeting = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Hi, ${seed.profile.firstName}', maxLines: 1, overflow: TextOverflow.ellipsis, style: text.headlineSmall),
              Text('How are you feeling today?', maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodyMedium),
            ],
          ),
        ),
        Avatar(name: seed.profile.name, image: seed.profile.avatar),
      ],
    );
    final filters = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Tokens.gutter, 4, Tokens.gutter, 0),
          child: SearchField(controller: search, hint: 'Search doctors or specialties', onChanged: (v) => setState(() => query = v)),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: _stripHeight,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter - 8),
            children: [for (final s in seed.specialties) SpecialtyTile(name: s, selected: s == specialty, onTap: () => setState(() => specialty = s == specialty ? null : s))],
          ),
        ),
      ],
    );

    return Stack(
      children: [
        ListView(
          controller: scroll,
          padding: EdgeInsets.fromLTRB(Tokens.gutter, TopChrome.extent(context, bottomHeight: _filtersHeight) + 6, Tokens.gutter, 130),
          children: [
            Entrance(
              spacing: 20,
              children: [
                if (next != null) AppointmentCard(doctor: seed.doctor(next.doctorId), appointment: next, now: now, prominent: true, onTap: () => ref.read(tabProvider.notifier).state = 1),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionTitle(specialty ?? 'Top doctors'),
                    const SizedBox(height: 10),
                    if (doctors.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        child: Text('No doctor matches that. Try a specialty instead.', style: text.bodyMedium, textAlign: TextAlign.center),
                      ),
                    for (final d in doctors) ...[DoctorRow(doctor: d, onTap: () => open(d)), const SizedBox(height: 12)],
                  ],
                ),
              ],
            ),
          ],
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: TopChrome(controller: scroll, row: greeting, bottom: filters, bottomHeight: _filtersHeight),
        ),
      ],
    );
  }

  /// The specialty tiles, with room for the chosen one's glow.
  static const _stripHeight = 102.0;
  static const _filtersHeight = 4 + 52 + 14 + _stripHeight;

  @override
  void dispose() {
    search.dispose();
    scroll.dispose();
    super.dispose();
  }
}
