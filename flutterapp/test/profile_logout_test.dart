import 'package:ecom_mobile/core/providers.dart';
import 'package:ecom_mobile/core/router/app_router.dart';
import 'package:ecom_mobile/core/storage/token_storage.dart';
import 'package:ecom_mobile/core/theme/app_theme.dart';
import 'package:ecom_mobile/features/auth/data/models/app_user.dart';
import 'package:ecom_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:ecom_mobile/features/cart/data/models/cart_models.dart';
import 'package:ecom_mobile/features/notification/data/repositories/notification_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fixtures.dart';
import 'helpers/test_app.dart';

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

/// Starts already signed in; `logout()` is the real implementation.
class SignedInAuth extends AuthController {
  @override
  AuthState build() => AuthState(
    status: AuthStatus.authenticated,
    user: AppUser.fromJson(authJson['user'] as Map<String, dynamic>),
  );
}

void main() {
  testWidgets(
    'Profile > Log out > confirm: signs out, clears storage, lands on /login',
    (tester) async {
      SharedPreferences.setMockInitialValues({'remember_session': true});
      final prefs = await SharedPreferences.getInstance();
      final storage = MemoryTokenStorage('secret-token');
      final cart = MockCartRepository();
      when(() => cart.getCart()).thenAnswer((_) async => const Cart());
      final notif = MockNotificationRepository();
      when(() => notif.unreadCount()).thenAnswer((_) async => 3);

      final routerProv = Provider<GoRouter>(
        (ref) => buildRouter(ref, initialLocation: '/profile'),
      );
      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [
            sharedPrefsProvider.overrideWithValue(prefs),
            tokenStorageProvider.overrideWithValue(storage),
            cartRepositoryProvider.overrideWithValue(cart),
            notificationRepositoryProvider.overrideWithValue(notif),
            authControllerProvider.overrideWith(SignedInAuth.new),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return MaterialApp.router(
                theme: AppTheme.light(),
                routerConfig: ref.watch(routerProv),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.byKey(const Key('logout')), 200);
      await tester.tap(find.byKey(const Key('logout')));
      await tester.pumpAndSettle();
      expect(find.text('Log out?'), findsOneWidget);

      // The dialog's confirm button must close the dialog and log out.
      await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
      await tester.pumpAndSettle();

      expect(find.text('Log out?'), findsNothing);
      expect(
        container.read(authControllerProvider).status,
        AuthStatus.unauthenticated,
      );
      expect(await storage.read(), isNull);
      expect(prefs.getBool('remember_session'), isNull);
      expect(find.text('Welcome back'), findsOneWidget); // login screen

      // Back / deep links to protected pages must bounce to /login.
      final router = container.read(routerProv);
      router.go('/orders');
      await tester.pumpAndSettle();
      expect(find.text('Welcome back'), findsOneWidget);
      expect(router.routerDelegate.currentConfiguration.uri.path, '/login');
    },
  );

  testWidgets('Cancel keeps the user signed in', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = MemoryTokenStorage('secret-token');
    final cart = MockCartRepository();
    when(() => cart.getCart()).thenAnswer((_) async => const Cart());
    final notif = MockNotificationRepository();
    when(() => notif.unreadCount()).thenAnswer((_) async => 0);
    final routerProv = Provider<GoRouter>(
      (ref) => buildRouter(ref, initialLocation: '/profile'),
    );
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          tokenStorageProvider.overrideWithValue(storage),
          cartRepositoryProvider.overrideWithValue(cart),
          notificationRepositoryProvider.overrideWithValue(notif),
          authControllerProvider.overrideWith(SignedInAuth.new),
        ],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: ref.watch(routerProv),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('logout')), 200);
    await tester.tap(find.byKey(const Key('logout')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Log out?'), findsNothing);
    expect(find.byKey(const Key('logout')), findsOneWidget);
    expect(await storage.read(), 'secret-token');
  });
}
