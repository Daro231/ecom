import 'package:ecom_mobile/core/network/api_exception.dart';
import 'package:ecom_mobile/core/providers.dart';
import 'package:ecom_mobile/features/cart/data/models/cart_models.dart';
import 'package:ecom_mobile/features/cart/presentation/providers/cart_providers.dart';
import 'package:ecom_mobile/features/cart/presentation/screens/cart_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers/fixtures.dart';
import 'helpers/test_app.dart';

void main() {
  late MockCartRepository repo;

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      routedApp(
        overrides: [
          ...await baseOverrides(),
          cartRepositoryProvider.overrideWithValue(repo),
        ],
        initial: '/cart',
        routes: [
          GoRoute(path: '/cart', builder: (_, _) => const CartScreen()),
          GoRoute(
            path: '/checkout',
            builder: (_, _) => const Scaffold(body: Text('CHECKOUT PAGE')),
          ),
          GoRoute(
            path: '/home',
            builder: (_, _) => const Scaffold(body: Text('HOME PAGE')),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    repo = MockCartRepository();
    when(() => repo.getCart()).thenAnswer((_) async => testCart);
  });

  testWidgets('lists items with backend totals', (tester) async {
    await pump(tester);
    expect(find.text('ASUS ROG Gladius III Gaming Mouse'), findsOneWidget);
    expect(find.text(r'$138.00'), findsWidgets);
    expect(find.textContaining('Subtotal (2 items)'), findsOneWidget);
  });

  testWidgets(
    '+ updates quantity through the API and shows the returned cart',
    (tester) async {
      when(() => repo.updateItem(1, 3)).thenAnswer(
        (_) async => const Cart(
          id: 1,
          totalItems: 3,
          subtotal: 207,
          items: [
            CartItem(
              id: 1,
              productId: 29,
              productName: 'ASUS ROG Gladius III Gaming Mouse',
              unitPrice: 69,
              quantity: 3,
              lineTotal: 207,
              stockQuantity: 38,
            ),
          ],
        ),
      );
      await pump(tester);
      await tester.tap(find.byKey(const Key('inc_1')));
      await tester.pumpAndSettle();
      verify(() => repo.updateItem(1, 3)).called(1);
      expect(find.text(r'$207.00'), findsWidgets);
    },
  );

  testWidgets('swipe to delete calls removeItem and shows the empty state', (
    tester,
  ) async {
    when(() => repo.removeItem(1)).thenAnswer((_) async => const Cart(id: 1));
    await pump(tester);
    await tester.drag(find.byType(Dismissible), const Offset(-600, 0));
    await tester.pumpAndSettle();
    verify(() => repo.removeItem(1)).called(1);
    expect(find.text('Your cart is empty'), findsOneWidget);
  });

  testWidgets('valid coupon shows discount and total from the backend', (
    tester,
  ) async {
    when(
      () => repo.applyCoupon('WELCOME10', 'STANDARD'),
    ).thenAnswer((_) async => CouponPreview.fromJson(couponJson));
    await pump(tester);
    await tester.enterText(find.byKey(const Key('coupon_field')), 'welcome10');
    await tester.tap(find.byKey(const Key('apply_coupon')));
    await tester.pumpAndSettle();
    expect(find.text(r'-$13.80'), findsOneWidget);
    expect(find.text(r'$129.20'), findsOneWidget);
    expect(find.text('Coupon WELCOME10 applied'), findsWidgets);
  });

  testWidgets('rejected coupon shows the backend message', (tester) async {
    when(() => repo.applyCoupon(any(), any())).thenThrow(
      const ApiException(
        type: ApiErrorType.validation,
        message: 'Coupon has expired',
      ),
    );
    await pump(tester);
    await tester.enterText(find.byKey(const Key('coupon_field')), 'EXPIRED');
    await tester.tap(find.byKey(const Key('apply_coupon')));
    await tester.pump();
    await tester.pump();
    expect(find.text('Coupon has expired'), findsOneWidget);
    expect(find.text('Coupon EXPIRED applied'), findsNothing);
  });

  testWidgets('empty cart offers to start shopping; error state has Retry', (
    tester,
  ) async {
    when(() => repo.getCart()).thenAnswer((_) async => const Cart());
    await pump(tester);
    expect(find.text('Your cart is empty'), findsOneWidget);

    when(() => repo.getCart()).thenThrow(
      const ApiException(
        type: ApiErrorType.network,
        message: 'No internet connection or the server is unreachable.',
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CartScreen)),
    );
    await container.read(cartProvider.notifier).refresh();
    await tester.pumpAndSettle();
    expect(find.text('You seem to be offline'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('checkout button navigates', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('go_checkout')));
    await tester.pumpAndSettle();
    expect(find.text('CHECKOUT PAGE'), findsOneWidget);
  });
}
