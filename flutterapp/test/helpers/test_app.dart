import 'package:ecom_mobile/core/providers.dart';
import 'package:ecom_mobile/core/storage/token_storage.dart';
import 'package:ecom_mobile/core/theme/app_theme.dart';
import 'package:ecom_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:ecom_mobile/features/cart/data/repositories/cart_repository.dart';
import 'package:ecom_mobile/features/checkout/data/repositories/payment_repository.dart';
import 'package:ecom_mobile/features/order/data/repositories/order_repository.dart';
import 'package:ecom_mobile/features/product/data/repositories/catalog_repository.dart';
import 'package:ecom_mobile/features/profile/data/repositories/profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockCartRepository extends Mock implements CartRepository {}

class MockOrderRepository extends Mock implements OrderRepository {}

class MockPaymentRepository extends Mock implements PaymentRepository {}

class MockCatalogRepository extends Mock implements CatalogRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

Future<List<Override>> baseOverrides() async {
  SharedPreferences.setMockInitialValues({});
  return [
    sharedPrefsProvider.overrideWithValue(
      await SharedPreferences.getInstance(),
    ),
    tokenStorageProvider.overrideWithValue(MemoryTokenStorage('t')),
    currentUserIdProvider.overrideWithValue(3),
  ];
}

/// Pumps [routes] (first one is the start page) inside a ProviderScope.
Widget routedApp({
  required List<Override> overrides,
  required String initial,
  required List<GoRoute> routes,
}) {
  final router = GoRouter(initialLocation: initial, routes: routes);
  return ProviderScope(
    retry: (_, _) => null,
    overrides: overrides,
    child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
  );
}

Widget plainApp(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      retry: (_, _) => null,
      overrides: overrides,
      child: MaterialApp(theme: AppTheme.light(), home: child),
    );
