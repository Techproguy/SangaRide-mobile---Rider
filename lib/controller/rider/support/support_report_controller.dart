import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/account/account_api.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/history_endpoints.dart';
import 'package:sanga_ride/core/api/support_endpoints.dart';
import 'package:sanga_ride/model/history/history_item.dart';
import 'package:sanga_ride/model/models.dart';

class SupportReportController extends GetxController {
  static const int recentRidesLimit = 8;

  final _api = Get.find<ApiService>();

  final Rx<SupportReportState> _state = Rx<SupportReportState>(const SupportReportLoading());

  IssueContext _context = IssueContext.trip;
  List<HistoryItem>? _rides;
  int _epoch = 0;

  SupportReportState get state => _state.value;

  IssueContext get context => _context;

  Future<void> open({required IssueContext context, String? tripId, bool refreshRides = true}) async {
    _context = context;
    if (refreshRides) _rides = null;
    final epoch = ++_epoch;
    _state.value = const SupportReportLoading();
    try {
      final response = await _api.get(
        SupportEndpoints.issueTypes,
        queryParameters: {'context': context.code},
        options: quietOptions,
      );
      final rides = _rides ??= await _recentRides();
      if (epoch != _epoch) return;
      _state.value = SupportReportDraft(
        types: [
          for (final type in dataOf(response)['types'] as List)
            IssueType.fromJson(Map<String, dynamic>.from(type as Map)),
        ],
        recentRides: _ridesFor(context, rides),
        tripId: tripId,
      );
    } catch (error) {
      log('report open failed: $error');
      if (epoch == _epoch) _state.value = SupportReportFailed(_problemOf(error));
    }
  }

  Future<void> reload() => open(context: _context, tripId: _draft?.tripId, refreshRides: false);

  Future<void> changeContext(IssueContext context) {
    final draft = _draft;
    if (draft != null && (context == _context || draft.isSubmitting)) return Future.value();
    return open(context: context, refreshRides: false);
  }

  void selectType(String id) {
    final draft = _draft;
    if (draft == null || draft.isSubmitting) return;
    _state.value = draft.copyWith(typeId: id, clearProblem: true);
  }

  void selectTrip(String? id) {
    final draft = _draft;
    if (draft == null || draft.isSubmitting) return;
    _state.value = id == null ? draft.copyWith(clearTrip: true) : draft.copyWith(tripId: id);
  }

  Future<SupportTicket?> submit({String? note}) async {
    final draft = _draft;
    final typeId = draft?.typeId;
    if (draft == null || typeId == null || draft.isSubmitting) return null;
    _state.value = draft.copyWith(isSubmitting: true, clearProblem: true);
    final trimmed = note?.trim() ?? '';
    try {
      final response = await _api.post(
        SupportEndpoints.tickets,
        data: {
          'type': typeId,
          'context': _context.code,
          'tripId': draft.tripId,
          'note': trimmed.isEmpty ? null : trimmed,
          'attachmentIds': const <String>[],
        },
        options: quietOptions,
      );
      _state.value = draft.copyWith(isSubmitting: false);
      return SupportTicket.fromJson(dataOf(response));
    } catch (error) {
      log('report submit failed: $error');
      _state.value = draft.copyWith(isSubmitting: false, problem: _problemOf(error));
      return null;
    }
  }

  SupportReportDraft? get _draft => switch (_state.value) {
    final SupportReportDraft draft => draft,
    _ => null,
  };

  List<HistoryItem> _ridesFor(IssueContext context, List<HistoryItem> rides) => switch (context) {
    IssueContext.trip => [
      for (final ride in rides)
        if (!ride.kind.isDelivery) ride,
    ],
    IssueContext.delivery => [
      for (final ride in rides)
        if (ride.kind.isDelivery) ride,
    ],
    IssueContext.account || IssueContext.payment => rides,
  };

  Future<List<HistoryItem>> _recentRides() async {
    try {
      final response = await _api.get(
        HistoryEndpoints.rides,
        queryParameters: {'status': HistoryStatus.completed.code, 'page': 1, 'pageSize': recentRidesLimit},
        options: quietOptions,
      );
      return HistoryPage.fromJson(dataOf(response)).items;
    } catch (error) {
      log('recent rides failed: $error');
      return const [];
    }
  }

  SupportProblem _problemOf(Object error) =>
      error is ApiException ? SupportProblem.fromCode(error.code) : SupportProblem.connection;
}
