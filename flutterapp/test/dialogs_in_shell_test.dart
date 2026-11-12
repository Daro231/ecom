// Every dialog / bottom sheet / menu, opened inside the REAL router (shell
// tabs + root routes): confirm, cancel and submit must close the overlay and
// deliver their result, and must not pop the page underneath.
import 'package:ecom_mobile/core/network/page_response.dart';
import 'package:ecom_mobile/core/providers.dart';
import 'package:ecom_mobile/features/order/data/models/order_models.dart';
import 'package:ecom_mobile/features/product/data/models/catalog_models.dart';
import 'package:ecom_mobile/features/product/data/models/product_filter.dart';
import 'package:ecom_mobile/features/product/presentation/providers/product_providers.dart';
import 'package:ecom_mobile/features/profile/data/models/address.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers/fixtures.dart';
import 'helpers/real_router.dart';
import 'helpers/test_app.dart';

const _addrJson = {
  'id': 1,
  'receiverName': 'Demo Customer',
  'phone': '012345678',
  'line1': 'No. 12, Street 271',
  'city': 'Phnom Penh',
  'isDefault': true,
};

void main() {
  setUpAll(() {
    registerFallbackValue(const ProductFilter());
  });

  // ---------- Filter bottom sheet + sort menu (Search tab = shell branch) ----
  group('Search tab (shell): filter sheet and sort menu', () {
    late MockCatalogRepository catalog;

    setUp(() {
      catalog = MockCatalogRepository();
      when(
        () => catalog.products(
          any(),
          page: any(named: 'page'),
          size: any(named: 'size'),
        ),
      ).thenAnswer(
        (_) async =>
            PageResponse.fromJson(pageOf([productJson]), Product.fromJson),
      );
      when(() => catalog.categories()).thenAnswer(
        (_) async => [const Category(id: 1, name: 'Laptop', slug: 'laptop')],
      );
      when(() => catalog.brands()).thenAnswer((_) async => const []);
    });

    testWidgets('Apply filters closes the sheet, applies, stays on /search', (
      tester,
    ) async {
      final router = await pumpRealApp(
        tester,
        location: '/search',
        overrides: [catalogRepositoryProvider.overrideWithValue(catalog)],
      );
      await tester.tap(find.byKey(const Key('open_filters')));
      await tester.pumpAndSettle();
      expect(find.text('Apply filters'), findsOneWidget);

      await tester.tap(find.text('Laptop').last); // pick category chip
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Apply filters'));
      await tester.tap(find.text('Apply filters'));
      await tester.pumpAndSettle();

      expect(find.text('Apply filters'), findsNothing, reason: 'sheet closed');
      expect(currentPath(router), '/search');
      final c = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold).first),
      );
      expect(c.read(productFilterProvider).categoryId, 1);
      expect(find.byKey(const Key('category_chip')), findsOneWidget);
    });

    testWidgets('sort menu item selects the sort and closes the menu', (
      tester,
    ) async {
      await pumpRealApp(
        tester,
        location: '/search',
        overrides: [catalogRepositoryProvider.overrideWithValue(catalog)],
      );
      await tester.tap(find.byTooltip('Sort'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Price: low to high').last);
      await tester.pumpAndSettle();
      final c = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold).first),
      );
      expect(c.read(productFilterProvider).sort, 'price_asc');
      expect(
        find.text('Price: high to low'),
        findsNothing,
        reason: 'menu closed',
      );
    });
  });

  // ---------- Address list: delete dialog + add/edit bottom sheet -----------
  group('Addresses: delete dialog and address form sheet', () {
    late MockProfileRepository profile;

    setUp(() {
      profile = MockProfileRepository();
      when(
        () => profile.addresses(),
      ).thenAnswer((_) async => [Address.fromJson(_addrJson)]);
    });

    testWidgets('Delete > Cancel keeps the address, closes the dialog', (
      tester,
    ) async {
      final router = await pumpRealApp(
        tester,
        location: '/profile/addresses',
        overrides: [profileRepositoryProvider.overrideWithValue(profile)],
      );
      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete address?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('delete_address_cancel')));
      await tester.pumpAndSettle();
      expect(find.text('Delete address?'), findsNothing);
      expect(currentPath(router), '/profile/addresses');
      verifyNever(() => profile.deleteAddress(any()));
    });

    testWidgets('Delete > Delete removes the address and closes the dialog', (
      tester,
    ) async {
      when(() => profile.deleteAddress(any())).thenAnswer((_) async {});
      final router = await pumpRealApp(
        tester,
        location: '/profile/addresses',
        overrides: [profileRepositoryProvider.overrideWithValue(profile)],
      );
      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('delete_address_confirm')));
      await tester.pumpAndSettle();
      expect(find.text('Delete address?'), findsNothing);
      expect(currentPath(router), '/profile/addresses');
      verify(() => profile.deleteAddress(1)).called(1);
    });

    testWidgets('Add address sheet: Save closes the sheet and saves', (
      tester,
    ) async {
      when(
        () => profile.addAddress(
          receiverName: any(named: 'receiverName'),
          phone: any(named: 'phone'),
          line1: any(named: 'line1'),
          city: any(named: 'city'),
          isDefault: any(named: 'isDefault'),
        ),
      ).thenAnswer((_) async => Address.fromJson(_addrJson));
      final router = await pumpRealApp(
        tester,
        location: '/profile/addresses',
        overrides: [profileRepositoryProvider.overrideWithValue(profile)],
      );
      await tester.tap(find.text('Add address'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Receiver name'),
        'Sok Dara',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Phone'),
        '012345678',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Address (house, street, district)'),
        'No. 5, Street 63',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'City'),
        'Phnom Penh',
      );
      await tester.ensureVisible(find.text('Save address'));
      await tester.tap(find.text('Save address'));
      await tester.pumpAndSettle();
      expect(find.text('Save address'), findsNothing, reason: 'sheet closed');
      expect(currentPath(router), '/profile/addresses');
      verify(
        () => profile.addAddress(
          receiverName: 'Sok Dara',
          phone: '012345678',
          line1: 'No. 5, Street 63',
          city: 'Phnom Penh',
          isDefault: any(named: 'isDefault'),
        ),
      ).called(1);
    });
  });

  // ---------- Order detail: cancel-with-reason dialog -----------------------
  group('Order detail: cancel order dialog', () {
    late MockOrderRepository orders;

    setUp(() {
      orders = MockOrderRepository();
      when(
        () => orders.get(any()),
      ).thenAnswer((_) async => Order.fromJson(orderJson));
      when(() => orders.tracking(any())).thenAnswer(
        (_) async => Shipment.fromJson(
          (orderJson['shipment'] as Map).cast<String, dynamic>(),
        ),
      );
    });

    Future<void> open(WidgetTester tester) async {
      await pumpRealApp(
        tester,
        location: '/order/ECOM-20261104-0001',
        overrides: [orderRepositoryProvider.overrideWithValue(orders)],
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('cancel_order')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('cancel_order')));
      await tester.pumpAndSettle();
      expect(find.text('Cancel this order?'), findsOneWidget);
    }

    testWidgets('Keep order closes the dialog without cancelling', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.text('Keep order'));
      await tester.pumpAndSettle();
      expect(find.text('Cancel this order?'), findsNothing);
      verifyNever(() => orders.cancel(any(), any()));
    });

    testWidgets('empty reason is rejected and the dialog stays open', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.byKey(const Key('confirm_cancel')));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a reason'), findsOneWidget);
      expect(find.text('Cancel this order?'), findsOneWidget);
      verifyNever(() => orders.cancel(any(), any()));
    });

    testWidgets('reason + confirm returns the reason, cancels, closes', (
      tester,
    ) async {
      when(() => orders.cancel(any(), any())).thenAnswer(
        (_) async => Order.fromJson({...orderJson, 'status': 'CANCELLED'}),
      );
      await open(tester);
      await tester.enterText(
        find.byKey(const Key('cancel_reason')),
        'Ordered by mistake',
      );
      await tester.tap(find.byKey(const Key('confirm_cancel')));
      await tester.pumpAndSettle();
      expect(find.text('Cancel this order?'), findsNothing);
      verify(
        () => orders.cancel('ECOM-20261104-0001', 'Ordered by mistake'),
      ).called(1);
    });
  });

  // ---------- Product detail: review dialog ---------------------------------
  group('Product detail: review dialog', () {
    late MockCatalogRepository catalog;

    setUp(() {
      catalog = MockCatalogRepository();
      when(
        () => catalog.product(any()),
      ).thenAnswer((_) async => Product.fromJson(productJson));
      when(
        () => catalog.reviews(
          any(),
          page: any(named: 'page'),
          size: any(named: 'size'),
        ),
      ).thenAnswer(
        (_) async => PageResponse.fromJson(pageOf([]), Review.fromJson),
      );
    });

    Future<void> open(WidgetTester tester) async {
      await pumpRealApp(
        tester,
        location: '/product/2',
        overrides: [
          catalogRepositoryProvider.overrideWithValue(catalog),
          canReviewProvider.overrideWith((ref, id) async => true),
        ],
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('write_review')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.byKey(const Key('write_review')));
      await tester.tap(find.byKey(const Key('write_review')));
      await tester.pumpAndSettle();
    }

    testWidgets('Cancel closes the dialog and stays on the product', (
      tester,
    ) async {
      await open(tester);
      expect(find.text('Submit'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Submit'), findsNothing);
      expect(find.text('Dell Inspiron 15 3530'), findsWidgets);
      verifyNever(
        () => catalog.createReview(
          any(),
          rating: any(named: 'rating'),
          comment: any(named: 'comment'),
        ),
      );
    });

    testWidgets('Submit sends the review and closes the dialog', (
      tester,
    ) async {
      when(
        () => catalog.createReview(
          any(),
          rating: any(named: 'rating'),
          comment: any(named: 'comment'),
        ),
      ).thenAnswer(
        (_) async => Review.fromJson({
          'id': 1,
          'productId': 2,
          'userId': 3,
          'userName': 'Demo Customer',
          'rating': 4,
          'comment': 'Great',
          'createdAt': '2026-11-04T15:43:18.239598',
        }),
      );
      await open(tester);
      await tester.tap(find.byKey(const Key('star_4')));
      await tester.enterText(find.byType(TextField).last, 'Great');
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
      expect(find.text('Submit'), findsNothing);
      verify(
        () => catalog.createReview(2, rating: 4, comment: 'Great'),
      ).called(1);
    });
  });
}
