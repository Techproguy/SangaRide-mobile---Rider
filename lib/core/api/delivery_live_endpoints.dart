import 'package:sanga_ride/core/api/upload_purposes.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

abstract final class DeliveryLiveEndpoints {
  static const String uploads = '/uploads';
  static const String pickupConfirmation = '/deliveries/:id/pickup-confirmation';
  static const String issues = '/deliveries/:id/issues';
  static const String issue = '/deliveries/:id/issues/:issueId';
  static const String issueResolution = '/deliveries/:id/issues/:issueId/resolution';

  static const String pickupProofPurpose = UploadPurposes.pickupProof;

  static String pickupConfirmationOf(String tripId) => fillPath(pickupConfirmation, {'id': tripId});

  static String issuesOf(String tripId) => fillPath(issues, {'id': tripId});

  static String issueOf(String tripId, String issueId) => _issuePath(issue, tripId, issueId);

  static String issueResolutionOf(String tripId, String issueId) => _issuePath(issueResolution, tripId, issueId);

  static String _issuePath(String template, String tripId, String issueId) =>
      fillPath(template, {'id': tripId, 'issueId': issueId});
}
