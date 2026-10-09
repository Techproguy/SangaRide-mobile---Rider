abstract final class IdempotencyIntent {
  static const String blockDriver = 'block-driver';
  static const String confirmDriver = 'confirm-driver';
  static const String deleteAccount = 'delete-account';
  static const String deliveryIssue = 'delivery-issue';
  static const String deliveryIssueResolve = 'delivery-issue-resolve';
  static const String deliveryPickup = 'delivery-pickup';
  static const String flightNotify = 'flight-notify';
  static const String groupCreate = 'group-create';
  static const String groupInvite = 'group-invite';
  static const String groupJoin = 'group-join';
  static const String groupLeave = 'group-leave';
  static const String holdOffer = 'hold-offer';
  static const String ignoreOffer = 'ignore-offer';
  static const String inviteAccept = 'invite-accept';
  static const String inviteDecline = 'invite-decline';
  static const String memberRemove = 'member-remove';
  static const String memberUpdate = 'member-update';
  static const String notificationsReadAll = 'notifications-read-all';
  static const String passengerCode = 'passenger-code';
  static const String phoneChange = 'phone-change';
  static const String phoneVerify = 'phone-verify';
  static const String profilePhoto = 'profile-photo';
  static const String remindRide = 'remind-ride';
  static const String requestOtp = 'request-otp';
  static const String rideRequest = 'ride-request';
  static const String safetyContact = 'safety-contact';
  static const String safetyReport = 'safety-report';
  static const String savePlace = 'save-place';
  static const String saveHome = 'save-home';
  static const String scheduleRide = 'schedule-ride';
  static const String signUp = 'sign-up';
  static const String sos = 'sos';
  static const String sosEnd = 'sos-end';
  static const String supportChat = 'support-chat';
  static const String supportTicket = 'support-ticket';
  static const String ticketResolution = 'ticket-resolution';
  static const String topUpOtp = 'topup-otp';
  static const String tripAddStops = 'trip-add-stops';
  static const String tripCancel = 'trip-cancel';
  static const String tripPay = 'trip-pay';
  static const String tripPayCancel = 'trip-pay-cancel';
  static const String tripRating = 'trip-rating';
  static const String tripShare = 'trip-share';
  static const String unblockDriver = 'unblock-driver';
  static const String verificationSubmit = 'verification-submit';

  static String approval(String action) => 'approval-$action';

  static String skipOnboardingStep(String step) => 'skip-$step';

  static String topUp(String methodCode) => 'topup-$methodCode';

  static String tripAction(String name) => 'trip-$name';

  static String cancelRideRequestKey(String requestId) => 'cancel-ride-request-$requestId';

  static String chatEndKey(String chatId) => 'chat-end-$chatId';

  static String chatMessageKey(String clientId) => 'chat-msg-$clientId';

  static String notificationReadKey(String notificationId) => 'notification-read-$notificationId';

  static String selfieKey(String uploadId) => 'selfie-$uploadId';

  static String tripChatKey(String clientId) => 'chat-$clientId';
}
