import 'package:google_maps_flutter/google_maps_flutter.dart';

class GeocodedLocation {
  final LatLng coordinates;
  final String formattedAddress;
  final String? streetNumber;
  final String? route;
  final String? locality;
  final String? subLocality;
  final String? administrativeAreaLevel1;
  final String? administrativeAreaLevel2;
  final String? country;
  final String? countryCode;
  final String? postalCode;
  final String? placeId;
  final String? name;

  GeocodedLocation({
    required this.coordinates,
    required this.formattedAddress,
    this.streetNumber,
    this.route,
    this.locality,
    this.subLocality,
    this.administrativeAreaLevel1,
    this.administrativeAreaLevel2,
    this.country,
    this.countryCode,
    this.postalCode,
    this.placeId,
    this.name,
  });

  GeocodedLocation copyWith({String? name}) {
    return GeocodedLocation(
      coordinates: coordinates,
      formattedAddress: formattedAddress,
      streetNumber: streetNumber,
      route: route,
      locality: locality,
      subLocality: subLocality,
      administrativeAreaLevel1: administrativeAreaLevel1,
      administrativeAreaLevel2: administrativeAreaLevel2,
      country: country,
      countryCode: countryCode,
      postalCode: postalCode,
      placeId: placeId,
      name: name ?? this.name,
    );
  }

  String get displayTitle {
    if (name != null && name!.trim().isNotEmpty) return name!.trim();
    if (city.isNotEmpty) return city;
    if (state.isNotEmpty) return state;
    return '';
  }

  String get fullAddress => formattedAddress;

  String get streetAddress {
    if (streetNumber != null && route != null) {
      return '$streetNumber $route';
    } else if (route != null) {
      return route!;
    } else if (streetNumber != null) {
      return streetNumber!;
    }
    return '';
  }

  String get city => locality ?? subLocality ?? '';

  String get state => administrativeAreaLevel1 ?? '';

  String get cityState {
    final cityName = city;
    final stateName = state;

    if (cityName.isNotEmpty && stateName.isNotEmpty) {
      return '$cityName, $stateName';
    } else if (cityName.isNotEmpty) {
      return cityName;
    } else if (stateName.isNotEmpty) {
      return stateName;
    }
    return '';
  }

  String get cityStateCountry {
    final parts = <String>[];

    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty) parts.add(state);
    if (country != null && country!.isNotEmpty) parts.add(country!);

    return parts.join(', ');
  }

  String get shortAddress {
    final street = streetAddress;
    final cityName = city;

    if (street.isNotEmpty && cityName.isNotEmpty) {
      return '$street, $cityName';
    } else if (street.isNotEmpty) {
      return street;
    } else if (cityName.isNotEmpty) {
      return cityName;
    }
    return formattedAddress;
  }

  String get zip => postalCode ?? '';

  bool get isValid => formattedAddress.isNotEmpty;

  factory GeocodedLocation.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'];
    final location = geometry?['location'];
    final lat = location?['lat'] ?? 0.0;
    final lng = location?['lng'] ?? 0.0;

    final addressComponents = json['address_components'] as List? ?? [];

    String? streetNumber;
    String? route;
    String? locality;
    String? subLocality;
    String? adminArea1;
    String? adminArea2;
    String? country;
    String? countryCode;
    String? postalCode;

    for (var component in addressComponents) {
      final types = component['types'] as List;
      final longName = component['long_name'] as String?;
      final shortName = component['short_name'] as String?;

      if (types.contains('street_number')) {
        streetNumber = longName;
      } else if (types.contains('route')) {
        route = longName;
      } else if (types.contains('locality')) {
        locality = longName;
      } else if (types.contains('sublocality') || types.contains('sublocality_level_1')) {
        subLocality = longName;
      } else if (types.contains('administrative_area_level_1')) {
        adminArea1 = shortName ?? longName;
      } else if (types.contains('administrative_area_level_2')) {
        adminArea2 = longName;
      } else if (types.contains('country')) {
        country = longName;
        countryCode = shortName;
      } else if (types.contains('postal_code')) {
        postalCode = longName;
      }
    }

    return GeocodedLocation(
      coordinates: LatLng(lat, lng),
      formattedAddress: json['formatted_address'] ?? '',
      streetNumber: streetNumber,
      route: route,
      locality: locality,
      subLocality: subLocality,
      administrativeAreaLevel1: adminArea1,
      administrativeAreaLevel2: adminArea2,
      country: country,
      countryCode: countryCode,
      postalCode: postalCode,
      placeId: json['place_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coordinates': {'lat': coordinates.latitude, 'lng': coordinates.longitude},
      'formatted_address': formattedAddress,
      'street_number': streetNumber,
      'route': route,
      'locality': locality,
      'sublocality': subLocality,
      'administrative_area_level_1': administrativeAreaLevel1,
      'administrative_area_level_2': administrativeAreaLevel2,
      'country': country,
      'country_code': countryCode,
      'postal_code': postalCode,
      'place_id': placeId,
    };
  }

  @override
  String toString() => fullAddress;
}
