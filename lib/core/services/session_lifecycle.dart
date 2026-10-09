import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/shared/user_controller.dart';
import 'package:sanga_ride/core/services/session_restore.dart';
import 'package:sanga_ride/core/services/session_storage.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

abstract final class SessionLifecycle {
  static void register() {
    final hub = SessionHub.instance;
    hub.register('restore', (_) => Get.find<SessionRestore>().reset());
    hub.register('tokens', (_) => SessionStorage.tokens.clear());
    hub.register('user', (_) => Get.find<UserController>().clear());
    hub.register('drafts', (_) => _clearDrafts());
    hub.register('controllers', (_) => _scheduleControllerReset());
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
