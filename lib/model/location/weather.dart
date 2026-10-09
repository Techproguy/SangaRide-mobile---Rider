import 'package:sanga_ride_core/sanga_ride_core.dart';

class Weather {
  const Weather({required this.city, required this.temperatureC});

  factory Weather.fromJson(Object? body) {
    final json = JsonReader.of(body);
    return Weather(city: json.str('city'), temperatureC: json.number('temperatureC').round());
  }

  final String city;
  final int temperatureC;
}
