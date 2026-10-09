import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/app_endpoints.dart';
import 'package:sanga_ride/model/trip/wrapup/wrapup.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

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
    final isRefresh = _tripId == tripId && state is ReceiptLoaded;
    _tripId = tripId;
    await _load(isQuiet: isRefresh);
  }

  Future<void> reload() async {
    if (_tripId == null || state is ReceiptLoading) return;
    await _load();
  }

  Future<void> _load({bool isQuiet = false}) async {
    final id = _tripId;
    if (id == null) return;
    final epoch = ++_epoch;
    if (!isQuiet) _state.value = const ReceiptLoading();
    try {
      final response = await _api.get(
        AppEndpoints.tripReceiptOf(id),
        suppressErrorToast: true,
        profile: RequestProfile.interactive,
      );
      if (epoch != _epoch) return;
      _state.value = ReceiptLoaded(TripReceipt.fromJson(JsonReader.of(JsonReader.of(response.data).raw['data']).raw));
    } catch (e) {
      log('receipt load failed: ${e is ApiException ? e.code : e.runtimeType}');
      if (epoch != _epoch || isQuiet) return;
      _state.value = ReceiptFailed(ReceiptFailure.of(e));
    }
  }
}
