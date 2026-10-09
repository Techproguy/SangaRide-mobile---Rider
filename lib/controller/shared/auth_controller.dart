import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/shared/user_controller.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/app_endpoints.dart';
import 'package:sanga_ride/core/services/session_restore.dart';
import 'package:sanga_ride/core/services/session_storage.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart' show SessionEndReason, SessionHub;

enum AuthProvider { google, apple }

enum OtpPurpose { login, registration }

class AuthController extends GetxController {
  static const otpLength = 4;
  static const Duration logoutRevokeCap = Duration(seconds: 3);

  final _api = Get.find<ApiService>();

  final RxBool _isSendingCode = false.obs;
  final RxBool _isVerifying = false.obs;
  final Rxn<AuthProvider> _signingInWith = Rxn<AuthProvider>();
  final RxnString _otpError = RxnString();
  final RxnString _phoneError = RxnString();

  bool get isSendingCode => _isSendingCode.value;

  bool get isVerifying => _isVerifying.value;

  AuthProvider? get signingInWith => _signingInWith.value;

  String? get otpError => _otpError.value;

  String? get phoneError => _phoneError.value;

  bool get isSignedIn => SessionStorage.tokens.hasSession;

  void clearOtpError() => _otpError.value = null;

  void clearPhoneError() => _phoneError.value = null;

  Future<bool> isRegistered(String phone) async {
    final response = await _api.post(AppEndpoints.checkExistence, data: {'phone': phone, 'userType': 'rider'});
    return response.data['data']['exists'] == true;
  }

  Future<bool> requestOtp(String phone, {required OtpPurpose purpose}) async {
    _isSendingCode.value = true;
    _phoneError.value = null;
    try {
      await _api.post(
        AppEndpoints.requestOtp,
        data: {'phone': phone, 'purpose': purpose.name},
        suppressErrorToast: purpose == OtpPurpose.login,
      );
      return true;
    } on ApiException catch (e) {
      if (purpose == OtpPurpose.login) _phoneError.value = e.message;
      return false;
    } catch (e) {
      log('requestOtp failed: $e');
      return false;
    } finally {
      _isSendingCode.value = false;
    }
  }

  Future<bool> verifyOtp({required String phone, required String code}) async {
    _isVerifying.value = true;
    _otpError.value = null;
    try {
      final response = await _api.post(
        AppEndpoints.verifyOtp,
        data: {'phone': phone, 'code': code},
        suppressErrorToast: true,
      );
      await _startSession(response.data['data'] as Map<String, dynamic>);
      return true;
    } on ApiException catch (e) {
      _otpError.value = e.message;
      return false;
    } catch (e) {
      log('verifyOtp failed: $e');
      _otpError.value = "We couldn't check that code. Try again.";
      return false;
    } finally {
      _isVerifying.value = false;
    }
  }

  Future<bool> continueWith(AuthProvider provider) async {
    _signingInWith.value = provider;
    try {
      final endpoint = switch (provider) {
        AuthProvider.google => AppEndpoints.googleSignIn,
        AuthProvider.apple => AppEndpoints.appleSignIn,
      };
      final response = await _api.post(endpoint);
      await _startSession(response.data['data'] as Map<String, dynamic>);
      return true;
    } catch (e) {
      log('continueWith $provider failed: $e');
      return false;
    } finally {
      _signingInWith.value = null;
    }
  }

  Future<void> logout() async {
    await _revokeSession();
    await SessionHub.instance.end(SessionEndReason.loggedOut);
  }

  Future<void> _revokeSession() async {
    try {
      await _api.post(AppEndpoints.logout, suppressErrorToast: true).timeout(logoutRevokeCap);
    } catch (e) {
      log('logout request failed: ${e.runtimeType}');
    }
  }

  Future<void> _startSession(Map<String, dynamic> data) async {
    final tokens = data['tokens'] as Map<String, dynamic>;
    await SessionStorage.tokens.save(
      accessToken: tokens['accessToken'] as String,
      refreshToken: tokens['refreshToken'] as String?,
    );
    await Get.find<UserController>().setUser(UserModel.fromJson(data['user'] as Map<String, dynamic>));
    unawaited(Get.find<SessionRestore>().refreshQuietly());
  }
}
