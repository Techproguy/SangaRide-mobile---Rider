import 'package:flutter/material.dart';
import 'package:sanga_ride/core/api/mock/mock_verification.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class DevMockSwitches extends StatelessWidget {
  const DevMockSwitches({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SangaSectionHeader('Mock switches'),
        const SizedBox(height: SangaSpacing.sm),
        ValueListenableBuilder<bool>(
          valueListenable: MockVerification.rejectNextSelfie,
          builder: (context, isOn, _) => SangaToggleRow(
            leading: const Icon(Icons.face_retouching_off_outlined, size: 22, color: SangaColors.textPrimary),
            title: 'Next selfie won’t match',
            subtitle: 'The next selfie check answers face_not_matched, then turns itself off',
            value: isOn,
            onChanged: (on) => MockVerification.rejectNextSelfie.value = on,
          ),
        ),
      ],
    );
  }
}
