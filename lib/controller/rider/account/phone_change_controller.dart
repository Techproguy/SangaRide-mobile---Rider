import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/account/account_api.dart';
import 'package:sanga_ride/controller/rider/account/account_controller.dart';
import 'package:sanga_ride/core/api/account_endpoints.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/model/models.dart';

class PhoneChangeController extends GetxController {
  final _api = Get.find<ApiService>();

  final Rx<PhoneChangeState> _state = Rx<PhoneChangeState>(const PhoneEntry());

  PhoneChangeState get state => _state.value;

  void start() => _state.value = const PhoneEntry();

  void editNumber() => _state.value = const PhoneEntry();

  void clearProblem() {
    final current = _state.value;
    if (current is PhoneEntry && current.problem != null) _state.value = const PhoneEntry();
    if (current is PhoneCode && current.problem != null) _state.value = PhoneCode(current.phone, current.sentAt);
  }

  Future<void> sendCode(String phone) async {
    if (_state.value is PhoneSending) return;
    _state.value = const PhoneSending();
    try {
      await _api.post(AccountEndpoints.phone, data: {'phone': phone}, options: quietOptions);
      _state.value = PhoneCode(phone, DateTime.now());
    } catch (error) {
      log('phone change request failed: $error');
      _state.value = PhoneEntry(problem: _problemOf(error));
    }
  }

  Future<void> resend() async {
    final current = _state.value;
    if (current is! PhoneCode) return;
    try {
      await _api.post(AccountEndpoints.phone, data: {'phone': current.phone}, options: quietOptions);
      _state.value = PhoneCode(current.phone, DateTime.now());
    } catch (error) {
      log('phone change resend failed: $error');
      _state.value = PhoneCode(current.phone, current.sentAt, problem: _problemOf(error));
    }
  }

  Future<bool> verify(String code) async {
    final current = _state.value;
    if (current is! PhoneCode || current.isVerifying) return false;
    _state.value = PhoneCode(current.phone, current.sentAt, isVerifying: true);
    try {
      final response = await _api.post(
        AccountEndpoints.phoneVerify,
        data: {'phone': current.phone, 'code': code},
        options: quietOptions,
      );
      await Get.find<AccountController>().apply(dataOf(response));
      _state.value = const PhoneChanged();
      return true;
    } catch (error) {
      log('phone change verify failed: $error');
      _state.value = PhoneCode(current.phone, current.sentAt, problem: _problemOf(error));
      return false;
    }
  }

  AccountProblem _problemOf(Object error) =>
      error is ApiException ? AccountProblem.fromCode(error.code) : AccountProblem.connection;
}
