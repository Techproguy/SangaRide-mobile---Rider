import 'dart:developer';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/app_endpoints.dart';
import 'package:sanga_ride/core/storage_keys.dart';
import 'package:sanga_ride/model/models.dart';

class UserController extends GetxController {
  final _api = Get.find<ApiService>();
  final _storage = GetStorage();

  final Rx<UserModel?> _user = Rx<UserModel?>(null);
  final RxBool _isSaving = false.obs;

  UserModel? get user => _user.value;

  bool get isSaving => _isSaving.value;

  @override
  void onInit() {
    super.onInit();
    final cached = _storage.read<Map<String, dynamic>>(SangaStorageKeys.user);
    if (cached != null) _user.value = UserModel.fromJson(cached);
  }

  Future<void> fetchMe() async {
    try {
      final response = await _api.get(AppEndpoints.me, suppressErrorToast: true);
      await setUser(UserModel.fromJson(response.data['data'] as Map<String, dynamic>));
    } catch (e) {
      log('fetchMe failed: $e');
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> fields) async {
    _isSaving.value = true;
    try {
      final response = await _api.patch(AppEndpoints.me, data: fields);
      await setUser(UserModel.fromJson(response.data['data'] as Map<String, dynamic>));
      return true;
    } catch (e) {
      log('updateProfile failed: $e');
      return false;
    } finally {
      _isSaving.value = false;
    }
  }

  Future<void> setUser(UserModel user) async {
    _user.value = user;
    await _storage.write(SangaStorageKeys.user, user.toJson());
  }

  Future<void> clear() async {
    _user.value = null;
    await _storage.remove(SangaStorageKeys.user);
  }
}
