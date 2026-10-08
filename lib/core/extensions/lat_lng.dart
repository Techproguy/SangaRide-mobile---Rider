import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

extension LatLngDistance on LatLng {
  double metersTo(LatLng other) => Geolocator.distanceBetween(latitude, longitude, other.latitude, other.longitude);
}
