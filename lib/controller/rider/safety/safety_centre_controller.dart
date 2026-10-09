import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/safety/sos_controller.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/safety_endpoints.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

class SafetyCentreController extends GetxController {
  final _api = Get.find<ApiService>();

  final Rx<SafetyCentreState> _state = Rx<SafetyCentreState>(const SafetyCentreLoading());
  String? _tripId;
  final Epoch _epoch = Epoch();

  Rx<SafetyCentreState> get stateRx => _state;

  SafetyCentreState get state => _state.value;

  SafetyCentre? get centre => switch (state) {
    SafetyCentreLoaded(:final centre) => centre,
    _ => null,
  };

  Future<void> open({String? tripId}) {
    _tripId = tripId;
    return _load();
  }

  Future<void> retry() => _load();

  Future<void> _load() async {
    final epoch = _epoch.next();
    _state.value = const SafetyCentreLoading();
    try {
      final response = await _api.get(
        SafetyEndpoints.centre,
        queryParameters: {'tripId': ?_tripId},
        suppressErrorToast: true,
        profile: RequestProfile.interactive,
      );
      if (!_epoch.isCurrent(epoch)) return;
      final centre = SafetyCentre.fromJson(response.dataMapOrEmpty);
      Get.find<SosController>().learnFrom(centre);
      _state.value = SafetyCentreLoaded(centre);
    } catch (e) {
      log('safety centre failed: $e');
      if (_epoch.isCurrent(epoch)) _state.value = SafetyCentreFailed(SafetyProblem.of(e));
    }
  }

  void applyContacts(List<EmergencyContact> contacts) {
    final current = centre;
    if (current != null) _state.value = SafetyCentreLoaded(current.withContacts(contacts));
  }
}
