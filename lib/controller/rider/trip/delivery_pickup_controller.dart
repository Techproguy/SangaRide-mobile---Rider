import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/trip/live_problem.dart';
import 'package:sanga_ride/controller/rider/trip/trip_controller.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/delivery_live_endpoints.dart';
import 'package:sanga_ride/core/api/idempotency_intents.dart';
import 'package:sanga_ride/core/api/server_codes.dart';
import 'package:sanga_ride/core/api/upload_purposes.dart';
import 'package:sanga_ride/core/services/image_compression_service.dart';
import 'package:sanga_ride/core/services/package_photo_service.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

class DeliveryPickupController extends GetxController {
  final _api = Get.find<ApiService>();
  final _trip = Get.find<TripController>();

  final Rx<DeliveryPickupState> _state = Rx<DeliveryPickupState>(const PickupEmpty());
  Mutation<Trip>? _mutation;
  String? _mutationSignature;
  String? _tripId;
  final Epoch _epoch = Epoch();

  Rx<DeliveryPickupState> get stateRx => _state;

  DeliveryPickupState get state => _state.value;

  @override
  void onClose() {
    _epoch.next();
    _releaseMutation();
    super.onClose();
  }

  void _releaseMutation() {
    _mutation?.dispose();
    _mutation = null;
    _mutationSignature = null;
  }

  void open(String tripId) {
    if (_tripId == tripId) return;
    _epoch.next();
    _tripId = tripId;
    _releaseMutation();
    _state.value = const PickupEmpty();
  }

  Future<void> takePhoto() async {
    if (state.isBusy && state is! PickupUploading) return;
    if (state is PickupConfirmed || state is PickupConfirming) return;
    final epoch = _epoch.next();
    final previous = state;
    try {
      final path = await PackagePhotoService.pick(
        PhotoSource.camera,
        onPicked: () {
          if (_epoch.isCurrent(epoch)) _state.value = const PickupPreparing();
        },
      );
      if (!_epoch.isCurrent(epoch)) return;
      if (path == null) {
        _state.value = previous is PickupPreparing ? const PickupEmpty() : previous;
        return;
      }
      await _discardPhotoOf(previous);
      await _upload(path, epoch);
    } on PhotoException catch (e) {
      if (_epoch.isCurrent(epoch)) _state.value = PickupPhotoFailed(DeliveryPickupProblem.fromCode(e.failure.code));
    }
  }

  Future<void> removePhoto() async {
    if (state is PickupConfirmed || state is PickupConfirming || state is PickupPreparing) return;
    _epoch.next();
    final previous = state;
    _state.value = const PickupEmpty();
    await _discardPhotoOf(previous);
  }

  Future<void> _discardPhotoOf(DeliveryPickupState previous) => ImageCompressionService.discard(previous.photoPath);

  Future<void> retryUpload() async {
    final path = state.photoPath;
    if (path == null || state is! PickupPhotoFailed) return;
    await _upload(path, _epoch.next());
  }

  Future<void> _upload(String path, int epoch) async {
    _state.value = PickupUploading(path, progress: 0);
    try {
      final ref = await _api.upload(
        DeliveryLiveEndpoints.uploads,
        file: File(path),
        purpose: UploadPurposes.pickupProof,
        suppressErrorToast: true,
        onProgress: (sent, total) {
          if (_epoch.isCurrent(epoch) && total > 0) _state.value = PickupUploading(path, progress: sent / total);
        },
      );
      if (!_epoch.isCurrent(epoch)) return;
      _state.value = PickupReady(path, photoId: ref.id);
    } catch (e) {
      log('pickup photo upload failed: ${e is ApiException ? e.code : e.runtimeType}');
      if (!_epoch.isCurrent(epoch)) return;
      final problem = e is ApiException && e.kind == ApiFailureKind.rejected
          ? DeliveryPickupProblem.fromCode(e.code)
          : DeliveryPickupProblem.uploadFailed;
      _state.value = PickupPhotoFailed(
        problem.isPhotoProblem ? problem : DeliveryPickupProblem.uploadFailed,
        path: path,
      );
    }
  }

  Future<bool> confirm() async {
    final id = _tripId;
    final current = state;
    if (id == null || !current.canConfirm) return false;
    if (LiveProblem.isOffline) {
      _state.value = PickupConfirmFailed(
        DeliveryPickupProblem.connection,
        path: current.photoPath,
        photoId: _photoIdOf(current),
      );
      return false;
    }
    final photoId = _photoIdOf(current);
    final path = current.photoPath;
    final epoch = _epoch.next();
    _state.value = PickupConfirming(path, photoId: photoId);
    final mutation = _mutationFor(id, photoId);
    final result = await mutation.start();
    if (!_epoch.isCurrent(epoch)) return false;
    switch (result) {
      case MutationDone<Trip>(:final value):
        _releaseMutation();
        _trip.applyServerTrip(value);
        _state.value = PickupConfirmed(path);
        unawaited(ImageCompressionService.discard(path));
        return true;
      case MutationRejected<Trip>(:final error):
        _releaseMutation();
        return _onRejected(error, path, photoId);
      case MutationFailed<Trip>(:final error):
        _state.value = PickupConfirmFailed(DeliveryPickupProblem.of(error), path: path, photoId: photoId);
      case MutationUnknown<Trip>():
        _state.value = PickupConfirmFailed(DeliveryPickupProblem.unknown, path: path, photoId: photoId);
      default:
        break;
    }
    return false;
  }

  String? _photoIdOf(DeliveryPickupState current) => switch (current) {
    PickupReady(:final photoId) => photoId,
    PickupConfirmFailed(:final photoId) => photoId,
    _ => null,
  };

  Future<bool> _onRejected(ApiException error, String? path, String? photoId) async {
    if (error.code == ServerCode.wrongStage) {
      final trip = await _trip.pollNow();
      final hasMovedOn = trip?.delivery?.stage.isPastPickup ?? false;
      if (hasMovedOn) {
        _state.value = PickupConfirmed(path);
        return true;
      }
      _state.value = PickupConfirmFailed(DeliveryPickupProblem.movedOn, path: path, photoId: photoId);
      return false;
    }
    _state.value = PickupConfirmFailed(DeliveryPickupProblem.of(error), path: path, photoId: photoId);
    return false;
  }

  Mutation<Trip> _mutationFor(String id, String? photoId) {
    final signature = '$id|$photoId';
    final existing = _mutation;
    if (existing != null && _mutationSignature == signature) return existing;
    existing?.dispose();
    _mutationSignature = signature;
    return _mutation = Mutation<Trip>(
      intent: IdempotencyIntent.deliveryPickup,
      run: (key) async {
        final response = await _api.post(
          DeliveryLiveEndpoints.pickupConfirmationOf(id),
          data: {'photoId': photoId},
          key: key,
          suppressErrorToast: true,
        );
        return Trip.fromJson(JsonReader.of(JsonReader.of(response.data).raw['data']).raw);
      },
      reconcile: () async {
        final trip = await _trip.pollNow();
        if (trip == null) return const ReconciledPending();
        final isDone = trip.delivery?.stage.isPastPickup ?? false;
        return isDone ? ReconciledDone(trip) : const ReconciledNotDone();
      },
    );
  }
}
