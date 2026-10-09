import 'dart:io';

import 'package:get/get.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/idempotency_intents.dart';
import 'package:sanga_ride/core/api/server_codes.dart';
import 'package:sanga_ride/core/api/upload_purposes.dart';
import 'package:sanga_ride/core/api/verification_endpoints.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart' show SangaSelfieOutcome;

class SelfieVerifier {
  static const Set<String> _acceptedStatuses = {'verified', 'pending'};

  final _api = Get.find<ApiService>();
  final Map<String, String> _uploadIds = {};

  Future<SangaSelfieOutcome> verify(String photoPath) async {
    if (ConnectionMonitor.current?.isOnline == false) return SangaSelfieOutcome.noConnection;
    try {
      final uploadId = _uploadIds[photoPath] ??= await _upload(photoPath);
      final response = await _api.post(
        VerificationEndpoints.selfie,
        data: {'uploadId': uploadId},
        key: IdempotencyKey(IdempotencyIntent.selfieKey(uploadId)),
        suppressErrorToast: true,
      );
      final status = JsonReader(response.dataMapOrEmpty).strOrNull('status');
      return _acceptedStatuses.contains(status) ? SangaSelfieOutcome.passed : SangaSelfieOutcome.serverTrouble;
    } on Object catch (error) {
      return switch (ProblemKind.of(error)) {
        ProblemOffline() => SangaSelfieOutcome.noConnection,
        ProblemRejected(code: ServerCode.faceNotMatched) => SangaSelfieOutcome.noMatch,
        _ => SangaSelfieOutcome.serverTrouble,
      };
    }
  }

  Future<String> _upload(String photoPath) async {
    final ref = await _api.upload(
      VerificationEndpoints.uploads,
      file: File(photoPath),
      purpose: UploadPurposes.selfie,
      suppressErrorToast: true,
    );
    return ref.id;
  }
}
