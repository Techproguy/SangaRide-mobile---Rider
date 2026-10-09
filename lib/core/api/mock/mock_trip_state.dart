abstract final class MockTripState {
  static final Map<String, Map<String, dynamic>> trips = {};
  static final Map<String, DateTime> paidAt = {};
  static final Map<String, String> paymentMethod = {};
  static final Map<String, DateTime> cashPostedAt = {};
  static final Map<String, String> cardLast4 = {};
  static final Map<String, String> cardChallenges = {};
  static final Map<String, int> ratings = {};
  static String? lastMethod;

  static void reset() {
    trips.clear();
    paidAt.clear();
    paymentMethod.clear();
    cashPostedAt.clear();
    cardLast4.clear();
    cardChallenges.clear();
    ratings.clear();
    lastMethod = null;
  }
}
