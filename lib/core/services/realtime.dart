import 'package:sanga_ride/core/constants.dart';
import 'package:sanga_ride/core/services/session_storage.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

abstract final class Realtime {
  static void start() {
    final socket = RideSocket.current = RideSocket(baseUrl: SangaConstants.baseUrl, tokens: SessionStorage.tokens);
    socket.connect();
  }

  static void resume() => RideSocket.current?.connect();
}
