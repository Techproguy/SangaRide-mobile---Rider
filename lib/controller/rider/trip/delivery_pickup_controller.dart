import 'dart:developer';
import 'dart:io';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/trip/trip_controller.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/delivery_live_endpoints.dart';
import 'package:sanga_ride/core/services/package_photo_service.dart';
import 'package:sanga_ride/model/models.dart';

class DeliveryPickupController extends GetxController {
  static const String movedOnCode = 'wrong_stage';

  final _api = Get.find<ApiService>();
  final _trip = Get.find<TripController>();

  final Rx<DeliveryPickupState> _state = Rx<DeliveryPickupState>(const PickupEmpty());
  String? _tripId;
  int _epoch = 0;

  Rx<DeliveryPickupState> get stateRx => _state;

  DeliveryPickupState get state => _state.value;

  @override
  void onClose() {
    _epoch++;
    super.onClose();
  }

  void open(String tripId) {
    if (_tripId == tripId) return;
    _epoch++;
    _tripId = tripId;
    _state.value = const PickupEmpty();
  }

  Future<void> takePhoto() async {
    if (state.isBusy || state is PickupConfirmed) return;
    final epoch = ++_epoch;
    final previous = state;
    try {
      final path = await PackagePhotoService.pick(
        PhotoSource.camera,
        onPicked: () {
          if (epoch == _epoch) _state.value = const PickupPreparing();
        },
      );
      if (epoch != _epoch) return;
      if (path == null) {
        _state.value = previous is PickupPreparing ? const PickupEmpty() : previous;
        return;
      }
      await _upload(path, epoch);
    } on PhotoException catch (e) {
      if (epoch == _epoch) _state.value = PickupPhotoFailed(DeliveryPickupProblem.fromCode(e.failure.code));
    }
  }

  void removePhoto() {
    if (state.isBusy || state is PickupConfirmed) return;
    _epoch++;
    _state.value = const PickupEmpty();
  }

  Future<void> retryUpload() async {
    final path = state.photoPath;
    if (path == null || state is! PickupPhotoFailed) return;
    await _upload(path, ++_epoch);
  }

  Future<void> _upload(String path, int epoch) async {
    _state.value = PickupUploading(path, progress: 0);
    try {
      final response = await _api.uploadFile(
        DeliveryLiveEndpoints.uploads,
        file: File(path),
        fields: {'purpose': DeliveryLiveEndpoints.pickupProofPurpose},
        suppressErrorToast: true,
        onSendProgress: (sent, total) {
          if (epoch == _epoch && total > 0) _state.value = PickupUploading(path, progress: sent / total);
        },
      );
      if (epoch != _epoch) return;
      final data = Map<String, dynamic>.from((response.data as Map)['data'] as Map);
      _state.value = PickupReady(path, photoId: data['id'] as String);
    } catch (e) {
      log('pickup photo upload failed: ${e is ApiException ? e.code : e.runtimeType}');
      if (epoch != _epoch) return;
      final problem = e is ApiException ? DeliveryPickupProblem.fromCode(e.code) : DeliveryPickupProblem.uploadFailed;
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
    final photoId = switch (current) {
      PickupReady(:final photoId) => photoId,
      PickupConfirmFailed(:final photoId) => photoId,
      _ => null,
    };
    final path = current.photoPath;
    final epoch = ++_epoch;
    _state.value = PickupConfirming(path, photoId: photoId);
    try {
      final response = await _api.post(
        DeliveryLiveEndpoints.pickupConfirmationOf(id),
        data: {'photoId': photoId},
        suppressErrorToast: true,
      );
      if (epoch != _epoch) return false;
      final data = Map<String, dynamic>.from((response.data as Map)['data'] as Map);
      _trip.applyServerTrip(Trip.fromJson(data));
      _state.value = PickupConfirmed(path);
      return true;
    } catch (e) {
      log('pickup confirmation failed: ${e is ApiException ? e.code : e.runtimeType}');
      if (epoch != _epoch) return false;
      final isMovedOn = e is ApiException && e.code == movedOnCode;
      final problem = isMovedOn ? DeliveryPickupProblem.movedOn : DeliveryPickupProblem.connection;
      _state.value = PickupConfirmFailed(problem, path: path, photoId: photoId);
      return false;
    }
  }
}
