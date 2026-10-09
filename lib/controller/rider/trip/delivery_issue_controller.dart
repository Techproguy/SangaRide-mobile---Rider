import 'dart:async';

import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/trip/live_problem.dart';
import 'package:sanga_ride/controller/rider/trip/trip_controller.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/delivery_live_endpoints.dart';
import 'package:sanga_ride/core/api/idempotency_intents.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

class DeliveryIssueController extends GetxController {
  static const Duration pollInterval = Duration(seconds: 3);

  final _api = Get.find<ApiService>();
  final _trip = Get.find<TripController>();

  final Rx<DeliveryIssueState> _state = Rx<DeliveryIssueState>(const IssueIdle());
  final Map<String, String> _issueIds = {};

  LivePoller? _poller;
  VoidCallback? _detachLink;
  Mutation<DeliveryIssue>? _submitMutation;
  String? _submitSignature;
  Mutation<DeliveryIssue>? _resolveMutation;
  String? _resolveSignature;
  String? _tripId;
  int _viewers = 0;
  final Epoch _epoch = Epoch();

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

  String? _issueIdFor(String tripId) => _issueIds[tripId] ?? _trip.trip?.delivery?.openIssueId;

  void release() {
    if (_viewers > 0) _viewers--;
    if (_viewers == 0) _stopPolling();
  }

  Future<void> open(String tripId) async {
    _viewers++;
    await _begin(tripId);
  }

  Future<void> retry() async {
    final tripId = _tripId;
    if (tripId != null) await _begin(tripId, force: true);
  }

  Future<void> _begin(String tripId, {bool force = false}) async {
    if (!force && _tripId == tripId && _poller != null && state is! IssueUnavailable) return;
    _stopPolling();
    _tripId = tripId;
    final epoch = _epoch.next();
    final issueId = _issueIdFor(tripId);
    if (issueId == null) {
      _state.value = const IssueIdle();
      return;
    }
    _issueIds[tripId] = issueId;
    _state.value = const IssueLoading();
    _startPolling(epoch);
  }

  void close() {
    _stopPolling();
    _releaseMutations();
    _epoch.next();
    _tripId = null;
    _viewers = 0;
    _state.value = const IssueIdle();
  }

  void _releaseMutations() {
    _submitMutation?.dispose();
    _submitMutation = null;
    _submitSignature = null;
    _resolveMutation?.dispose();
    _resolveMutation = null;
    _resolveSignature = null;
  }

  void _startPolling(int epoch) {
    _stopPolling();
    final poller = LivePoller(fetch: () => _pollOnce(epoch), interval: pollInterval);
    void mirror() => _onLink(poller.link.value);
    poller.link.addListener(mirror);
    _detachLink = () => poller.link.removeListener(mirror);
    _poller = poller;
    poller.start();
  }

  void _stopPolling() {
    _detachLink?.call();
    _detachLink = null;
    _poller?.dispose();
    _poller = null;
  }

  void _onLink(LinkState link) {
    final current = state;
    if (current is! IssueInProgress) return;
    final isStale = link != LinkState.live;
    if (current.isStale != isStale) _state.value = IssueInProgress(current.issue, isStale: isStale);
  }

  Future<void> _pollOnce(int epoch) async {
    final tripId = _tripId;
    final issueId = tripId == null ? null : _issueIds[tripId];
    if (tripId == null || issueId == null || !_epoch.isCurrent(epoch)) return;
    final current = state;
    if (current is IssueSubmitting || current is IssueResolving) return;
    try {
      final fetched = await _fetchIssue(tripId, issueId);
      if (!_epoch.isCurrent(epoch)) return;
      _apply(fetched);
    } catch (error) {
      if (!_epoch.isCurrent(epoch)) return;
      if (state is IssueLoading) _state.value = IssueUnavailable(DeliveryIssueProblem.of(error));
      rethrow;
    }
  }

