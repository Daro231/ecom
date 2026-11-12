import 'dart:convert';

import 'package:ecom_mobile/core/providers.dart';
import 'package:ecom_mobile/core/widgets/location_map.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:ecom_mobile/core/router/app_router.dart';
import 'package:ecom_mobile/core/storage/token_storage.dart';
import 'package:ecom_mobile/core/theme/app_theme.dart';
import 'package:ecom_mobile/features/auth/data/models/app_user.dart';
import 'package:ecom_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:ecom_mobile/features/cart/data/models/cart_models.dart';
import 'package:ecom_mobile/features/notification/data/repositories/notification_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures.dart';
import 'test_app.dart';

/// 1x1 transparent PNG: map tests never touch the network.
final _blankPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

class BlankTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(_blankPng);
}

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

/// Starts already signed in.
class SignedInAuth extends AuthController {
  @override
  AuthState build() => AuthState(
    status: AuthStatus.authenticated,
    user: AppUser.fromJson(userJson),
  );
}

/// Boots the REAL app router (shell tabs + root routes) at [location], signed
/// in, with repositories supplied through [overrides]. Returns the router so
/// tests can assert on the current location.
Future<GoRouter> pumpRealApp(
  WidgetTester tester, {
  required String location,
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = const Size(1000, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final cart = MockCartRepository();
  when(() => cart.getCart()).thenAnswer((_) async => const Cart());
  final notif = MockNotificationRepository();
  when(() => notif.unreadCount()).thenAnswer((_) async => 0);

  late GoRouter router;
  final routerProv = Provider<GoRouter>(
    (ref) => router = buildRouter(ref, initialLocation: location),
  );
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        tokenStorageProvider.overrideWithValue(MemoryTokenStorage('t')),
        cartRepositoryProvider.overrideWithValue(cart),
        notificationRepositoryProvider.overrideWithValue(notif),
        authControllerProvider.overrideWith(SignedInAuth.new),
        mapTileProviderProvider.overrideWithValue(BlankTileProvider()),
        ...overrides,
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
  return router;
}

String currentPath(GoRouter r) =>
    r.routerDelegate.currentConfiguration.uri.toString();
