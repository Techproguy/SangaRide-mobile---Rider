part of 'api.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? code;
  final Map<String, dynamic> data;

  const ApiException(this.statusCode, this.message, {this.code, this.data = const {}});

  @override
  String toString() => message;
}

Future<Exception> _handleDioError(DioException error) async {
  final suppressToast = error.requestOptions.extra['suppressErrorToast'] == true;
  void toast(String message) {
    if (!suppressToast) Toast.error(message);
  }

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      toast('Connection timed out. Please check your internet and try again.');
      return Exception('Connection timeout.');

    case DioExceptionType.badResponse:
      return _handleStatusCode(
        error.response?.statusCode,
        error.response?.data,
        isAuthEndpoint: error.requestOptions.path.contains('/auth/'),
        suppressToast: suppressToast,
      );

    case DioExceptionType.cancel:
      return Exception('Request was cancelled.');

    case DioExceptionType.connectionError:
      if (await _hasInternetAccess()) {
        toast('Server is unreachable. Please try again later.');
        return Exception('Server unreachable.');
      }
      toast('No internet connection. Please check your network and try again.');
      return Exception('No internet connection.');

    default:
      toast("Couldn't reach the server. Check your connection and try again.");
      return Exception('Unexpected error occurred.');
  }
}

Exception _handleStatusCode(
  int? statusCode,
  dynamic responseData, {
  bool isAuthEndpoint = false,
  bool suppressToast = false,
}) {
  final message = _extractUserFriendlyMessage(responseData);
  final body = responseData is Map ? Map<String, dynamic>.from(responseData) : const <String, dynamic>{};
  final code = body['code'] is String ? body['code'] as String : null;

  final isSilent4xx = (statusCode == 401 || statusCode == 403) && !isAuthEndpoint;
  final isClientError = statusCode != null && statusCode >= 400 && statusCode < 500;
  if (message != null && isClientError && !isSilent4xx && !suppressToast) {
    Toast.error(message);
  }

  ApiException api(int status, String fallback) => ApiException(status, message ?? fallback, code: code, data: body);

  return switch (statusCode) {
    400 => api(400, 'Bad request'),
    401 => api(401, 'Unauthorized. Please login again.'),
    403 => api(403, 'Access forbidden'),
    404 => api(404, 'Resource not found'),
    409 => api(409, 'Conflict'),
    410 => api(410, 'This is no longer available'),
    422 => api(422, 'Invalid request. Please check your input.'),
    500 || 502 => Exception('Server error. Please try again later.'),
    503 => Exception('Service unavailable. Please try again later.'),
    _ => api(statusCode ?? 0, 'Unexpected error occurred. Please try again.'),
  };
}

String? _extractUserFriendlyMessage(dynamic responseData) {
  String? raw;

  if (responseData is Map<String, dynamic>) {
    final errors = responseData['errors'];
    if (errors is List && errors.isNotEmpty) {
      final messages = errors
          .whereType<Map<String, dynamic>>()
          .map((e) => e['message']?.toString())
          .whereType<String>()
          .toList();
      if (messages.isNotEmpty) raw = messages.join('. ');
    } else if (errors is Map && errors.isNotEmpty) {
      raw = errors.values.expand((e) => e is List ? e : [e]).join(', ');
    }
    if (raw == null || raw.isEmpty) {
      raw = (responseData['message'] ?? responseData['error'])?.toString();
    }
  } else if (responseData is String) {
    raw = responseData;
  }

  if (raw == null || raw.isEmpty || _isTechnicalMessage(raw)) return null;
  return raw;
}

Future<bool> _hasInternetAccess() async {
  try {
    final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 2));
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}

const _opaqueMessages = {
  'network error',
  'internal server error',
  'bad gateway',
  'gateway timeout',
  'service unavailable',
  'too many requests',
  'request failed',
  'request error',
  'unknown error',
  'error',
};

const _stackTraceFingerprints = [
  'econnrefused',
  'typeerror:',
  'referenceerror:',
  'syntaxerror:',
  'cannot read propert',
  'is not a function',
  'stack trace',
];

bool _isTechnicalMessage(String message) {
  final lower = message.toLowerCase().trim();
  if (RegExp(r'^cannot (get|post|patch|put|delete) ').hasMatch(lower)) return true;
  if (_opaqueMessages.contains(lower)) return true;
  if (message.length > 300) return true;
  return _stackTraceFingerprints.any(lower.contains);
}
