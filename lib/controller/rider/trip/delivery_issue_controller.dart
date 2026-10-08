import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/trip/trip_controller.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/delivery_live_endpoints.dart';
import 'package:sanga_ride/model/models.dart';

class DeliveryIssueController extends GetxController {
  static const Duration pollInterval = Duration(seconds: 3);
  static const int maxMissedPolls = 3;

  final _api = Get.find<ApiService>();
  final _trip = Get.find<TripController>();

  final Rx<DeliveryIssueState> _state = Rx<DeliveryIssueState>(const IssueIdle());
  final Map<String, String> _issueIds = {};

  Timer? _poller;
  String? _tripId;
  int _epoch = 0;
  int _missedPolls = 0;
  bool _isPolling = false;

  Rx<DeliveryIssueState> get stateRx => _state;

  DeliveryIssueState get state => _state.value;

  DeliveryIssue? get issue => switch (state) {
    IssueLoaded(:final issue) => issue,
    _ => null,
  };

  bool get hasOpenIssue => issue?.status.isOpen ?? false;

  @override
  void onClose() {
    close();
    super.onClose();
  }

  Future<void> open(String tripId) async {
    if (_tripId == tripId && state is! IssueUnavailable) return;
    _stopPolling();
    _tripId = tripId;
    final epoch = ++_epoch;
    _missedPolls = 0;
    final issueId = _issueIds[tripId];
    if (issueId == null) {
      _state.value = const IssueIdle();
      return;
    }
    _state.value = const IssueLoading();
    await _fetch(tripId, issueId, epoch);
    if (epoch == _epoch) _startPolling();
  }

  void close() {
    _stopPolling();
    _epoch++;
    _tripId = null;
    _state.value = const IssueIdle();
  }

  void pause() => _stopPolling();

  void resume() {
    if (_tripId == null || !hasOpenIssue) return;
    _startPolling(immediate: true);
  }

  void _startPolling({bool immediate = false}) {
    _stopPolling();
    if (_tripId == null || !hasOpenIssue) return;
    _poller = Timer.periodic(pollInterval, (_) => unawaited(_pollOnce()));
    if (immediate) unawaited(_pollOnce());
  }

  void _stopPolling() {
    _poller?.cancel();
    _poller = null;
  }

  Future<void> _pollOnce() async {
    final tripId = _tripId;
    final issueId = tripId == null ? null : _issueIds[tripId];
    if (tripId == null || issueId == null || _isPolling) return;
    await _fetch(tripId, issueId, _epoch);
  }

  Future<void> _fetch(String tripId, String issueId, int epoch) async {
    if (_isPolling) return;
    _isPolling = true;
    try {
      final response = await _api.get(DeliveryLiveEndpoints.issueOf(tripId, issueId), suppressErrorToast: true);
      if (epoch != _epoch) return;
      _missedPolls = 0;
      _apply(DeliveryIssue.fromJson(_dataOf(response.data)));
    } catch (e) {
      log('issue poll failed: ${e is ApiException ? e.code : e.runtimeType}');
      if (epoch != _epoch) return;
      _onMissedPoll(e);
    } finally {
      _isPolling = false;
    }
  }

  void _onMissedPoll(Object error) {
    final current = state;
    if (current is IssueLoading) {
      _state.value = IssueUnavailable(_problemOf(error));
      return;
    }
    if (++_missedPolls >= maxMissedPolls && current is IssueInProgress && !current.isStale) {
      _state.value = IssueInProgress(current.issue, isStale: true);
    }
  }

  void _apply(DeliveryIssue issue) {
    final current = state;
    _state.value = switch (issue.status) {
      DeliveryIssueStatus.resolved => IssueResolved(issue),
      DeliveryIssueStatus.actionNeeded => IssueActionNeeded(
        issue,
        selectedId: switch (current) {
          IssueActionNeeded(:final selectedId) when issue.options.any((option) => option.id == selectedId) =>
            selectedId,
          _ => null,
        },
      ),
      DeliveryIssueStatus.reported || DeliveryIssueStatus.investigating => IssueInProgress(issue),
    };
    if (issue.status == DeliveryIssueStatus.resolved) {
      _stopPolling();
      unawaited(_trip.pollNow());
    }
  }

  Future<bool> submit(DeliveryIssueReason reason, String note) async {
    final tripId = _tripId;
    if (tripId == null || state is IssueSubmitting) return false;
    final epoch = ++_epoch;
    final trimmed = note.trim();
    _state.value = IssueSubmitting(reason, trimmed);
    try {
      final response = await _api.post(
        DeliveryLiveEndpoints.issuesOf(tripId),
        data: {'reason': reason.code, 'note': trimmed.isEmpty ? null : trimmed},
        suppressErrorToast: true,
      );
      if (epoch != _epoch) return false;
      final issue = DeliveryIssue.fromJson(_dataOf(response.data));
      _issueIds[tripId] = issue.id;
      _missedPolls = 0;
      _apply(issue);
      _startPolling();
      return true;
    } catch (e) {
      log('issue submit failed: ${e is ApiException ? e.code : e.runtimeType}');
      if (epoch == _epoch) _state.value = IssueSubmitFailed(_problemOf(e), reason, trimmed);
      return false;
    }
  }

  void backToReasons() {
    final current = state;
    if (current is IssueSubmitFailed || current is IssueUnavailable) _state.value = const IssueIdle();
  }

  void selectOption(String optionId) {
    final current = state;
    if (current is IssueActionNeeded) _state.value = current.withSelected(optionId);
    if (current is IssueResolutionFailed) _state.value = IssueActionNeeded(current.issue, selectedId: optionId);
  }

  Future<bool> resolve() async {
    final tripId = _tripId;
    final current = state;
    final optionId = switch (current) {
      IssueActionNeeded(:final selectedId) => selectedId,
      IssueResolutionFailed(:final optionId) => optionId,
      _ => null,
    };
    if (tripId == null || current is! IssueLoaded || optionId == null) return false;
    final issue = current.issue;
    final epoch = ++_epoch;
    _stopPolling();
    _state.value = IssueResolving(issue, optionId: optionId);
    try {
      final response = await _api.post(
        DeliveryLiveEndpoints.issueResolutionOf(tripId, issue.id),
        data: {'option': optionId},
        suppressErrorToast: true,
      );
      if (epoch != _epoch) return false;
      _apply(DeliveryIssue.fromJson(_dataOf(response.data)));
      _startPolling();
      return true;
    } catch (e) {
      log('issue resolution failed: ${e is ApiException ? e.code : e.runtimeType}');
      if (epoch == _epoch) {
        _state.value = IssueResolutionFailed(issue, optionId: optionId, problem: _problemOf(e));
        _startPolling();
      }
      return false;
    }
  }

  DeliveryIssueProblem _problemOf(Object error) =>
      error is ApiException ? DeliveryIssueProblem.fromCode(error.code) : DeliveryIssueProblem.connection;

  Map<String, dynamic> _dataOf(dynamic body) => Map<String, dynamic>.from((body as Map)['data'] as Map);
}
