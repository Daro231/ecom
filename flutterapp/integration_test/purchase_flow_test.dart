// End-to-end purchase flow against a RUNNING backend in MOCK KHQR mode.
//
//   flutter test integration_test/purchase_flow_test.dart -d <device>
//   (real device: add --dart-define=API_BASE_URL=http://<pc-ip>:8080/api/v1)
//
// Uses the seed account customer@ecom.com / Customer@123 and coupon WELCOME10.
import 'package:ecom_mobile/app.dart';
import 'package:ecom_mobile/core/location/geocoder.dart';
import 'package:ecom_mobile/core/location/location_service.dart';
import 'package:ecom_mobile/core/providers.dart';
import 'package:ecom_mobile/core/storage/token_storage.dart';
import 'package:ecom_mobile/features/notification/presentation/providers/notification_providers.dart';
import 'package:ecom_mobile/features/product/presentation/widgets/product_card.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SilentNotifier implements LocalNotifier {
  @override
  Future<void> init() async {}
  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {}
}

/// `pumpAndSettle` never returns on screens with timers (KHQR countdown), so
/// poll for the widget instead.
Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder');
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Saves a screenshot through the driver (web only; see test_driver).
  Future<void> shot(WidgetTester tester, String name) async {
    if (!kIsWeb) return;
    await tester.pump(const Duration(milliseconds: 400));
    await binding.takeScreenshot(name);
  }

  testWidgets(
    'login -> search laptop -> add to cart -> WELCOME10 -> KHQR checkout -> simulate -> CONFIRMED',
    (tester) async {
      await SecureTokenStorage().clear();
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [
            sharedPrefsProvider.overrideWithValue(prefs),
            localNotifierProvider.overrideWithValue(_SilentNotifier()),
          ],
          child: const EcomApp(),
        ),
      );

      // Login
      await pumpUntil(tester, find.byKey(const Key('login_email')));
      await shot(tester, '01_login');
      await tester.enterText(
        find.byKey(const Key('login_email')),
        'customer@ecom.com',
      );
      await tester.enterText(
        find.byKey(const Key('login_password')),
        'Customer@123',
      );
      await tester.tap(find.byKey(const Key('login_submit')));
      await pumpUntil(tester, find.byKey(const Key('home_search')));
      await shot(tester, '02_home');

      // Search "laptop" and open the first result
      await tester.enterText(find.byKey(const Key('home_search')), 'laptop');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await pumpUntil(tester, find.byType(ProductCard));
      await shot(tester, '03_search_laptop');
      // "laptop" is a category name: filter by category (removable chip) so the
      // Thunderbolt dock (an Accessory mentioning "laptop") is not listed.
      expect(find.byKey(const Key('category_chip')), findsOneWidget);
      expect(find.textContaining('Thunderbolt'), findsNothing);
      await tester.tap(find.byType(ProductCard).first);

      // Product detail -> add to cart
      // (The spec table can be below the fold on a wide browser window.)
      await pumpUntil(tester, find.byType(PageView));
      await shot(tester, '04_product_detail');
      // The page is a lazy ListView: scroll until the button is built.
      await tester.scrollUntilVisible(
        find.byKey(const Key('add_to_cart')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.byKey(const Key('add_to_cart')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const Key('add_to_cart')));
      await pumpUntil(tester, find.text('View cart'));
      await tester.tap(find.text('View cart'));

      // Cart -> coupon
      await pumpUntil(tester, find.byKey(const Key('coupon_field')));
      await tester.enterText(
        find.byKey(const Key('coupon_field')),
        'WELCOME10',
      );
      await tester.tap(find.byKey(const Key('apply_coupon')));
      await pumpUntil(tester, find.text('Coupon WELCOME10 applied'));
      await shot(tester, '05_cart_coupon');
      // The summary sits at the end of a lazy ListView: scroll it into view.
      await tester.scrollUntilVisible(
        find.byKey(const Key('go_checkout')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      // A floating "coupon applied" SnackBar can cover the button: dismiss it.
      ScaffoldMessenger.of(
        tester.element(find.byType(Scaffold).first),
      ).clearSnackBars();
      await tester.pump(const Duration(milliseconds: 500));
      // Scroll further until it is not hidden behind the bottom navigation bar.
      for (
        var i = 0;
        i < 6 &&
            find
                .byKey(const Key('go_checkout'))
                .hitTestable()
                .evaluate()
                .isEmpty;
        i++
      ) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
        await tester.pump(const Duration(milliseconds: 300));
      }
      await tester.tap(find.byKey(const Key('go_checkout')).hitTestable());

      // Checkout stepper: address -> shipping -> payment (KHQR is preselected) -> review
      Future<void> next() async {
        await pumpUntil(
          tester,
          find.byKey(const Key('step_next')).hitTestable(),
        );
        await tester.tap(find.byKey(const Key('step_next')).hitTestable());
        await tester.pump(const Duration(milliseconds: 400));
      }

      await pumpUntil(tester, find.byKey(const Key('step_next')).hitTestable());
      await shot(tester, '06_checkout_address');
      await next(); // address (default preselected)
      await next(); // shipping (first method preselected)
      await tester.tap(find.byKey(const Key('pay_KHQR')));
      await next(); // payment
      await pumpUntil(
        tester,
        find.byKey(const Key('place_order')).hitTestable(),
      );
      await tester.tap(find.byKey(const Key('place_order')).hitTestable());

      // KHQR screen (MOCK mode shows the simulate button)
      await pumpUntil(tester, find.byKey(const Key('khqr_qr')));
      expect(
        find.byKey(const Key('khqr_simulate')),
        findsOneWidget,
        reason: 'backend must run with KHQR_MODE=mock',
      );
      await shot(tester, '07_khqr_payment');
      await tester.tap(find.byKey(const Key('khqr_simulate')));

      // Success -> view order -> CONFIRMED
      await pumpUntil(tester, find.text('Payment received!'));
      await shot(tester, '08_payment_success');
      await tester.tap(find.byKey(const Key('view_order')));
      await pumpUntil(tester, find.text('Confirmed'));
      expect(find.text('Confirmed'), findsWidgets);
      expect(find.text('KHQR'), findsWidgets); // not "Khqr"
      expect(find.text('Khqr'), findsNothing);
      await shot(tester, '09_order_detail_confirmed');

      // Notifications: the bell opens the list (payment/order notifications).
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/home');
      await pumpUntil(tester, find.byTooltip('Notifications'));
      await tester.tap(find.byTooltip('Notifications').first);
      await pumpUntil(tester, find.byKey(const Key('mark_all_read')));
      await shot(tester, '10_notifications');
    },
  );

  testWidgets(
    'login -> logout -> login screen -> restart stays on login -> login again',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      Future<void> boot() async {
        await tester.pumpWidget(
          ProviderScope(
            retry: (_, _) => null,
            overrides: [
              sharedPrefsProvider.overrideWithValue(prefs),
              localNotifierProvider.overrideWithValue(_SilentNotifier()),
            ],
            child: const EcomApp(),
          ),
        );
      }

      Future<void> signIn() async {
        await pumpUntil(tester, find.byKey(const Key('login_email')));
        await tester.enterText(
          find.byKey(const Key('login_email')),
          'customer@ecom.com',
        );
        await tester.enterText(
          find.byKey(const Key('login_password')),
          'Customer@123',
        );
        await tester.tap(find.byKey(const Key('login_submit')));
        await pumpUntil(tester, find.byKey(const Key('home_search')));
      }

      await boot();
      await signIn();

      // Profile tab -> Log out -> confirm in the dialog.
      await tester.tap(find.text('Profile').last);
      await pumpUntil(
        tester,
        find.byKey(const Key('logout')),
        timeout: const Duration(seconds: 10),
      ).catchError((_) {});
      await tester.scrollUntilVisible(
        find.byKey(const Key('logout')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.byKey(const Key('logout')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const Key('logout')));
      await pumpUntil(tester, find.byKey(const Key('logout_confirm')));
      await shot(tester, '11_logout_dialog');
      await tester.tap(find.byKey(const Key('logout_confirm')));

      // Redirected to the login screen immediately; token + flag are gone.
      await pumpUntil(tester, find.byKey(const Key('login_email')));
      expect(find.byKey(const Key('logout_confirm')), findsNothing);
      expect(prefs.getString('access_token'), isNull);
      expect(prefs.getBool('remember_session'), isNull);
      await shot(tester, '12_after_logout');

      // "Reload": tear the whole app down and boot it again (fresh providers and
      // router, reading the same browser storage) - it must stay on /login.
      await tester.pumpWidget(const SizedBox());
      await boot();
      await pumpUntil(tester, find.byKey(const Key('login_email')));
      expect(find.byKey(const Key('home_search')), findsNothing);
      await shot(tester, '13_after_reload_login');

      // Signing in again works.
      await signIn();
      expect(find.byKey(const Key('home_search')), findsOneWidget);
      await shot(tester, '14_login_again');
    },
  );

  testWidgets(
    'add an address with a map pin (mocked location), see it on the card, delete it',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [
            sharedPrefsProvider.overrideWithValue(prefs),
            localNotifierProvider.overrideWithValue(_SilentNotifier()),
            // Mocked: the browser location prompt cannot be answered in a test,
            // and Nominatim should not be hit by automated runs.
            locationServiceProvider.overrideWithValue(_FixedLocation()),
            geocoderProvider.overrideWithValue(_FixedGeocoder()),
          ],
          child: const EcomApp(),
        ),
      );
      await pumpUntil(tester, find.byKey(const Key('login_email')));
      await tester.enterText(
        find.byKey(const Key('login_email')),
        'customer@ecom.com',
      );
      await tester.enterText(
        find.byKey(const Key('login_password')),
        'Customer@123',
      );
      await tester.tap(find.byKey(const Key('login_submit')));
      await pumpUntil(tester, find.byKey(const Key('home_search')));

      GoRouter.of(
        tester.element(find.byType(Scaffold).first),
      ).go('/profile/addresses');
      await pumpUntil(tester, find.text('Add address'));
      await tester.tap(find.text('Add address'));
      await pumpUntil(tester, find.byKey(const Key('use_my_location')));
      expect(find.byKey(const Key('address_map')), findsOneWidget);

      await tester.tap(find.byKey(const Key('use_my_location')));
      await pumpUntil(tester, find.byKey(const Key('map_pin')));
      // Debounce (1 s) then the fake geocoder fills Address + City.
      await pumpUntil(
        tester,
        find.text('Integration St 1, Daun Penh'),
        timeout: const Duration(seconds: 10),
      );
      await tester.pump(const Duration(seconds: 2)); // let tiles load
      await shot(tester, '15_address_sheet_with_pin');

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Receiver name'),
        'Integration Test',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Phone'),
        '012999888',
      );
      await tester.ensureVisible(find.text('Save address'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Save address'));

      // The saved address comes back from the backend WITH its coordinates, so
      // the card shows the map preview.
      final card = find.ancestor(
        of: find.text('Integration Test'),
        matching: find.byType(Card),
      );
      await pumpUntil(tester, card);
      expect(
        find.descendant(
          of: card,
          matching: find.byKey(const ValueKey('map_preview')),
        ),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 2));
      await shot(tester, '16_address_card_map');

      // Clean up: delete the test address again.
      await tester.tap(
        find.descendant(of: card, matching: find.byTooltip('Delete')),
      );
      await pumpUntil(tester, find.byKey(const Key('delete_address_confirm')));
      await tester.tap(find.byKey(const Key('delete_address_confirm')));
      await pumpUntil(tester, find.text('Default'));
      expect(find.text('Integration Test'), findsNothing);
    },
  );
}

class _FixedLocation implements LocationService {
  @override
  Future<LocationResult> current() async =>
      const LocationResult.ok(11.5700, 104.9100);
}

class _FixedGeocoder implements Geocoder {
  @override
  Future<GeocodeResult?> reverse(double latitude, double longitude) async =>
      const GeocodeResult(
        line1: 'Integration St 1, Daun Penh',
        city: 'Phnom Penh',
      );
}
