import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/view/ride/who_for/business_details_screen.dart';
import 'package:sanga_ride/view/ride/who_for/business_profile_screen.dart';
import 'package:sanga_ride/view/ride/who_for/family_member_screen.dart';
import 'package:sanga_ride/view/ride/who_for/passenger_info_screen.dart';
import 'package:sanga_ride/view/ride/who_for/passenger_otp_screen.dart';
import 'package:sanga_ride/view/ride/who_for/who_for_screen.dart';

abstract final class WhoForRoutes {
  static const String root = '/ride/who-for';
  static const String passenger = '/ride/who-for/passenger';
  static const String passengerOtp = '/ride/who-for/passenger/otp';
  static const String family = '/ride/who-for/family';
  static const String business = '/ride/who-for/business';
  static const String businessDetails = '/ride/who-for/business/details';

  static Future<bool> open(BuildContext context) async => await context.push<bool>(root) ?? false;

  static Future<void> continueTo(BuildContext context, String path) async {
    final done = await context.push<bool>(path);
    if (done == true && context.mounted) context.pop(true);
  }

  static final List<RouteBase> all = [
    GoRoute(path: root, builder: (context, state) => const WhoForScreen()),
    GoRoute(path: passenger, builder: (context, state) => const PassengerInfoScreen()),
    GoRoute(path: passengerOtp, builder: (context, state) => const PassengerOtpScreen()),
    GoRoute(path: family, builder: (context, state) => const FamilyMemberScreen()),
    GoRoute(path: business, builder: (context, state) => const BusinessProfileScreen()),
    GoRoute(path: businessDetails, builder: (context, state) => const BusinessDetailsScreen()),
  ];
}
