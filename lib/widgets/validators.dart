/// Checks shared by every form.
abstract final class Check {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

  static bool email(String value) => _email.hasMatch(value.trim());

  /// 0 empty, 1 too short, 2 weak, 3 good, 4 strong. Length counts for far
  /// more than a jumble of symbols, and one character repeated never passes.
  static int password(String value) {
    if (value.isEmpty) return 0;
    if (value.length < 8) return 1;
    if (value.split('').toSet().length == 1) return 1;
    var score = 2;
    if (value.length >= 12) score++;
    final kinds = [
      RegExp(r'[a-z]'),
      RegExp(r'[A-Z]'),
      RegExp(r'[0-9]'),
      RegExp(r'[^A-Za-z0-9]'),
    ].where((r) => r.hasMatch(value)).length;
    if (kinds >= 2 && value.length >= 10) score++;
    if (value.length >= 16) score++;
    return score.clamp(0, 4);
  }

  static String? emailError(String value) => value.trim().isEmpty
      ? 'Enter your email'
      : (email(value) ? null : 'Enter an email like name@example.com');
}
