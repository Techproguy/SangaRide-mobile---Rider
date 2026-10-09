abstract final class ServerCode {
  static const String activeTrip = 'active_trip';
  static const String alreadyNotified = 'already_notified';
  static const String alreadyPaid = 'already_paid';
  static const String alreadyRated = 'already_rated';
  static const String articleNotFound = 'article_not_found';
  static const String cardDeclined = 'card_declined';
  static const String cardExpired = 'card_expired';
  static const String chatEnded = 'chat_ended';
  static const String chatUnavailable = 'chat_unavailable';
  static const String emailTaken = 'email_taken';
  static const String faceNotMatched = 'face_not_matched';
  static const String fileTooLarge = 'file_too_large';
  static const String groupWalletShort = 'group_wallet_short';
  static const String incomplete = 'incomplete';
  static const String insufficientBalance = 'insufficient_balance';
  static const String invalidEmail = 'invalid_email';
  static const String invalidOption = 'invalid_option';
  static const String invalidPhone = 'invalid_phone';
  static const String nameRequired = 'name_required';
  static const String noteTooLong = 'note_too_long';
  static const String otpExpired = 'otp_expired';
  static const String otpMismatch = 'otp_mismatch';
  static const String phoneTaken = 'phone_taken';
  static const String photoUnreadable = 'photo_unreadable';
  static const String quoteExpired = 'quote_expired';
  static const String requiresApproval = 'requires_approval';
  static const String samePhone = 'same_phone';
  static const String ticketNotFound = 'ticket_not_found';
  static const String tooYoung = 'too_young';
  static const String typeRequired = 'type_required';
  static const String unsupportedType = 'unsupported_type';
  static const String uploadFailed = 'upload_failed';
  static const String wrongStage = 'wrong_stage';

  static const Set<String> paymentDeclines = {cardDeclined, cardExpired, insufficientBalance, groupWalletShort};
}
