import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride/model/models.dart';

class MockPlaces {
  MockPlaces._();

  static const Duration _latency = Duration(milliseconds: 300);

  static const List<Place> _lagos = [
    Place(placeId: 'mock_yaba', name: 'Yaba', address: 'Yaba, Lagos', coordinates: LatLng(6.5095, 3.3711)),
    Place(placeId: 'mock_bariga', name: 'Bariga', address: 'Bariga, Yaba, Lagos', coordinates: LatLng(6.5397, 3.3889)),
    Place(
      placeId: 'mock_yabatech',
      name: 'Yaba College of Technology',
      address: 'Herbert Macaulay Way, Yaba, Lagos',
      coordinates: LatLng(6.5191, 3.3741),
    ),
    Place(
      placeId: 'mock_lekki',
      name: 'Lekki Phase 1',
      address: 'Lekki Phase 1, Lagos',
      coordinates: LatLng(6.4474, 3.4723),
    ),
    Place(
      placeId: 'mock_ikeja',
      name: 'Ikeja GRA',
      address: 'Ikeja GRA, Ikeja, Lagos',
      coordinates: LatLng(6.5833, 3.3500),
    ),
    Place(placeId: 'mock_surulere', name: 'Surulere', address: 'Surulere, Lagos', coordinates: LatLng(6.5000, 3.3500)),
    Place(
      placeId: 'mock_vi',
      name: 'Victoria Island',
      address: 'Victoria Island, Lagos',
      coordinates: LatLng(6.4281, 3.4219),
    ),
    Place(placeId: 'mock_ajah', name: 'Ajah', address: 'Ajah, Lekki, Lagos', coordinates: LatLng(6.4698, 3.5852)),
  ];

  static Future<List<Place>> search(String query) async {
    await Future<void>.delayed(_latency);
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return [];
    return _lagos.where((place) => '${place.name} ${place.address}'.toLowerCase().contains(needle)).toList();
  }

  static Future<Place> nearest(LatLng position) async {
    await Future<void>.delayed(_latency);
    return Place(placeId: 'mock_current', name: 'Yaba', address: 'Yaba, Lagos', coordinates: position);
  }
}
