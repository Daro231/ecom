import 'package:clock/clock.dart';

import '../../../../core/network/dio_client.dart';
import '../../../order/data/models/order_models.dart';
import '../models/khqr_models.dart';

Map<String, dynamic> _map(Object? o) => (o as Map).cast<String, dynamic>();

class PaymentRepository {
  PaymentRepository(this._api);
  final ApiClient _api;

  /// Generates (or returns the still-valid) KHQR for an order. Expiry is
  /// measured against the *server* clock so device time zone/clock drift
  /// cannot make a fresh QR look expired.
  Future<KhqrSession> generateKhqr(String orderNumber) async {
    final r = await _api.post('/payments/$orderNumber/khqr');
    final data = KhqrData.fromJson(_map(r.data));
    final serverNow = r.timestamp ?? clock.now();
    final remaining = data.expiresAt.difference(serverNow);
    return KhqrSession(data: data, expiresAtLocal: clock.now().add(remaining));
  }

  Future<Payment> status(String orderNumber) async {
    final r = await _api.get('/payments/$orderNumber/status');
    return Payment.fromJson(_map(r.data));
  }

  /// MOCK mode only: simulates the gateway calling back with PAID.
  Future<Payment> simulatePayment(String orderNumber) async {
    final r = await _api.post(
      '/payments/callback',
      body: {
        'transactionRef': 'MOCK-${DateTime.now().millisecondsSinceEpoch}',
        'orderNumber': orderNumber,
        'status': 'PAID',
      },
    );
    return Payment.fromJson(_map(r.data));
  }
}
