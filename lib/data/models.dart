import 'package:flutter/material.dart';

/// Money is whole cents, formatted only at the edge.
String money(int cents) => '\$${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';

class Doctor {
  const Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.focus,
    required this.years,
    required this.rating,
    required this.reviews,
    required this.fee,
    required this.clinic,
    required this.about,
    required this.hue,
  });

  final String id, name, specialty, focus, clinic, about;
  final int years, reviews, fee;
  final double rating;

  /// Which step of the accent ramp the portrait is drawn in.
  final int hue;

  /// "AO" for "Dr. Adaeze Okoro"
  String get initials => name.replaceFirst('Dr. ', '').split(' ').map((w) => w[0]).take(2).join();

  String get shortName => name.split(' ').take(2).join(' ').replaceAll('Dr.', 'Dr');

  factory Doctor.fromJson(Map<String, Object?> j) => Doctor(
        id: j['id'] as String,
        name: j['name'] as String,
        specialty: j['specialty'] as String,
        focus: j['focus'] as String,
        years: j['years'] as int,
        rating: (j['rating'] as num).toDouble(),
        reviews: j['reviews'] as int,
        fee: j['fee'] as int,
        clinic: j['clinic'] as String,
        about: j['about'] as String,
        hue: j['hue'] as int,
      );
}

/// The icon for a specialty.
IconData specialtyIcon(String specialty) => switch (specialty) {
      'Cardiology' => Icons.favorite_rounded,
      'General practice' => Icons.medical_services_rounded,
      'Dermatology' => Icons.spa_rounded,
      'Pediatrics' => Icons.child_care_rounded,
      'Dentistry' => Icons.sentiment_satisfied_alt_rounded,
      'Neurology' => Icons.psychology_rounded,
      'Psychology' => Icons.self_improvement_rounded,
      'Orthopedics' => Icons.directions_run_rounded,
      _ => Icons.local_hospital_rounded,
    };

/// A time of day, minutes from midnight.
class Slot {
  const Slot(this.minutes);

  final int minutes;

  int get hour => minutes ~/ 60;
  int get minute => minutes % 60;

  /// "9:30 AM"
  String get label {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    return '$h:${minute.toString().padLeft(2, '0')} ${hour < 12 ? 'AM' : 'PM'}';
  }

  static Slot parse(String hhmm) {
    final parts = hhmm.split(':');
    return Slot(int.parse(parts[0]) * 60 + int.parse(parts[1]));
  }

  @override
  bool operator ==(Object other) => other is Slot && other.minutes == minutes;

  @override
  int get hashCode => minutes.hashCode;
}

/// Opening hours: every half hour from 9:00 to 16:30, closed 12:30 to 13:30.
const openSlots = [
  Slot(540), Slot(570), Slot(600), Slot(630), Slot(660), Slot(690), Slot(720),
  Slot(810), Slot(840), Slot(870), Slot(900), Slot(930), Slot(960), Slot(990),
];

enum Reason {
  checkUp('Check-up'),
  followUp('Follow-up'),
  newProblem('Something new'),
  results('Test results');

  const Reason(this.label);
  final String label;
}

class Appointment {
  const Appointment({required this.id, required this.doctorId, required this.start, required this.reason, this.cancelled = false});

  final String id, doctorId;
  final DateTime start;
  final Reason reason;
  final bool cancelled;

  DateTime get end => start.add(const Duration(minutes: 30));

  Appointment copyWith({DateTime? start, bool? cancelled}) =>
      Appointment(id: id, doctorId: doctorId, start: start ?? this.start, reason: reason, cancelled: cancelled ?? this.cancelled);

  Map<String, Object?> toJson() => {
        'id': id,
        'doctorId': doctorId,
        'start': start.toIso8601String(),
        'reason': reason.name,
        'cancelled': cancelled,
      };

  factory Appointment.fromJson(Map<String, Object?> j) => Appointment(
        id: j['id'] as String,
        doctorId: j['doctorId'] as String,
        start: DateTime.parse(j['start'] as String),
        reason: Reason.values.byName(j['reason'] as String),
        cancelled: j['cancelled'] as bool? ?? false,
      );
}

class Profile {
  const Profile({required this.name, required this.email, required this.bloodType, required this.heartRate, required this.allergies, this.avatar});

  final String name, email, bloodType;
  final int heartRate;
  final List<String> allergies;
  final String? avatar;

  String get firstName => name.split(' ').first;
}

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String weekday(DateTime d) => _days[d.weekday - 1];
String monthShort(DateTime d) => _months[d.month - 1];

/// "Tue 24 Nov"
String dayLabel(DateTime d) => '${weekday(d)} ${d.day} ${monthShort(d)}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
