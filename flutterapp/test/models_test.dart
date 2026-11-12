import 'package:ecom_mobile/core/network/page_response.dart';
import 'package:ecom_mobile/features/auth/data/models/app_user.dart';
import 'package:ecom_mobile/features/cart/data/models/cart_models.dart';
import 'package:ecom_mobile/features/checkout/data/models/khqr_models.dart';
import 'package:ecom_mobile/features/notification/data/models/app_notification.dart';
import 'package:ecom_mobile/features/order/data/models/order_models.dart';
import 'package:ecom_mobile/features/product/data/models/catalog_models.dart';
import 'package:ecom_mobile/features/product/data/models/product_filter.dart';
import 'package:ecom_mobile/features/profile/data/models/address.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fixtures.dart';

void main() {
  group('auth models', () {
    test('AuthResult.fromJson', () {
      final r = AuthResult.fromJson(authJson);
      expect(r.accessToken, startsWith('eyJ'));
      expect(r.expiresInSeconds, 86400);
      expect(r.user.email, 'customer@ecom.com');
      expect(r.user.role, 'CUSTOMER');
      expect(r.user.createdAt, isNotNull);
    });

    test('toJson round trip', () {
      final u = AppUser.fromJson(userJson);
      expect(AppUser.fromJson(u.toJson()), u);
    });
  });

  group('Product', () {
    test('fromJson with specs and nested objects', () {
      final p = Product.fromJson(productJson);
      expect(p.name, 'Dell Inspiron 15 3530');
      expect(p.price, 749.0);
      expect(p.category!.name, 'Laptop');
      expect(p.brand!.id, 1);
      expect(p.ram, 16);
      expect(p.screenSize, 15.6);
      expect(p.images, hasLength(1));
      expect(p.inStock, isTrue);
      expect(p.lowStock, isFalse);
    });

    test(
      'integer price, missing specs and fractional-nanosecond dates parse',
      () {
        final p = Product.fromJson(accessoryJson);
        expect(p.price, 69.0);
        expect(p.cpu, isNull);
        expect(p.images, isEmpty);
        expect(p.firstImage, isNull);
        final u = AppUser.fromJson({
          ...userJson,
          'createdAt': '2026-11-04T15:43:16.607548428',
        });
        expect(u.createdAt, isNotNull);
      },
    );

    test('toJson round trip keeps values', () {
      final p = Product.fromJson(productJson);
      expect(Product.fromJson(p.toJson()), p);
    });

    test('stock helpers', () {
      expect(testProduct(stock: 0).inStock, isFalse);
      expect(testProduct(stock: 3, low: 5).lowStock, isTrue);
    });
  });

  test('PageResponse parses paging metadata', () {
    final page = PageResponse.fromJson(
      pageOf([productJson], last: false),
      Product.fromJson,
    );
    expect(page.content, hasLength(1));
    expect(page.last, isFalse);
    expect(page.totalElements, 1);
  });

  test('Cart and CouponPreview', () {
    final c = Cart.fromJson(cartJson);
    expect(c.items.single.lineTotal, 138.0);
    expect(c.totalItems, 2);
    expect(c.subtotal, 138.0);
    final p = CouponPreview.fromJson(couponJson);
    expect(p.discount, 13.8);
    expect(p.total, 129.2);
  });

  group('Order', () {
    test('fromJson', () {
      final o = Order.fromJson(orderJson);
      expect(o.orderNumber, 'ECOM-20261104-0001');
      expect(o.total, 77.1);
      expect(o.items.single.quantity, 1);
      expect(o.payment!.method, 'KHQR');
      expect(o.shipment!.status, 'PREPARING');
      expect(o.canCancel, isTrue);
      expect(o.canPayNow, isTrue);
    });

    test('rules: delivered, cancelled, paid after cancel', () {
      expect(testOrder(status: 'DELIVERED').canCancel, isFalse);
      expect(testOrder(status: 'SHIPPED').canCancel, isFalse);
      expect(testOrder(method: 'CASH_ON_DELIVERY').canPayNow, isFalse);
      final late = testOrder(
        status: 'CANCELLED',
        payStatus: 'PAID_AFTER_CANCEL',
      );
      expect(late.paidAfterCancel, isTrue);
      expect(late.canPayNow, isFalse);
      expect(testOrder(payStatus: 'PAID').canPayNow, isFalse);
    });

    test('toJson round trip', () {
      final o = Order.fromJson(orderJson);
      expect(Order.fromJson(o.toJson()), o);
    });
  });

  test('KhqrData ignores qrPayload and detects mode', () {
    final k = KhqrData.fromJson(khqrJson);
    expect(k.qrString, startsWith('MOCK-KHQR'));
    expect(k.amount, 77.1);
    expect(k.isMock, isTrue);
    expect(KhqrData.fromJson({...khqrJson, 'mode': 'BAKONG'}).isMock, isFalse);
  });

  test('KhqrSession expiry', () {
    final s = testSession(validFor: const Duration(seconds: 30));
    expect(s.isExpired(), isFalse);
    expect(s.isExpired(DateTime.now().add(const Duration(minutes: 1))), isTrue);
  });

  test('AppNotification priority', () {
    expect(AppNotification.fromJson(notificationJson).isHigh, isFalse);
    expect(
      AppNotification.fromJson({
        ...notificationJson,
        'priority': 'HIGH',
      }).isHigh,
      isTrue,
    );
  });

  test('Address uses isDefault', () {
    final a = Address.fromJson({
      'id': 1,
      'receiverName': 'A',
      'phone': '1',
      'line1': 'x',
      'city': 'PP',
      'isDefault': true,
    });
    expect(a.isDefault, isTrue);
    expect(a.toJson()['isDefault'], isTrue);
    expect(a.fullLine, 'x, PP');
  });

  test('ProductFilter builds the query', () {
    const f = ProductFilter(
      keyword: ' laptop ',
      categoryId: 1,
      minPrice: 500,
      maxPrice: 1000,
      ram: 16,
      inStockOnly: true,
      sort: 'price_asc',
    );
    final q = f.toQuery(page: 2, size: 12);
    expect(q, {
      'keyword': 'laptop',
      'categoryId': 1,
      'minPrice': 500.0,
      'maxPrice': 1000.0,
      'ram': 16,
      'inStock': true,
      'sort': 'price_asc',
      'page': 2,
      'size': 12,
    });
    expect(f.activeCount, 4);
  });
}
