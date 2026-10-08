abstract final class DeliveryLiveEndpoints {
  static const String uploads = '/uploads';
  static const String pickupConfirmation = '/deliveries/:id/pickup-confirmation';
  static const String issues = '/deliveries/:id/issues';
  static const String issue = '/deliveries/:id/issues/:issueId';
  static const String issueResolution = '/deliveries/:id/issues/:issueId/resolution';

  static const String pickupProofPurpose = 'pickup_proof';

  static String pickupConfirmationOf(String tripId) => pickupConfirmation.replaceFirst(':id', tripId);

  static String issuesOf(String tripId) => issues.replaceFirst(':id', tripId);

  static String issueOf(String tripId, String issueId) => _issuePath(issue, tripId, issueId);

  static String issueResolutionOf(String tripId, String issueId) => _issuePath(issueResolution, tripId, issueId);

  static String _issuePath(String template, String tripId, String issueId) =>
      template.replaceFirst(':id', tripId).replaceFirst(':issueId', issueId);
}
