import 'package:dio/dio.dart';
import 'package:sanga_ride/core/api/mock/mock_routes.dart';

class MockRequest {
  final String path;
  final Map<String, dynamic> body;
  final Map<String, dynamic> query;
  final Map<String, String> params;

  const MockRequest({required this.path, required this.body, required this.query, required this.params});
}

class MockFailure implements Exception {
  final int statusCode;
  final String message;
  final String? code;
  final Map<String, dynamic> data;

  const MockFailure(this.statusCode, this.message, {this.code, this.data = const {}});
}

typedef MockHandler = Object? Function(MockRequest request);

class MockRoute {
  final String method;
  final MockHandler handler;
  final RegExp _pattern;
  final List<String> _paramNames;

  MockRoute(this.method, String path, this.handler)
    : _paramNames = RegExp(r':(\w+)').allMatches(path).map((m) => m.group(1)!).toList(),
      _pattern = RegExp('^${path.replaceAll(RegExp(r':\w+'), '([^/]+)')}\$');

  MockRoute.get(String path, MockHandler handler) : this('GET', path, handler);

  MockRoute.post(String path, MockHandler handler) : this('POST', path, handler);

  MockRoute.patch(String path, MockHandler handler) : this('PATCH', path, handler);

  MockRoute.delete(String path, MockHandler handler) : this('DELETE', path, handler);

  Map<String, String>? match(String method, String path) {
    if (method != this.method) return null;
    final match = _pattern.firstMatch(path);
    if (match == null) return null;
    return {for (var i = 0; i < _paramNames.length; i++) _paramNames[i]: match.group(i + 1)!};
  }
}

class MockServerInterceptor extends Interceptor {
  static const Duration _latency = Duration(milliseconds: 400);

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    await Future<void>.delayed(_latency);
    final (statusCode, body) = _respond(options);
    final response = Response(requestOptions: options, statusCode: statusCode, data: body);
    if (statusCode >= 400) {
      handler.reject(
        DioException.badResponse(statusCode: statusCode, requestOptions: options, response: response),
        true,
      );
    } else {
      handler.resolve(response, true);
    }
  }

  (int, Map<String, dynamic>) _respond(RequestOptions options) {
    final method = options.method.toUpperCase();
    final path = Uri.parse(options.path).path;
    for (final route in MockRoutes.all) {
      final params = route.match(method, path);
      if (params == null) continue;
      final request = MockRequest(
        path: path,
        body: options.data is Map<String, dynamic> ? options.data as Map<String, dynamic> : const {},
        query: options.queryParameters,
        params: params,
      );
      try {
        return (200, {'success': true, 'message': 'Success', 'data': route.handler(request)});
      } on MockFailure catch (failure) {
        return (
          failure.statusCode,
          {...failure.data, 'success': false, 'message': failure.message, 'code': ?failure.code},
        );
      }
    }
    return (404, {'success': false, 'message': 'No mock for $method $path'});
  }
}
