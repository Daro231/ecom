import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Address text for a coordinate. Either field may be null.
class GeocodeResult {
  const GeocodeResult({this.line1, this.city});
  final String? line1;
  final String? city;

  bool get isEmpty => (line1 ?? '').isEmpty && (city ?? '').isEmpty;
}

abstract class Geocoder {
  /// Returns null when nothing is found. Throws on network / server errors.
  Future<GeocodeResult?> reverse(double latitude, double longitude);
}

/// OpenStreetMap Nominatim reverse geocoding.
///
/// Follows the usage policy (https://operations.osmfoundation.org/policies/nominatim/):
/// at most one request per second (enforced here, on top of the caller's
/// debounce) and an identifying User-Agent. Browsers do not allow scripts to
/// set `User-Agent`; they send their own plus the page `Referer`, which the
/// policy accepts for web apps.
class NominatimGeocoder implements Geocoder {
  NominatimGeocoder({Dio? dio, this.minInterval = const Duration(seconds: 1)})
    : _dio = dio ?? _defaultDio();

  static const userAgent =
      'EcomComputerStore-MobileApp/1.0 (+https://github.com/ecom-store; address lookup)';

  final Dio _dio;
  final Duration minInterval;
  DateTime? _last;
  Future<void> _queue = Future.value();

  static Dio _defaultDio() => Dio(
    BaseOptions(
      baseUrl: 'https://nominatim.openstreetmap.org',
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      headers: {if (!kIsWeb) 'User-Agent': userAgent},
    ),
  );

  /// Serialises calls and spaces them [minInterval] apart.
  Future<T> _throttled<T>(Future<T> Function() run) {
    final completer = Completer<T>();
    _queue = _queue.then((_) async {
      final last = _last;
      if (last != null) {
        final wait = minInterval - DateTime.now().difference(last);
        if (!wait.isNegative) await Future<void>.delayed(wait);
      }
      _last = DateTime.now();
      try {
        completer.complete(await run());
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  @override
  Future<GeocodeResult?> reverse(double latitude, double longitude) =>
      _throttled(() async {
        final r = await _dio.get<Object?>(
          '/reverse',
          queryParameters: {
            'format': 'jsonv2',
            'lat': latitude.toStringAsFixed(6),
            'lon': longitude.toStringAsFixed(6),
            'accept-language': 'en,km',
            'addressdetails': 1,
          },
        );
        return parse(r.data);
      });

  /// Public for tests.
  ///
  /// In Cambodia Nominatim puts the *district* (Khan) in `town`/`city_district`
  /// and the sangkat/phum in `village`/`hamlet`/`suburb`, so those go into the
  /// address line. The City field is the city or province only:
  /// `city ?? state ?? province` (e.g. "Phnom Penh", "Siem Reap").
  static GeocodeResult? parse(Object? data) {
    if (data is! Map || data['error'] != null) return null;
    final a = (data['address'] is Map)
        ? (data['address'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    String? s(String k) {
      final v = a[k];
      return (v is String && v.trim().isNotEmpty) ? v.trim() : null;
    }

    final city = s('city') ?? s('state') ?? s('province');

    final street = [
      s('house_number'),
      s('road'),
    ].whereType<String>().join(' ').trim();
    // Smallest area first: phum / sangkat / quarter, then the khan (district).
    final parts = <String>[
      if (street.isNotEmpty) street,
      for (final k in const [
        'hamlet',
        'village',
        'neighbourhood',
        'quarter',
        'suburb',
        'city_district',
        'district',
        'town',
        'municipality',
      ])
        ?s(k),
    ];
    final seen = <String>{if (city != null) city.toLowerCase()};
    final line = [
      for (final p in parts)
        if (seen.add(p.toLowerCase())) p,
    ].join(', ');
    var line1 = line;
    if (line1.isEmpty) {
      // Fall back to the first parts of the display name.
      final dn = (data['display_name'] as String?) ?? '';
      line1 = dn.split(',').map((e) => e.trim()).take(3).join(', ');
    }
    final result = GeocodeResult(
      line1: line1.isEmpty ? null : line1,
      city: city,
    );
    return result.isEmpty ? null : result;
  }
}

final geocoderProvider = Provider<Geocoder>((ref) => NominatimGeocoder());
