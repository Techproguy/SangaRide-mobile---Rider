import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/app_endpoints.dart';
import 'package:sanga_ride/model/trip/wrapup/wrapup.dart';

class TripReceiptController extends GetxController {
  final _api = Get.find<ApiService>();

  final Rx<ReceiptState> _state = Rx<ReceiptState>(const ReceiptLoading());
  String? _tripId;
  int _epoch = 0;

  Rx<ReceiptState> get stateRx => _state;

  ReceiptState get state => _state.value;

  TripReceipt? get receipt => switch (state) {
    ReceiptLoaded(:final receipt) => receipt,
    _ => null,
  };

  @override
  void onClose() {
    _epoch++;
    super.onClose();
  }

  Future<void> open(String tripId) async {
    if (_tripId == tripId && state is ReceiptLoaded) return;
    _tripId = tripId;
    await _load();
  }

  Future<void> reload() async {
    if (_tripId == null || state is ReceiptLoading) return;
    await _load();
  }

  Future<void> _load() async {
    final id = _tripId;
    if (id == null) return;
    final epoch = ++_epoch;
    _state.value = const ReceiptLoading();
    try {
      final response = await _api.get(AppEndpoints.tripReceiptOf(id), suppressErrorToast: true);
      if (epoch != _epoch) return;
      final data = Map<String, dynamic>.from((response.data as Map)['data'] as Map);
      _state.value = ReceiptLoaded(TripReceipt.fromJson(data));
    } catch (e) {
      log('receipt load failed: ${e is ApiException ? e.code : e.runtimeType}');
      if (epoch == _epoch) _state.value = ReceiptFailed(ReceiptFailure.fromCode(e is ApiException ? e.code : null));
    }
  }
}
