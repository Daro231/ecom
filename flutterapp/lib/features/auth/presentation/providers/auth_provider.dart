import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../../product/presentation/providers/product_providers.dart';
import '../../data/models/app_user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.sessionExpired = false,
  });

  final AuthStatus status;
  final AppUser? user;

  /// True when the user was signed out because the token was rejected (401).
  final bool sessionExpired;

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  /// Splash: restore the session from the stored token.
  Future<void> bootstrap() async {
    final token = await ref.read(tokenStorageProvider).read();
    final remember =
        ref.read(sharedPrefsProvider).getBool(_rememberKey) ?? true;
    if (!remember) await ref.read(tokenStorageProvider).clear();
    if (!remember || token == null || token.isEmpty) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      final user = await ref.read(authRepositoryProvider).me();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on ApiException catch (e) {
      // Only a rejected token ends the session; an offline start keeps it
      // so the user is not logged out just because the server is unreachable.
      if (e.type == ApiErrorType.unauthorized) {
        await ref.read(tokenStorageProvider).clear();
        state = const AuthState(status: AuthStatus.unauthenticated);
      } else {
        rethrow;
      }
    }
  }

  static const _rememberKey = 'remember_session';

  Future<void> login(
    String email,
    String password, {
    bool remember = true,
  }) async {
    final result = await ref
        .read(authRepositoryProvider)
        .login(email, password);
    await _accept(result, remember: remember);
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final result = await ref
        .read(authRepositoryProvider)
        .register(
          fullName: fullName,
          email: email,
          password: password,
          phone: phone,
        );
    await _accept(result);
  }

  Future<void> _accept(AuthResult result, {bool remember = true}) async {
    if (result.user.role != 'CUSTOMER') {
      // The admin panel is web-only; this app is for customers.
      throw const ApiException(
        type: ApiErrorType.forbidden,
        message:
            'This app is for customers. Staff and admins please use the web admin panel.',
      );
    }
    await ref.read(tokenStorageProvider).write(result.accessToken);
    await ref.read(sharedPrefsProvider).setBool(_rememberKey, remember);
    state = AuthState(status: AuthStatus.authenticated, user: result.user);
  }

  /// Signs out: removes the token from the storage used on this platform
  /// (localStorage on web, keystore on mobile) and the "keep me signed in"
  /// flag, drops the cached user, then resets every user-scoped provider so
  /// the next account never sees the previous account's data.
  Future<void> logout() async {
    try {
      await ref.read(tokenStorageProvider).clear();
    } catch (_) {
      // Storage errors must never block signing out.
    }
    try {
      await ref.read(sharedPrefsProvider).remove(_rememberKey);
    } catch (_) {}
    state = const AuthState(status: AuthStatus.unauthenticated);
    _resetUserScopedState();
  }

  /// Called by the Dio interceptor on a 401.
  void sessionExpired() {
    if (state.status == AuthStatus.unauthenticated) return;
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      sessionExpired: true,
    );
    _resetUserScopedState();
  }

  /// Cart (and its badge), orders, notifications (and unread count) and
  /// addresses watch [currentUserIdProvider], so they reset by themselves as
  /// soon as the user becomes null (Riverpod forbids invalidating them from
  /// here because they depend on this controller). The ones that do not depend
  /// on the user are reset explicitly: applied coupon and search filter.
  void _resetUserScopedState() {
    ref.invalidate(appliedCouponProvider);
    ref.invalidate(productFilterProvider);
  }

  void setUser(AppUser user) {
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// Id of the signed-in user; user-scoped providers watch this so they reset
/// on logout / account switch.
final currentUserIdProvider = Provider<int?>(
  (ref) => ref.watch(authControllerProvider.select((s) => s.user?.id)),
);
