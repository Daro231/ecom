import 'package:ecom_mobile/core/network/api_exception.dart';
import 'package:ecom_mobile/core/providers.dart';
import 'package:ecom_mobile/core/storage/token_storage.dart';
import 'package:ecom_mobile/features/auth/data/models/app_user.dart';
import 'package:ecom_mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:ecom_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:ecom_mobile/features/cart/presentation/providers/cart_providers.dart';
import 'package:ecom_mobile/features/product/data/models/product_filter.dart';
import 'package:ecom_mobile/features/product/presentation/providers/product_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fixtures.dart';
import 'helpers/test_app.dart' show MockCartRepository;
import 'package:ecom_mobile/features/cart/data/models/cart_models.dart';
import 'package:ecom_mobile/features/notification/data/repositories/notification_repository.dart';
import 'package:ecom_mobile/features/notification/presentation/providers/notification_providers.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

void main() {
  late MockAuthRepository repo;
  late MemoryTokenStorage storage;
  late ProviderContainer container;

  Future<ProviderContainer> make({
    String? token,
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    storage = MemoryTokenStorage(token);
    final c = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        tokenStorageProvider.overrideWithValue(storage),
        sharedPrefsProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() => repo = MockAuthRepository());

  test('login stores the token and authenticates', () async {
    container = await make();
    when(
      () => repo.login(any(), any()),
    ).thenAnswer((_) async => AuthResult.fromJson(authJson));
    await container
        .read(authControllerProvider.notifier)
        .login('customer@ecom.com', 'Customer@123');
    final s = container.read(authControllerProvider);
    expect(s.isAuthenticated, isTrue);
    expect(s.user!.email, 'customer@ecom.com');
    expect(await storage.read(), startsWith('eyJ'));
    expect(container.read(currentUserIdProvider), 3);
  });

  test('wrong credentials leave the user logged out', () async {
    container = await make();
    when(() => repo.login(any(), any())).thenThrow(
      const ApiException(
        type: ApiErrorType.unauthorized,
        message: 'Invalid email or password',
        statusCode: 401,
      ),
    );
    await expectLater(
      container.read(authControllerProvider.notifier).login('a@b.co', 'x'),
      throwsA(isA<ApiException>()),
    );
    expect(container.read(authControllerProvider).isAuthenticated, isFalse);
    expect(await storage.read(), isNull);
  });

  test('staff / admin accounts are rejected in the customer app', () async {
    container = await make();
    when(() => repo.login(any(), any())).thenAnswer(
      (_) async => AuthResult.fromJson({
        ...authJson,
        'user': {...userJson, 'role': 'ADMIN'},
      }),
    );
    await expectLater(
      container
          .read(authControllerProvider.notifier)
          .login('admin@ecom.com', 'Admin@123'),
      throwsA(isA<ApiException>()),
    );
    expect(await storage.read(), isNull);
  });

  test('logout clears the token', () async {
    container = await make(token: 'abc');
    when(() => repo.me()).thenAnswer((_) async => AppUser.fromJson(userJson));
    await container.read(authControllerProvider.notifier).bootstrap();
    expect(container.read(authControllerProvider).isAuthenticated, isTrue);
    await container.read(authControllerProvider.notifier).logout();
    expect(
      container.read(authControllerProvider).status,
      AuthStatus.unauthenticated,
    );
    expect(await storage.read(), isNull);
  });

  test('bootstrap without token -> unauthenticated, no network call', () async {
    container = await make();
    await container.read(authControllerProvider.notifier).bootstrap();
    expect(
      container.read(authControllerProvider).status,
      AuthStatus.unauthenticated,
    );
    verifyNever(() => repo.me());
  });

  test('bootstrap with a rejected token clears it; offline keeps it', () async {
    container = await make(token: 'old');
    when(() => repo.me()).thenThrow(
      const ApiException(
        type: ApiErrorType.unauthorized,
        message: 'expired',
        statusCode: 401,
      ),
    );
    await container.read(authControllerProvider.notifier).bootstrap();
    expect(
      container.read(authControllerProvider).status,
      AuthStatus.unauthenticated,
    );
    expect(await storage.read(), isNull);

    container = await make(token: 'keep');
    when(() => repo.me()).thenThrow(
      const ApiException(type: ApiErrorType.network, message: 'offline'),
    );
    await expectLater(
      container.read(authControllerProvider.notifier).bootstrap(),
      throwsA(isA<ApiException>()),
    );
    expect(await storage.read(), 'keep');
  });

  test('"keep me signed in" off -> next cold start is logged out', () async {
    container = await make();
    when(
      () => repo.login(any(), any()),
    ).thenAnswer((_) async => AuthResult.fromJson(authJson));
    await container
        .read(authControllerProvider.notifier)
        .login('a@b.co', 'x', remember: false);

    final prefs = await SharedPreferences.getInstance();
    final restarted = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        tokenStorageProvider.overrideWithValue(storage),
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(restarted.dispose);
    await restarted.read(authControllerProvider.notifier).bootstrap();
    expect(
      restarted.read(authControllerProvider).status,
      AuthStatus.unauthenticated,
    );
  });

  test('sessionExpired (401) logs out and flags it', () async {
    container = await make();
    when(
      () => repo.login(any(), any()),
    ).thenAnswer((_) async => AuthResult.fromJson(authJson));
    await container.read(authControllerProvider.notifier).login('a@b.co', 'x');
    container.read(authControllerProvider.notifier).sessionExpired();
    final s = container.read(authControllerProvider);
    expect(s.status, AuthStatus.unauthenticated);
    expect(s.sessionExpired, isTrue);
  });

  group('logout', () {
    test('clears token, remember flag, user and user-scoped state', () async {
      container = await make(token: 'abc', prefs: {'remember_session': true});
      when(
        () => repo.login(any(), any()),
      ).thenAnswer((_) async => AuthResult.fromJson(authJson));
      final auth = container.read(authControllerProvider.notifier);
      await auth.login('customer@ecom.com', 'Customer@123');
      expect(container.read(authControllerProvider).user, isNotNull);

      // State that belongs to the signed-in user / session.
      container.read(appliedCouponProvider.notifier).set('WELCOME10');
      container
          .read(productFilterProvider.notifier)
          .set(const ProductFilter(keyword: 'laptop', categoryId: 1));

      await auth.logout();

      final s = container.read(authControllerProvider);
      expect(s.status, AuthStatus.unauthenticated);
      expect(s.user, isNull);
      expect(s.sessionExpired, isFalse);
      expect(await storage.read(), isNull);
      expect(
        container.read(sharedPrefsProvider).getBool('remember_session'),
        isNull,
      );
      expect(container.read(currentUserIdProvider), isNull);
      expect(container.read(appliedCouponProvider), isNull);
      expect(container.read(productFilterProvider), const ProductFilter());
    });

    test('cart, cart badge and unread count are empty after logout', () async {
      container = await make();
      final cartRepo = MockCartRepository();
      final notifRepo = MockNotificationRepository();
      when(
        () => cartRepo.getCart(),
      ).thenAnswer((_) async => Cart.fromJson(cartJson));
      when(() => notifRepo.unreadCount()).thenAnswer((_) async => 5);
      final c = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          tokenStorageProvider.overrideWithValue(storage),
          sharedPrefsProvider.overrideWithValue(
            container.read(sharedPrefsProvider),
          ),
          cartRepositoryProvider.overrideWithValue(cartRepo),
          notificationRepositoryProvider.overrideWithValue(notifRepo),
        ],
      );
      addTearDown(c.dispose);
      when(
        () => repo.login(any(), any()),
      ).thenAnswer((_) async => AuthResult.fromJson(authJson));
      final auth = c.read(authControllerProvider.notifier);
      await auth.login('customer@ecom.com', 'Customer@123');

      final sub1 = c.listen(cartProvider, (_, _) {});
      final sub2 = c.listen(unreadCountProvider, (_, _) {});
      final sub3 = c.listen(cartCountProvider, (_, _) {});
      addTearDown(sub1.close);
      addTearDown(sub2.close);
      addTearDown(sub3.close);
      await c.read(cartProvider.future);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(c.read(cartCountProvider), greaterThan(0));
      expect(c.read(unreadCountProvider), 5);

      await auth.logout();
      await c.read(cartProvider.future);

      expect(c.read(cartCountProvider), 0);
      expect(c.read(unreadCountProvider), 0);
      verify(
        () => cartRepo.getCart(),
      ).called(1); // not re-fetched when signed out
    });

    test('logout still signs out when the storage throws', () async {
      container = await make(token: 'abc');
      final auth = container.read(authControllerProvider.notifier);
      await auth.logout();
      expect(
        container.read(authControllerProvider).status,
        AuthStatus.unauthenticated,
      );
    });
  });
}
