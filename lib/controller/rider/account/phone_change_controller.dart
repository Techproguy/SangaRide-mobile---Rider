import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/account/account_api.dart';
import 'package:sanga_ride/controller/rider/account/account_controller.dart';
import 'package:sanga_ride/core/api/account_endpoints.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

class PhoneChangeController extends GetxController {
  static const Duration _fallbackLifetime = Duration(minutes: 5);

  final _api = Get.find<ApiService>();

  final Rx<PhoneChangeState> _state = Rx<PhoneChangeState>(const PhoneEntry());

  PhoneChangeState get state => _state.value;

  void start() => _state.value = const PhoneEntry();

  void editNumber() => _state.value = const PhoneEntry();

  void clearProblem() {
    final current = _state.value;
    if (current is PhoneEntry && current.problem != null) _state.value = const PhoneEntry();
    if (current is PhoneCode && current.problem != null) {
      _state.value = PhoneCode(current.phone, current.sentAt, current.lifetime);
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
        key: IdempotencyKey.newFor('phone-change'),
        options: quietOptions,
      );
      _state.value = PhoneCode(phone, DateTime.now(), _lifetimeOf(dataOf(response)));
    } on Object catch (error) {
      _state.value = PhoneEntry(problem: AccountProblem.of(error));
    }
  }

  Future<void> resend() async {
    final current = _state.value;
    if (current is! PhoneCode) return;
    if (_isOffline) {
      _state.value = PhoneCode(current.phone, current.sentAt, current.lifetime, problem: AccountProblem.connection);
      return;
    }
    try {
      final response = await _api.post(
        AccountEndpoints.phone,
        data: {'phone': current.phone},
        key: IdempotencyKey.newFor('phone-change'),
        options: quietOptions,
      );
      _state.value = PhoneCode(current.phone, DateTime.now(), _lifetimeOf(dataOf(response)));
    } on Object catch (error) {
      _state.value = PhoneCode(current.phone, current.sentAt, current.lifetime, problem: AccountProblem.of(error));
    }
  }

  Future<bool> verify(String code) async {
    final current = _state.value;
    if (current is! PhoneCode || current.isVerifying) return false;
    if (_isOffline) {
      _state.value = PhoneCode(current.phone, current.sentAt, current.lifetime, problem: AccountProblem.connection);
      return false;
    }
    _state.value = PhoneCode(current.phone, current.sentAt, current.lifetime, isVerifying: true);
    try {
      final response = await _api.post(
        AccountEndpoints.phoneVerify,
        data: {'phone': current.phone, 'code': code},
        key: IdempotencyKey.newFor('phone-verify'),
        options: quietOptions,
      );
      await Get.find<AccountController>().apply(dataOf(response));
      _state.value = const PhoneChanged();
      return true;
    } on Object catch (error) {
      _state.value = PhoneCode(current.phone, current.sentAt, current.lifetime, problem: AccountProblem.of(error));
      return false;
    }
  }

  bool get _isOffline => ConnectionMonitor.current?.isOnline == false;

  Duration _lifetimeOf(Map<String, dynamic> data) {
    final expiresAt = JsonReader(data).timeOrNull('expiresAt');
    if (expiresAt == null) return _fallbackLifetime;
    final remaining = ServerClock.instance.remaining(expiresAt);
    return remaining == Duration.zero ? _fallbackLifetime : remaining;
  }
}
