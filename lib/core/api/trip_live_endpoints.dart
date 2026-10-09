abstract final class TripLiveEndpoints {
  static const String tripPaymentAuthorize = '/trips/:id/payment/authorize';
  static const String tripShare = '/trips/:id/share';
  static const String tripReturnFee = '/trips/:id/return-fee';

  static String tripPaymentAuthorizeOf(String id) => tripPaymentAuthorize.replaceFirst(':id', id);

  static String tripShareOf(String id) => tripShare.replaceFirst(':id', id);
}
