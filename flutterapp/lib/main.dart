import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/providers.dart';
import 'features/notification/presentation/providers/notification_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final notifier = PluginLocalNotifier();
  await notifier.init();

  runApp(
    ProviderScope(
      // Failed requests surface as error states with a Retry button instead
      // of being silently retried by Riverpod.
      retry: (_, _) => null,
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        localNotifierProvider.overrideWithValue(notifier),
      ],
      child: const EcomApp(),
    ),
  );
}
