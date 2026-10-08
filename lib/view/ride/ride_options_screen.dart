import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_async_state.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_image.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class RideOptionsScreen extends StatefulWidget {
  const RideOptionsScreen({super.key});

  @override
  State<RideOptionsScreen> createState() => _RideOptionsScreenState();
}

class _RideOptionsScreenState extends State<RideOptionsScreen> {
  static const _skeletonCount = 6;

  final _ride = Get.find<RideRequestController>();

  @override
  void initState() {
    super.initState();
    _ride.loadOptions();
  }

  @override
  Widget build(BuildContext context) {
    return SangaPageLayout(
      title: 'Choose a ride',
      footer: Obx(
        () => SangaButton.primary(
          label: 'Confirm',
          onPressed: _ride.option == null ? null : () => context.push(SangaRoutes.ridePreferences),
        ),
      ),
      children: [
        Obx(
          () => RideOptionAsyncState(
            isLoading: _ride.isLoadingOptions,
            hasFailed: _ride.optionsFailed,
            errorTitle: 'We couldn’t load rides',
            onRetry: _ride.loadOptions,
            skeletonCount: _skeletonCount,
            skeletonHeight: SangaVehicleCard.height,
            builder: _buildOptions,
          ),
        ),
      ],
    );
  }

  Widget _buildOptions(BuildContext context) {
    if (_ride.options.isEmpty) {
      return SangaInlineMessage(
        title: 'No rides nearby right now',
        message: 'Drivers come and go fast. Give it a minute and try again.',
        actionLabel: 'Try again',
        onAction: _ride.loadOptions,
      );
    }
    return Column(
      spacing: SangaSpacing.md,
      children: [
        for (final option in _ride.options)
          SangaVehicleCard(
            image: option.category.image,
            name: option.name,
            description: option.description,
            seats: option.seats,
            price: SangaMoney.perKm(option.pricePerKm),
            isSelected: _ride.option?.id == option.id,
            onTap: () => _ride.selectOption(option),
          ),
      ],
    );
  }
}
