import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/safety/safety_api.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/safety_endpoints.dart';
import 'package:sanga_ride/model/models.dart';

class SafetyReportController extends GetxController {
  final _api = Get.find<ApiService>();

  final Rx<ReportState> _state = Rx<ReportState>(const ReportIdle());

  Rx<ReportState> get stateRx => _state;

  ReportState get state => _state.value;

  void reset() => _state.value = const ReportIdle();

  Future<SafetyReportReceipt?> submit({
    required String? tripId,
    required ReportCategory category,
    required String details,
  }) async {
    if (state is ReportSubmitting) return null;
    _state.value = const ReportSubmitting();
    try {
      final response = await _api.post(
        SafetyEndpoints.reports,
        data: {'tripId': tripId, 'category': category.code, 'details': details.trim()},
        suppressErrorToast: true,
      );
      final receipt = SafetyReportReceipt.fromJson(safetyDataOf(response.data));
      _state.value = ReportSent(receipt);
      return receipt;
    } catch (e) {
      log('safety report failed: $e');
      _state.value = ReportFailed(safetyProblemOf(e));
      return null;
    }
  }
}
