import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/checkout/presentation/screens/checkout_screen.dart';
import '../../features/checkout/presentation/screens/khqr_payment_screen.dart';
import '../../features/checkout/presentation/screens/order_success_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/notification/presentation/screens/notifications_screen.dart';
import '../../features/order/presentation/screens/invoice_screen.dart';
import '../../features/order/presentation/screens/order_detail_screen.dart';
import '../../features/order/presentation/screens/orders_screen.dart';
import '../../features/product/presentation/screens/product_detail_screen.dart';
import '../../features/product/presentation/screens/product_list_screen.dart';
import '../../features/profile/presentation/screens/addresses_screen.dart';
import '../../features/profile/presentation/screens/change_password_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../widgets/main_shell.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Re-evaluates the router redirect when the auth status changes.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen<AuthStatus>(
      authControllerProvider.select((s) => s.status),
      (_, _) => notifyListeners(),
    );
  }
}

String? authRedirect(AuthStatus status, String location) {
  const publicRoutes = {'/login', '/register'};
  switch (status) {
    case AuthStatus.unknown:
      return location == '/splash' ? null : '/splash';
    case AuthStatus.unauthenticated:
      return publicRoutes.contains(location) ? null : '/login';
    case AuthStatus.authenticated:
      return (location == '/splash' || publicRoutes.contains(location))
          ? '/home'
          : null;
  }
}

GoRouter buildRouter(Ref ref, {String initialLocation = '/splash'}) {
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);

  GoRoute full(String path, Widget Function(GoRouterState s) builder) =>
      GoRoute(
        path: path,
        parentNavigatorKey: _rootKey,
        builder: (_, s) => builder(s),
      );

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: initialLocation,
    refreshListenable: refresh,
    redirect: (context, state) => authRedirect(
      ref.read(authControllerProvider).status,
      state.matchedLocation,
    ),
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (_, _) => const ProductListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/cart', builder: (_, _) => const CartScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/orders', builder: (_, _) => const OrdersScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      full(
        '/product/:id',
        (s) =>
            ProductDetailScreen(productId: int.parse(s.pathParameters['id']!)),
      ),
      full('/checkout', (_) => const CheckoutScreen()),
      full(
        '/pay/:orderNumber',
        (s) => KhqrPaymentScreen(orderNumber: s.pathParameters['orderNumber']!),
      ),
      full(
        '/success/:orderNumber',
        (s) => OrderSuccessScreen(
          orderNumber: s.pathParameters['orderNumber']!,
          paid: s.uri.queryParameters['paid'] == '1',
        ),
      ),
      full(
        '/order/:orderNumber',
        (s) => OrderDetailScreen(orderNumber: s.pathParameters['orderNumber']!),
      ),
      full(
        '/order/:orderNumber/invoice',
        (s) => InvoiceScreen(orderNumber: s.pathParameters['orderNumber']!),
      ),
      full('/notifications', (_) => const NotificationsScreen()),
      full('/profile/edit', (_) => const EditProfileScreen()),
      full('/profile/password', (_) => const ChangePasswordScreen()),
      full('/profile/addresses', (_) => const AddressesScreen()),
    ],
  );
}

final routerProvider = Provider<GoRouter>((ref) => buildRouter(ref));
