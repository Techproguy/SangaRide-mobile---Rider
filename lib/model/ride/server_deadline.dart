import 'package:sanga_ride_core/sanga_ride_core.dart';

DateTime serverInstantOf(JsonReader json, String key) => json.time(key).toUtc();

DateTime? serverInstantOrNull(JsonReader json, String key) => json.timeOrNull(key)?.toUtc();

DateTime deviceDeadlineAt(DateTime serverInstant) => DateTime.now().add(ServerClock.instance.remaining(serverInstant));

bool hasServerPassed(DateTime serverInstant) => ServerClock.instance.hasPassed(serverInstant);
