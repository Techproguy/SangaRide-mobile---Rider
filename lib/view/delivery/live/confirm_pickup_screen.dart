import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/trip/delivery_pickup_controller.dart';
import 'package:sanga_ride/controller/rider/trip/trip_controller.dart';
import 'package:sanga_ride/core/services/permission_center.dart';
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

  final _permissions = Get.find<PermissionCenter>();

  @override
  void initState() {
    super.initState();
    unawaited(_trip.open(widget.tripId));
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickup.open(widget.tripId));
  }

  @override
  void dispose() {
    _trip.close(onlyTripId: widget.tripId);
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final access = await _permissions.prime(PermissionKind.camera, context);
    if (!mounted || access.canAskAgain) return;
    await _pickup.takePhoto();
  }

  Future<void> _confirm() async {
    FocusScope.of(context).unfocus();
    final isConfirmed = await _pickup.confirm();
    if (!mounted) return;
    if (isConfirmed) {
      unawaited(HapticFeedback.mediumImpact());
      SangaToast.show('Pickup confirmed', tone: SangaToastTone.success);
      context.pop();
      return;
    }
    if (_pickup.state case PickupConfirmFailed(:final problem) when problem == DeliveryPickupProblem.movedOn) {
      SangaToast.show(problem.message);
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
              const SangaSkeleton.heights([120, 150])
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
                    onTake: _takePhoto,
                    onRemove: _pickup.removePhoto,
                    onRetryUpload: _pickup.retryUpload,
                    onOpenSettings: _permissions.openSettings,
                  ),
                  if (state case PickupConfirmFailed(:final problem))
                    SangaNotice(message: problem.message, tone: SangaTone.warning, icon: Icons.error_outline_rounded),
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
