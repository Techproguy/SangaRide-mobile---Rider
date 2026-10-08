import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';

class VerificationHeroCopy {
  const VerificationHeroCopy({required this.title, required this.message});

  final String title;
  final String message;
}

abstract final class VerificationCopy {
  static VerificationHeroCopy heroOf(Verification verification) => switch (verification.status) {
    VerificationStatus.unverified => const VerificationHeroCopy(
      title: 'Let’s verify you',
      message: 'A quick selfie and a valid ID keep rides safer for you and your drivers.',
    ),
    VerificationStatus.pending => VerificationHeroCopy(
      title: 'Under review',
      message:
          'We’re checking your details. This usually takes up to ${hoursLabel(verification.estimatedReviewHours)}.',
    ),
    VerificationStatus.verified => const VerificationHeroCopy(
      title: 'You’re verified',
      message: 'Thanks for helping keep Sanga safe.',
    ),
    VerificationStatus.rejected || VerificationStatus.actionNeeded => const VerificationHeroCopy(
      title: 'Let’s fix a few things',
      message: 'We couldn’t verify everything. Check the steps below and try again.',
    ),
  };

  static String hoursLabel(int hours) {
    if (hours % 24 == 0) {
      final days = hours ~/ 24;
      return days == 1 ? '24 hours' : '$days days';
    }
    return hours == 1 ? '1 hour' : '$hours hours';
  }

  static String primaryLabelOf(Verification verification) {
    final next = verification.nextItem;
    final status = verification.status;
    if (next == null) {
      return verification.isReadyToSubmit ? 'Submit for review' : 'Done';
    }
    if (status.needsAction) return 'Try again';
    return next.status == ItemStatus.missing && verification.items.every((item) => item.status == ItemStatus.missing)
        ? 'Start verification'
        : 'Continue';
  }

  static String itemSubtitleOf(VerificationItem item) => switch (item.status) {
    ItemStatus.missing => item.kind == VerificationItemKind.selfie ? 'Take a quick selfie' : 'Upload a valid ID',
    ItemStatus.pending => 'We’re reviewing this',
    ItemStatus.verified => 'All good',
    ItemStatus.rejected || ItemStatus.expired => item.reason?.message ?? 'This needs another go',
    ItemStatus.expiring => 'Expires soon',
  };

  static IconData iconOf(VerificationItemKind kind) => switch (kind) {
    VerificationItemKind.document => Icons.badge_outlined,
    VerificationItemKind.selfie => Icons.face_retouching_natural_outlined,
  };
}
