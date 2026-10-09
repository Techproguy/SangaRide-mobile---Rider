abstract final class MockTripState {
  static final Map<String, Map<String, dynamic>> trips = {};
  static final Map<String, DateTime> paidAt = {};
  static final Map<String, String> paymentMethod = {};

  static void reset() {
    trips.clear();
    paidAt.clear();
    paymentMethod.clear();
  }
}
