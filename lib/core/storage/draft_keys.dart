abstract final class DraftKeys {
  static const String rideMatch = 'ride_match';
  static const String pendingRideCancels = 'pending_ride_cancels';
  static const String verificationDocument = 'verification:document';
  static const String deliveryDraft = 'delivery_draft';

  static String topUp(String? scopeTag) => 'topup:${scopeTag ?? 'personal'}';
}

abstract final class SessionNames {
  static const String restore = 'restore';
  static const String tokens = 'tokens';
  static const String user = 'user';
  static const String drafts = 'drafts';
  static const String controllers = 'controllers';
  static const String rideMatch = 'ride_match';
}
