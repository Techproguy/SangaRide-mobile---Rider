import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/trip/delivery_pickup_controller.dart';
import 'package:sanga_ride/controller/rider/trip/trip_controller.dart';
import 'package:sanga_ride/core/services/toast_service.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/delivery/live/widgets/package_details_card.dart';
import 'package:sanga_ride/view/delivery/live/widgets/pickup_photo_field.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ConfirmPickupScreen extends StatefulWidget {
  const ConfirmPickupScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<ConfirmPickupScreen> createState() => _ConfirmPickupScreenState();
}

class _ConfirmPickupScreenState extends State<ConfirmPickupScreen> {
  final _trip = Get.find<TripController>();
  final _pickup = Get.find<DeliveryPickupController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickup.open(widget.tripId));
  }

  Future<void> _confirm() async {
    FocusScope.of(context).unfocus();
    final isConfirmed = await _pickup.confirm();
    if (!mounted) return;
    if (isConfirmed) {
      unawaited(HapticFeedback.mediumImpact());
      Toast.success('Pickup confirmed');
      context.pop();
      return;
    }
    if (_pickup.state case PickupConfirmFailed(:final problem) when problem == DeliveryPickupProblem.movedOn) {
      Toast.info(problem.message);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final delivery = _trip.trip?.delivery;
      final state = _pickup.state;
      return PopScope(
        canPop: !state.isBusy,
        child: SangaPageLayout(
          title: 'Confirm pickup',
          footer: SangaButton.primary(
            label: state is PickupConfirmFailed ? 'Try again' : 'Confirm',
            isLoading: state is PickupConfirming,
            onPressed: delivery != null && state.canConfirm ? _confirm : null,
          ),
          children: [
            if (delivery == null)
              const Padding(
                padding: EdgeInsets.all(SangaSpacing.xl),
                child: Center(child: SangaActivityIndicator(size: 40)),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: SangaSpacing.lg,
                children: [
                  PackageDetailsCard(delivery: delivery),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: SangaSpacing.xs,
                    children: [
                      Text('Add a photo (recommended)', style: SangaTextStyles.cardTitle),
                      Text(
                        'Snap the package with your driver so there’s a record of the handover.',
                        style: SangaTextStyles.cardSubtitle,
                      ),
                    ],
                  ),
                  PickupPhotoField(
                    state: state,
                    onTake: _pickup.takePhoto,
                    onRemove: _pickup.removePhoto,
                    onRetryUpload: _pickup.retryUpload,
                    onOpenSettings: Geolocator.openAppSettings,
                  ),
                  if (state case PickupConfirmFailed(:final problem))
                    SangaNotice(message: problem.message, icon: Icons.error_outline_rounded),
                  const SangaNotice(
                    message: 'Make sure you’re handing your driver the right package before you confirm.',
                    icon: Icons.info_outline_rounded,
                  ),
                ],
              ),
          ],
        ),
      );
    });
  }
}
