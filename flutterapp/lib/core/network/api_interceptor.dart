import 'dart:async';

import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'api_exception.dart';

typedef UnauthorizedCallback = FutureOr<void> Function();

/// Adds the bearer token, and converts every failure into a [DioException]
/// whose `error` is a typed [ApiException].
class ApiInterceptor extends Interceptor {
  ApiInterceptor({required this.tokenStorage, this.onUnauthorized});

  final TokenStorage tokenStorage;
  UnauthorizedCallback? onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await tokenStorage.read();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final ex = toApiException(err);
    final isAuthCall = err.requestOptions.path.startsWith('/auth/');
    if (ex.type == ApiErrorType.unauthorized && !isAuthCall) {
      await tokenStorage.clear();
      await onUnauthorized?.call();
    }
    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: ex,
        message: ex.message,
      ),
    );
  }

  static ApiException toApiException(DioException err) {
    if (err.error is ApiException) return err.error as ApiException;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          type: ApiErrorType.timeout,
          message: 'The request timed out. Please try again.',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          type: ApiErrorType.network,
          message: 'No internet connection or the server is unreachable.',
        );
      default:
        break;
    }

    final res = err.response;
    if (res == null) {
      return const ApiException(
        type: ApiErrorType.network,
        message: 'No internet connection or the server is unreachable.',
      );
    }

    final status = res.statusCode;
    String? message;
    var fields = <String, String>{};
    final body = res.data;
    if (body is Map) {
      final m = body['message'];
      if (m is String && m.isNotEmpty) message = m;
      final e = body['errors'];
      if (e is Map) {
        fields = e.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    }
    return ApiException(
      type: ApiException.typeForStatus(status),
      statusCode: status,
      message: message ?? _fallbackMessage(status),
      fieldErrors: fields,
    );
  }

  static String _fallbackMessage(int? status) {
    switch (status) {
      case 401:
        return 'Your session has expired. Please sign in again.';
      case 403:
        return 'You are not allowed to do that.';
      case 404:
        return 'Not found.';
      case 502:
        return 'The payment provider is not available right now.';
      case 504:
        return 'The payment provider timed out.';
      default:
        return 'Server error ($status). Please try again later.';
    }
  }
}
