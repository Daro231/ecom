import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Why a position could not be obtained.
enum LocationProblem {
  /// The user refused the permission prompt (can ask again).
  denied,

  /// Refused with "don't ask again" - only the system settings can fix it.
  deniedForever,

  /// GPS / location services are switched off on the device.
  serviceOff,

  /// No fix within the time limit.
  timeout,

  /// Anything else (unsupported platform, plugin error...).
  failed,
}

/// Result of [LocationService.current]. Never throws.
class LocationResult {
  const LocationResult.ok(this.latitude, this.longitude, {this.accuracy})
    : problem = null;
  const LocationResult.fail(this.problem)
    : latitude = null,
      longitude = null,
      accuracy = null;

  final double? latitude;
  final double? longitude;

  /// Horizontal accuracy radius in metres (Position.accuracy), if known.
  final double? accuracy;
  final LocationProblem? problem;

  bool get isOk => problem == null;

  /// User-facing explanation (null when ok).
  String? get message => switch (problem) {
    null => null,
    LocationProblem.denied =>
      'Location permission was denied. You can still tap the map to place the pin.',
    LocationProblem.deniedForever =>
      'Location permission is blocked. Enable it in your browser/app settings, or tap the map to place the pin.',
    LocationProblem.serviceOff =>
      'Location is turned off on this device. Turn it on, or tap the map to place the pin.',
    LocationProblem.timeout =>
      'Could not get your location in time. Showing Phnom Penh - tap the map to place the pin.',
    LocationProblem.failed =>
      'Could not get your location. Tap the map to place the pin.',
  };
}

/// Fixes worse than this (metres) get an "approximate" warning.
const approximateAccuracyMeters = 100.0;

/// `±350 m`, `±2.5 km`.
String formatAccuracy(double meters) => meters >= 1000
    ? '±${(meters / 1000).toStringAsFixed(1)} km'
    : '±${meters.round()} m';

/// Warning for a coarse fix (null when accurate enough or unknown).
String? accuracyWarning(double? meters) =>
    (meters == null || meters <= approximateAccuracyMeters)
    ? null
    : 'Your location is approximate (${formatAccuracy(meters)}). '
          'Please drag the pin to your exact location.';

abstract class LocationService {
  Future<LocationResult> current();
}

/// Real implementation (geolocator: Android, iOS and web).
class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService({this.timeout = const Duration(seconds: 15)});
  final Duration timeout;

  /// Best accuracy on mobile (GPS); `high` on the web, where browsers choose
  /// between GPS and network location themselves.
  static LocationSettings settingsFor({
    required bool web,
    required Duration timeout,
  }) => LocationSettings(
    accuracy: web ? LocationAccuracy.high : LocationAccuracy.best,
    timeLimit: timeout,
  );

  @override
  Future<LocationResult> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult.fail(LocationProblem.serviceOff);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult.fail(LocationProblem.deniedForever);
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        return const LocationResult.fail(LocationProblem.denied);
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: settingsFor(web: kIsWeb, timeout: timeout),
      ).timeout(timeout + const Duration(seconds: 2));
      return LocationResult.ok(p.latitude, p.longitude, accuracy: p.accuracy);
    } on TimeoutException {
      return const LocationResult.fail(LocationProblem.timeout);
    } on LocationServiceDisabledException {
      return const LocationResult.fail(LocationProblem.serviceOff);
    } on PermissionDeniedException {
      return const LocationResult.fail(LocationProblem.denied);
    } catch (_) {
      return const LocationResult.fail(LocationProblem.failed);
    }
  }
}

final locationServiceProvider = Provider<LocationService>(
  (ref) => const GeolocatorLocationService(),
);
