import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/trip/live_problem.dart';
import 'package:sanga_ride/controller/rider/trip/trip_controller.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/app_endpoints.dart';
import 'package:sanga_ride/core/services/session_restore.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

class CancelController extends GetxController {
  final _api = Get.find<ApiService>();
  final _trip = Get.find<TripController>();

  final Rx<CancelState> _state = Rx<CancelState>(const CancelChoosing());
  Mutation<CancelOutcome>? _mutation;
  String? _signature;
  String? _tripId;
  int _epoch = 0;

  Rx<CancelState> get stateRx => _state;

  CancelState get state => _state.value;

  bool get isBusy => switch (state) {
    CancelLoadingReview() => true,
    CancelReviewing(:final isSubmitting) => isSubmitting,
    _ => false,
  };

  @override
  void onClose() {
    _releaseMutation();
    super.onClose();
  }

  void open(String tripId) {
    _tripId = tripId;
    _epoch++;
    _releaseMutation();
    _state.value = const CancelChoosing();
  }

  void reset() {
    _tripId = null;
    _epoch++;
    _releaseMutation();
    _state.value = const CancelChoosing();
  }

  void _releaseMutation() {
    _mutation?.dispose();
    _mutation = null;
    _signature = null;
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
    if (LiveProblem.isOffline) {
      LiveProblem.toastOffline();
      return;
    }
    final reason = current.reason!;
    final epoch = ++_epoch;
    _state.value = CancelLoadingReview(reason, current.note);
    try {
      final review = await _fetchReview(id, reason);
      if (epoch != _epoch) return;
      _state.value = CancelReviewing(reason, current.note, review);
    } catch (e) {
      log('cancellation review failed: $e');
      if (epoch == _epoch) await _fail(e, previous: current, fallback: CancelFailure.reviewUnavailable);
    }
  }

  Future<CancellationReview> _fetchReview(String id, CancelReason reason) async {
    final response = await _api.get(
      AppEndpoints.liveTripCancellationOf(id),
      queryParameters: {'reason': reason.code},
      suppressErrorToast: true,
      profile: RequestProfile.interactive,
    );
    return CancellationReview.fromJson(_dataOf(response.data));
  }

  Future<void> submit() async {
    final current = state;
    final id = _tripId;
    if (current is! CancelReviewing || current.isSubmitting || id == null) return;
    if (LiveProblem.isOffline) {
      LiveProblem.toastOffline();
      return;
    }
    final epoch = ++_epoch;
    final reviewing = CancelReviewing(current.reason, current.note, current.review);
    _state.value = reviewing.submitting();
    final mutation = _mutationFor(id, reviewing);
    final result = await mutation.start();
    if (epoch != _epoch) return;
    switch (result) {
      case MutationDone<CancelOutcome>(:final value):
        _releaseMutation();
        _state.value = CancelDone(value);
        unawaited(_afterCancel());
      case MutationRejected<CancelOutcome>(:final error):
        _releaseMutation();
        await _onRejected(error, reviewing);
      case MutationFailed<CancelOutcome>(:final error):
        _state.value = CancelFailed(CancelFailure.of(error, fallback: CancelFailure.connection), reviewing);
      case MutationUnknown<CancelOutcome>():
        _state.value = CancelFailed(CancelFailure.outcomeUnknown, reviewing);
      default:
        break;
    }
  }

  Mutation<CancelOutcome> _mutationFor(String id, CancelReviewing reviewing) {
    final note = reviewing.note.trim();
    final signature = '${reviewing.review.reviewId}|${reviewing.reason.code}|$note';
    final existing = _mutation;
    if (existing != null && _signature == signature) return existing;
    existing?.dispose();
    _signature = signature;
    return _mutation = Mutation<CancelOutcome>(
      intent: 'trip-cancel',
      run: (key) async {
        final response = await _api.post(
          AppEndpoints.liveTripCancelOf(id),
          data: {
            'reason': reviewing.reason.code,
            if (note.isNotEmpty) 'note': note,
            'reviewId': reviewing.review.reviewId,
            'fee': reviewing.review.fee,
          },
          key: key,
          suppressErrorToast: true,
        );
        return CancelOutcome.fromJson(_dataOf(response.data));
      },
      reconcile: () => _reconcile(id, reviewing.review.fee),
    );
  }

