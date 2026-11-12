import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/utils/messenger.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/notification/presentation/providers/notification_providers.dart';
import 'features/profile/presentation/providers/profile_providers.dart';

class EcomApp extends ConsumerWidget {
  const EcomApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Ecom',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootMessengerKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) =>
          _LifecycleWatcher(child: child ?? const SizedBox.shrink()),
    );
  }
}

/// Polls notifications when the app returns to the foreground and once a
/// minute while it is open.
class _LifecycleWatcher extends ConsumerStatefulWidget {
  const _LifecycleWatcher({required this.child});
  final Widget child;

  @override
  ConsumerState<_LifecycleWatcher> createState() => _LifecycleWatcherState();
}

class _LifecycleWatcherState extends ConsumerState<_LifecycleWatcher>
    with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  void _check() {
    if (ref.read(authControllerProvider).isAuthenticated) {
      ref.read(notificationWatcherProvider).check();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  @override
  Widget build(BuildContext context) {
    // Run a first check right after login.
    ref.listen(authControllerProvider.select((s) => s.isAuthenticated), (
      _,
      authed,
    ) {
      if (authed) _check();
    });
    return widget.child;
  }
}
