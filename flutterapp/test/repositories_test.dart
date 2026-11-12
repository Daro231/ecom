import 'package:dio/dio.dart';
import 'package:ecom_mobile/core/network/api_exception.dart';
import 'package:ecom_mobile/core/network/api_interceptor.dart';
import 'package:ecom_mobile/core/network/dio_client.dart';
import 'package:ecom_mobile/core/storage/token_storage.dart';
import 'package:ecom_mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:ecom_mobile/features/cart/data/repositories/cart_repository.dart';
import 'package:ecom_mobile/features/checkout/data/repositories/payment_repository.dart';
import 'package:ecom_mobile/features/notification/data/repositories/notification_repository.dart';
import 'package:ecom_mobile/features/order/data/repositories/order_repository.dart';
import 'package:ecom_mobile/features/product/data/models/product_filter.dart';
import 'package:ecom_mobile/features/product/data/repositories/catalog_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers/fixtures.dart';

class MockDio extends Mock implements Dio {}

Response<dynamic> ok(Object? body, [int status = 200]) => Response<dynamic>(
  requestOptions: RequestOptions(path: ''),
  data: body,
  statusCode: status,
);

DioException dioFail(int status, Map<String, dynamic> body) {
  final req = RequestOptions(path: '/x');
  return DioException(
    requestOptions: req,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: req, statusCode: status, data: body),
  );
}

