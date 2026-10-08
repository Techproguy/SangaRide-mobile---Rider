import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/model/models.dart';

Map<String, dynamic> safetyDataOf(dynamic body) => Map<String, dynamic>.from((body as Map)['data'] as Map);

SafetyProblem safetyProblemOf(Object error) {
  if (error is ApiException) return SafetyProblem.fromCode(error.code);
  return SafetyProblem.connection;
}
