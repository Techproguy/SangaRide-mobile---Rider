import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/model/models.dart';

extension RideOptionQuote on RideRequestController {
  Future<void> loadQuote() async {
    if (isEstimating) return;
    final isLoaded = estimate != null || await loadEstimate();
    if (isLoaded && estimate != null && pricing == null) selectPricing(PricingOption.standard);
  }
}
