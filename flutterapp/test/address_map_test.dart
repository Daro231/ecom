// Map + current location + reverse geocoding in the address sheet, run in the
// real router with fake location / geocoder services.
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:ecom_mobile/core/location/geocoder.dart';
import 'package:ecom_mobile/core/location/location_service.dart';
import 'package:ecom_mobile/core/location/url_opener.dart';
import 'package:ecom_mobile/core/providers.dart';
import 'package:ecom_mobile/features/order/data/models/order_models.dart';
import 'package:ecom_mobile/features/profile/data/models/address.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart' show LocationAccuracy;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers/fixtures.dart';
import 'helpers/real_router.dart';
import 'helpers/test_app.dart';

class FakeLocation implements LocationService {
  FakeLocation(this.result, {this.delay = Duration.zero});
  LocationResult result;
  final Duration delay;
  int calls = 0;
  @override
  Future<LocationResult> current() async {
    calls++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return result;
  }
}

class FakeGeocoder implements Geocoder {
  FakeGeocoder({this.result, this.fail = false});
  GeocodeResult? result;
  bool fail;
  final calls = <(double, double)>[];
  @override
  Future<GeocodeResult?> reverse(double lat, double lng) async {
    calls.add((lat, lng));
    if (fail) throw Exception('nominatim down');
    return result;
  }
}

const _wat = LocationResult.ok(11.5700, 104.9100);
const _found = GeocodeResult(
  line1: 'No. 5, Street 63, Boeung Keng Kang',
  city: 'Phnom Penh',
);

const _addr = {
  'id': 1,
  'receiverName': 'Demo Customer',
  'phone': '012345678',
  'line1': 'No. 12, Street 271',
  'city': 'Phnom Penh',
  'isDefault': true,
};

