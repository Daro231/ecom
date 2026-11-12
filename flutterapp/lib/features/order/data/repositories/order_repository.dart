import '../../../../core/network/dio_client.dart';
import '../../../../core/network/page_response.dart';
import '../models/order_models.dart';

Map<String, dynamic> _map(Object? o) => (o as Map).cast<String, dynamic>();

class CheckoutRequest {
  const CheckoutRequest({
    required this.addressId,
    required this.shippingMethod,
    required this.paymentMethod,
    this.couponCode,
    this.note,
  });

  final int addressId;
  final String shippingMethod;
  final String paymentMethod;
  final String? couponCode;
  final String? note;

  Map<String, dynamic> toJson() => {
    'addressId': addressId,
    'shippingMethod': shippingMethod,
    'paymentMethod': paymentMethod,
    if (couponCode != null && couponCode!.trim().isNotEmpty)
      'couponCode': couponCode!.trim(),
    if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
  };
}

class OrderRepository {
  OrderRepository(this._api);
  final ApiClient _api;

  Future<Order> checkout(CheckoutRequest req) async {
    final r = await _api.post('/orders/checkout', body: req.toJson());
    return Order.fromJson(_map(r.data));
  }

  Future<PageResponse<Order>> list({int page = 0, int size = 20}) async {
    final r = await _api.get('/orders', query: {'page': page, 'size': size});
    return PageResponse.fromJson(r.data, Order.fromJson);
  }

  Future<Order> get(String orderNumber) async =>
      Order.fromJson(_map((await _api.get('/orders/$orderNumber')).data));

  Future<Invoice> invoice(String orderNumber) async => Invoice.fromJson(
    _map((await _api.get('/orders/$orderNumber/invoice')).data),
  );

  Future<Shipment> tracking(String orderNumber) async => Shipment.fromJson(
    _map((await _api.get('/orders/$orderNumber/tracking')).data),
  );

  Future<Order> cancel(String orderNumber, String reason) async {
    final r = await _api.post(
      '/orders/$orderNumber/cancel',
      body: {'reason': reason.trim()},
    );
    return Order.fromJson(_map(r.data));
  }

  /// True when one of the (up to [maxPages]) newest orders is DELIVERED and
  /// contains [productId] - the only case in which a review is accepted.
  Future<bool> hasDeliveredPurchase(int productId, {int maxPages = 5}) async {
    for (var page = 0; page < maxPages; page++) {
      final res = await list(page: page, size: 50);
      for (final o in res.content) {
        if (o.isDelivered && o.items.any((i) => i.productId == productId)) {
          return true;
        }
      }
      if (res.last) break;
    }
    return false;
  }
}
