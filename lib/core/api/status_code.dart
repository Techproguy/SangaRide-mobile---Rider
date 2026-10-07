part of 'api.dart';

extension ResponseSuccessExtension<T> on Response<T> {
  bool get isSuccess {
    final code = statusCode;
    return code != null && code >= 200 && code < 300;
  }
}
