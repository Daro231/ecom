import '../../../../core/network/dio_client.dart';
import '../models/cart_models.dart';

Map<String, dynamic> _map(Object? o) => (o as Map).cast<String, dynamic>();

class CartRepository {
  CartRepository(this._api);
  final ApiClient _api;

  Future<Cart> getCart() async =>
      Cart.fromJson(_map((await _api.get('/cart')).data));

  Future<Cart> addItem(int productId, int quantity) async {
    final r = await _api.post(
      '/cart/items',
      body: {'productId': productId, 'quantity': quantity},
    );
    return Cart.fromJson(_map(r.data));
  }

  Future<Cart> updateItem(int itemId, int quantity) async {
    final r = await _api.put(
      '/cart/items/$itemId',
      body: {'quantity': quantity},
    );
    return Cart.fromJson(_map(r.data));
  }

  Future<Cart> removeItem(int itemId) async {
    final r = await _api.delete('/cart/items/$itemId');
    return Cart.fromJson(_map(r.data));
  }

  Future<CouponPreview> applyCoupon(String code, String shippingMethod) async {
    final r = await _api.post(
      '/cart/apply-coupon',
      body: {'code': code.trim(), 'shippingMethod': shippingMethod},
    );
    return CouponPreview.fromJson(_map(r.data));
  }
}