  Future<DeliveryIssue> _fetchIssue(String tripId, String issueId) async {
    final response = await _api.get(DeliveryLiveEndpoints.issueOf(tripId, issueId), suppressErrorToast: true);
    return DeliveryIssue.fromJson(response.dataMapOrEmpty);
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
      DeliveryIssueStatus.reported ||
      DeliveryIssueStatus.investigating ||
      DeliveryIssueStatus.unknown => IssueInProgress(issue),
    };
    if (issue.status == DeliveryIssueStatus.resolved) {
      _stopPolling();
      unawaited(_trip.pollNow());
    }
  }

  Future<bool> submit(DeliveryIssueReason reason, String note) async {
    final tripId = _tripId;
    if (tripId == null || state is IssueSubmitting) return false;
    final trimmed = note.trim();
    if (LiveProblem.isOffline) {
      _state.value = IssueSubmitFailed(DeliveryIssueProblem.connection, reason, trimmed);
      return false;
    }
    final epoch = _epoch.next();
    _stopPolling();
    _state.value = IssueSubmitting(reason, trimmed);
    final mutation = _submitMutationFor(tripId, reason, trimmed);
    final result = await mutation.start();
    if (!_epoch.isCurrent(epoch)) return false;
    switch (result) {
      case MutationDone<DeliveryIssue>(:final value):
        _submitMutation?.dispose();
        _submitMutation = null;
        _issueIds[tripId] = value.id;
        _apply(value);
        _startPolling(epoch);
        return true;
      case MutationRejected<DeliveryIssue>(:final error):
        _submitMutation?.dispose();
        _submitMutation = null;
        _state.value = IssueSubmitFailed(DeliveryIssueProblem.of(error), reason, trimmed);
      case MutationFailed<DeliveryIssue>(:final error):
        _state.value = IssueSubmitFailed(DeliveryIssueProblem.of(error), reason, trimmed);
      case MutationUnknown<DeliveryIssue>():
        _state.value = IssueSubmitFailed(DeliveryIssueProblem.unknown, reason, trimmed);
      default:
        break;
    }
    return false;
  }

  Mutation<DeliveryIssue> _submitMutationFor(String tripId, DeliveryIssueReason reason, String note) {
    final signature = '$tripId|${reason.code}|$note';
    final existing = _submitMutation;
    if (existing != null && _submitSignature == signature) return existing;
    existing?.dispose();
    _submitSignature = signature;
    return _submitMutation = Mutation<DeliveryIssue>(
      intent: IdempotencyIntent.deliveryIssue,
      run: (key) async {
        final response = await _api.post(
          DeliveryLiveEndpoints.issuesOf(tripId),
          data: {'reason': reason.code, 'note': note.isEmpty ? null : note},
          key: key,
          suppressErrorToast: true,
        );
        return DeliveryIssue.fromJson(response.dataMapOrEmpty);
      },
      reconcile: () async {
        final trip = await _trip.pollNow();
        final issueId = trip?.delivery?.openIssueId;
        if (trip == null) return const ReconciledPending();
        if (issueId == null) return const ReconciledNotDone();
        return ReconciledDone(await _fetchIssue(tripId, issueId));
      },
    );
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
    if (LiveProblem.isOffline) {
      _state.value = IssueResolutionFailed(issue, optionId: optionId, problem: DeliveryIssueProblem.connection);
      return false;
    }
    final epoch = _epoch.next();
    _stopPolling();
    _state.value = IssueResolving(issue, optionId: optionId);
    final mutation = _resolveMutationFor(tripId, issue, optionId);
    final result = await mutation.start();
    if (!_epoch.isCurrent(epoch)) return false;
    switch (result) {
      case MutationDone<DeliveryIssue>(:final value):
        _resolveMutation?.dispose();
        _resolveMutation = null;
        _apply(value);
        if (value.status != DeliveryIssueStatus.resolved) _startPolling(epoch);
        return true;
      case MutationRejected<DeliveryIssue>(:final error):
        _resolveMutation?.dispose();
        _resolveMutation = null;
        _state.value = IssueResolutionFailed(issue, optionId: optionId, problem: DeliveryIssueProblem.of(error));
      case MutationFailed<DeliveryIssue>(:final error):
        _state.value = IssueResolutionFailed(issue, optionId: optionId, problem: DeliveryIssueProblem.of(error));
      case MutationUnknown<DeliveryIssue>():
        _state.value = IssueResolutionFailed(issue, optionId: optionId, problem: DeliveryIssueProblem.unknown);
      default:
        break;
    }
    _startPolling(epoch);
    return false;
  }

  Mutation<DeliveryIssue> _resolveMutationFor(String tripId, DeliveryIssue issue, String optionId) {
    final signature = '$tripId|${issue.id}|$optionId';
    final existing = _resolveMutation;
    if (existing != null && _resolveSignature == signature) return existing;
    existing?.dispose();
    _resolveSignature = signature;
    return _resolveMutation = Mutation<DeliveryIssue>(
      intent: IdempotencyIntent.deliveryIssueResolve,
      run: (key) async {
        final response = await _api.post(
          DeliveryLiveEndpoints.issueResolutionOf(tripId, issue.id),
          data: {'option': optionId},
          key: key,
          suppressErrorToast: true,
        );
        return DeliveryIssue.fromJson(response.dataMapOrEmpty);
      },
      reconcile: () async {
        final fresh = await _fetchIssue(tripId, issue.id);
        return fresh.status == DeliveryIssueStatus.actionNeeded ? const ReconciledNotDone() : ReconciledDone(fresh);
      },
    );
  }
}
