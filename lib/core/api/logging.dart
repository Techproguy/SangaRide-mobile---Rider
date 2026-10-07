part of 'api.dart';

Interceptor _loggingInterceptor() {
  return InterceptorsWrapper(
    onRequest: (options, handler) {
      log('🚀 REQUEST[${options.method}] => PATH: ${options.path}');
      log('📦 DATA: ${options.data}');
      return handler.next(options);
    },
    onResponse: (response, handler) {
      log('✅ RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
      log('📥 DATA: ${response.data}');
      return handler.next(response);
    },
    onError: (error, handler) {
      log('❌ ERROR[${error.response?.statusCode}] => PATH: ${error.requestOptions.path}');
      log('💥 MESSAGE: ${error.response?.statusMessage}');
      return handler.next(error);
    },
  );
}
