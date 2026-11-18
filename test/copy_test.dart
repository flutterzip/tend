import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every string on screen ends up in a recording. No em dashes, and nothing
/// that talks to the builder.
void main() {
  test('no em dashes or builder notes in on-screen strings', () {
    final literal = RegExp(r"""'([^'\\]|\\.)*'""");
    final offenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      for (final (i, line) in f.readAsLinesSync().indexed) {
        if (line.trimLeft().startsWith('//')) continue;
        for (final m in literal.allMatches(line)) {
          final s = m.group(0)!;
          if (s.contains('—') || RegExp(r'screenshot|for the demo video|good for', caseSensitive: false).hasMatch(s)) {
            offenders.add('${f.path}:${i + 1} $s');
          }
        }
      }
    }
    expect(offenders, isEmpty);
  });
}
