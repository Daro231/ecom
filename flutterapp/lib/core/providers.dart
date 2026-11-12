import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/data/repositories/auth_repository.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/cart/data/repositories/cart_repository.dart';
import '../features/checkout/data/repositories/payment_repository.dart';
import '../features/notification/data/repositories/notification_repository.dart';
import '../features/order/data/repositories/order_repository.dart';
import '../features/product/data/repositories/catalog_repository.dart';
import '../features/profile/data/repositories/profile_repository.dart';
import 'network/dio_client.dart';
import 'storage/token_storage.dart';

/// Overridden in `main()` with the real instance.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider must be overridden'),
);

/// Keystore/keychain on mobile; SharedPreferences (localStorage) on web where
/// the secure-storage plugin needs HTTPS + WebCrypto.
final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => kIsWeb
      ? PrefsTokenStorage(ref.watch(sharedPrefsProvider))
      : SecureTokenStorage(),
);

final dioProvider = Provider<Dio>((ref) {
  return createDio(
    tokenStorage: ref.watch(tokenStorageProvider),
    onUnauthorized: () =>
        ref.read(authControllerProvider.notifier).sessionExpired(),
  );
});

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(dioProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(apiClientProvider)),
);
final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(ref.watch(apiClientProvider)),
);
final cartRepositoryProvider = Provider<CartRepository>(
  (ref) => CartRepository(ref.watch(apiClientProvider)),
);
final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => OrderRepository(ref.watch(apiClientProvider)),
);
final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => PaymentRepository(ref.watch(apiClientProvider)),
);
final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(ref.watch(apiClientProvider)),
);
