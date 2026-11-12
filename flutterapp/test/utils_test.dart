import 'package:ecom_mobile/core/config/env.dart';
import 'package:ecom_mobile/core/core_exports.dart';
import 'package:ecom_mobile/core/router/app_router.dart';
import 'package:ecom_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatters', () {
    test('formatUsd', () {
      expect(formatUsd(1299), r'$1,299.00');
      expect(formatUsd(77.1), r'$77.10');
      expect(formatUsd(0), r'$0.00');
    });
    test('humanizeEnum', () {
      expect(humanizeEnum('PAID_AFTER_CANCEL'), 'Paid after cancel');
      expect(humanizeEnum('CASH_ON_DELIVERY'), 'Cash on delivery');
    });
    test('formatCountdown', () {
      expect(formatCountdown(const Duration(minutes: 9, seconds: 5)), '09:05');
      expect(formatCountdown(const Duration(seconds: -4)), '00:00');
    });
    test('toDouble helpers', () {
      expect(toDouble(5), 5.0);
      expect(toDouble('2.5'), 2.5);
      expect(toDouble(null), 0);
      expect(toDoubleOrNull(null), isNull);
      expect(toDateTimeOrNull('2026-11-04T15:43:16.607548428'), isNotNull);
      expect(toDateTimeOrNull('nope'), isNull);
    });
  });

  group('validators', () {
    test('email', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('abc'), isNotNull);
      expect(Validators.email('a@b.co'), isNull);
    });
    test('password', () {
      expect(Validators.password('short'), isNotNull);
      expect(Validators.password('Passw0rd!'), isNull);
    });
    test('phone', () {
      expect(Validators.phone('12'), isNotNull);
      expect(Validators.phone('012 345 678'), isNull);
    });
    test('match', () {
      expect(Validators.match(() => 'a', 'no')('b'), 'no');
      expect(Validators.match(() => 'a', 'no')('a'), isNull);
    });
  });

  group('cart / order totals', () {
    test('shipping is free at the threshold', () {
      expect(
        shippingFeeFor(subtotal: 999.99, fee: 5, freeShippingThreshold: 1000),
        5,
      );
      expect(
        shippingFeeFor(subtotal: 1000, fee: 5, freeShippingThreshold: 1000),
        0,
      );
      expect(shippingFeeFor(subtotal: 5000, fee: 25), 25);
    });
    test('total = subtotal - discount + shipping', () {
      const t = OrderTotals(subtotal: 138, discount: 13.8, shippingFee: 5);
      expect(t.total, 129.2);
      expect(
        const OrderTotals(subtotal: 10, discount: 50, shippingFee: 0).total,
        0,
      );
    });
  });

  group('Env', () {
    test('resolveImage', () {
      expect(
        Env.resolveImage('https://placehold.co/a.png'),
        'https://placehold.co/a.png',
      );
      expect(Env.resolveImage('/uploads/x.png'), '${Env.origin}/uploads/x.png');
      expect(
        Env.resolveImage('http://localhost:8080/uploads/x.png'),
        contains('/uploads/x.png'),
      );
    });
    test(
      'base url ends with /api/v1',
      () => expect(Env.baseUrl, endsWith('/api/v1')),
    );
  });

  group('auth redirect', () {
    test(
      'unknown -> splash',
      () => expect(authRedirect(AuthStatus.unknown, '/home'), '/splash'),
    );
    test('logged out -> login', () {
      expect(authRedirect(AuthStatus.unauthenticated, '/cart'), '/login');
      expect(authRedirect(AuthStatus.unauthenticated, '/register'), isNull);
    });
    test('logged in leaves auth pages', () {
      expect(authRedirect(AuthStatus.authenticated, '/login'), '/home');
      expect(authRedirect(AuthStatus.authenticated, '/splash'), '/home');
      expect(authRedirect(AuthStatus.authenticated, '/cart'), isNull);
    });
  });
}
