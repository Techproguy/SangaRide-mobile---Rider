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
  bool _isSosSheetOpen = false;
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
    });
  }

  @override
  void dispose() {
    _worker.dispose();
    if (_openedTripId case final id?) _trip.close(onlyTripId: id);
    super.dispose();
  }

  void _onCentre(SafetyCentreState next) {
    final previous = _previous;
    _previous = next;
    if (!mounted || next is! SafetyCentreLoaded || previous is! SafetyCentreLoading) return;
    final centre = next.centre;
    _openTripIfNeeded(centre.trip);
    if (centre.activeSos case final active?) _sos.resume(active);
    if (!_sos.isIdle) unawaited(_openSosSheet(centre));
  }

  void _openTripIfNeeded(SafetyTrip? trip) {
    if (trip == null || _trip.trip != null) return;
    _openedTripId = trip.id;
    unawaited(_trip.open(trip.id));
  }

  void _startSos(SafetyCentre centre) {
    if (!_sos.isIdle) return;
    _sos.start(tripId: centre.trip?.id);
    unawaited(_openSosSheet(centre));
  }

  Future<void> _openSosSheet(SafetyCentre centre) async {
    if (_isSosSheetOpen || !mounted) return;
    _isSosSheetOpen = true;
    await showSosSheet(
      context: context,
      contactCount: centre.contacts.length,
      grace: centre.sosGrace,
      emergencyNumber: centre.emergencyNumber,
      onEnd: () => unawaited(_confirmEndSos()),
      onCallEmergency: () => unawaited(dialNumber(centre.emergencyNumber)),
      onOpenContacts: _openContacts,
    );
    _isSosSheetOpen = false;
  }

  Future<void> _confirmEndSos() async {
    final isConfirmed = await showSangaPromptSheet(
      context: context,
      icon: Icons.health_and_safety_rounded,
      title: 'End SOS?',
      message: 'Only end it if you’re safe. We’ll stop alerting and sharing your location.',
      actionLabel: 'End SOS',
      dismissLabel: 'Keep SOS on',
    );
    if (isConfirmed) await _sos.end();
  }

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
      removingContactId: contactsState is ContactsRemoving ? contactsState.id : null,
      onSos: () => _startSos(centre),
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
