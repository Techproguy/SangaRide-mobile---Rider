import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/groups/group_controller.dart';
import 'package:sanga_ride/controller/rider/groups/groups_controller.dart';
import 'package:sanga_ride/controller/rider/ride_history_controller.dart';
import 'package:sanga_ride/model/history/history_scope.dart';

void registerGroupControllers() {
  Get.lazyPut(() => GroupsController(), fenix: true);
}

abstract final class GroupControllers {
  static GroupController group(String groupId) {
    final tag = 'group:$groupId';
    if (!Get.isRegistered<GroupController>(tag: tag)) {
      Get.lazyPut(() => GroupController(groupId), tag: tag, fenix: true);
    }
    return Get.find<GroupController>(tag: tag);
  }

  static RideHistoryController rides(String groupId) {
    final scope = HistoryScope.group(groupId);
    if (!Get.isRegistered<RideHistoryController>(tag: scope.tag)) {
      Get.lazyPut(() => RideHistoryController(scope), tag: scope.tag, fenix: true);
    }
    return Get.find<RideHistoryController>(tag: scope.tag);
  }
}
