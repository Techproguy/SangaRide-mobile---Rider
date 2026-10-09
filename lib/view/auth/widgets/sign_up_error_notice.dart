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
      return AnimatedSize(
        duration: SangaMotion.quick,
        curve: SangaMotion.springBlock,
        alignment: Alignment.topCenter,
        child: message == null
            ? const SizedBox(width: double.infinity)
            : Padding(
                padding: const EdgeInsets.only(bottom: SangaSpacing.md),
                child: SangaNotice(message: message, tone: SangaTone.warning),
              ),
      );
    });
  }
}
