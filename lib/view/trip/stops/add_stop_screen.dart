import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/rider_home_controller.dart';
import 'package:sanga_ride/controller/rider/trip/add_stop_controller.dart';
import 'package:sanga_ride/controller/rider/trip/trip_controller.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/ride/widgets/place_search_sheet.dart';
import 'package:sanga_ride/view/trip/stops/stop_drafting_view.dart';
import 'package:sanga_ride/view/trip/stops/stop_location_confirm.dart';
import 'package:sanga_ride/view/trip/stops/stop_quote_view.dart';
import 'package:sanga_ride/view/trip/stops/widgets/stop_sheets.dart';
import 'package:sanga_ride/view/trip/widgets/trip_page_gate.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class AddStopScreen extends StatefulWidget {
  const AddStopScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<AddStopScreen> createState() => _AddStopScreenState();
}

class _AddStopScreenState extends State<AddStopScreen> {
  final _add = Get.find<AddStopController>();
  final _trip = Get.find<TripController>();
  late final Worker _worker;
  AddStopState _previous = const AddStopDrafting([]);

  @override
  void initState() {
    super.initState();
    _worker = ever(_add.stateRx, _onState);
    WidgetsBinding.instance.addPostFrameCallback((_) => _add.open(widget.tripId));
  }

  @override
  void dispose() {
    _worker.dispose();
    scheduleMicrotask(_add.reset);
    super.dispose();
  }

  void _onState(AddStopState next) {
    final previous = _previous;
    _previous = next;
    if (!mounted) return;
    switch (next) {
      case AddStopQuoting() when previous is! AddStopQuoting:
        unawaited(showStopUpdatingSheet(context));
      case AddStopFailed():
        _closeSheet();
        unawaited(_showFailure(next.reason, next.serverMessage));
      case AddStopApplied():
        context.pop();
      default:
        if (previous is AddStopQuoting) _closeSheet();
    }
  }

  void _closeSheet() => Navigator.of(context).popUntil((route) => route is! PopupRoute);

  Future<void> _showFailure(AddStopFailure failure, String? message) async {
    final isPrimary = await showStopFailureSheet(context, failure, message: message);
    if (!mounted) return;
    if (_add.resolveFailure(isPrimary: isPrimary)) context.pop();
  }

  Future<void> _choose() async {
    final trip = _trip.trip;
    if (trip == null) return;
    final place = await PlaceSearchSheet.show(
      context,
      kind: SangaStopKind.stop,
      hintText: 'Where should we stop?',
      origin: trip.driverPosition?.position ?? trip.pickup.position,
      onPick: (place) => _add.validate(place, trip),
    );
    if (place == null || !mounted) return;
    _add.choose(place);
  }

  void _changePlace() {
    _add.cancelPlace();
    unawaited(_choose());
  }

  void _confirmPlace(Place place) {
    _add.confirmPlace();
    unawaited(Get.find<RiderHomeController>().rememberPlace(place));
  }

  void _handleBack(AddStopState state) {
    switch (state) {
      case AddStopPlacing():
        _add.cancelPlace();
      case AddStopReviewing():
        _add.backToDrafting();
      default:
        context.pop();
    }
  }

  Widget _drafting(Trip trip, AddStopState state) {
    return StopDraftingView(
      trip: trip,
      added: _add.added,
      slotsLeft: _add.slotsLeft(trip),
      onChoose: () => unawaited(_choose()),
      onRemove: _add.removeAt,
      onDone: () => unawaited(_add.requestQuote()),
    );
  }

  Widget _quote(AddStopReviewing state) {
    return StopQuoteView(
      quote: state.quote,
      isRefreshed: state.isRefreshed,
      isApplying: state.isApplying,
      onConfirm: () => unawaited(_add.confirm()),
      onKeep: context.pop,
      onBack: () => _handleBack(state),
    );
  }

  Widget _body(Trip trip, AddStopState state) {
    return switch (state) {
      AddStopPlacing(:final place) => StopLocationConfirm(
        place: place,
        stopNumber: trip.stops.length + _add.added.length + 1,
        onConfirm: () => _confirmPlace(place),
        onChange: _changePlace,
        onBack: () => _handleBack(state),
      ),
      AddStopReviewing() => _quote(state),
      AddStopFailed(:final quote?) => _quote(AddStopReviewing(state.added, quote)),
      _ => _drafting(trip, state),
    };
  }

  @override
  Widget build(BuildContext context) {
    return TripPageGate(
      tripId: widget.tripId,
      title: 'Add stops',
      child: Obx(() {
        final trip = _trip.trip;
        final state = _add.state;
        if (trip == null) {
          return const SangaPageLayout(
            title: 'Add stops',
            children: [
              SangaSkeleton.heights([160, 56]),
            ],
          );
        }
        return PopScope(
          canPop: state is AddStopDrafting,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _handleBack(state);
          },
          child: _body(trip, state),
        );
      }),
    );
  }
}
