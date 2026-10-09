import 'dart:io';

import 'package:dio/dio.dart' show Response;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' show GetxService;
import 'package:sanga_ride/core/api/api_environment.dart';
import 'package:sanga_ride/core/api/app_endpoints.dart';
import 'package:sanga_ride/core/api/error_handling.dart';
import 'package:sanga_ride/core/api/mock/mock_server.dart';
import 'package:sanga_ride/core/constants.dart';
import 'package:sanga_ride/core/services/session_lifecycle.dart';
import 'package:sanga_ride/core/services/session_storage.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart' show SangaToast, SangaToastTone;
import 'package:sanga_ride_core/sanga_ride_core.dart';

export 'package:sanga_ride/core/api/error_handling.dart';
export 'package:sanga_ride_core/sanga_ride_core.dart' show IdempotencyKey, RequestProfile, UploadRef;

class ApiService extends GetxService {
  ApiService({ApiClient? client}) : client = client ?? _createClient();

  static const String _authPrefix = '/auth';

  final ApiClient client;

  static ApiClient _createClient() {
    return ApiClient(
      ApiClientConfig(
        baseUrl: SangaConstants.baseUrl,
        tokens: SessionStorage.tokens,
        refreshPath: AppEndpoints.refreshToken,
        authPathPrefix: _authPrefix,
        healthPath: AppEndpoints.health,
        onSessionEnded: SessionLifecycle.endFromClient,
        extraInterceptors: [if (ApiEnvironment.usesMock) MockServer.engine],
        logBodies: kDebugMode,
      ),
    );
  }

  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    bool suppressErrorToast = false,
    RequestProfile? profile,
  }) {
    return _guard(
      endpoint,
      suppressErrorToast,
      () => client.get(endpoint, query: queryParameters, profile: profile ?? RequestProfile.background),
    );
  }

  Future<Response> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool suppressErrorToast = false,
    IdempotencyKey? key,
    RequestProfile? profile,
  }) {
    return _guard(
      endpoint,
      suppressErrorToast,
      () => client.post(
        endpoint,
        body: data,
        query: queryParameters,
        key: key,
        profile: profile ?? RequestProfile.interactive,
      ),
    );
  }

  Future<Response> put(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool suppressErrorToast = false,
    IdempotencyKey? key,
    RequestProfile? profile,
  }) {
    return _guard(
      endpoint,
      suppressErrorToast,
      () => client.put(
        endpoint,
        body: data,
        query: queryParameters,
        key: key,
        profile: profile ?? RequestProfile.interactive,
      ),
    );
  }

  Future<Response> patch(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool suppressErrorToast = false,
    IdempotencyKey? key,
    RequestProfile? profile,
  }) {
    return _guard(
      endpoint,
      suppressErrorToast,
      () => client.patch(
        endpoint,
        body: data,
        query: queryParameters,
        key: key,
        profile: profile ?? RequestProfile.interactive,
      ),
    );
  }

  Future<Response> delete(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool suppressErrorToast = false,
    IdempotencyKey? key,
    RequestProfile? profile,
  }) {
    return _guard(
      endpoint,
      suppressErrorToast,
      () => client.delete(
        endpoint,
        body: data,
        query: queryParameters,
        key: key,
        profile: profile ?? RequestProfile.interactive,
      ),
    );
  }

  Future<UploadRef> upload(
    String endpoint, {
    required File file,
    required String purpose,
    String fieldName = 'file',
    Map<String, dynamic>? fields,
    void Function(int sent, int total)? onProgress,
    bool suppressErrorToast = false,
  }) {
    return _guard(
      endpoint,
      suppressErrorToast,
      () => client.upload(
        endpoint,
        file: file,
        purpose: purpose,
        fieldName: fieldName,
        fields: fields,
        onProgress: onProgress,
      ),
    );
  }

  Future<T> _guard<T>(String endpoint, bool suppress, Future<T> Function() call) async {
    try {
      return await call();
    } on ApiException catch (error) {
      if (!suppress) _announce(endpoint, error);
      rethrow;
    }
  }

  void _announce(String endpoint, ApiException error) {
    final message = ApiFailureCopy.toastFor(error, isAuthPath: endpoint.startsWith(_authPrefix));
    if (message != null) SangaToast.show(message, tone: SangaToastTone.error);
  }
}
