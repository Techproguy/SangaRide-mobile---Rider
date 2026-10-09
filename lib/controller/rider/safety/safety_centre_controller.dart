import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/safety/safety_api.dart';
import 'package:sanga_ride/controller/rider/safety/sos_controller.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/safety_endpoints.dart';
import 'package:sanga_ride/model/models.dart';

class SafetyCentreController extends GetxController {
  final _api = Get.find<ApiService>();

  final Rx<SafetyCentreState> _state = Rx<SafetyCentreState>(const SafetyCentreLoading());
  String? _tripId;
  int _epoch = 0;

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
    final epoch = ++_epoch;
    _state.value = const SafetyCentreLoading();
    try {
      final response = await _api.get(
        SafetyEndpoints.centre,
        queryParameters: {'tripId': ?_tripId},
        suppressErrorToast: true,
        profile: RequestProfile.interactive,
      );
      if (epoch != _epoch) return;
      final centre = SafetyCentre.fromJson(safetyDataOf(response.data));
      Get.find<SosController>().learnFrom(centre);
      _state.value = SafetyCentreLoaded(centre);
    } catch (e) {
      log('safety centre failed: $e');
      if (epoch == _epoch) _state.value = SafetyCentreFailed(safetyProblemOf(e));
    }
  }

  void applyContacts(List<EmergencyContact> contacts) {
    final current = centre;
    if (current != null) _state.value = SafetyCentreLoaded(current.withContacts(contacts));
  }
}
