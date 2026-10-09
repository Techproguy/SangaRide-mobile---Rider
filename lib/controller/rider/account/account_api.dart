import 'package:dio/dio.dart' show Options, Response;

final Options quietOptions = Options(extra: {'suppressErrorToast': true});

abstract final class AccountDeletionEndpoints {
  static const String preview = '/me/deletion-preview';
}

Map<String, dynamic> dataOf(Response response) {
  final body = response.data;
  final data = body is Map ? body['data'] : null;
  return data is Map ? Map<String, dynamic>.from(data) : const {};
}
