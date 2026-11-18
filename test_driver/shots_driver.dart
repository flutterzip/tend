import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Saves every screenshot the shots test takes to `build/shots/NAME.png`.
Future<void> main() => integrationDriver(
      onScreenshot: (name, bytes, [args]) async {
        final f = File('build/shots/$name.png');
        await f.create(recursive: true);
        await f.writeAsBytes(bytes);
        return true;
      },
    );
