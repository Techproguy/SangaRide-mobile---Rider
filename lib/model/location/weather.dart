class Weather {
  const Weather({required this.city, required this.temperatureC});

  factory Weather.fromJson(Map<String, dynamic> json) =>
      Weather(city: json['city'] as String, temperatureC: (json['temperatureC'] as num).round());

  final String city;
  final int temperatureC;
}
