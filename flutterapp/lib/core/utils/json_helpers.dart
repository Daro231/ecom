/// Converters for numbers that the API may send as `int` or `double`.
double toDouble(Object? v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

double? toDoubleOrNull(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

/// Parses ISO-8601 local date-times, including 9-digit fractional seconds.
DateTime? toDateTimeOrNull(Object? v) {
  if (v is! String || v.isEmpty) return null;
  return DateTime.tryParse(v);
}

DateTime toDateTime(Object? v) =>
    toDateTimeOrNull(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
