import 'package:dio/dio.dart';

import '../config/env.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'api_interceptor.dart';

/// Parsed backend envelope `{ success, message, data, errors, timestamp }`.
class ApiEnvelope {
  const ApiEnvelope({
    required this.message,
    required this.data,
    this.timestamp,
  });

  final String message;
  final dynamic data;

  /// Server clock when the response was produced (used for countdowns so the
  /// phone's clock / time zone does not matter).
  final DateTime? timestamp;

  factory ApiEnvelope.fromJson(Object? json) {
    if (json is Map) {
      final ts = json['timestamp'];
      return ApiEnvelope(
        message: (json['message'] as String?) ?? '',
        data: json['data'],
        timestamp: ts is String ? DateTime.tryParse(ts) : null,
      );
    }
    return const ApiEnvelope(message: '', data: null);
  }
}

Dio createDio({
  required TokenStorage tokenStorage,
  UnauthorizedCallback? onUnauthorized,
  String? baseUrl,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl ?? Env.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
      contentType: Headers.jsonContentType,
    ),
  );
  dio.interceptors.add(
    ApiInterceptor(tokenStorage: tokenStorage, onUnauthorized: onUnauthorized),
  );
  return dio;
}

/// Thin wrapper around [Dio] that unwraps the envelope and throws [ApiException].
class ApiClient {
  ApiClient(this.dio);

  final Dio dio;

  Future<ApiEnvelope> get(String path, {Map<String, dynamic>? query}) =>
      _run(() => dio.get<dynamic>(path, queryParameters: query));

  Future<ApiEnvelope> post(String path, {Object? body}) =>
      _run(() => dio.post<dynamic>(path, data: body));

  Future<ApiEnvelope> put(String path, {Object? body}) =>
      _run(() => dio.put<dynamic>(path, data: body));

  Future<ApiEnvelope> patch(String path, {Object? body}) =>
      _run(() => dio.patch<dynamic>(path, data: body));

  Future<ApiEnvelope> delete(String path) =>
      _run(() => dio.delete<dynamic>(path));

  Future<ApiEnvelope> _run(Future<Response<dynamic>> Function() call) async {
    try {
      final res = await call();
      return ApiEnvelope.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiInterceptor.toApiException(e);
    }
  }
}
