import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/safety/safety_api.dart';
import 'package:sanga_ride/controller/rider/trip/live_problem.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/safety_endpoints.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

class SafetyReportController extends GetxController {
  final _api = Get.find<ApiService>();

  final Rx<ReportState> _state = Rx<ReportState>(const ReportIdle());
  Mutation<SafetyReportReceipt>? _mutation;
  String? _signature;

  Rx<ReportState> get stateRx => _state;

  ReportState get state => _state.value;

  @override
  void onClose() {
    _mutation?.dispose();
    super.onClose();
  }

  void reset() {
    _mutation?.dispose();
    _mutation = null;
    _signature = null;
    _state.value = const ReportIdle();
  }

  Future<SafetyReportReceipt?> submit({
    required String? tripId,
    required ReportCategory category,
    required String details,
  }) async {
    if (state is ReportSubmitting) return null;
    if (LiveProblem.isOffline) {
      _state.value = const ReportFailed(SafetyProblem.connection);
      return null;
    }
    _state.value = const ReportSubmitting();
    final body = details.trim();
    final mutation = _mutationFor(tripId, category, body);
    final result = await mutation.start();
    switch (result) {
      case MutationDone<SafetyReportReceipt>(:final value):
        _mutation?.dispose();
        _mutation = null;
        _state.value = ReportSent(value);
        return value;
      case MutationRejected<SafetyReportReceipt>(:final error):
        _mutation?.dispose();
        _mutation = null;
        _state.value = ReportFailed(safetyProblemOf(error));
      case MutationFailed<SafetyReportReceipt>(:final error):
        log('safety report failed: ${error.kind}');
        _state.value = ReportFailed(safetyProblemOf(error));
      case MutationUnknown<SafetyReportReceipt>(:final error):
        _state.value = ReportFailed(safetyProblemOf(error));
      default:
        break;
    }
    return null;
  }

  Mutation<SafetyReportReceipt> _mutationFor(String? tripId, ReportCategory category, String body) {
    final signature = '$tripId|${category.code}|$body';
    final existing = _mutation;
    if (existing != null && _signature == signature) return existing;
    existing?.dispose();
    _signature = signature;
    return _mutation = Mutation<SafetyReportReceipt>(
      intent: 'safety-report',
      run: (key) async {
        final response = await _api.post(
          SafetyEndpoints.reports,
          data: {'tripId': tripId, 'category': category.code, 'details': body},
          key: key,
          suppressErrorToast: true,
        );
        return SafetyReportReceipt.fromJson(safetyDataOf(response.data));
      },
    );
  }
}
