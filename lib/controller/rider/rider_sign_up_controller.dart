import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/shared/auth_controller.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/mock/mock_endpoints.dart';
import 'package:sanga_ride/core/api/places_endpoints.dart';
import 'package:sanga_ride/model/models.dart';

class RiderSignUpController extends GetxController {
  final _api = Get.find<ApiService>();

  final RxBool _isSaving = false.obs;
  final RxnString _phoneError = RxnString();

  bool get isSaving => _isSaving.value;

  String? get phoneError => _phoneError.value;

  void clearPhoneError() => _phoneError.value = null;

  Future<bool> start({required String firstName, required String lastName, required String phone}) async {
    _isSaving.value = true;
    try {
      if (await Get.find<AuthController>().isRegistered(phone)) {
        _phoneError.value = 'This number already has an account.';
        return false;
      }
      await _api.post(MockEndpoints.signUp, data: {'firstName': firstName, 'lastName': lastName, 'phone': phone});
      return true;
    } catch (e) {
      log('start sign up failed: $e');
      return false;
    } finally {
      _isSaving.value = false;
    }
  }

  Future<bool> saveProfile({required String email, DateTime? birthday, String? referralCode}) {
    return _save(
      () => _api.patch(
        MockEndpoints.me,
        data: {'email': email, 'birthday': ?birthday?.toIso8601String(), 'referralCode': ?referralCode},
      ),
    );
  }

  Future<bool> verifySelfie(String photoPath) async {
    try {
      final response = await _api.post(MockEndpoints.selfie, data: {'photo': photoPath}, suppressErrorToast: true);
      return response.data['data']['status'] == 'verified';
    } catch (e) {
      log('verifySelfie failed: $e');
      return false;
    }
  }

  Future<bool> saveHome(Place place) => _save(
    () => _api.post(PlacesEndpoints.saved, data: {'kind': 'home', 'label': 'Home', 'place': place.toJson()}),
  );

  Future<bool> _save(Future<Object?> Function() request) async {
    _isSaving.value = true;
    try {
      await request();
      return true;
    } catch (e) {
      log('sign up step failed: $e');
      return false;
    } finally {
      _isSaving.value = false;
    }
  }
}
