enum ApiErrorType {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  validation,
  conflict,
  badGateway,
  gatewayTimeout,
  server,
  unknown,
}

/// Typed error produced by the API layer. [message] is the backend `message`
/// whenever one was sent; [fieldErrors] is the backend `errors` map.
class ApiException implements Exception {
  const ApiException({
    required this.type,
    required this.message,
    this.statusCode,
    this.fieldErrors = const {},
  });

  final ApiErrorType type;
  final String message;
  final int? statusCode;
  final Map<String, String> fieldErrors;

  bool get isConnectivity =>
      type == ApiErrorType.network || type == ApiErrorType.timeout;

  /// 502 / 504 from the KHQR status endpoint: provider problem, not a payment failure.
  bool get isProviderProblem =>
      type == ApiErrorType.badGateway || type == ApiErrorType.gatewayTimeout;

  static ApiErrorType typeForStatus(int? status) {
    switch (status) {
      case 400:
      case 422:
        return ApiErrorType.validation;
      case 401:
        return ApiErrorType.unauthorized;
      case 403:
        return ApiErrorType.forbidden;
      case 404:
        return ApiErrorType.notFound;
      case 409:
        return ApiErrorType.conflict;
      case 502:
        return ApiErrorType.badGateway;
      case 504:
        return ApiErrorType.gatewayTimeout;
      case null:
        return ApiErrorType.unknown;
      default:
        return status >= 500 ? ApiErrorType.server : ApiErrorType.unknown;
    }
  }

  @override
  String toString() => 'ApiException($statusCode, $type, $message)';
}

/// Message for any thrown object, suitable for a SnackBar.
String errorMessage(Object error) {
  if (error is ApiException) return error.message;
  return 'Something went wrong. Please try again.';
}
