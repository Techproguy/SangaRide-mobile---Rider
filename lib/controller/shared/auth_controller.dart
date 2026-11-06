import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/shared/user_controller.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/app_endpoints.dart';
import 'package:sanga_ride/core/api/server_codes.dart';
import 'package:sanga_ride/core/api/idempotency_intents.dart';
import 'package:sanga_ride/core/constants.dart';
import 'package:sanga_ride/core/copy/auth_problem_copy.dart';
import 'package:sanga_ride/core/services/auth_config.dart';
import 'package:sanga_ride/core/services/realtime.dart';
import 'package:sanga_ride/core/services/session_restore.dart';
import 'package:sanga_ride/core/services/session_storage.dart';
import 'package:sanga_ride/model/auth/auth_problem.dart';
import 'package:sanga_ride/model/auth/social_outcome.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart'
    show
        ConnectionMonitor,
        OtpNotSent,
        OtpPurpose,
        OtpRequestResult,
        OtpSent,
        OtpSession,
        ResponseData,
        SessionEndReason,
        SessionHub,
        SocialCredential,
        SocialFailed,
        SocialObtained,
        SocialProvider,
        SocialProviderLabel,
        SocialSignIn,
        SocialReply,
        SocialSession,
        SocialSignInResult,
        SocialSignupRequired,
        SocialUnavailable;
import 'package:sanga_ride_ui/sanga_ride_ui.dart' show SangaAuthCopy, SangaRegion, SangaToast, SangaToastTone;

class AuthController extends GetxController {
  static int get otpLength => AuthConfig.current.otpLength;
  static const Duration logoutRevokeCap = Duration(seconds: 3);

  final _api = Get.find<ApiService>();

  final RxBool _isSendingCode = false.obs;
  final RxBool _isVerifying = false.obs;
  final Rxn<SocialProvider> _signingInWith = Rxn<SocialProvider>();
  final RxnString _otpError = RxnString();
  final RxnString _phoneError = RxnString();
  final RxnString _requestError = RxnString();

  bool get isSendingCode => _isSendingCode.value;

  bool get isVerifying => _isVerifying.value;

  SocialProvider? get signingInWith => _signingInWith.value;

  String? get otpError => _otpError.value;

  String? get phoneError => _phoneError.value;

  String? get requestError => _requestError.value;

  void clearOtpError() => _otpError.value = null;

  void clearPhoneError() {
    _phoneError.value = null;
    _requestError.value = null;
  }

  Future<bool> isRegistered(String phone) async {
    final response = await _api.post(
      AppEndpoints.checkExistence,
      data: {'phone': phone, 'userType': SangaConstants.userType},
    );
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
        data: {
          'phone': phone,
          'country': (SangaRegion.ofPhone(phone) ?? SangaRegion.current).isoCode,
          'purpose': purpose.name,
        },
        key: IdempotencyKey.newFor(IdempotencyIntent.requestOtp),
        suppressErrorToast: true,
      );
      return OtpSent(OtpSession.fromData((response.data as Map)['data']));
    } on ApiException catch (e) {
      if (e.kind == ApiFailureKind.rejected && purpose == OtpPurpose.login && e.statusCode != 429) {
        final message = _rejectedMessage(e);
        _phoneError.value = message;
        return OtpNotSent(message, resendIn: OtpSession.resendDelayOf(e));
      }
      final message = e.kind == ApiFailureKind.rejected ? _rejectedMessage(e) : AuthProblem.of(e).message;
      return _failRequest(message, purpose, resendIn: OtpSession.resendDelayOf(e));
    } catch (e) {
      log('requestOtp failed: $e');
      return _failRequest(AuthProblem.unknown.message, purpose);
    } finally {
      _isSendingCode.value = false;
    }
  }

  String _rejectedMessage(ApiException error) {
    if (error.isNotFound) return SangaAuthCopy.noAccountForNumber;
    return ApiFailureCopy.rejectionMessage(error);
  }

  OtpNotSent _failRequest(String message, OtpPurpose purpose, {Duration? resendIn}) {
    if (purpose == OtpPurpose.login) _requestError.value = message;
    return OtpNotSent(message, resendIn: resendIn);
  }

  Future<bool> verifyOtp({required String phone, required String code, required OtpPurpose purpose}) async {
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
        data: {'phone': phone, 'code': code, 'purpose': purpose.name},
        suppressErrorToast: true,
      );
      await _startSession(response.dataMap);
      return true;
    } on ApiException catch (e) {
      _otpError.value = e.kind == ApiFailureKind.rejected ? _rejectedMessage(e) : AuthProblem.of(e).message;
      return false;
    } catch (e) {
      log('verifyOtp failed: $e');
      _otpError.value = SangaAuthCopy.couldntCheckCode;
      return false;
    } finally {
      _isVerifying.value = false;
    }
  }

  Future<SocialOutcome> continueWith(SocialProvider provider) async {
    if (_signingInWith.value != null) return const SocialStopped();
    if (_isOffline) {
      SangaToast.show(AuthProblem.offline.message, tone: SangaToastTone.error);
      return const SocialStopped();
    }
    _signingInWith.value = provider;
    try {
      final result = await SocialSignIn.acquire(provider);
      if (result is SocialObtained) return await _exchange(result.credential);
      _reportUnobtained(provider, result);
      return const SocialStopped();
    } finally {
      _signingInWith.value = null;
    }
  }

  void _reportUnobtained(SocialProvider provider, SocialSignInResult result) {
    final message = switch (result) {
      SocialUnavailable() => SangaAuthCopy.socialUnavailable(provider.label),
      SocialFailed() => SangaAuthCopy.socialFailed,
      _ => null,
    };
    if (message != null) SangaToast.show(message, tone: SangaToastTone.error);
  }

  Future<SocialOutcome> _exchange(SocialCredential credential) async {
    final endpoint = switch (credential.provider) {
      SocialProvider.google => AppEndpoints.googleSignIn,
      SocialProvider.apple => AppEndpoints.appleSignIn,
    };
    try {
      final response = await _api.post(endpoint, data: credential.requestBodyFor('rider'), suppressErrorToast: true);
      switch (SocialReply.fromData(response.dataMap)) {
        case SocialSession(:final data):
          await _startSession(data);
          return const SocialSignedIn();
        case final SocialSignupRequired reply:
          return SocialNeedsSignUp(SocialPrefill.of(credential, reply));
      }
    } on ApiException catch (e) {
      log('continueWith ${credential.provider} failed: $e');
      SangaToast.show(_socialMessage(e), tone: SangaToastTone.error);
      return const SocialStopped();
    } catch (e) {
      log('continueWith ${credential.provider} failed: $e');
      SangaToast.show(AuthProblem.of(e).message, tone: SangaToastTone.error);
      return const SocialStopped();
    }
  }

  String _socialMessage(ApiException error) {
    if (error.hasCode(ServerCode.invalidSocialToken) || error.hasCode(ServerCode.invalidProviderToken)) {
      return SangaAuthCopy.socialFailed;
    }
    final isRefusal = error.kind == ApiFailureKind.rejected || error.kind == ApiFailureKind.unauthorized;
    return isRefusal ? _rejectedMessage(error) : AuthProblem.of(error).message;
  }

  Future<void> logout() async {
    unawaited(_revokeSession());
    await Future<void>.delayed(Duration.zero);
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
    Realtime.resume();
    await Get.find<UserController>().setUser(UserModel.fromJson(data['user'] as Map<String, dynamic>));
    unawaited(Get.find<SessionRestore>().refreshQuietly());
  }
}
