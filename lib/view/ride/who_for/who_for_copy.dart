abstract final class WhoForCopy {
  static const String passengerConfirmed = 'Passenger confirmed';

  static String textTripDetails(String firstName) => 'We’ll text $firstName the trip details.';

  static String passengerCodeLead(int length, String maskedPhone, String firstName) =>
      'Enter the $length-digit code sent to $maskedPhone to check this is $firstName’s number.';
}
