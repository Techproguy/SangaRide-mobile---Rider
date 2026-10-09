import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/shared/user_controller.dart';
import 'package:sanga_ride/core/services/session_restore.dart';
import 'package:sanga_ride/core/services/session_storage.dart';
import 'package:sanga_ride/core/storage/draft_keys.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

abstract final class SessionLifecycle {
  static void register() {
    final hub = SessionHub.instance;
    hub.register(SessionNames.restore, (_) => Get.find<SessionRestore>().reset());
    hub.register(SessionNames.tokens, (_) => SessionStorage.tokens.clear());
    hub.register(SessionNames.user, (_) => Get.find<UserController>().clear());
    hub.register(SessionNames.drafts, (_) => _clearDrafts());
    hub.register(SessionNames.controllers, (_) => _scheduleControllerReset());
  }

  static Future<void> endFromClient(SessionEndReason reason) async {
    if (!SessionStorage.tokens.hasSession) return;
    await SessionHub.instance.end(reason);
  }

  static Future<void> _clearDrafts() async {
    await SessionStorage.drafts.clearScope();
    SessionStorage.drafts.userScope = null;
  }

  static void _scheduleControllerReset() {
    WidgetsBinding.instance
      ..addPostFrameCallback((_) => unawaited(Get.deleteAll()))
      ..ensureVisualUpdate();
  }
}
