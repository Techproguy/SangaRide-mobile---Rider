import 'package:sanga_ride_core/sanga_ride_core.dart';

class Weather {
  const Weather({required this.city, required this.temperatureC});

  static Weather? tryFromJson(Object? body, {required String city}) {
    if (body is! Map || city.isEmpty) return null;
    final temperature = JsonReader.of(body).numOrNull('tempC');
    return temperature == null ? null : Weather(city: city, temperatureC: temperature.round());
  }

  final String city;
  final int temperatureC;
}
