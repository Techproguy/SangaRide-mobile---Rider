import 'package:go_router/go_router.dart';

abstract final class TripWrapUpRoutes {
  static const String pay = '/trip/:id/pay';
  static const String complete = '/trip/:id/complete';
  static const String receipt = '/trip/:id/receipt';
  static const String rate = '/trip/:id/rate';

  static String payOf(String id) => pay.replaceFirst(':id', id);

  static String completeOf(String id) => complete.replaceFirst(':id', id);

  static String receiptOf(String id) => receipt.replaceFirst(':id', id);

  static String rateOf(String id) => rate.replaceFirst(':id', id);

  static final List<RouteBase> all = [];
}
