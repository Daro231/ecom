import 'package:ecom_mobile/core/providers.dart';
import 'package:ecom_mobile/features/cart/data/models/cart_models.dart';
import 'package:ecom_mobile/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:ecom_mobile/features/order/data/models/order_models.dart';
import 'package:ecom_mobile/features/order/data/repositories/order_repository.dart';
import 'package:ecom_mobile/features/product/data/models/catalog_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers/fixtures.dart';
import 'helpers/test_app.dart';

class FakeCheckoutRequest extends Fake implements CheckoutRequest {}

void main() {
  late MockCartRepository cart;
  late MockOrderRepository orders;
  late MockProfileRepository profile;
  late MockCatalogRepository catalog;

  setUpAll(() => registerFallbackValue(FakeCheckoutRequest()));

  setUp(() {
    cart = MockCartRepository();
    orders = MockOrderRepository();
    profile = MockProfileRepository();
    catalog = MockCatalogRepository();
    when(() => cart.getCart()).thenAnswer((_) async => testCart);
    when(() => profile.addresses()).thenAnswer((_) async => [testAddress]);
    when(() => catalog.shippingMethods()).thenAnswer(
      (_) async => const [
        ShippingMethodInfo(
          code: 'STANDARD',
          label: 'Standard',
          fee: 5,
          estimatedDelivery: '3-5 days',
          freeShippingThreshold: 1000,
        ),
        ShippingMethodInfo(
          code: 'EXPRESS',
          label: 'Express',
          fee: 15,
          estimatedDelivery: '1-2 days',
          freeShippingThreshold: 1000,
        ),
      ],
    );
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      routedApp(
        overrides: [
          ...await baseOverrides(),
          cartRepositoryProvider.overrideWithValue(cart),
          orderRepositoryProvider.overrideWithValue(orders),
          profileRepositoryProvider.overrideWithValue(profile),
          catalogRepositoryProvider.overrideWithValue(catalog),
        ],
        initial: '/checkout',
        routes: [
          GoRoute(path: '/checkout', builder: (_, _) => const CheckoutScreen()),
          GoRoute(
            path: '/success/:o',
            builder: (_, s) =>
                Scaffold(body: Text('SUCCESS ${s.pathParameters['o']}')),
          ),
          GoRoute(
            path: '/pay/:o',
            builder: (_, s) =>
                Scaffold(body: Text('PAY ${s.pathParameters['o']}')),
          ),
          GoRoute(
            path: '/home',
            builder: (_, _) => const Scaffold(body: Text('HOME')),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder next() => find.byKey(const Key('step_next'));

  testWidgets(
    'walks address -> shipping -> payment -> review and places a COD order',
    (tester) async {
      when(() => orders.checkout(any())).thenAnswer(
        (_) async => Order.fromJson({
          ...orderJson,
          'orderNumber': 'ECOM-COD-1',
          'paymentMethod': 'CASH_ON_DELIVERY',
        }),
      );
      await pump(tester);

      // Step 1: default address preselected.
      expect(find.text('Demo Customer  (default)'), findsOneWidget);
      await tester.tap(next());
      await tester.pumpAndSettle();

      // Step 2: shipping.
      expect(find.byKey(const Key('ship_STANDARD')), findsOneWidget);
      await tester.tap(find.byKey(const Key('ship_EXPRESS')));
      await tester.pumpAndSettle();
      await tester.tap(next());
      await tester.pumpAndSettle();

      // Step 3: payment methods.
      for (final code in [
        'KHQR',
        'CASH_ON_DELIVERY',
        'CARD',
        'BANK_TRANSFER',
      ]) {
        expect(find.byKey(Key('pay_$code')), findsOneWidget);
      }
      await tester.tap(find.byKey(const Key('pay_CASH_ON_DELIVERY')));
      await tester.pumpAndSettle();
      await tester.tap(next());
      await tester.pumpAndSettle();

      // Step 4: review totals = 138 + 15 express.
      expect(find.text(r'$153.00'), findsOneWidget);
      await tester.tap(find.byKey(const Key('place_order')));
      await tester.pumpAndSettle();

      final req =
          verify(() => orders.checkout(captureAny())).captured.single
              as CheckoutRequest;
      expect(req.addressId, 1);
      expect(req.shippingMethod, 'EXPRESS');
      expect(req.paymentMethod, 'CASH_ON_DELIVERY');
      expect(find.text('SUCCESS ECOM-COD-1'), findsOneWidget);
    },
  );

  testWidgets('KHQR order goes to the payment screen', (tester) async {
    when(
      () => orders.checkout(any()),
    ).thenAnswer((_) async => Order.fromJson(orderJson));
    await pump(tester);
    for (var i = 0; i < 3; i++) {
      await tester.tap(next());
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const Key('place_order')));
    await tester.pumpAndSettle();
    final req =
        verify(() => orders.checkout(captureAny())).captured.single
            as CheckoutRequest;
    expect(req.paymentMethod, 'KHQR');
    expect(find.text('PAY ECOM-20261104-0001'), findsOneWidget);
  });

  testWidgets('free shipping at 1000 USD subtotal', (tester) async {
    when(() => cart.getCart()).thenAnswer(
      (_) async => const Cart(
        id: 1,
        totalItems: 1,
        subtotal: 1200,
        items: [
          CartItem(
            id: 1,
            productId: 2,
            productName: 'Laptop',
            unitPrice: 1200,
            quantity: 1,
            lineTotal: 1200,
            stockQuantity: 5,
          ),
        ],
      ),
    );
    await pump(tester);
    await tester.tap(next());
    await tester.pumpAndSettle();
    expect(find.text('FREE'), findsAtLeastNWidgets(2));
  });

  testWidgets(
    'checkout failure (409) shows the message and stays on the stepper',
    (tester) async {
      when(() => orders.checkout(any())).thenThrow(Exception('boom'));
      await pump(tester);
      for (var i = 0; i < 3; i++) {
        await tester.tap(next());
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const Key('place_order')));
      await tester.pumpAndSettle();
      expect(
        find.text('Something went wrong. Please try again.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('place_order')), findsOneWidget);
    },
  );

  testWidgets('Continue is disabled without an address', (tester) async {
    when(() => profile.addresses()).thenAnswer((_) async => []);
    await pump(tester);
    expect(find.text('You have no saved address yet.'), findsOneWidget);
    expect(tester.widget<FilledButton>(next()).onPressed, isNull);
  });
}
