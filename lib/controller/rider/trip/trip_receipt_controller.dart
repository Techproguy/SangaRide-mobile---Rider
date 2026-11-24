import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/wallet_controller.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/app_endpoints.dart';
import 'package:sanga_ride/model/trip/trip.dart';
import 'package:sanga_ride/model/trip/wrapup/wrapup.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

class TripReceiptController extends GetxController {
  final _api = Get.find<ApiService>();

  final Rx<ReceiptState> _state = Rx<ReceiptState>(const ReceiptLoading());
  String? _tripId;
  final Epoch _epoch = Epoch();

  Rx<ReceiptState> get stateRx => _state;

  ReceiptState get state => _state.value;

  TripReceipt? get receipt => switch (state) {
    ReceiptLoaded(:final receipt) => receipt,
    _ => null,
  };

  @override
  void onClose() {
    _epoch.next();
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

  Future<bool> refreshContent() async {
    final current = state;
    if (_tripId == null || current is ReceiptLoading) return true;
    return _load(isQuiet: current is ReceiptLoaded);
  }

  Future<TripReceipt> _withCategory(String id, TripReceipt receipt) async {
    try {
      final response = await _api.get(AppEndpoints.liveTripOf(id), suppressErrorToast: true);
      final trip = Trip.fromJson(response.dataMapOrEmpty);
      return receipt.withCategory(trip.rideType);
    } catch (_) {
      return receipt;
    }
  }

  Future<bool> _load({bool isQuiet = false}) async {
    final id = _tripId;
    if (id == null) return true;
    final epoch = _epoch.next();
    if (!isQuiet) _state.value = const ReceiptLoading();
    try {
      final response = await _api.get(
        AppEndpoints.tripReceiptOf(id),
        suppressErrorToast: true,
        profile: RequestProfile.interactive,
      );
      if (!_epoch.isCurrent(epoch)) return true;
      final json = JsonReader.of(JsonReader.of(response.data).raw['data']).raw;
      var receipt = TripReceipt.fromJson(json);
      receipt = await _withCategory(id, receipt);
      if (!_epoch.isCurrent(epoch)) return true;
      _state.value = ReceiptLoaded(receipt);
      unawaited(Get.find<WalletController>().reloadQuietly());
      return true;
    } catch (e) {
      log('receipt load failed: ${e is ApiException ? e.code : e.runtimeType}');
      if (!_epoch.isCurrent(epoch)) return true;
      if (!isQuiet) _state.value = ReceiptFailed(ReceiptFailure.of(e));
      return false;
    }
  }
}
