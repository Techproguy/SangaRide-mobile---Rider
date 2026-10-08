import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/delivery/send_delivery_controller.dart';
import 'package:sanga_ride/core/router/delivery_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/delivery/send/widgets/package_photo_actions.dart';
import 'package:sanga_ride/view/delivery/send/widgets/package_photo_circle.dart';
import 'package:sanga_ride/view/delivery/send/widgets/photo_source_sheet.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class DeliveryPhotoScreen extends StatelessWidget {
  const DeliveryPhotoScreen({super.key, required this.isEditing});

  static const double _maxCircle = 260;

  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final delivery = Get.find<SendDeliveryController>();
    return SangaPageLayout(
      title: 'Package photo',
      subtitle: delivery.isPhotoRequired
          ? 'Snap a clear photo of what you’re sending'
          : 'Optional, but it helps your driver',
      footer: Obx(() => _footer(context, delivery)),
      children: [
        Obx(() {
          final state = delivery.photo;
          return Column(
            spacing: SangaSpacing.xl,
            children: [
              const SizedBox(height: SangaSpacing.md),
              LayoutBuilder(
                builder: (context, constraints) => PackagePhotoCircle(
                  state: state,
                  size: constraints.maxWidth < _maxCircle ? constraints.maxWidth : _maxCircle,
                  onTap: () => _pick(context, delivery),
                ),
              ),
              PackagePhotoActions(
                state: state,
                onRetake: () => _pick(context, delivery),
                onRemove: delivery.removePhoto,
                onRetry: delivery.retryUpload,
                onOpenSettings: Geolocator.openAppSettings,
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _footer(BuildContext context, SendDeliveryController delivery) {
    final state = delivery.photo;
    final isSkipping = !delivery.isPhotoRequired && state is! PhotoUploaded;
    final label = isEditing ? 'Save' : (isSkipping ? 'Skip for now' : 'Continue');
    final onPressed = delivery.canLeavePhotoStep
        ? () => DeliveryRoutes.advance(context, next: DeliveryRoutes.value, isEditing: isEditing)
        : null;
    return isSkipping
        ? SangaButton.outline(label: label, onPressed: onPressed)
        : SangaButton.primary(label: label, isLoading: state.isBusy, onPressed: onPressed);
  }

  Future<void> _pick(BuildContext context, SendDeliveryController delivery) async {
    if (delivery.photo.isBusy) return;
    final source = await showPhotoSourceSheet(context);
    if (source != null) await delivery.pickPhoto(source);
  }
}
