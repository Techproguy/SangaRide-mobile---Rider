import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

Map<String, dynamic> safetyDataOf(dynamic body) => JsonReader.of(JsonReader.of(body).raw['data']).raw;

SafetyProblem safetyProblemOf(Object error) => SafetyProblem.of(error);
