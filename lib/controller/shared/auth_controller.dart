import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/shared/user_controller.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/api_environment.dart';
import 'package:sanga_ride/core/api/app_endpoints.dart';
import 'package:sanga_ride/core/services/session_restore.dart';
import 'package:sanga_ride/core/services/session_storage.dart';
import 'package:sanga_ride/model/auth/otp_session.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart' show ConnectionMonitor, SessionEndReason, SessionHub;
import 'package:sanga_ride_ui/sanga_ride_ui.dart' show SangaToast, SangaToastTone;

enum AuthProvider { google, apple }

enum OtpPurpose { login, registration }

typedef ProviderTokenSource = Future<String?> Function(AuthProvider provider);

class AuthController extends GetxController {
  static const otpLength = 4;
  static const Duration logoutRevokeCap = Duration(seconds: 3);

  static ProviderTokenSource? providerTokens;

  static bool get providersAvailable => providerTokens != null || ApiEnvironment.usesMock;

  final _api = Get.find<ApiService>();

  final RxBool _isSendingCode = false.obs;
  final RxBool _isVerifying = false.obs;
  final Rxn<AuthProvider> _signingInWith = Rxn<AuthProvider>();
  final RxnString _otpError = RxnString();
  final RxnString _phoneError = RxnString();
  final RxnString _requestError = RxnString();

  bool get isSendingCode => _isSendingCode.value;

  bool get isVerifying => _isVerifying.value;

  AuthProvider? get signingInWith => _signingInWith.value;

  String? get otpError => _otpError.value;

  String? get phoneError => _phoneError.value;

  String? get requestError => _requestError.value;

  bool get isSignedIn => SessionStorage.tokens.hasSession;

  void clearOtpError() => _otpError.value = null;

  void clearPhoneError() {
    _phoneError.value = null;
    _requestError.value = null;
  }

  Future<bool> isRegistered(String phone) async {
    final response = await _api.post(AppEndpoints.checkExistence, data: {'phone': phone, 'userType': 'rider'});
    return response.data['data']['exists'] == true;
  }

  bool get _isOffline => ConnectionMonitor.current?.isOnline == false;

  Future<OtpRequestResult> requestOtp(String phone, {required OtpPurpose purpose}) async {
    if (_isSendingCode.value) return const OtpNotSent('');
    _phoneError.value = null;
    _requestError.value = null;
    if (_isOffline) return _failRequest(AuthProblem.offline.message, purpose);
    _isSendingCode.value = true;
    try {
      final response = await _api.post(
        AppEndpoints.requestOtp,
        data: {'phone': phone, 'purpose': purpose.name},
        key: IdempotencyKey.newFor('request-otp'),
        suppressErrorToast: true,
      );
      return OtpSent(OtpSession.fromData((response.data as Map)['data']));
    } on ApiException catch (e) {
      if (e.kind == ApiFailureKind.rejected && purpose == OtpPurpose.login) {
        _phoneError.value = e.message;
        return OtpNotSent(e.message);
      }
      return _failRequest(e.kind == ApiFailureKind.rejected ? e.message : AuthProblem.of(e).message, purpose);
    } catch (e) {
      log('requestOtp failed: $e');
      return _failRequest(AuthProblem.unknown.message, purpose);
    } finally {
      _isSendingCode.value = false;
    }
  }

  OtpNotSent _failRequest(String message, OtpPurpose purpose) {
    if (purpose == OtpPurpose.login) _requestError.value = message;
    return OtpNotSent(message);
  }

  Future<bool> verifyOtp({required String phone, required String code}) async {
    if (_isVerifying.value) return false;
    _otpError.value = null;
    if (_isOffline) {
      _otpError.value = AuthProblem.offline.message;
      return false;
    }
    _isVerifying.value = true;
    try {
      final response = await _api.post(
        AppEndpoints.verifyOtp,
        data: {'phone': phone, 'code': code},
        suppressErrorToast: true,
      );
      await _startSession(response.data['data'] as Map<String, dynamic>);
      return true;
    } on ApiException catch (e) {
      _otpError.value = e.kind == ApiFailureKind.rejected ? e.message : AuthProblem.of(e).message;
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
    if (_signingInWith.value != null) return false;
    if (_isOffline) {
      SangaToast.show(AuthProblem.offline.message, tone: SangaToastTone.error);
      return false;
    }
    _signingInWith.value = provider;
    try {
      final token = await providerTokens?.call(provider);
      if (token == null && !ApiEnvironment.usesMock) return false;
      final endpoint = switch (provider) {
        AuthProvider.google => AppEndpoints.googleSignIn,
        AuthProvider.apple => AppEndpoints.appleSignIn,
      };
      final response = await _api.post(endpoint, data: {'idToken': ?token}, suppressErrorToast: true);
      await _startSession(response.data['data'] as Map<String, dynamic>);
      return true;
    } catch (e) {
      log('continueWith $provider failed: $e');
      final message = e is ApiException && e.kind == ApiFailureKind.rejected && e.message.isNotEmpty
          ? e.message
          : AuthProblem.of(e).message;
      SangaToast.show(message, tone: SangaToastTone.error);
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
      await _api
          .post(
            AppEndpoints.logout,
            data: {'refreshToken': SessionStorage.tokens.refreshToken},
            suppressErrorToast: true,
          )
          .timeout(logoutRevokeCap);
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
