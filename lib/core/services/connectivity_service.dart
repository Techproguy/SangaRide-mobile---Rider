import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ConnectivityService extends GetxService {
  ConnectivityService(this.monitor);

  final ConnectionMonitor monitor;

  final RxBool isOnline = true.obs;
  final RxBool hasLink = true.obs;
  final ValueNotifier<SangaConnectionState> bannerState = ValueNotifier(SangaConnectionState.online);

  @override
  void onInit() {
    super.onInit();
    monitor.status.addListener(_sync);
    _sync();
  }

  @override
  void onClose() {
    monitor.status.removeListener(_sync);
    bannerState.dispose();
    super.onClose();
  }

  Future<void> refresh() => monitor.recheck();

  void _sync() {
    final status = monitor.status.value;
    isOnline.value = status == ConnectionStatus.online;
    hasLink.value = status != ConnectionStatus.offline;
    bannerState.value = switch (status) {
      ConnectionStatus.online => SangaConnectionState.online,
      ConnectionStatus.offline => SangaConnectionState.offline,
      ConnectionStatus.degraded => SangaConnectionState.degraded,
    };
  }
}
