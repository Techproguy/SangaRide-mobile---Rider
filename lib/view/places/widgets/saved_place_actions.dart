import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/rider_home_controller.dart';
import 'package:sanga_ride/controller/rider/saved_places_controller.dart';
import 'package:sanga_ride/core/services/toast_service.dart';
import 'package:sanga_ride/model/location/place.dart';
import 'package:sanga_ride/model/places/saved_place.dart';
import 'package:sanga_ride/view/ride/widgets/place_search_sheet.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

Future<Place?> pickSavedPlaceLocation(BuildContext context, {required String hint}) {
  return PlaceSearchSheet.show(
    context,
    kind: SangaStopKind.dropoff,
    hintText: hint,
    origin: Get.find<RiderHomeController>().currentPlace?.coordinates,
    onPick: (_) => null,
  );
}

Future<bool> confirmRemoveSavedPlace(BuildContext context, SavedPlace saved) async {
  final isConfirmed = await showSangaPromptSheet(
    context: context,
    icon: Icons.delete_outline_rounded,
    title: 'Remove ${saved.label}?',
    message: saved.kind.isSlot
        ? 'Its shortcut on your home screen goes away. You can add it back anytime.'
        : 'It leaves your saved places. You can add it again anytime.',
    actionLabel: 'Remove',
    dismissLabel: 'Keep it',
  );
  if (!isConfirmed || !context.mounted) return false;
  final problem = await Get.find<SavedPlacesController>().remove(saved);
  if (problem != null) Toast.error(problem.message);
  return problem == null;
}
