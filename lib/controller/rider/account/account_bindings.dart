import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/account/account_controller.dart';
import 'package:sanga_ride/controller/rider/account/notifications_controller.dart';
import 'package:sanga_ride/controller/rider/account/phone_change_controller.dart';
import 'package:sanga_ride/controller/rider/account/verification_controller.dart';
import 'package:sanga_ride/controller/rider/support/support_chat_controller.dart';
import 'package:sanga_ride/controller/rider/support/support_help_controller.dart';
import 'package:sanga_ride/controller/rider/support/support_report_controller.dart';
import 'package:sanga_ride/controller/rider/support/support_tickets_controller.dart';

void registerAccountControllers() {
  Get.lazyPut(() => AccountController(), fenix: true);
  Get.lazyPut(() => PhoneChangeController(), fenix: true);
  Get.lazyPut(() => NotificationsController(), fenix: true);
  Get.lazyPut(() => VerificationController(), fenix: true);
  Get.lazyPut(() => SupportHelpController(), fenix: true);
  Get.lazyPut(() => SupportReportController(), fenix: true);
  Get.lazyPut(() => SupportTicketsController(), fenix: true);
  Get.lazyPut(() => SupportChatController(), fenix: true);
}

void resetAccountAreaControllers() {
  Get.delete<NotificationsController>(force: true);
  Get.delete<VerificationController>(force: true);
  Get.delete<PhoneChangeController>(force: true);
  Get.delete<SupportHelpController>(force: true);
  Get.delete<SupportReportController>(force: true);
  Get.delete<SupportTicketsController>(force: true);
  Get.delete<SupportChatController>(force: true);
}
