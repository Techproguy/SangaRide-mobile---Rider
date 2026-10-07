import 'package:google_maps_flutter/google_maps_flutter.dart';

class Place {
  final String placeId;
  final String name;
  final String address;
  final LatLng? coordinates;

  const Place({required this.placeId, required this.name, required this.address, this.coordinates});

  factory Place.fromJson(Map<String, dynamic> json) {
    LatLng? coords;
    final loc = json['location'] ?? json['coordinates'];
    if (loc is Map) {
      final lat = loc['latitude'] ?? loc['lat'];
      final lng = loc['longitude'] ?? loc['lng'];
      if (lat is num && lng is num) coords = LatLng(lat.toDouble(), lng.toDouble());
    }

    final displayName = json['displayName'];
    return Place(
      placeId: json['id'] ?? json['place_id'] ?? '',
      name: (displayName is Map ? displayName['text'] : displayName) ?? json['name'] ?? '',
      address: json['formattedAddress'] ?? json['address'] ?? '',
      coordinates: coords,
    );
  }

  Map<String, dynamic> toJson() => {
    'place_id': placeId,
    'name': name,
    'address': address,
    'coordinates': coordinates == null ? null : {'lat': coordinates!.latitude, 'lng': coordinates!.longitude},
  };
}

class PlaceAutocomplete {
  final String placeId;
  final String description;
  final String? mainText;
  final String? secondaryText;

  const PlaceAutocomplete({required this.placeId, required this.description, this.mainText, this.secondaryText});

  factory PlaceAutocomplete.fromJson(Map<String, dynamic> json) {
    final structured = json['structuredFormat'] as Map?;
    final text = json['text'];
    return PlaceAutocomplete(
      placeId: json['placeId'] ?? json['place_id'] ?? '',
      description: (text is Map ? text['text'] : text) ?? json['description'] ?? '',
      mainText: (structured?['mainText'] as Map?)?['text'],
      secondaryText: (structured?['secondaryText'] as Map?)?['text'],
    );
  }
}
