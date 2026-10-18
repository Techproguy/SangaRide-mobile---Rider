import 'dart:developer';

import 'package:sanga_ride/core/services/region_memory.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/app_endpoints.dart';
import 'package:sanga_ride/core/services/session_storage.dart';
import 'package:sanga_ride/core/storage_keys.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart' show JsonReader, ResponseData;
import 'package:sanga_ride/model/models.dart';

class UserController extends GetxController {
  final _api = Get.find<ApiService>();
  final _storage = GetStorage();

  final Rx<UserModel?> _user = Rx<UserModel?>(null);

  UserModel? get user => _user.value;

  @override
  void onInit() {
    super.onInit();
    final cached = _storage.read<Map<String, dynamic>>(SangaStorageKeys.user);
    if (cached == null) return;
    _user.value = UserModel.fromJson(cached);
    RegionMemory.applyPhone(_user.value?.phone);
    SessionStorage.drafts.userScope = _user.value?.id;
  }

  Future<void> fetchMe() async {
    try {
      final tripCount = fetchTripCount();
      final response = await _api.get(AppEndpoints.profile, suppressErrorToast: true);
      final user = UserModel.fromJson(response.dataMap);
      await setUser(user.withTripCount(await tripCount ?? _user.value?.tripCount ?? user.tripCount));
    } catch (e) {
      log('fetchMe failed: $e');
    }
  }

  Future<int?> fetchTripCount() async {
    try {
      final response = await _api.get(
        AppEndpoints.rideRequests,
        queryParameters: {'status': 'completed', 'limit': 1},
        suppressErrorToast: true,
      );
      return JsonReader.of(response.data).objectOrNull('meta')?.intOrNull('total');
    } catch (e) {
      log('trip count failed: $e');
      return null;
    }
  }

  Future<void> setUser(UserModel user) async {
    RegionMemory.applyPhone(user.phone);
    _user.value = user;
    SessionStorage.drafts.userScope = user.id;
    await _storage.write(SangaStorageKeys.user, user.toJson());
  }

  Future<void> clear() async {
    _user.value = null;
    await _storage.remove(SangaStorageKeys.user);
  }
}
