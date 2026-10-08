import 'package:sanga_ride/model/delivery/package_photo.dart';
import 'package:sanga_ride/model/verification/id_document_type.dart';
import 'package:sanga_ride/model/verification/verification_problem.dart';

enum DocumentSide { front, back }

class DocumentDraft {
  const DocumentDraft({
    this.type,
    this.front = const PhotoNone(),
    this.back = const PhotoNone(),
    this.isSubmitting = false,
    this.problem,
    this.missing = const [],
  });

  final IdDocumentType? type;
  final PackagePhotoState front;
  final PackagePhotoState back;
  final bool isSubmitting;
  final VerificationProblem? problem;
  final List<String> missing;

  PackagePhotoState sideOf(DocumentSide side) => side == DocumentSide.front ? front : back;

  bool get needsBack => type?.hasBack ?? false;

  bool get isBusy => front.isBusy || back.isBusy || isSubmitting;

  bool get isReady => type != null && front is PhotoUploaded && (!needsBack || back is PhotoUploaded) && !isBusy;

  DocumentDraft copyWith({
    IdDocumentType? type,
    PackagePhotoState? front,
    PackagePhotoState? back,
    bool? isSubmitting,
    VerificationProblem? problem,
    bool clearProblem = false,
    List<String>? missing,
  }) => DocumentDraft(
    type: type ?? this.type,
    front: front ?? this.front,
    back: back ?? this.back,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    problem: clearProblem ? null : problem ?? this.problem,
    missing: missing ?? this.missing,
  );
}
