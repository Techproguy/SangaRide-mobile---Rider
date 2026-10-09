import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/ride_for_controller.dart';
import 'package:sanga_ride/core/router/who_for_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/ride/who_for/widgets/ride_for_list_body.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final _flow = Get.find<RideForController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _flow.loadBusinesses());
  }

  @override
  Widget build(BuildContext context) {
    return SangaPageLayout(
      title: 'Choose a business profile',
      footer: Obx(
        () => SangaButton.primary(
          label: 'Continue',
          onPressed: _flow.pickedProfile == null
              ? null
              : () => WhoForRoutes.continueTo(context, WhoForRoutes.businessDetails),
        ),
      ),
      children: [
        Obx(
          () => RideForListBody<BusinessProfile>(
            state: _flow.business,
            emptyIcon: Icons.apartment_rounded,
            emptyTitle: 'No business profile yet',
            emptyMessage: 'You’re not on a company profile, so this ride has nowhere to be charged.',
            failedTitle: 'We couldn’t load your profiles',
            onRetry: _flow.loadBusinesses,
            builder: (context, profiles) => Column(
              spacing: SangaSpacing.md,
              children: [
                for (final profile in profiles)
                  SangaOptionCard(
                    leading: const SangaIconBadge(child: Icon(Icons.apartment_rounded)),
                    title: profile.companyName,
                    subtitle: profile.role,
                    isSelected: _flow.pickedProfile?.id == profile.id,
                    onTap: () => _flow.pickProfile(profile),
                  ),
                if (_flow.pickedProfile case final profile?)
                  SangaCallout.info(
                    lines: [
                      SangaCalloutLine(
                        icon: SangaAssets.shield,
                        text: 'This ride is charged to ${profile.companyName}, not to you.',
                      ),
                    ],
                  ).animate().fadeIn(duration: SangaMotion.quick, curve: SangaMotion.fadeCurve),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
