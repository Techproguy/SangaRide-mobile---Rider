import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';

class VerificationHeroCopy {
  const VerificationHeroCopy({required this.title, required this.message});

  final String title;
  final String message;
}

abstract final class VerificationCopy {
  static const String done = 'Done';
  static const String tryAgain = 'Try again';
  static const String addYourId = 'Add your ID';
  static const String underReviewTitle = 'Verification under review';
  static const String idSavedTakeSelfie = 'Your ID is saved. Take your selfie and we’ll send it all off.';
  static const String takeYourSelfie = 'Take your selfie';
  static const String documentType = 'Document type';
  static const String pickIdLead = 'Pick the ID you want to use and we’ll show you what to upload.';
  static const String backOfId = 'Back of ID';
  static const String informationSecure = 'Your information is secure and only used for verification.';
  static const String documentVerification = 'Document verification';
  static const String submitForReview = 'Submit for review';
  static const String uploadValidId = 'Upload a valid ID';
  static const String verifiedTitle = 'You’re verified';
  static const String verifiedMessage = 'Thanks for waiting. Your account is all set.';
  static const String anotherGoTitle = 'Verification needs another go';
  static const String anotherGoMessage = 'We couldn’t verify everything. Have a look and try again.';
  static const String notNow = 'Not now';
  static const String talkToSupport = 'Need help? Talk to support';
  static const String centreTitle = 'Verification centre';
  static const String selfieTitle = 'Selfie verification';
  static const String selfieSubtitle = 'Verify your identity';
  static const String selfiePassed = 'Looking good! Your selfie is saved.';
  static const String uploaded = 'Uploaded';
  static const String choosePhoto = 'Choose a photo';
  static const String chooseAnother = 'Choose another';
  static const String tagVerified = 'Verified';
  static const String tagInReview = 'In review';
  static const String tagExpired = 'Expired';
  static const String tagExpiringSoon = 'Expiring soon';

  static String underReviewMessage(int estimatedReviewHours) =>
      'This usually takes up to ${hoursLabel(estimatedReviewHours)}. We’ll let you know in your notifications.';

  static String sentLine(String ago) => 'Sent $ago. We’ll let you know in your notifications.';

  static String uploading(String label) => 'Uploading $label';

  static String replace(String label) => 'Replace $label';

  static String remove(String label) => 'Remove $label';

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
      return verification.isReadyToSubmit ? submitForReview : done;
    }
    if (status.needsAction) return tryAgain;
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
