import 'package:intl/intl.dart';

final NumberFormat _usd = NumberFormat.currency(locale: 'en_US', symbol: r'$');

/// `1299` -> `$1,299.00`
String formatUsd(num value) => _usd.format(value);

/// `2026-11-04T15:43:17` -> `Nov 4, 2026 · 3:43 PM`
String formatDateTime(DateTime? d) =>
    d == null ? '-' : DateFormat('MMM d, y · h:mm a').format(d);

String formatDate(DateTime? d) =>
    d == null ? '-' : DateFormat('MMM d, y').format(d);

/// `ECOM_ORDER` / `PAID_AFTER_CANCEL` -> `Paid after cancel`
String humanizeEnum(String value) {
  final s = value.replaceAll('_', ' ').toLowerCase();
  return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

/// Display names for payment / shipping enum codes from the API.
const _enumLabels = {
  'KHQR': 'KHQR',
  'CASH_ON_DELIVERY': 'Cash on Delivery',
  'COD': 'Cash on Delivery',
  'CARD': 'Card',
  'BANK_TRANSFER': 'Bank Transfer',
  'STANDARD': 'Standard',
  'EXPRESS': 'Express',
  'SAME_DAY': 'Same Day',
};

/// `CASH_ON_DELIVERY` -> `Cash on Delivery`, `KHQR` -> `KHQR`; unknown codes
/// fall back to [humanizeEnum].
String enumLabel(String value) =>
    _enumLabels[value.toUpperCase()] ?? humanizeEnum(value);

/// `mm:ss` countdown text.
String formatCountdown(Duration d) {
  final total = d.isNegative ? 0 : d.inSeconds;
  final m = (total ~/ 60).toString().padLeft(2, '0');
  final s = (total % 60).toString().padLeft(2, '0');
  return '$m:$s';
}
