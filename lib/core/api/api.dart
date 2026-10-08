import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;
import 'package:get_storage/get_storage.dart';
import 'package:sanga_ride/core/api/mock/mock_server.dart';
import 'package:sanga_ride/core/constants.dart';
import 'package:sanga_ride/core/router/router.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/core/services/secure_token_store.dart';
import 'package:sanga_ride/core/services/toast_service.dart';
import 'package:sanga_ride/core/storage_keys.dart';

part 'error_handling.dart';

part 'status_code.dart';

part 'logging.dart';

class ApiService extends GetxService {
  static const Duration _connectTimeout = Duration(seconds: 30);
  static const Duration _receiveTimeout = Duration(seconds: 30);

  late final Dio _dio = _createDio();

  Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: SangaConstants.baseUrl,
        connectTimeout: _connectTimeout,
        receiveTimeout: _receiveTimeout,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      ),
    );
    if (kDebugMode) dio.interceptors.add(_loggingInterceptor());
    dio.interceptors.add(_accessTokenInterceptor());
    dio.interceptors.add(_retryInterceptor(dio));
    dio.interceptors.add(_unauthorizedInterceptor());
    dio.interceptors.add(MockServerInterceptor());
    return dio;
  }

  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool suppressErrorToast = false,
  }) async {
    try {
      final effectiveOptions = suppressErrorToast
          ? (options ?? Options()).copyWith(extra: {...?options?.extra, 'suppressErrorToast': true})
          : options;
      return await _dio.get(endpoint, queryParameters: queryParameters, options: effectiveOptions);
    } on DioException catch (e) {
      throw await _handleDioError(e);
    }
  }

  Future<Response> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool suppressErrorToast = false,
  }) async {
    try {
      final effectiveOptions = suppressErrorToast
          ? (options ?? Options()).copyWith(extra: {...?options?.extra, 'suppressErrorToast': true})
          : options;
      return await _dio.post(endpoint, data: data, queryParameters: queryParameters, options: effectiveOptions);
    } on DioException catch (e) {
      throw await _handleDioError(e);
    }
  }

  Future<Response> put(String endpoint, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      return await _dio.put(endpoint, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw await _handleDioError(e);
    }
  }

  Future<Response> patch(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch(endpoint, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw await _handleDioError(e);
    }
  }

  Future<Response> delete(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(endpoint, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw await _handleDioError(e);
    }
  }

  Future<Response> uploadFile(
    String endpoint, {
    required File file,
    String fieldName = 'file',
    Map<String, dynamic>? fields,
    void Function(int, int)? onSendProgress,
    bool suppressErrorToast = false,
  }) async {
    try {
      final formData = FormData.fromMap({
        ...?fields,
        fieldName: await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
      });
      return await _dio.post(
        endpoint,
        data: formData,
        onSendProgress: onSendProgress,
        options: suppressErrorToast ? Options(extra: {'suppressErrorToast': true}) : null,
      );
    } on DioException catch (e) {
      throw await _handleDioError(e);
    }
  }

  Interceptor _accessTokenInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.headers['requiresAuth'] == false) {
          options.headers.remove('requiresAuth');
          return handler.next(options);
        }
        final token = SecureTokenStore.instance.accessToken;
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        return handler.next(options);
      },
    );
  }

  Interceptor _retryInterceptor(Dio dio) {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        final isTimeout =
            error.type == DioExceptionType.connectionTimeout || error.type == DioExceptionType.receiveTimeout;
        final retries = error.requestOptions.extra['retries'] as int? ?? 0;
        if (!isTimeout || retries >= 3) return handler.next(error);

        error.requestOptions.extra['retries'] = retries + 1;
        await Future.delayed(Duration(seconds: retries + 1));
        try {
          return handler.resolve(await dio.fetch(error.requestOptions));
        } catch (_) {
          return handler.next(error);
        }
      },
    );
  }

  Interceptor _unauthorizedInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) {
        final isAuthEndpoint = error.requestOptions.path.contains('/auth/');
        if (error.response?.statusCode == 401 && !isAuthEndpoint) _handleUnauthorized();
        return handler.next(error);
      },
    );
  }

  bool _handlingUnauthorized = false;

  void _handleUnauthorized() {
    if (_handlingUnauthorized) return;
    _handlingUnauthorized = true;
    Toast.warning('Your session has expired. Please log in again.');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await SecureTokenStore.instance.clear();
      await GetStorage().remove(SangaStorageKeys.user);
      SangaRouter.router.go(SangaRoutes.onboarding);
      _handlingUnauthorized = false;
    });
  }
}
