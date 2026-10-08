import 'package:dio/dio.dart' show Options, Response;

final Options quietOptions = Options(extra: {'suppressErrorToast': true});

Map<String, dynamic> dataOf(Response response) => Map<String, dynamic>.from((response.data as Map)['data'] as Map);
