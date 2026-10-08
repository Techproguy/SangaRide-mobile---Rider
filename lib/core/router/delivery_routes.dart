import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/view/delivery/send/delivery_item_screen.dart';
import 'package:sanga_ride/view/delivery/send/delivery_kind_screen.dart';
import 'package:sanga_ride/view/delivery/send/delivery_photo_screen.dart';
import 'package:sanga_ride/view/delivery/send/delivery_recipient_screen.dart';
import 'package:sanga_ride/view/delivery/send/delivery_review_screen.dart';
import 'package:sanga_ride/view/delivery/send/delivery_tier_screen.dart';
import 'package:sanga_ride/view/delivery/send/delivery_value_screen.dart';

abstract final class DeliveryRoutes {
  static const String kind = '/delivery/type';
  static const String item = '/delivery/item';
  static const String photo = '/delivery/photo';
  static const String value = '/delivery/value';
  static const String route = SangaRoutes.rideRoute;
  static const String tier = '/delivery/tier';
  static const String recipient = '/delivery/recipient';
  static const String review = '/delivery/review';

  static const String _editParam = 'edit';

  static String editing(String path) => '$path?$_editParam=1';

  static bool isEditing(GoRouterState state) => state.uri.queryParameters[_editParam] == '1';

  static void advance(BuildContext context, {required String next, required bool isEditing}) {
    if (isEditing) {
      context.pop();
    } else {
      context.push(next);
    }
  }

  static final List<RouteBase> all = [
    GoRoute(path: kind, builder: (context, state) => const DeliveryKindScreen()),
    GoRoute(
      path: item,
      builder: (context, state) => DeliveryItemScreen(isEditing: isEditing(state)),
    ),
    GoRoute(
      path: photo,
      builder: (context, state) => DeliveryPhotoScreen(isEditing: isEditing(state)),
    ),
    GoRoute(
      path: value,
      builder: (context, state) => DeliveryValueScreen(isEditing: isEditing(state)),
    ),
    GoRoute(
      path: tier,
      builder: (context, state) => DeliveryTierScreen(isEditing: isEditing(state)),
    ),
    GoRoute(
      path: recipient,
      builder: (context, state) => DeliveryRecipientScreen(isEditing: isEditing(state)),
    ),
    GoRoute(path: review, builder: (context, state) => const DeliveryReviewScreen()),
  ];
}
