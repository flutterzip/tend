import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'state/store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final results = await Future.wait([SharedPreferences.getInstance(), Seed.load()]);
  runApp(
    ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(results[0] as SharedPreferences),
        seedProvider.overrideWithValue(results[1] as Seed),
      ],
      child: const TendApp(),
    ),
  );
}
