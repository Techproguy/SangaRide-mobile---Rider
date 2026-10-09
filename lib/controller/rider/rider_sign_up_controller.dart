import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/shared/auth_controller.dart';
import 'package:sanga_ride/core/api/account_endpoints.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/app_endpoints.dart';
import 'package:sanga_ride/core/api/places_endpoints.dart';
import 'package:sanga_ride/model/auth/otp_session.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart' show ConnectionMonitor;
import 'package:sanga_ride_ui/sanga_ride_ui.dart' show SangaToast, SangaToastTone;

enum SelfieResult { verified, noMatch, unavailable }

class RiderSignUpController extends GetxController {
  static const String selfiePurpose = 'selfie';
  static const String noMatchCode = 'face_not_matched';
  static const String homeStepCode = 'home';
  static const Duration skipCap = Duration(seconds: 3);

  final _api = Get.find<ApiService>();

  final RxBool _isSaving = false.obs;
  final RxnString _phoneError = RxnString();
  final RxnString _formError = RxnString();

  IdempotencyKey? _signUpKey;
  String? _signUpSignature;
  IdempotencyKey? _homeKey;
  String? _homeSignature;

  bool get isSaving => _isSaving.value;

  String? get phoneError => _phoneError.value;

  String? get formError => _formError.value;

  void clearPhoneError() {
    _phoneError.value = null;
    _formError.value = null;
  }

  void clearFormError() => _formError.value = null;

  bool get _isOffline => ConnectionMonitor.current?.isOnline == false;

  Future<OtpSession?> start({required String firstName, required String lastName, required String phone}) async {
    if (_isSaving.value) return null;
    _phoneError.value = null;
    _formError.value = null;
    if (_isOffline) {
      _formError.value = AuthProblem.offline.message;
      return null;
    }
    _isSaving.value = true;
    try {
      if (await Get.find<AuthController>().isRegistered(phone)) {
        _phoneError.value = 'This number already has an account.';
        return null;
      }
      final body = {'firstName': firstName, 'lastName': lastName, 'phone': phone};
      final response = await _api.post(
        AppEndpoints.signUp,
        data: body,
        key: _keyFor(body, isHome: false),
        suppressErrorToast: true,
      );
      _signUpKey = null;
      return OtpSession.fromData((response.data as Map)['data']);
    } catch (e) {
      log('start sign up failed: $e');
      _formError.value = _messageOf(e);
      return null;
    } finally {
      _isSaving.value = false;
    }
  }

  Future<bool> saveProfile({required String email, DateTime? birthday, String? referralCode}) {
    return _save(
      () => _api.patch(
        AppEndpoints.me,
        data: {'email': email, 'birthday': ?birthday?.toIso8601String(), 'referralCode': ?referralCode},
        suppressErrorToast: true,
      ),
    );
  }

  Future<SelfieResult> verifySelfie(String photoPath) async {
    try {
      await _api.upload(AppEndpoints.selfie, file: File(photoPath), purpose: selfiePurpose, suppressErrorToast: true);
      return SelfieResult.verified;
    } catch (e) {
      log('verifySelfie failed: $e');
      if (e is ApiException && e.kind == ApiFailureKind.rejected && e.code == noMatchCode) return SelfieResult.noMatch;
      SangaToast.show(_selfieMessageOf(e), tone: SangaToastTone.error);
      return SelfieResult.unavailable;
    }
  }

  Future<bool> saveHome(Place place) {
    final body = {'kind': 'home', 'label': 'Home', 'place': place.toJson()};
    return _save(
      () => _api.post(PlacesEndpoints.saved, data: body, key: _keyFor(body, isHome: true), suppressErrorToast: true),
      onDone: () => _homeKey = null,
    );
  }

  void skipHome() {
    if (_isOffline) return;
    unawaited(_sendSkip(homeStepCode));
  }

  Future<void> _sendSkip(String step) async {
    try {
      await _api
          .post(
            AccountEndpoints.onboardingSkip,
            data: {'step': step},
            key: IdempotencyKey.newFor('skip-$step'),
            suppressErrorToast: true,
          )
          .timeout(skipCap);
    } catch (e) {
      log('skip $step failed: $e');
    }
  }

  IdempotencyKey _keyFor(Map<String, dynamic> body, {required bool isHome}) {
    final signature = body.toString();
    if (isHome) {
      if (_homeKey == null || _homeSignature != signature) {
        _homeKey = IdempotencyKey.newFor('save-home');
        _homeSignature = signature;
      }
      return _homeKey!;
    }
    if (_signUpKey == null || _signUpSignature != signature) {
      _signUpKey = IdempotencyKey.newFor('sign-up');
      _signUpSignature = signature;
    }
    return _signUpKey!;
  }

  Future<bool> _save(Future<Object?> Function() request, {void Function()? onDone}) async {
    if (_isSaving.value) return false;
    _formError.value = null;
    if (_isOffline) {
      _formError.value = AuthProblem.offline.message;
      return false;
    }
    _isSaving.value = true;
    try {
      await request();
      onDone?.call();
      return true;
    } catch (e) {
      log('sign up step failed: $e');
      _formError.value = _messageOf(e);
      return false;
    } finally {
      _isSaving.value = false;
    }
  }

  String _messageOf(Object error) {
    if (error is ApiException && error.kind == ApiFailureKind.rejected && error.message.isNotEmpty) {
      return error.message;
    }
    return AuthProblem.of(error).message;
  }

  String _selfieMessageOf(Object error) {
    if (error is ApiException && error.kind == ApiFailureKind.rejected && error.message.isNotEmpty) {
      return error.message;
    }
    return switch (AuthProblem.of(error)) {
      AuthProblem.offline => 'No connection. Your selfie is fine. Try again once you’re back online.',
      AuthProblem.server || AuthProblem.unknown => 'We can’t check selfies right now. Try again in a moment.',
    };
  }
}
