import 'package:ecom_mobile/core/network/api_exception.dart';
import 'package:ecom_mobile/core/providers.dart';
import 'package:ecom_mobile/features/checkout/presentation/screens/khqr_payment_screen.dart';
import 'package:ecom_mobile/features/order/data/models/order_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers/fixtures.dart';
import 'helpers/test_app.dart';

const order = 'ECOM-20261104-0001';

Payment payment(String status, {String? reason}) => Payment(
  id: 1,
  orderNumber: order,
  method: 'KHQR',
  status: status,
  amount: 77.1,
  failureReason: reason,
);

void main() {
  late MockPaymentRepository pay;

  setUp(() {
    pay = MockPaymentRepository();
    when(() => pay.generateKhqr(any())).thenAnswer((_) async => testSession());
    when(() => pay.status(any())).thenAnswer((_) async => payment('PENDING'));
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      routedApp(
        overrides: [
          ...await baseOverrides(),
          paymentRepositoryProvider.overrideWithValue(pay),
          orderRepositoryProvider.overrideWithValue(MockOrderRepository()),
          khqrPollIntervalProvider.overrideWithValue(
            const Duration(milliseconds: 500),
          ),
        ],
        initial: '/pay/$order',
        routes: [
          GoRoute(
            path: '/pay/:o',
            builder: (_, s) =>
                KhqrPaymentScreen(orderNumber: s.pathParameters['o']!),
          ),
          GoRoute(
            path: '/success/:o',
            builder: (_, s) => Scaffold(
              body: Text(
                'SUCCESS ${s.pathParameters['o']} paid=${s.uri.queryParameters['paid']}',
              ),
            ),
          ),
          GoRoute(
            path: '/order/:o',
            builder: (_, s) =>
                Scaffold(body: Text('ORDER ${s.pathParameters['o']}')),
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  /// Leaves the screen so its timers are cancelled before the test ends.
  Future<void> leave(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
  }

  testWidgets(
    'shows the QR card with amount, countdown and the simulate button in MOCK mode',
    (tester) async {
      await pump(tester);
      expect(find.byKey(const Key('khqr_qr')), findsOneWidget);
      expect(find.byKey(const Key('khqr_amount')), findsOneWidget);
      expect(find.text(r'$77.10'), findsOneWidget);
      expect(find.byKey(const Key('khqr_countdown')), findsOneWidget);
      expect(find.byKey(const Key('khqr_simulate')), findsOneWidget);
      expect(find.byKey(const Key('khqr_save')), findsOneWidget);
      expect(find.byKey(const Key('khqr_share')), findsOneWidget);
      await leave(tester);
    },
  );

  testWidgets('Simulate button is hidden in BAKONG mode', (tester) async {
    when(
      () => pay.generateKhqr(any()),
    ).thenAnswer((_) async => testSession(mode: 'BAKONG'));
    await pump(tester);
    expect(find.byKey(const Key('khqr_qr')), findsOneWidget);
    expect(find.byKey(const Key('khqr_simulate')), findsNothing);
    await leave(tester);
  });

  testWidgets('simulate payment -> status PAID -> success page', (
    tester,
  ) async {
    when(
      () => pay.simulatePayment(any()),
    ).thenAnswer((_) async => payment('PAID'));
    await pump(tester);
    when(() => pay.status(any())).thenAnswer((_) async => payment('PAID'));
    await tester.ensureVisible(find.byKey(const Key('khqr_simulate')));
    await tester.tap(find.byKey(const Key('khqr_simulate')));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();
    verify(() => pay.simulatePayment(order)).called(1);
    expect(find.text('SUCCESS $order paid=1'), findsOneWidget);
  });

  testWidgets('polling detects PAID and navigates to Success', (tester) async {
    await pump(tester);
    when(() => pay.status(any())).thenAnswer((_) async => payment('PAID'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('SUCCESS $order paid=1'), findsOneWidget);
  });

  testWidgets('expired QR -> "Generate new QR" fetches a new one', (
    tester,
  ) async {
    var calls = 0;
    when(() => pay.generateKhqr(any())).thenAnswer(
      (_) async => calls++ == 0
          ? testSession(validFor: const Duration(seconds: 2))
          : testSession(),
    );
    await pump(tester);
    expect(find.byKey(const Key('khqr_expired')), findsNothing);

    await tester.pump(const Duration(seconds: 3));
    expect(find.byKey(const Key('khqr_expired')), findsOneWidget);
    expect(find.text('Generate new QR'), findsOneWidget);

    await tester.tap(find.byKey(const Key('khqr_regenerate')));
    await tester.pump();
    await tester.pump();
    verify(() => pay.generateKhqr(order)).called(2);
    expect(find.byKey(const Key('khqr_expired')), findsNothing);
    expect(find.byKey(const Key('khqr_countdown')), findsOneWidget);
    await leave(tester);
  });

  testWidgets('FAILED with "QR expired" also offers a new QR', (tester) async {
    await pump(tester);
    when(
      () => pay.status(any()),
    ).thenAnswer((_) async => payment('FAILED', reason: 'QR expired'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('khqr_expired')), findsOneWidget);
    await leave(tester);
  });

  testWidgets('FAILED shows the failure reason', (tester) async {
    await pump(tester);
    when(() => pay.status(any())).thenAnswer(
      (_) async =>
          payment('FAILED', reason: 'Amount mismatch: expected 77.10 USD'),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.byKey(const Key('khqr_failure')), findsOneWidget);
    expect(find.text('Amount mismatch: expected 77.10 USD'), findsOneWidget);
    await leave(tester);
  });

  testWidgets(
    '504 keeps polling, shows a small warning, then recovers to PAID',
    (tester) async {
      await pump(tester);
      var n = 0;
      when(() => pay.status(any())).thenAnswer((_) async {
        n++;
        if (n <= 2)
          throw const ApiException(
            type: ApiErrorType.gatewayTimeout,
            statusCode: 504,
            message: 'Bakong timed out',
          );
        return payment('PAID');
      });

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      expect(find.byKey(const Key('khqr_warning')), findsOneWidget);
      expect(find.byKey(const Key('khqr_failure')), findsNothing);
      expect(find.byKey(const Key('khqr_expired')), findsNothing);

      await tester.pump(
        const Duration(milliseconds: 500),
      ); // 2nd 504, still polling
      await tester.pump();
      expect(find.byKey(const Key('khqr_warning')), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500)); // PAID
      await tester.pumpAndSettle();
      expect(n, 3);
      expect(find.text('SUCCESS $order paid=1'), findsOneWidget);
    },
  );

  testWidgets('502 is treated like 504', (tester) async {
    await pump(tester);
    when(() => pay.status(any())).thenAnswer(
      (_) async => throw const ApiException(
        type: ApiErrorType.badGateway,
        statusCode: 502,
        message: 'token',
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.byKey(const Key('khqr_warning')), findsOneWidget);
    expect(
      find.text('Payment provider unavailable. Still checking…'),
      findsOneWidget,
    );
    await leave(tester);
  });

  testWidgets('paid after cancel explains what happens next', (tester) async {
    await pump(tester);
    when(
      () => pay.status(any()),
    ).thenAnswer((_) async => payment('PAID_AFTER_CANCEL'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(
      find.textContaining(
        'received your payment after the order was cancelled',
      ),
      findsOneWidget,
    );
    await leave(tester);
  });

  testWidgets('cancelled order (400) cannot show a QR', (tester) async {
    when(() => pay.generateKhqr(any())).thenThrow(
      const ApiException(
        type: ApiErrorType.validation,
        statusCode: 400,
        message: 'Order is cancelled',
      ),
    );
    when(() => pay.status(any())).thenAnswer((_) async => payment('FAILED'));
    await pump(tester);
    await tester.pump();
    expect(find.text('Order is cancelled'), findsOneWidget);
    expect(find.byKey(const Key('khqr_qr')), findsNothing);
    expect(find.text('View order'), findsOneWidget);
  });
}
