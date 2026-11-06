import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/account/account_controller.dart';
import 'package:sanga_ride/core/api/account_endpoints.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/idempotency_intents.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

class PhoneChangeController extends GetxController {
  final _api = Get.find<ApiService>();

  final Rx<PhoneChangeState> _state = Rx<PhoneChangeState>(const PhoneEntry());

  PhoneChangeState get state => _state.value;

  void start() => _state.value = const PhoneEntry();

  void editNumber() => _state.value = const PhoneEntry();

  void clearProblem() {
    final current = _state.value;
    if (current is PhoneEntry && current.problem != null) _state.value = const PhoneEntry();
    if (current is PhoneCode && current.problem != null) {
      _state.value = PhoneCode(current.phone, current.session);
    }
  }

  Future<void> sendCode(String phone) async {
    if (_state.value is PhoneSending) return;
    if (_isOffline) {
      _state.value = const PhoneEntry(problem: AccountProblem.connection);
      return;
    }
    _state.value = const PhoneSending();
    try {
      final response = await _api.post(
        AccountEndpoints.phone,
        data: {'phone': phone},
        key: IdempotencyKey.newFor(IdempotencyIntent.phoneChange),
        suppressErrorToast: true,
      );
      _state.value = PhoneCode(phone, OtpSession.fromData(response.dataMapOrEmpty));
    } on Object catch (error) {
      _state.value = PhoneEntry(problem: AccountProblem.of(error));
    }
  }

  Future<void> resend() async {
    final current = _state.value;
    if (current is! PhoneCode) return;
    if (_isOffline) {
      _state.value = PhoneCode(current.phone, current.session, problem: AccountProblem.connection);
      return;
    }
    try {
      final response = await _api.post(
        AccountEndpoints.phone,
        data: {'phone': current.phone},
        key: IdempotencyKey.newFor(IdempotencyIntent.phoneChange),
        suppressErrorToast: true,
      );
      _state.value = PhoneCode(current.phone, OtpSession.fromData(response.dataMapOrEmpty));
    } on Object catch (error) {
      _state.value = PhoneCode(current.phone, _throttled(current.session, error), problem: AccountProblem.of(error));
    }
  }

  OtpSession _throttled(OtpSession session, Object error) {
    final delay = error is ApiException ? OtpSession.resendDelayOf(error) : null;
    return delay == null ? session : session.restartedAfter(delay);
  }

  Future<bool> verify(String code) async {
    final current = _state.value;
    if (current is! PhoneCode || current.isVerifying) return false;
    if (_isOffline) {
      _state.value = PhoneCode(current.phone, current.session, problem: AccountProblem.connection);
      return false;
    }
    _state.value = PhoneCode(current.phone, current.session, isVerifying: true);
    try {
      final response = await _api.post(
        AccountEndpoints.phoneVerify,
        data: {'phone': current.phone, 'code': code},
        key: IdempotencyKey.newFor(IdempotencyIntent.phoneVerify),
        suppressErrorToast: true,
      );
      await Get.find<AccountController>().apply(response.dataMapOrEmpty);
      _state.value = const PhoneChanged();
      return true;
    } on Object catch (error) {
      _state.value = PhoneCode(current.phone, current.session, problem: AccountProblem.of(error));
      return false;
    }
  }

  bool get _isOffline => ConnectionMonitor.current?.isOnline == false;
}