void main() {
  late MockDio dio;
  late ApiClient api;

  setUp(() {
    dio = MockDio();
    api = ApiClient(dio);
  });

  void stubGet(Object body) => when(
    () =>
        dio.get<dynamic>(any(), queryParameters: any(named: 'queryParameters')),
  ).thenAnswer((_) async => ok(body));
  void stubPost(Object body) => when(
    () => dio.post<dynamic>(any(), data: any(named: 'data')),
  ).thenAnswer((_) async => ok(body));

  group('AuthRepository', () {
    test('login posts credentials and parses the token', () async {
      stubPost(envelope(authJson, message: 'Login successful'));
      final r = await AuthRepository(
        api,
      ).login(' customer@ecom.com ', 'Customer@123');
      expect(r.accessToken, isNotEmpty);
      expect(r.user.fullName, 'Demo Customer');
      final body =
          verify(
                () => dio.post<dynamic>(
                  '/auth/login',
                  data: captureAny(named: 'data'),
                ),
              ).captured.single
              as Map;
      expect(body, {'email': 'customer@ecom.com', 'password': 'Customer@123'});
    });

    test('401 becomes a typed ApiException with the backend message', () async {
      when(() => dio.post<dynamic>(any(), data: any(named: 'data'))).thenThrow(
        dioFail(401, {
          'success': false,
          'message': 'Invalid email or password',
        }),
      );
      await expectLater(
        AuthRepository(api).login('a@b.co', 'x'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.type, 'type', ApiErrorType.unauthorized)
              .having((e) => e.message, 'message', 'Invalid email or password'),
        ),
      );
    });

    test('validation errors expose field errors', () async {
      when(() => dio.post<dynamic>(any(), data: any(named: 'data'))).thenThrow(
        dioFail(400, {
          'success': false,
          'message': 'Validation failed',
          'errors': {'email': 'Email is invalid'},
        }),
      );
      try {
        await AuthRepository(
          api,
        ).register(fullName: 'A', email: 'bad', password: 'x');
        fail('should throw');
      } on ApiException catch (e) {
        expect(e.type, ApiErrorType.validation);
        expect(e.fieldErrors['email'], 'Email is invalid');
      }
    });
  });

  group('CatalogRepository', () {
    test('products sends filter parameters', () async {
      stubGet(envelope(pageOf([productJson])));
      final page = await CatalogRepository(api).products(
        const ProductFilter(keyword: 'laptop', ram: 16, sort: 'price_asc'),
        page: 1,
        size: 12,
      );
      expect(page.content.single.name, contains('Dell'));
      final q =
          verify(
                () => dio.get<dynamic>(
                  '/products',
                  queryParameters: captureAny(named: 'queryParameters'),
                ),
              ).captured.single
              as Map;
      expect(q['keyword'], 'laptop');
      expect(q['ram'], 16);
      expect(q['sort'], 'price_asc');
      expect(q['page'], 1);
    });

    test('createReview posts rating and comment', () async {
      stubPost(
        envelope({'id': 1, 'rating': 5, 'comment': 'Great', 'productId': 29}),
      );
      final r = await CatalogRepository(
        api,
      ).createReview(29, rating: 5, comment: ' Great ');
      expect(r.rating, 5);
      verify(
        () => dio.post<dynamic>(
          '/products/29/reviews',
          data: {'rating': 5, 'comment': 'Great'},
        ),
      ).called(1);
    });
  });

  group('CartRepository', () {
    test('addItem / applyCoupon', () async {
      stubPost(envelope(cartJson));
      final c = await CartRepository(api).addItem(29, 2);
      expect(c.totalItems, 2);
      verify(
        () => dio.post<dynamic>(
          '/cart/items',
          data: {'productId': 29, 'quantity': 2},
        ),
      ).called(1);

      stubPost(envelope(couponJson));
      final p = await CartRepository(api).applyCoupon('WELCOME10', 'STANDARD');
      expect(p.total, 129.2);
      verify(
        () => dio.post<dynamic>(
          '/cart/apply-coupon',
          data: {'code': 'WELCOME10', 'shippingMethod': 'STANDARD'},
        ),
      ).called(1);
    });

    test('409 insufficient stock is a conflict', () async {
      when(() => dio.post<dynamic>(any(), data: any(named: 'data'))).thenThrow(
        dioFail(409, {'success': false, 'message': 'Insufficient stock'}),
      );
      expect(
        CartRepository(api).addItem(1, 99),
        throwsA(
          isA<ApiException>().having(
            (e) => e.type,
            'type',
            ApiErrorType.conflict,
          ),
        ),
      );
    });
  });

  group('OrderRepository', () {
    test('checkout sends the contract fields only', () async {
      stubPost(envelope(orderJson));
      final o = await OrderRepository(api).checkout(
        const CheckoutRequest(
          addressId: 1,
          shippingMethod: 'EXPRESS',
          paymentMethod: 'KHQR',
          couponCode: 'WELCOME10',
          note: 'Call me',
        ),
      );
      expect(o.orderNumber, 'ECOM-20261104-0001');
      verify(
        () => dio.post<dynamic>(
          '/orders/checkout',
          data: {
            'addressId': 1,
            'shippingMethod': 'EXPRESS',
            'paymentMethod': 'KHQR',
            'couponCode': 'WELCOME10',
            'note': 'Call me',
          },
        ),
      ).called(1);
    });

    test('cancel sends the reason', () async {
      stubPost(
        envelope({
          ...orderJson,
          'status': 'CANCELLED',
          'cancelledReason': 'Ordered by mistake',
        }),
      );
      final o = await OrderRepository(
        api,
      ).cancel('ECOM-1', 'Ordered by mistake');
      expect(o.isCancelled, isTrue);
      expect(o.cancelledReason, 'Ordered by mistake');
      verify(
        () => dio.post<dynamic>(
          '/orders/ECOM-1/cancel',
          data: {'reason': 'Ordered by mistake'},
        ),
      ).called(1);
    });

    test('hasDeliveredPurchase looks through delivered orders', () async {
      stubGet(
        envelope(
          pageOf([
            {...orderJson, 'status': 'DELIVERED'},
          ]),
        ),
      );
      expect(await OrderRepository(api).hasDeliveredPurchase(29), isTrue);
      expect(await OrderRepository(api).hasDeliveredPurchase(999), isFalse);
    });
  });

  group('PaymentRepository', () {
    test('generateKhqr measures expiry against the server clock', () async {
      // Server says "now" is 15:43:18 and the QR expires at 15:53:18 -> 10 min,
      // regardless of the phone's own clock.
      stubPost(
        envelope({
          ...khqrJson,
          'expiresAt': '2026-11-04T15:53:18.039323947',
        }, ts: '2026-11-04T15:43:18.04107867'),
      );
      final s = await PaymentRepository(api).generateKhqr('ECOM-20261104-0001');
      expect(s.data.mode, 'MOCK');
      expect(s.remaining().inSeconds, inInclusiveRange(598, 600));
    });

    test('status maps 504 to a provider problem (not a failure)', () async {
      when(
        () => dio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(
        dioFail(504, {'success': false, 'message': 'Bakong timed out'}),
      );
      await expectLater(
        PaymentRepository(api).status('X'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.isProviderProblem,
            'provider',
            isTrue,
          ),
        ),
      );
      when(
        () => dio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(dioFail(502, {'success': false, 'message': 'Token'}));
      await expectLater(
        PaymentRepository(api).status('X'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.type,
            't',
            ApiErrorType.badGateway,
          ),
        ),
      );
    });

    test('simulatePayment posts the callback body', () async {
      stubPost(
        envelope({
          'id': 1,
          'orderNumber': 'X',
          'method': 'KHQR',
          'status': 'PAID',
          'amount': 77.1,
        }),
      );
      final p = await PaymentRepository(api).simulatePayment('X');
      expect(p.isPaid, isTrue);
      final body =
          verify(
                () => dio.post<dynamic>(
                  '/payments/callback',
                  data: captureAny(named: 'data'),
                ),
              ).captured.single
              as Map;
      expect(body['orderNumber'], 'X');
      expect(body['status'], 'PAID');
      expect(body['transactionRef'], startsWith('MOCK-'));
    });
  });

  test('NotificationRepository unread count reads a bare number', () async {
    stubGet(envelope(6));
    expect(await NotificationRepository(api).unreadCount(), 6);
  });

  group('ApiInterceptor', () {
    test('timeouts and connection errors are friendly', () {
      final req = RequestOptions(path: '/x');
      expect(
        ApiInterceptor.toApiException(
          DioException(
            requestOptions: req,
            type: DioExceptionType.receiveTimeout,
          ),
        ).type,
        ApiErrorType.timeout,
      );
      expect(
        ApiInterceptor.toApiException(
          DioException(
            requestOptions: req,
            type: DioExceptionType.connectionError,
          ),
        ).isConnectivity,
        isTrue,
      );
    });

    test('adds bearer token and clears it on 401 (not for /auth/*)', () async {
      final storage = MemoryTokenStorage('tok');
      var expired = 0;
      final i = ApiInterceptor(
        tokenStorage: storage,
        onUnauthorized: () => expired++,
      );

      final handler = _CapturingReqHandler();
      final opts = RequestOptions(path: '/cart');
      await i.onRequest(opts, handler);
      expect(opts.headers['Authorization'], 'Bearer tok');

      final h2 = _CapturingErrHandler();
      await i.onError(
        dioFail(401, {
          'message': 'expired',
        }).copyWith(requestOptions: RequestOptions(path: '/cart')),
        h2,
      );
      expect(expired, 1);
      expect(await storage.read(), isNull);

      await storage.write('tok2');
      final h3 = _CapturingErrHandler();
      await i.onError(
        dioFail(401, {
          'message': 'Bad credentials',
        }).copyWith(requestOptions: RequestOptions(path: '/auth/login')),
        h3,
      );
      expect(expired, 1);
      expect(await storage.read(), 'tok2');
    });
  });
}

class _CapturingReqHandler extends RequestInterceptorHandler {}

class _CapturingErrHandler extends ErrorInterceptorHandler {
  _CapturingErrHandler() {
    future.ignore();
  }
}
