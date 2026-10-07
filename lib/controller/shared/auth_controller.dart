import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/shared/user_controller.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/mock/mock_endpoints.dart';
import 'package:sanga_ride/core/router/router.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/core/services/secure_token_store.dart';
import 'package:sanga_ride/model/models.dart';

class AuthController extends GetxController {
  final _api = Get.find<ApiService>();

  final RxBool _isLoading = false.obs;

  bool get isLoading => _isLoading.value;

  bool get isSignedIn => SecureTokenStore.instance.hasSession;

  Future<bool> requestOtp(String phone) async {
    _isLoading.value = true;
    try {
      await _api.post(MockEndpoints.requestOtp, data: {'phone': phone});
      return true;
    } catch (e) {
      log('requestOtp failed: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> verifyOtp({required String phone, required String code}) async {
    _isLoading.value = true;
    try {
      final response = await _api.post(MockEndpoints.verifyOtp, data: {'phone': phone, 'code': code});
      final data = response.data['data'] as Map<String, dynamic>;
      final tokens = data['tokens'] as Map<String, dynamic>;
      await SecureTokenStore.instance.saveSession(
        accessToken: tokens['accessToken'] as String,
        refreshToken: tokens['refreshToken'] as String?,
      );
      await Get.find<UserController>().setUser(UserModel.fromJson(data['user'] as Map<String, dynamic>));
      return true;
    } catch (e) {
      log('verifyOtp failed: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.post(MockEndpoints.logout);
    } catch (e) {
      log('logout request failed: $e');
    }
    await SecureTokenStore.instance.clear();
    await Get.find<UserController>().clear();
    SangaRouter.router.go(SangaRoutes.getStarted);
  }
}
