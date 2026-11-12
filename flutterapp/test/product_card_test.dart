import 'package:ecom_mobile/features/product/presentation/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fixtures.dart';
import 'helpers/test_app.dart';

void main() {
  Widget host(Widget child) =>
      plainApp(Scaffold(body: SizedBox(width: 200, height: 320, child: child)));

  testWidgets('shows name, brand, price, rating and handles tap', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        ProductCard(
          product: testProduct(name: 'Dell XPS 13', price: 1299),
          onTap: () => taps++,
        ),
      ),
    );
    expect(find.text('Dell XPS 13'), findsOneWidget);
    // Brand appears in the card text and in the image fallback (no network in tests).
    expect(find.text('Dell'), findsWidgets);
    expect(find.text(r'$1,299.00'), findsOneWidget);
    expect(find.text('(3)'), findsOneWidget);
    expect(find.text('SOLD OUT'), findsNothing);
    await tester.tap(find.byType(ProductCard));
    expect(taps, 1);
  });

  testWidgets('out of stock is marked', (tester) async {
    await tester.pumpWidget(
      host(ProductCard(product: testProduct(stock: 0), onTap: () {})),
    );
    expect(find.text('SOLD OUT'), findsOneWidget);
    expect(find.text('Out of stock'), findsOneWidget);
  });

  testWidgets('low stock warning', (tester) async {
    await tester.pumpWidget(
      host(ProductCard(product: testProduct(stock: 2, low: 5), onTap: () {})),
    );
    expect(find.text('Only 2 left'), findsOneWidget);
  });

  testWidgets('list layout renders too', (tester) async {
    await tester.pumpWidget(
      plainApp(
        Scaffold(
          body: ProductCard(
            horizontal: true,
            product: testProduct(),
            onTap: () {},
          ),
        ),
      ),
    );
    expect(find.text('Test Laptop'), findsOneWidget);
  });
}
