import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/top_up_controller.dart';
import 'package:sanga_ride/controller/rider/wallet_controller.dart';
import 'package:sanga_ride/controller/rider/wallet_transactions_controller.dart';

void registerWalletControllers() {
  Get.lazyPut(() => WalletController(), fenix: true);
  Get.lazyPut(() => WalletTransactionsController(), fenix: true);
  Get.lazyPut(() => TopUpController(), fenix: true);
}
