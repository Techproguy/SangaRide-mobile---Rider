import 'package:sanga_ride/core/api/api_environment.dart';
import 'package:sanga_ride/core/constants.dart';
import 'package:sanga_ride/core/services/session_storage.dart';
import 'package:sanga_ride/core/storage/draft_keys.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

abstract final class Realtime {
  static void start() {
    if (ApiEnvironment.usesMock) return;
    final socket = RideSocket.current = RideSocket(baseUrl: SangaConstants.baseUrl, tokens: SessionStorage.tokens);
    SessionHub.instance.register(SessionNames.realtime, (_) => socket.disconnect());
    socket.connect();
  }

  static void resume() => RideSocket.current?.connect();
}
