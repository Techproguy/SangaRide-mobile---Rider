import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/safety/contacts_controller.dart';
import 'package:sanga_ride/controller/rider/safety/safety_centre_controller.dart';
import 'package:sanga_ride/controller/rider/safety/sos_controller.dart';
import 'package:sanga_ride/controller/rider/trip/trip_controller.dart';
import 'package:sanga_ride/core/router/safety_routes.dart';
import 'package:sanga_ride/core/router/trip_routes.dart';
import 'package:sanga_ride/core/services/permission_center.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/safety/widgets/dial_number.dart';
import 'package:sanga_ride/view/safety/widgets/remove_contact.dart';
import 'package:sanga_ride/view/safety/widgets/safety_centre_body.dart';
import 'package:sanga_ride/view/safety/widgets/sos_sheet.dart';
import 'package:sanga_ride/view/trip/widgets/share_trip.dart';
import 'package:sanga_ride/view/trip/wrapup/widgets/wrapup_async_body.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class SafetyCentreScreen extends StatefulWidget {
  const SafetyCentreScreen({super.key, this.tripId});

  final String? tripId;

  @override
  State<SafetyCentreScreen> createState() => _SafetyCentreScreenState();
}

class _SafetyCentreScreenState extends State<SafetyCentreScreen> {
  final _centre = Get.find<SafetyCentreController>();
  final _sos = Get.find<SosController>();
  final _contacts = Get.find<ContactsController>();
  final _trip = Get.find<TripController>();
  late final Worker _worker;
  SafetyCentreState _previous = const SafetyCentreLoading();
  String? _openedTripId;
  bool _isOpened = false;

  @override
  void initState() {
    super.initState();
    _worker = ever(_centre.stateRx, _onCentre);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _isOpened = true);
      _contacts.reset();
      unawaited(_centre.open(tripId: widget.tripId));
      unawaited(_prepareLocation());
      if (!_sos.isIdle) unawaited(SosLauncher.present(context));
    });
  }

  @override
  void dispose() {
    _worker.dispose();
    if (_openedTripId case final id?) _trip.close(onlyTripId: id);
    super.dispose();
  }

  Future<void> _prepareLocation() async {
    final permissions = Get.find<PermissionCenter>();
    final access = await permissions.check(PermissionKind.location);
    if (!mounted || !access.canAskAgain) return;
    await permissions.prime(PermissionKind.location, context);
  }

  void _onCentre(SafetyCentreState next) {
    final previous = _previous;
    _previous = next;
    if (!mounted || next is! SafetyCentreLoaded || previous is! SafetyCentreLoading) return;
    final centre = next.centre;
    _openTripIfNeeded(centre.trip);
    if (centre.activeSos case final active?) _sos.resume(active);
    if (!_sos.isIdle) unawaited(SosLauncher.present(context));
  }

  void _openTripIfNeeded(SafetyTrip? trip) {
    if (trip == null || _trip.trip != null) return;
    _openedTripId = trip.id;
    unawaited(_trip.open(trip.id));
  }

  void _startSos() => unawaited(SosLauncher.start(context, tripId: _centre.centre?.trip?.id ?? widget.tripId));

  void _openContacts() => unawaited(context.push(SafetyRoutes.contacts));

  void _openReport(SafetyCentre centre) => unawaited(context.push(SafetyRoutes.reportOf(tripId: centre.trip?.id)));

  void _openTripDetails(SafetyTrip trip) => unawaited(context.push(TripRoutes.timelineOf(trip.id)));

  WrapUpFailure? _failureOf(SafetyCentreState state) => switch (state) {
    SafetyCentreFailed(:final problem) => WrapUpFailure(
      title: 'We couldn’t load your Safety Centre',
      message: problem.message,
      onRetry: () => unawaited(_centre.retry()),
    ),
    SafetyCentreLoading() || SafetyCentreLoaded() => null,
  };

  Widget _body(SafetyCentreState state, ContactsState contactsState) {
    if (state is! SafetyCentreLoaded) return const SizedBox.shrink();
    final centre = state.centre;
    final trip = centre.trip;
    return SafetyCentreBody(
      centre: centre,
      onSos: _startSos,
      removingContactId: contactsState is ContactsRemoving ? contactsState.id : null,
      onAddContact: _openContacts,
      onCallContact: (contact) => unawaited(dialNumber(contact.phone)),
      onRemoveContact: (contact) => unawaited(confirmRemoveContact(context, contact)),
      onShareTrip: () {
        if (trip != null) unawaited(shareTrip(trip.id));
      },
      onTripDetails: () {
        if (trip != null) _openTripDetails(trip);
      },
      onReport: () => _openReport(centre),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _centre.state;
      final contactsState = _contacts.state;
      return SangaPageLayout(
        title: 'Safety Centre',
        children: [
          WrapUpAsyncBody(
            isLoading: !_isOpened || state is SafetyCentreLoading,
            failure: _failureOf(state),
            skeletonHeights: const [90, 150, 210],
            builder: (_) => _body(state, contactsState),
          ),
        ],
      );
    });
  }
}