void main() {
  late MockProfileRepository profile;

  setUp(() {
    profile = MockProfileRepository();
    when(() => profile.addresses()).thenAnswer((_) async => []);
    when(
      () => profile.addAddress(
        receiverName: any(named: 'receiverName'),
        phone: any(named: 'phone'),
        line1: any(named: 'line1'),
        city: any(named: 'city'),
        isDefault: any(named: 'isDefault'),
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer((_) async => Address.fromJson(_addr));
  });

  Future<void> openSheet(
    WidgetTester tester, {
    required FakeLocation location,
    required FakeGeocoder geocoder,
    List<Map<String, dynamic>> existing = const [],
  }) async {
    when(
      () => profile.addresses(),
    ).thenAnswer((_) async => [for (final a in existing) Address.fromJson(a)]);
    await pumpRealApp(
      tester,
      location: '/profile/addresses',
      overrides: [
        profileRepositoryProvider.overrideWithValue(profile),
        locationServiceProvider.overrideWithValue(location),
        geocoderProvider.overrideWithValue(geocoder),
      ],
    );
    await tester.tap(find.text('Add address'));
    await tester.pumpAndSettle();
  }

  Future<void> fillAndSave(
    WidgetTester tester, {
    bool fillAddress = true,
  }) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Receiver name'),
      'Sok Dara',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Phone'),
      '012345678',
    );
    if (fillAddress) {
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Address (house, street, district)'),
        'My typed street',
      );
    }
    await tester.ensureVisible(find.text('Save address'));
    await tester.tap(find.text('Save address'));
    await tester.pumpAndSettle();
  }

  TextFormField field(WidgetTester tester, String label) =>
      tester.widget<TextFormField>(find.widgetWithText(TextFormField, label));

  String text(WidgetTester t, String label) => field(t, label).controller!.text;

  group('Use my current location', () {
    testWidgets(
      'granted: pin is placed, address + city are filled, saved with lat/lng',
      (tester) async {
        final loc = FakeLocation(
          _wat,
          delay: const Duration(milliseconds: 300),
        );
        final geo = FakeGeocoder(result: _found);
        await openSheet(tester, location: loc, geocoder: geo);
        expect(find.byKey(const Key('address_map')), findsOneWidget);
        expect(find.byKey(const Key('map_pin')), findsNothing); // no pin yet
        expect(find.text('© OpenStreetMap contributors'), findsOneWidget);

        await tester.tap(find.byKey(const Key('use_my_location')));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Getting your location…'), findsOneWidget); // loading
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byKey(const Key('map_pin')), findsOneWidget);
        expect(geo.calls, isEmpty, reason: 'debounced: not called immediately');

        await tester.pump(const Duration(milliseconds: 1100)); // debounce 1 s
        await tester.pumpAndSettle();
        expect(geo.calls, [(11.5700, 104.9100)]);
        expect(text(tester, 'Address (house, street, district)'), _found.line1);
        expect(text(tester, 'City'), 'Phnom Penh');

        await fillAndSave(tester, fillAddress: false);
        verify(
          () => profile.addAddress(
            receiverName: 'Sok Dara',
            phone: '012345678',
            line1: _found.line1!,
            city: 'Phnom Penh',
            isDefault: any(named: 'isDefault'),
            latitude: 11.5700,
            longitude: 104.9100,
          ),
        ).called(1);
      },
    );

    testWidgets('does not overwrite what the user already typed', (
      tester,
    ) async {
      final geo = FakeGeocoder(result: _found);
      await openSheet(tester, location: FakeLocation(_wat), geocoder: geo);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Address (house, street, district)'),
        'My typed street',
      );
      await tester.tap(find.byKey(const Key('use_my_location')));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pumpAndSettle();
      expect(geo.calls, hasLength(1)); // city is still untouched
      expect(
        text(tester, 'Address (house, street, district)'),
        'My typed street',
      );
      expect(text(tester, 'City'), 'Phnom Penh');
    });

    testWidgets(
      'permission denied: clear message, no pin, still saves without location',
      (tester) async {
        final geo = FakeGeocoder(result: _found);
        await openSheet(
          tester,
          location: FakeLocation(
            const LocationResult.fail(LocationProblem.denied),
          ),
          geocoder: geo,
        );
        await tester.tap(find.byKey(const Key('use_my_location')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('location_message')), findsOneWidget);
        expect(find.textContaining('permission was denied'), findsOneWidget);
        expect(find.byKey(const Key('map_pin')), findsNothing);
        expect(geo.calls, isEmpty);

        await fillAndSave(tester);
        verify(
          () => profile.addAddress(
            receiverName: 'Sok Dara',
            phone: '012345678',
            line1: 'My typed street',
            city: 'Phnom Penh',
            isDefault: any(named: 'isDefault'),
            latitude: null,
            longitude: null,
          ),
        ).called(1);
      },
    );

    testWidgets('location off / blocked / timeout show their own messages', (
      tester,
    ) async {
      final loc = FakeLocation(
        const LocationResult.fail(LocationProblem.serviceOff),
      );
      await openSheet(tester, location: loc, geocoder: FakeGeocoder());
      Future<void> tryAgain(LocationProblem p, String expected) async {
        loc.result = LocationResult.fail(p);
        await tester.tap(find.byKey(const Key('use_my_location')));
        await tester.pumpAndSettle();
        expect(find.textContaining(expected), findsOneWidget, reason: '$p');
        expect(find.byKey(const Key('map_pin')), findsNothing);
      }

      await tester.tap(find.byKey(const Key('use_my_location')));
      await tester.pumpAndSettle();
      expect(find.textContaining('turned off'), findsOneWidget);
      await tryAgain(LocationProblem.deniedForever, 'blocked');
      await tryAgain(LocationProblem.timeout, 'in time');
      await tryAgain(LocationProblem.failed, 'Could not get your location.');
      expect(tester.takeException(), isNull);
    });
  });

  group('Location accuracy', () {
    double zoom(WidgetTester t) =>
        MapCamera.of(t.element(find.byType(TileLayer))).zoom;
    double circleRadius(WidgetTester t) => t
        .widget<CircleLayer>(find.byKey(const Key('accuracy_circle')))
        .circles
        .first
        .radius;

    testWidgets('accurate fix (30 m): circle drawn, no warning, zoomed in', (
      tester,
    ) async {
      await openSheet(
        tester,
        location: FakeLocation(
          const LocationResult.ok(11.5700, 104.9100, accuracy: 30),
        ),
        geocoder: FakeGeocoder(result: _found),
      );
      await tester.tap(find.byKey(const Key('use_my_location')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('accuracy_circle')), findsOneWidget);
      expect(circleRadius(tester), 30);
      expect(
        tester
            .widget<CircleLayer>(find.byKey(const Key('accuracy_circle')))
            .circles
            .first
            .useRadiusInMeter,
        isTrue,
      );
      expect(find.byKey(const Key('accuracy_warning')), findsNothing);
      expect(zoom(tester), 16);
    });

    testWidgets('exactly 100 m is still "accurate" (no warning)', (
      tester,
    ) async {
      await openSheet(
        tester,
        location: FakeLocation(
          const LocationResult.ok(11.57, 104.91, accuracy: 100),
        ),
        geocoder: FakeGeocoder(),
      );
      await tester.tap(find.byKey(const Key('use_my_location')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('accuracy_circle')), findsOneWidget);
      expect(find.byKey(const Key('accuracy_warning')), findsNothing);
    });

    testWidgets('coarse fix (2.5 km): warning, circle, zoomed out to fit it', (
      tester,
    ) async {
      await openSheet(
        tester,
        location: FakeLocation(
          const LocationResult.ok(11.5700, 104.9100, accuracy: 2500),
        ),
        geocoder: FakeGeocoder(result: _found),
      );
      await tester.tap(find.byKey(const Key('use_my_location')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('accuracy_warning')), findsOneWidget);
      expect(
        find.text(
          'Your location is approximate (±2.5 km). Please drag the pin to your exact location.',
        ),
        findsOneWidget,
      );
      expect(circleRadius(tester), 2500);
      // 5 km across in a ~220 px map needs zoom ~12, far below the street zoom 16.
      expect(zoom(tester), lessThan(14));
      expect(zoom(tester), greaterThan(8));
    });

    testWidgets('a few hundred metres is shown in metres', (tester) async {
      await openSheet(
        tester,
        location: FakeLocation(
          const LocationResult.ok(11.57, 104.91, accuracy: 350),
        ),
        geocoder: FakeGeocoder(),
      );
      await tester.tap(find.byKey(const Key('use_my_location')));
      await tester.pumpAndSettle();
      expect(find.textContaining('approximate (±350 m)'), findsOneWidget);
    });

    testWidgets('moving the pin by hand removes the circle and the warning', (
      tester,
    ) async {
      await openSheet(
        tester,
        location: FakeLocation(
          const LocationResult.ok(11.57, 104.91, accuracy: 2500),
        ),
        geocoder: FakeGeocoder(),
      );
      await tester.tap(find.byKey(const Key('use_my_location')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('accuracy_warning')), findsOneWidget);
      // The pin sits at the centre: tap the map beside it.
      await tester.tapAt(
        tester.getCenter(find.byKey(const Key('address_map'))) +
            const Offset(70, 40),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('map_pin')), findsOneWidget);
      expect(find.byKey(const Key('accuracy_circle')), findsNothing);
      expect(find.byKey(const Key('accuracy_warning')), findsNothing);
      await tester.pump(
        const Duration(seconds: 2),
      ); // let the 1 s debounce fire
    });

    testWidgets('a fix without accuracy info shows no circle', (tester) async {
      await openSheet(
        tester,
        location: FakeLocation(_wat), // accuracy null
        geocoder: FakeGeocoder(),
      );
      await tester.tap(find.byKey(const Key('use_my_location')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('map_pin')), findsOneWidget);
      expect(find.byKey(const Key('accuracy_circle')), findsNothing);
      expect(find.byKey(const Key('accuracy_warning')), findsNothing);
    });

    test('formatting and thresholds', () {
      expect(formatAccuracy(2500), '±2.5 km');
      expect(formatAccuracy(1000), '±1.0 km');
      expect(formatAccuracy(349.6), '±350 m');
      expect(accuracyWarning(null), isNull);
      expect(accuracyWarning(100), isNull);
      expect(accuracyWarning(100.5), contains('approximate'));
    });

    test('geolocator is asked for best accuracy on mobile, high on web', () {
      const t = Duration(seconds: 15);
      final mobile = GeolocatorLocationService.settingsFor(
        web: false,
        timeout: t,
      );
      final web = GeolocatorLocationService.settingsFor(web: true, timeout: t);
      expect(mobile.accuracy, LocationAccuracy.best);
      expect(web.accuracy, LocationAccuracy.high);
      expect(mobile.timeLimit, t);
    });
  });

  group('Reverse geocoding', () {
    testWidgets('failure keeps the pin and lets the user type the address', (
      tester,
    ) async {
      final geo = FakeGeocoder(fail: true);
      await openSheet(tester, location: FakeLocation(_wat), geocoder: geo);
      await tester.tap(find.byKey(const Key('use_my_location')));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('map_pin')), findsOneWidget);
      expect(
        find.textContaining('Could not look up the address'),
        findsOneWidget,
      );
      expect(text(tester, 'Address (house, street, district)'), isEmpty);

      await fillAndSave(tester);
      verify(
        () => profile.addAddress(
          receiverName: 'Sok Dara',
          phone: '012345678',
          line1: 'My typed street',
          city: 'Phnom Penh',
          isDefault: any(named: 'isDefault'),
          latitude: 11.5700,
          longitude: 104.9100,
        ),
      ).called(1);
    });

    testWidgets(
      'tapping the map twice within 1 s makes ONE lookup (debounce)',
      (tester) async {
        final geo = FakeGeocoder(result: _found);
        await openSheet(tester, location: FakeLocation(_wat), geocoder: geo);
        final map = find.byKey(const Key('address_map'));
        final c = tester.getCenter(map);
        await tester.tapAt(c);
        await tester.pump(const Duration(milliseconds: 400));
        await tester.tapAt(c + const Offset(30, 20));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byKey(const Key('map_pin')), findsOneWidget);
        expect(geo.calls, isEmpty);
        await tester.pump(const Duration(milliseconds: 1200));
        await tester.pumpAndSettle();
        expect(geo.calls, hasLength(1));
      },
    );

    testWidgets('dragging the pin moves it (and the map does not pan)', (
      tester,
    ) async {
      final geo = FakeGeocoder(result: _found);
      await openSheet(tester, location: FakeLocation(_wat), geocoder: geo);
      await tester.tap(find.byKey(const Key('use_my_location')));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle();
      expect(geo.calls, hasLength(1));
      final before = geo.calls.first;

      await tester.drag(find.byKey(const Key('map_pin')), const Offset(70, 50));
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle();
      expect(geo.calls, hasLength(2));
      final after = geo.calls.last;
      expect(after.$2, greaterThan(before.$2), reason: 'moved east');
      expect(after.$1, lessThan(before.$1), reason: 'moved south');
    });

    testWidgets('Remove pin clears the location', (tester) async {
      await openSheet(
        tester,
        location: FakeLocation(_wat),
        geocoder: FakeGeocoder(result: _found),
      );
      await tester.tap(find.byKey(const Key('use_my_location')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('clear_pin')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('map_pin')), findsNothing);
      await fillAndSave(tester);
      verify(
        () => profile.addAddress(
          receiverName: any(named: 'receiverName'),
          phone: any(named: 'phone'),
          line1: any(named: 'line1'),
          city: any(named: 'city'),
          isDefault: any(named: 'isDefault'),
          latitude: null,
          longitude: null,
        ),
      ).called(1);
    });
  });

  group('Map preview', () {
    testWidgets('address card shows the map; tap opens Google Maps', (
      tester,
    ) async {
      Uri? opened;
      when(() => profile.addresses()).thenAnswer(
        (_) async => [
          Address.fromJson({
            ..._addr,
            'latitude': 11.5564,
            'longitude': 104.9282,
          }),
          Address.fromJson({..._addr, 'id': 2, 'line1': 'No location here'}),
        ],
      );
      await pumpRealApp(
        tester,
        location: '/profile/addresses',
        overrides: [
          profileRepositoryProvider.overrideWithValue(profile),
          urlOpenerProvider.overrideWithValue((u) async {
            opened = u;
            return true;
          }),
        ],
      );
      expect(find.byKey(const Key('address_map_1')), findsOneWidget);
      expect(find.byKey(const Key('address_map_2')), findsNothing);
      expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
      await tester.tap(find.byKey(const Key('address_map_1')));
      await tester.pump();
      expect(
        opened.toString(),
        'https://www.google.com/maps?q=11.5564,104.9282',
      );
    });

    testWidgets(
      'order detail shows the delivery map when the order has coordinates',
      (tester) async {
        Uri? opened;
        final orders = MockOrderRepository();
        when(() => orders.get(any())).thenAnswer(
          (_) async => Order.fromJson({
            ...orderJson,
            'deliveryLatitude': 11.5564,
            'deliveryLongitude': 104.9282,
          }),
        );
        when(() => orders.tracking(any())).thenAnswer(
          (_) async => Shipment.fromJson(
            (orderJson['shipment'] as Map).cast<String, dynamic>(),
          ),
        );
        await pumpRealApp(
          tester,
          location: '/order/ECOM-20261104-0001',
          overrides: [
            orderRepositoryProvider.overrideWithValue(orders),
            urlOpenerProvider.overrideWithValue((u) async {
              opened = u;
              return true;
            }),
          ],
        );
        await tester.scrollUntilVisible(
          find.byKey(const Key('order_map')),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.byKey(const Key('order_map')));
        await tester.pump();
        expect(opened?.host, 'www.google.com');
        expect(opened?.queryParameters['q'], '11.5564,104.9282');
      },
    );
  });

  group('Edit address with a saved location', () {
    testWidgets('shows the pin, keeps typed data, resends the coordinates', (
      tester,
    ) async {
      when(() => profile.addresses()).thenAnswer(
        (_) async => [
          Address.fromJson({
            ..._addr,
            'latitude': 11.5564,
            'longitude': 104.9282,
          }),
        ],
      );
      when(
        () => profile.updateAddress(
          any(),
          receiverName: any(named: 'receiverName'),
          phone: any(named: 'phone'),
          line1: any(named: 'line1'),
          city: any(named: 'city'),
          isDefault: any(named: 'isDefault'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer((_) async => Address.fromJson(_addr));
      final geo = FakeGeocoder(result: _found);
      await pumpRealApp(
        tester,
        location: '/profile/addresses',
        overrides: [
          profileRepositoryProvider.overrideWithValue(profile),
          geocoderProvider.overrideWithValue(geo),
        ],
      );
      await tester.tap(find.byTooltip('Edit'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('map_pin')), findsOneWidget);
      // Move the pin: stored address text must NOT be replaced.
      await tester.tapAt(
        tester.getCenter(find.byKey(const Key('address_map'))) +
            const Offset(50, 30),
      );
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle();
      expect(geo.calls, isEmpty);
      expect(
        text(tester, 'Address (house, street, district)'),
        'No. 12, Street 271',
      );
      await tester.ensureVisible(find.text('Save address'));
      await tester.tap(find.text('Save address'));
      await tester.pumpAndSettle();
      final v = verify(
        () => profile.updateAddress(
          1,
          receiverName: any(named: 'receiverName'),
          phone: any(named: 'phone'),
          line1: 'No. 12, Street 271',
          city: any(named: 'city'),
          isDefault: any(named: 'isDefault'),
          latitude: captureAny(named: 'latitude'),
          longitude: captureAny(named: 'longitude'),
        ),
      )..called(1);
      expect(v.captured[0], isNot(11.5564)); // the pin moved
      expect(v.captured[0], isA<double>());
    });
  });

  group('NominatimGeocoder', () {
    test('parses a typical Phnom Penh response', () {
      final g = NominatimGeocoder.parse({
        'display_name': 'x',
        'address': {
          'house_number': '5',
          'road': 'Street 63',
          'suburb': 'Boeung Keng Kang 1',
          'city': 'Phnom Penh',
        },
      });
      expect(g?.line1, '5 Street 63, Boeung Keng Kang 1');
      expect(g?.city, 'Phnom Penh');
    });

    test('falls back to state / display_name; error body -> null', () {
      final g = NominatimGeocoder.parse({
        'display_name': 'Wat Phnom, Daun Penh, Phnom Penh, Cambodia',
        'address': {'state': 'Phnom Penh'},
      });
      expect(g?.line1, 'Wat Phnom, Daun Penh, Phnom Penh');
      expect(g?.city, 'Phnom Penh');
      expect(NominatimGeocoder.parse({'error': 'Unable to geocode'}), isNull);
      expect(NominatimGeocoder.parse('garbage'), isNull);
    });

    test(
      'sends the policy-required params/User-Agent and spaces requests',
      () async {
        final seen = <RequestOptions>[];
        final times = <DateTime>[];
        final dio =
            Dio(
                BaseOptions(
                  baseUrl: 'https://nominatim.openstreetmap.org',
                  headers: {'User-Agent': NominatimGeocoder.userAgent},
                ),
              )
              ..httpClientAdapter = _FakeAdapter((o) {
                seen.add(o);
                times.add(DateTime.now());
                return {
                  'address': {'road': 'R', 'city': 'Phnom Penh'},
                };
              });
        final g = NominatimGeocoder(
          dio: dio,
          minInterval: const Duration(milliseconds: 300),
        );
        await Future.wait([
          g.reverse(11.5, 104.9),
          g.reverse(11.6, 104.8),
          g.reverse(11.7, 104.7),
        ]);
        expect(seen, hasLength(3));
        final q = seen.first.queryParameters;
        expect(seen.first.path, '/reverse');
        expect(q['format'], 'jsonv2');
        expect(q['accept-language'], 'en,km');
        expect(q['lat'], '11.500000');
        expect(q['lon'], '104.900000');
        expect(seen.first.headers['User-Agent'], contains('EcomComputerStore'));
        for (var i = 1; i < times.length; i++) {
          expect(
            times[i].difference(times[i - 1]).inMilliseconds,
            greaterThanOrEqualTo(280),
            reason: 'max 1 request per interval',
          );
        }
      },
    );
  });
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.body);
  final Object Function(RequestOptions) body;
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final json = body(options);
    return ResponseBody.fromString(
      jsonEncode(json),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}
