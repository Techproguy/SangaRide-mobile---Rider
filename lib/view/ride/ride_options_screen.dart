import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/core/router/booking_routes.dart';
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
  static const double _tooSmallOpacity = 0.4;

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
          onPressed: _ride.option == null || !_ride.fitsGroup(_ride.option!)
              ? null
              : () => context.push(BookingRoutes.afterOptions(_ride.tripType)),
        ),
      ),
      children: [
        Obx(
          () => RideOptionAsyncState(
            isLoading: _ride.isLoadingOptions,
            hasFailed: _ride.optionsFailed,
            errorTitle: 'We couldn’t load rides',
            failureMessage: _ride.optionsProblem?.message,
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
      return SangaEmptyMessage(
        icon: Icons.directions_car_outlined,
        title: 'No rides nearby right now',
        message: 'Drivers come and go fast. Give it a minute and try again.',
        actionLabel: 'Try again',
        onAction: _ride.loadOptions,
      );
    }
    final booking = _ride.airportBooking;
    final hasTooSmall = booking != null && _ride.options.any((option) => !_ride.fitsGroup(option));
    return Column(
      spacing: SangaSpacing.md,
      children: [
        if (hasTooSmall)
          SangaNotice(
            message: 'Some rides are too small for ${booking.details.passengersLabel}.',
            tone: SangaTone.neutral,
            icon: Icons.info_outline_rounded,
          ),
        for (final option in _ride.options)
          Opacity(
            opacity: _ride.fitsGroup(option) ? 1 : _tooSmallOpacity,
            child: SangaVehicleCard(
              image: option.category.image,
              name: option.name,
              description: option.description,
              seats: option.seats,
              price: _ride.rateLabel(option),
              isSelected: _ride.option?.id == option.id,
              onTap: _ride.fitsGroup(option) ? () => _ride.selectOption(option) : null,
            ),
          ),
      ],
    );
  }
}
