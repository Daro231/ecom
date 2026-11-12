import 'package:ecom_mobile/core/utils/formatters.dart';
import 'package:ecom_mobile/core/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('enumLabel shows proper payment and shipping names', () {
    expect(enumLabel('KHQR'), 'KHQR');
    expect(enumLabel('CASH_ON_DELIVERY'), 'Cash on Delivery');
    expect(enumLabel('CARD'), 'Card');
    expect(enumLabel('BANK_TRANSFER'), 'Bank Transfer');
    expect(enumLabel('STANDARD'), 'Standard');
    expect(enumLabel('EXPRESS'), 'Express');
    expect(enumLabel('SAME_DAY'), 'Same Day');
    expect(enumLabel('SOMETHING_NEW'), 'Something new');
  });

  testWidgets('ProductImage without an image shows category icon + brand', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 200,
          height: 200,
          child: ProductImage(url: null, category: 'Laptop', brand: 'Dell'),
        ),
      ),
    );
    expect(find.byIcon(Icons.laptop_mac_rounded), findsOneWidget);
    expect(find.text('Dell'), findsOneWidget);
  });

  testWidgets('ContentWidth limits and centers wide content', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        home: ContentWidth(child: SizedBox.expand(key: Key('c'))),
      ),
    );
    final r = tester.getRect(find.byKey(const Key('c')));
    expect(r.width, 900);
    expect(r.center.dx, 800);
  });
}
