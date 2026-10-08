import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/trip/trip_controller.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/mock/mock_endpoints.dart';
import 'package:sanga_ride/model/models.dart';

class CancelController extends GetxController {
  final _api = Get.find<ApiService>();
  final _trip = Get.find<TripController>();

  final Rx<CancelState> _state = Rx<CancelState>(const CancelChoosing());
  String? _tripId;
  int _epoch = 0;

  Rx<CancelState> get stateRx => _state;

  CancelState get state => _state.value;

  bool get isBusy => switch (state) {
    CancelLoadingReview() => true,
    CancelReviewing(:final isSubmitting) => isSubmitting,
    _ => false,
  };

  void open(String tripId) {
    _tripId = tripId;
    _epoch++;
    _state.value = const CancelChoosing();
  }

  void reset() {
    _tripId = null;
    _epoch++;
    _state.value = const CancelChoosing();
  }

  void selectReason(CancelReason reason) {
    if (state case final CancelChoosing choosing) _state.value = choosing.withReason(reason);
  }

  void setNote(String note) {
    if (state case final CancelChoosing choosing) {
      _state.value = choosing.withNote(note);
    }
  }

  void backToReasons() {
    final current = state;
    if (current is CancelReviewing && !current.isSubmitting) {
      _state.value = CancelChoosing(reason: current.reason, note: current.note);
    }
  }

  Future<void> loadReview() async {
    final current = state;
    final id = _tripId;
    if (current is! CancelChoosing || !current.canContinue || id == null) return;
    final reason = current.reason!;
    final epoch = ++_epoch;
    _state.value = CancelLoadingReview(reason, current.note);
    try {
      final response = await _api.get(
        MockEndpoints.liveTripCancellationOf(id),
        queryParameters: {'reason': reason.code},
        suppressErrorToast: true,
      );
      if (epoch != _epoch) return;
      _state.value = CancelReviewing(reason, current.note, CancellationReview.fromJson(_dataOf(response.data)));
    } catch (e) {
      log('cancellation review failed: $e');
      if (epoch == _epoch) await _fail(e, previous: current, fallback: CancelFailure.reviewUnavailable);
    }
  }

  Future<void> submit() async {
    final current = state;
    final id = _tripId;
    if (current is! CancelReviewing || current.isSubmitting || id == null) return;
    final epoch = ++_epoch;
    _state.value = current.submitting();
    final note = current.note.trim();
    try {
      final response = await _api.post(
        MockEndpoints.liveTripCancelOf(id),
        data: {'reason': current.reason.code, if (note.isNotEmpty) 'note': note},
        suppressErrorToast: true,
      );
      final outcome = CancelOutcome.fromJson(_dataOf(response.data));
      if (epoch == _epoch) _state.value = CancelDone(outcome);
    } catch (e) {
      log('cancel failed: $e');
      if (epoch == _epoch) {
        await _fail(
          e,
          previous: CancelReviewing(current.reason, current.note, current.review),
          fallback: CancelFailure.connection,
        );
      }
    }
  }

  Future<void> _fail(Object error, {required CancelState previous, required CancelFailure fallback}) async {
    final failure = error is ApiException && error.code != null ? CancelFailure.fromCode(error.code) : fallback;
    if (!failure.isStale) {
      _state.value = CancelFailed(failure, previous);
      return;
    }
    final epoch = _epoch;
    await _trip.pollNow();
    if (epoch != _epoch) return;
    final trip = _trip.trip;
    final isTripLive = trip != null && !trip.status.isTerminal;
    _state.value = isTripLive ? CancelFailed(failure, previous) : CancelSettled(failure);
  }

  bool resolveFailure({required bool isPrimary}) {
    final current = state;
    if (current is! CancelFailed) return false;
    final failure = current.failure;
    if (failure.isStale) return true;
    if (!isPrimary) {
      _state.value = current.previous;
      return false;
    }
    switch (current.previous) {
      case CancelChoosing():
        _state.value = current.previous;
        unawaited(loadReview());
      case CancelReviewing():
        _state.value = current.previous;
        unawaited(submit());
      default:
        _state.value = const CancelChoosing();
    }
    return false;
  }

  Map<String, dynamic> _dataOf(dynamic body) => Map<String, dynamic>.from((body as Map)['data'] as Map);
}
