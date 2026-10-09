import 'dart:io';

import 'package:dio/dio.dart' show Options, RequestOptions, Response;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' show GetxService;
import 'package:sanga_ride/core/api/api_environment.dart';
import 'package:sanga_ride/core/api/app_endpoints.dart';
import 'package:sanga_ride/core/api/error_handling.dart';
import 'package:sanga_ride/core/api/mock/mock_server.dart';
import 'package:sanga_ride/core/constants.dart';
import 'package:sanga_ride/core/services/session_lifecycle.dart';
import 'package:sanga_ride/core/services/session_storage.dart';
import 'package:sanga_ride/core/services/toast_service.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

export 'package:sanga_ride/core/api/error_handling.dart';
export 'package:sanga_ride_core/sanga_ride_core.dart' show IdempotencyKey, RequestProfile, UploadRef;

class ApiService extends GetxService {
  ApiService({ApiClient? client}) : client = client ?? _createClient();

  static const String _authPrefix = '/auth';
  static const String _suppressKey = 'suppressErrorToast';

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
    Options? options,
    bool suppressErrorToast = false,
    RequestProfile? profile,
  }) {
    return _guard(
      endpoint,
      options,
      suppressErrorToast,
      () => client.get(endpoint, query: queryParameters, profile: profile ?? RequestProfile.background),
    );
  }

  Future<Response> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool suppressErrorToast = false,
    IdempotencyKey? key,
    RequestProfile? profile,
  }) {
    return _guard(
      endpoint,
      options,
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
    Options? options,
    bool suppressErrorToast = false,
    IdempotencyKey? key,
    RequestProfile? profile,
  }) {
    return _guard(
      endpoint,
      options,
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
    Options? options,
    bool suppressErrorToast = false,
    IdempotencyKey? key,
    RequestProfile? profile,
  }) {
    return _guard(
      endpoint,
      options,
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
    Options? options,
    bool suppressErrorToast = false,
    IdempotencyKey? key,
    RequestProfile? profile,
  }) {
    return _guard(
      endpoint,
      options,
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
      null,
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

  Future<Response> uploadFile(
    String endpoint, {
    required File file,
    String fieldName = 'file',
    Map<String, dynamic>? fields,
    void Function(int, int)? onSendProgress,
    bool suppressErrorToast = false,
  }) async {
    final extraFields = {...?fields};
    final purpose = '${extraFields.remove('purpose') ?? ''}';
    final ref = await upload(
      endpoint,
      file: file,
      purpose: purpose,
      fieldName: fieldName,
      fields: extraFields.isEmpty ? null : extraFields,
      onProgress: onSendProgress,
      suppressErrorToast: suppressErrorToast,
    );
    return _envelopeOf(endpoint, ref);
  }

  Response _envelopeOf(String endpoint, UploadRef ref) {
    return Response(
      requestOptions: RequestOptions(path: endpoint),
      statusCode: 200,
      data: {
        'success': true,
        'message': 'Success',
        'data': {'id': ref.id, 'url': ref.url},
      },
    );
  }

  Future<T> _guard<T>(String endpoint, Options? options, bool suppress, Future<T> Function() call) async {
    try {
      return await call();
    } on ApiException catch (error) {
      final isQuiet = suppress || options?.extra?[_suppressKey] == true;
      if (!isQuiet) _announce(endpoint, error);
      rethrow;
    }
  }

  void _announce(String endpoint, ApiException error) {
    final message = ApiFailureCopy.toastFor(error, isAuthPath: endpoint.startsWith(_authPrefix));
    if (message != null) Toast.error(message);
  }
}
