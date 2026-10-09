import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/top_up_controller.dart';
import 'package:sanga_ride/controller/rider/wallet_controller.dart';
import 'package:sanga_ride/controller/rider/wallet_transactions_controller.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';

void registerWalletControllers() {
  const scope = WalletScope.personal();
  Get.lazyPut(() => WalletController(scope), fenix: true);
  Get.lazyPut(() => WalletTransactionsController(scope), fenix: true);
  Get.lazyPut(() => TopUpController(scope), fenix: true);
}

abstract final class WalletControllers {
  static void ensure(WalletScope scope) {
    if (!scope.isGroup || Get.isRegistered<WalletController>(tag: scope.tag)) return;
    Get.lazyPut(() => WalletController(scope), tag: scope.tag, fenix: true);
    Get.lazyPut(() => WalletTransactionsController(scope), tag: scope.tag, fenix: true);
    Get.lazyPut(() => TopUpController(scope), tag: scope.tag, fenix: true);
  }

  static WalletController wallet(WalletScope scope) {
    ensure(scope);
    return Get.find<WalletController>(tag: scope.tag);
  }

  static WalletTransactionsController transactions(WalletScope scope) {
    ensure(scope);
    return Get.find<WalletTransactionsController>(tag: scope.tag);
  }

  static TopUpController topUp(WalletScope scope) {
    ensure(scope);
    return Get.find<TopUpController>(tag: scope.tag);
  }
}