  Future<Reconciled<CancelOutcome>> _reconcile(String id, int fee) async {
    final trip = await _trip.pollNow();
    if (trip == null) return const ReconciledPending();
    if (trip.status != TripStatus.cancelled) return const ReconciledNotDone();
    final reason = trip.cancellationReason ?? TripCancelReason.riderCancelled;
    return ReconciledDone(
      CancelOutcome(tripId: id, feeCharged: fee, message: trip.cancellationMessage ?? reason.message),
    );
  }

  Future<void> _afterCancel() async {
    await _trip.pollNow();
    await Get.find<SessionRestore>().refreshQuietly();
  }

  Future<void> _onRejected(ApiException error, CancelReviewing reviewing) async {
    final failure = CancelFailure.fromCode(error.code);
    if (failure.isFeeChange) {
      await _reviewAgain(error, reviewing);
      return;
    }
    await _fail(error, previous: reviewing, fallback: CancelFailure.connection);
  }

  Future<void> _reviewAgain(ApiException error, CancelReviewing reviewing) async {
    final epoch = _epoch;
    final id = _tripId;
    if (id == null) return;
    final embedded = error.data['review'];
    try {
      final review = embedded is Map
          ? CancellationReview.fromJson(Map<String, dynamic>.from(embedded))
          : await _fetchReview(id, reviewing.reason);
      if (epoch != _epoch) return;
      _state.value = CancelReviewing(reviewing.reason, reviewing.note, review, feeWas: reviewing.review.fee);
    } catch (e) {
      log('cancellation re-review failed: $e');
      if (epoch == _epoch) {
        _state.value = CancelFailed(
          CancelFailure.of(e, fallback: CancelFailure.reviewUnavailable),
          CancelChoosing(reason: reviewing.reason, note: reviewing.note),
        );
      }
    }
  }

  Future<void> _fail(Object error, {required CancelState previous, required CancelFailure fallback}) async {
    final failure = CancelFailure.of(error, fallback: fallback);
    if (!failure.isStale) {
      _state.value = CancelFailed(failure, previous);
      return;
    }
    final epoch = _epoch;
    await _trip.pollNow();
    if (epoch != _epoch) return;
    final trip = _trip.trip;
    final isTripLive = trip != null && !trip.status.isTerminal;
    _state.value = isTripLive
        ? CancelFailed(failure, previous)
        : CancelSettled(failure, message: trip?.cancellationMessage);
  }

  bool resolveFailure({required bool isPrimary}) {
    final current = state;
    if (current is! CancelFailed) return false;
    final failure = current.failure;
    if (failure.isStale) return true;
    if (failure == CancelFailure.outcomeUnknown) return _resolveUnknown(current, isPrimary: isPrimary);
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

  bool _resolveUnknown(CancelFailed current, {required bool isPrimary}) {
    if (!isPrimary) return true;
    final previous = current.previous;
    if (previous is! CancelReviewing) return false;
    _state.value = previous.submitting();
    unawaited(_recheck(previous));
    return false;
  }

  Future<void> _recheck(CancelReviewing reviewing) async {
    final mutation = _mutation;
    final epoch = ++_epoch;
    if (mutation == null) {
      _state.value = reviewing;
      return;
    }
    final result = await mutation.recheck();
    if (epoch != _epoch) return;
    switch (result) {
      case MutationDone<CancelOutcome>(:final value):
        _releaseMutation();
        _state.value = CancelDone(value);
        unawaited(_afterCancel());
      case MutationFailed<CancelOutcome>():
        _state.value = reviewing;
      default:
        _state.value = CancelFailed(CancelFailure.outcomeUnknown, reviewing);
    }
  }

  Map<String, dynamic> _dataOf(dynamic body) => JsonReader.of(JsonReader.of(body).raw['data']).raw;
}
