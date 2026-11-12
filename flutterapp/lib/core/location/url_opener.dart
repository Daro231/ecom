import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens [url] outside the app (replaceable in tests).
typedef UrlOpener = Future<bool> Function(Uri url);

Future<bool> _launch(Uri url) async {
  try {
    return await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

final urlOpenerProvider = Provider<UrlOpener>((ref) => _launch);

Uri googleMapsUri(double lat, double lng) =>
    Uri.parse('https://www.google.com/maps?q=$lat,$lng');
