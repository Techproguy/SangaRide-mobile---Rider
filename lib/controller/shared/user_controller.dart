import 'dart:developer';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/app_endpoints.dart';
import 'package:sanga_ride/core/services/session_storage.dart';
import 'package:sanga_ride/core/storage_keys.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart' show ResponseData;
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
    SessionStorage.drafts.userScope = _user.value?.id;
  }

  Future<void> fetchMe() async {
    try {
      final response = await _api.get(AppEndpoints.me, suppressErrorToast: true);
      await setUser(UserModel.fromJson(response.dataMap));
    } catch (e) {
      log('fetchMe failed: $e');
    }
  }

  Future<void> setUser(UserModel user) async {
    _user.value = user;
    SessionStorage.drafts.userScope = user.id;
    await _storage.write(SangaStorageKeys.user, user.toJson());
  }

  Future<void> clear() async {
    _user.value = null;
    await _storage.remove(SangaStorageKeys.user);
  }
}
