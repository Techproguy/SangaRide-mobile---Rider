import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/saved_places_controller.dart';
import 'package:sanga_ride/core/router/places_routes.dart';
import 'package:sanga_ride/model/location/place.dart';
import 'package:sanga_ride/model/places/saved_place.dart';
import 'package:sanga_ride/view/places/widgets/saved_place_actions.dart';
import 'package:sanga_ride/view/places/widgets/saved_place_form.dart';
import 'package:sanga_ride/view/places/widgets/saved_places_list.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_async_state.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class SavedPlacesScreen extends StatefulWidget {
  const SavedPlacesScreen({super.key});

  @override
  State<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
  final _places = Get.find<SavedPlacesController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _places.load());
  }

  Future<bool> _add(String label, Place place) async {
    final problem = await _places.save(kind: SavedPlaceKind.other, label: label, place: place);
    if (!mounted) return false;
    if (problem != null) {
      SangaToast.show(problem.message, tone: SangaToastTone.error);
      return false;
    }
    SangaToast.show('$label is saved', tone: SangaToastTone.success);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _places.state;
      return SangaPageLayout(
        title: 'Saved places',
        children: [
          RideOptionAsyncState(
            isLoading: state is SavedPlacesLoading,
            hasFailed: state is SavedPlacesFailed,
            errorTitle: 'We couldn’t load your places',
            failureMessage: state is SavedPlacesFailed ? state.problem.message : null,
            onRetry: _places.load,
            skeletonCount: 3,
            skeletonHeight: 64,
            builder: (context) => switch (_places.state) {
              SavedPlacesLoaded(:final book, :final busy) => _body(context, book, busy),
              SavedPlacesLoading() || SavedPlacesFailed() => const SizedBox.shrink(),
            },
          ),
        ],
      );
    });
  }

  Widget _body(BuildContext context, SavedPlaceBook book, Set<String> busy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.xl,
      children: [
        SavedPlacesList(
          book: book,
          busy: busy,
          onSet: (kind) => context.push<Place>(PlacesRoutes.editOf(kind)),
          onEdit: (saved) => context.push<Place>(PlacesRoutes.editOf(saved.kind, id: saved.id)),
          onRemove: (saved) => confirmRemoveSavedPlace(context, saved),
        ),
        if (book.canAddOther) _addNew(context, book, busy) else _limitNotice(book),
      ],
    );
  }

  Widget _addNew(BuildContext context, SavedPlaceBook book, Set<String> busy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.md,
      children: [
        const SangaSectionHeader('Add new'),
        SavedPlaceForm(
          kind: SavedPlaceKind.other,
          book: book,
          isSaving: busy.contains(SavedPlacesLoaded.newPlaceKey),
          submitLabel: 'Add',
          locationPlaceholder: 'Choose location',
          locationHint: 'Search for an address or landmark',
          onPickLocation: () => pickSavedPlaceLocation(context, hint: 'Search for this place'),
          onSubmit: _add,
        ),
      ],
    );
  }

  Widget _limitNotice(SavedPlaceBook book) {
    return SangaNotice(
      message: 'You’ve saved ${book.maxOthers} places, the most we can hold. Remove one to add another.',
      tone: SangaTone.neutral,
      icon: Icons.info_outline_rounded,
    );
  }
}
