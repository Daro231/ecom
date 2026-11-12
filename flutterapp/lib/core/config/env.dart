import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Runtime configuration.
///
/// Base URL resolution order:
///  1. `--dart-define=API_BASE_URL=http://192.168.1.20:8080/api/v1` (real device / any override)
///  2. Android emulator -> `http://10.0.2.2:8080/api/v1`
///  3. iOS simulator / desktop -> `http://localhost:8080/api/v1`
///
/// On a real phone use the LAN IP of the PC that runs the backend (phone and PC
/// must be on the same Wi-Fi), e.g. `flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8080/api/v1`.
class Env {
  Env._();

  static const String _override = String.fromEnvironment('API_BASE_URL');

  /// Coupon advertised on the home banner (a store setting, not product data).
  static const String promoCoupon = String.fromEnvironment(
    'PROMO_COUPON',
    defaultValue: 'WELCOME10',
  );

  static const String merchantName = 'ECOM Computer Store';

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://localhost:8080/api/v1';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8080/api/v1';
    } catch (_) {
      // Platform not available (e.g. web) - fall through.
    }
    return 'http://localhost:8080/api/v1';
  }

  /// Server origin without the `/api/v1` suffix (used for `/uploads/...` images).
  static String get origin {
    final url = baseUrl;
    final i = url.indexOf('/api/');
    return i == -1 ? url : url.substring(0, i);
  }

  /// Turns an image path from the API into an absolute URL that the current
  /// device can reach (relative paths and `localhost` hosts are rewritten).
  static String resolveImage(String url) {
    if (url.isEmpty) return url;
    if (url.startsWith('/')) return '$origin$url';
    if (!url.startsWith('http')) return '$origin/$url';
    final uri = Uri.tryParse(url);
    if (uri != null && (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
      final o = Uri.parse(origin);
      return uri
          .replace(scheme: o.scheme, host: o.host, port: o.port)
          .toString();
    }
    return url;
  }
}
