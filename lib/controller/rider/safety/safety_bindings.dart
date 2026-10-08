import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/safety/contacts_controller.dart';
import 'package:sanga_ride/controller/rider/safety/safety_centre_controller.dart';
import 'package:sanga_ride/controller/rider/safety/safety_report_controller.dart';
import 'package:sanga_ride/controller/rider/safety/sos_controller.dart';

void registerSafetyControllers() {
  Get.lazyPut(() => SafetyCentreController(), fenix: true);
  Get.lazyPut(() => SosController(), fenix: true);
  Get.lazyPut(() => ContactsController(), fenix: true);
  Get.lazyPut(() => SafetyReportController(), fenix: true);
}
