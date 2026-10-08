import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/saved_places_controller.dart';
import 'package:sanga_ride/core/services/toast_service.dart';
import 'package:sanga_ride/model/location/place.dart';
import 'package:sanga_ride/model/places/saved_place.dart';
import 'package:sanga_ride/view/places/widgets/saved_place_actions.dart';
import 'package:sanga_ride/view/places/widgets/saved_place_form.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_async_state.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class SavedPlaceEditScreen extends StatefulWidget {
  const SavedPlaceEditScreen({super.key, required this.kind, this.placeId});

  final SavedPlaceKind kind;
  final String? placeId;

  @override
  State<SavedPlaceEditScreen> createState() => _SavedPlaceEditScreenState();
}

class _SavedPlaceEditScreenState extends State<SavedPlaceEditScreen> {
  final _places = Get.find<SavedPlacesController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _places.ensureLoaded());
  }

  SavedPlace? _existing(SavedPlaceBook book) {
    if (widget.kind.isSlot) return book.of(widget.kind);
    return book.others.where((saved) => saved.id == widget.placeId).firstOrNull;
  }

  String _title(SavedPlace? existing) {
    final name = widget.kind.label.toLowerCase();
    if (!widget.kind.isSlot) return 'Edit place';
    return existing == null ? 'Add $name' : 'Change $name';
  }

  Future<bool> _save(SavedPlace? existing, String label, Place place) async {
    final problem = await _places.save(kind: widget.kind, label: label, place: place, id: existing?.id);
    if (!mounted) return false;
    if (problem != null) {
      Toast.error(problem.message);
      return false;
    }
    context.pop(place);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _places.state;
      final book = _places.book;
      final existing = book == null ? null : _existing(book);
      return SangaPageLayout(
        title: _title(existing),
        children: [
          RideOptionAsyncState(
            isLoading: state is SavedPlacesLoading,
            hasFailed: state is SavedPlacesFailed,
            errorTitle: 'We couldn’t load your places',
            onRetry: _places.load,
            skeletonCount: 2,
            skeletonHeight: 58,
            builder: (context) => switch (_places.state) {
              SavedPlacesLoaded(:final book, :final busy) => _form(context, book, busy),
              SavedPlacesLoading() || SavedPlacesFailed() => const SizedBox.shrink(),
            },
          ),
        ],
      );
    });
  }

  Widget _form(BuildContext context, SavedPlaceBook book, Set<String> busy) {
    final existing = _existing(book);
    if (!widget.kind.isSlot && existing == null) {
      return SangaInlineMessage(
        title: 'We can’t find that place',
        message: 'It may already be gone.',
        actionLabel: 'Go back',
        onAction: context.pop,
      );
    }
    final name = widget.kind.label.toLowerCase();
    final isSlot = widget.kind.isSlot;
    return SavedPlaceForm(
      kind: widget.kind,
      book: book,
      editing: existing,
      isSaving: busy.contains(existing?.id ?? widget.kind.code),
      submitLabel: isSlot ? 'Save location' : 'Save changes',
      locationPlaceholder: isSlot ? 'Choose your $name location' : 'Choose location',
      locationHint: isSlot ? 'Search for an address or landmark' : null,
      onPickLocation: () =>
          pickSavedPlaceLocation(context, hint: isSlot ? 'Search for your $name' : 'Search for this place'),
      onSubmit: (label, place) => _save(existing, label, place),
    );
  }
}
