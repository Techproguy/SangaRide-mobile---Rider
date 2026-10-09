import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/ride_match_controller.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/core/router/trip_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/ride/matching/widgets/confirm_driver_card.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_image.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ConfirmDriverScreen extends StatefulWidget {
  const ConfirmDriverScreen({super.key});

  @override
  State<ConfirmDriverScreen> createState() => _ConfirmDriverScreenState();
}

class _ConfirmDriverScreenState extends State<ConfirmDriverScreen> {
  final _match = Get.find<RideMatchController>();
  final _trip = Get.find<RideRequestController>();
  late final DriverHold? _hold = _match.holding;
  bool _isLeaving = false;

  @override
  void initState() {
    super.initState();
    if (_hold == null) WidgetsBinding.instance.addPostFrameCallback((_) => _popOnce());
  }

  bool get _isConfirming => switch (_match.state) {
    MatchHolding(:final isConfirming) => isConfirming,
    _ => false,
  };

  void _popOnce() {
    if (_isLeaving || !mounted) return;
    _isLeaving = true;
    context.pop();
  }

  void _back() {
    if (_isConfirming || _isLeaving) return;
    unawaited(_match.releaseHold());
    _popOnce();
  }

  void _leaveWhileConfirming() {
    if (_isLeaving || !mounted) return;
    _isLeaving = true;
    context.go(SangaRoutes.home);
  }

  Future<void> _expired() async {
    if (_isConfirming || _isLeaving || _match.state is! MatchHolding) return;
    await _match.expireHold();
    _popOnce();
  }

  Future<void> _confirm() async {
    final isConfirmed = await _match.confirm();
    if (!mounted) return;
    final state = _match.state;
    if (!isConfirmed) {
      if (state is! MatchHolding) _popOnce();
      return;
    }
    if (state is! MatchConfirmed) return;
    await showSangaStatusSheet(
      context: context,
      status: SangaStatus.success,
      title: _trip.tripType == TripType.delivery ? 'Delivery accepted' : 'Ride accepted',
      message: '${state.trip.driver.firstName} is heading to your pickup.',
      actionLabel: 'Done',
    );
    if (mounted) context.go(TripRoutes.tripOf(state.trip.tripId));
  }

  @override
  Widget build(BuildContext context) {
    final hold = _hold;
    if (hold == null) return const Scaffold();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: SangaPageLayout(
        title: 'Confirm driver',
        onBack: _back,
        footer: Obx(() {
          final isConfirming = _isConfirming;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SangaCountdown(
                endsAt: hold.holdExpiresAt,
                onFinished: _expired,
                builder: (context, remaining) => SangaButton.primary(
                  label: 'Confirm driver (${remaining.minutesAndSeconds})',
                  isLoading: isConfirming,
                  onPressed: _confirm,
                ),
              ),
              if (isConfirming) SangaBusyEscape(onClose: _leaveWhileConfirming),
            ],
          );
        }),
        children: [
          ConfirmDriverCard(
            hold: hold,
            pickup: _trip.pickup?.name ?? '',
            dropoff: _trip.dropoff?.name ?? '',
            stops: [for (final stop in _trip.stops) stop.name],
            vehicleImage: (_trip.option?.category ?? RideCategory.go).image,
          ),
        ],
      ),
    );
  }
}
