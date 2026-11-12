import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/cart_models.dart';

class CartController extends AsyncNotifier<Cart> {
  @override
  Future<Cart> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const Cart();
    return ref.watch(cartRepositoryProvider).getCart();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(cartRepositoryProvider).getCart(),
    );
  }

  /// Throws [ApiException] (e.g. 409 insufficient stock) so the UI can show it.
  Future<void> add(int productId, int quantity) async {
    final cart = await ref
        .read(cartRepositoryProvider)
        .addItem(productId, quantity);
    state = AsyncData(cart);
  }

  Future<void> setQuantity(int itemId, int quantity) async {
    final cart = await ref
        .read(cartRepositoryProvider)
        .updateItem(itemId, quantity);
    state = AsyncData(cart);
  }

  Future<void> remove(int itemId) async {
    final cart = await ref.read(cartRepositoryProvider).removeItem(itemId);
    state = AsyncData(cart);
  }

  /// The backend empties the cart on checkout - reload it.
  Future<void> afterCheckout() async {
    ref.read(appliedCouponProvider.notifier).clear();
    await refresh();
  }
}

final cartProvider = AsyncNotifierProvider<CartController, Cart>(
  CartController.new,
);

final cartCountProvider = Provider<int>(
  (ref) => ref.watch(cartProvider).value?.totalItems ?? 0,
);

/// Coupon code the customer applied in the cart (validated by the backend).
class AppliedCouponNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String code) => state = code;
  void clear() => state = null;
}

final appliedCouponProvider = NotifierProvider<AppliedCouponNotifier, String?>(
  AppliedCouponNotifier.new,
);

/// Backend totals for (coupon, shipping method).
final couponPreviewProvider = FutureProvider.autoDispose
    .family<CouponPreview, ({String code, String shipping})>(
      (ref, key) =>
          ref.watch(cartRepositoryProvider).applyCoupon(key.code, key.shipping),
    );
