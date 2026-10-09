import 'package:sanga_ride_core/sanga_ride_core.dart';

DateTime deviceDeadlineOf(String iso) =>
    DateTime.now().add(DateTime.parse(iso).toUtc().difference(ServerClock.instance.now()));

DateTime? deviceDeadlineOrNull(String? iso) {
  final parsed = iso == null ? null : DateTime.tryParse(iso);
  return parsed == null ? null : DateTime.now().add(parsed.toUtc().difference(ServerClock.instance.now()));
}
