import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class ConnectivityService extends GetxService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;

  final RxBool isOnline = true.obs;
  final RxBool hasLink = true.obs;

  @override
  void onInit() {
    super.onInit();
    _sub = _connectivity.onConnectivityChanged.listen(_handle);
    _connectivity.checkConnectivity().then(_handle);
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  Future<void> refresh() async => _handle(await _connectivity.checkConnectivity());

  Future<void> _handle(List<ConnectivityResult> results) async {
    final linked = results.any((r) => r != ConnectivityResult.none);
    hasLink.value = linked;
    isOnline.value = linked && await _probeUpstream();
  }

  Future<bool> _probeUpstream() async {
    try {
      final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 2));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
