import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/rider_sign_up_controller.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class SignUpErrorNotice extends StatelessWidget {
  const SignUpErrorNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final signUp = Get.find<RiderSignUpController>();
    return Obx(() {
      final message = signUp.formError;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SangaReveal(
            isVisible: message != null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: SangaSpacing.md),
              child: SangaNotice(message: message ?? '', tone: SangaTone.warning),
            ),
          ),
          SangaReveal(
            isVisible: message == null,
            child: const SizedBox(height: SangaSpacing.xxl),
          ),
        ],
      );
    });
  }
}
