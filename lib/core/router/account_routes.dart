import 'package:go_router/go_router.dart';
import 'package:sanga_ride/view/account/change_phone_screen.dart';
import 'package:sanga_ride/view/account/delete_account_screen.dart';
import 'package:sanga_ride/view/account/profile_screen.dart';

abstract final class AccountRoutes {
  static const String profile = '/account';
  static const String phone = '/account/phone';
  static const String delete = '/account/delete';

  static final List<RouteBase> all = [
    GoRoute(path: profile, builder: (context, state) => const ProfileScreen()),
    GoRoute(path: phone, builder: (context, state) => const ChangePhoneScreen()),
    GoRoute(path: delete, builder: (context, state) => const DeleteAccountScreen()),
  ];
}
