import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/support_endpoints.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

abstract final class IssueCategoriesService {
  static Future<List<IssueType>> load(ApiService api) async {
    final response = await api.get(SupportEndpoints.issueCategories, suppressErrorToast: true);
    return JsonReader.of({'categories': (response.data as Map)['data']}).listOf('categories', IssueType.fromReader);
  }
}
