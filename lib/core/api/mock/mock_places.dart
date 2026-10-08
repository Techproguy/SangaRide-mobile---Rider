import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride/core/extensions/lat_lng.dart';
import 'package:sanga_ride/model/models.dart';

class MockPlaces {
  MockPlaces._();

  static const Duration _latency = Duration(milliseconds: 300);
  static const int _maxResults = 6;

  static const List<Place> _areas = [
    Place(placeId: 'mock_yaba', name: 'Yaba', address: 'Yaba, Lagos', coordinates: LatLng(6.5095, 3.3711)),
    Place(placeId: 'mock_bariga', name: 'Bariga', address: 'Bariga, Yaba, Lagos', coordinates: LatLng(6.5397, 3.3889)),
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
    Place(
      placeId: 'mock_idumota',
      name: 'Idumota',
      address: 'Idumota, Lagos Island',
      coordinates: LatLng(6.4596, 3.3887),
    ),
    Place(placeId: 'mock_bodija', name: 'Bodija', address: 'Bodija, Ibadan, Oyo', coordinates: LatLng(7.4352, 3.9133)),
    Place(placeId: 'mock_wuse', name: 'Wuse 2', address: 'Wuse 2, Abuja, FCT', coordinates: LatLng(9.0790, 7.4700)),
    Place(
      placeId: 'mock_gra_benin',
      name: 'GRA Benin',
      address: 'GRA, Benin City, Edo',
      coordinates: LatLng(6.3176, 5.6145),
    ),
    Place(
      placeId: 'mock_gra_ph',
      name: 'Old GRA',
      address: 'Old GRA, Port Harcourt, Rivers',
      coordinates: LatLng(4.7900, 7.0130),
    ),
  ];

  static const List<Place> _landmarks = [
    Place(
      placeId: 'mock_yabatech',
      name: 'Yaba College of Technology',
      address: 'Herbert Macaulay Way, Yaba, Lagos',
      coordinates: LatLng(6.5191, 3.3741),
    ),
    Place(
      placeId: 'mock_cr_ikeja',
      name: 'Chicken Republic',
      address: 'Allen Avenue, Ikeja, Lagos',
      coordinates: LatLng(6.6018, 3.3515),
    ),
    Place(
      placeId: 'mock_cr_idumota',
      name: 'Chicken Republic',
      address: 'Nnamdi Azikiwe Street, Idumota, Lagos',
      coordinates: LatLng(6.4601, 3.3895),
    ),
    Place(
      placeId: 'mock_cr_vi',
      name: 'Chicken Republic',
      address: 'Adeola Odeku Street, Victoria Island, Lagos',
      coordinates: LatLng(6.4310, 3.4180),
    ),
    Place(
      placeId: 'mock_cr_lekki',
      name: 'Chicken Republic',
      address: 'Admiralty Way, Lekki Phase 1, Lagos',
      coordinates: LatLng(6.4441, 3.4691),
    ),
    Place(
      placeId: 'mock_palms',
      name: 'The Palms Mall',
      address: 'Lekki Phase 1, Lagos',
      coordinates: LatLng(6.4352, 3.4515),
    ),
    Place(placeId: 'mock_cv', name: 'Computer Village', address: 'Ikeja, Lagos', coordinates: LatLng(6.5951, 3.3398)),
    Place(
      placeId: 'mock_icm',
      name: 'Ikeja City Mall',
      address: 'Obafemi Awolowo Way, Ikeja, Lagos',
      coordinates: LatLng(6.6142, 3.3576),
    ),
    Place(
      placeId: 'mock_airport',
      name: 'Murtala Muhammed International Airport',
      address: 'Ikeja, Lagos',
      coordinates: LatLng(6.5774, 3.3212),
    ),
    Place(
      placeId: 'mock_lcc',
      name: 'Lekki Conservation Centre',
      address: 'Lekki Peninsula, Lagos',
      coordinates: LatLng(6.4412, 3.5352),
    ),
    Place(
      placeId: 'mock_eko',
      name: 'Eko Hotel and Suites',
      address: 'Adetokunbo Ademola Street, Victoria Island, Lagos',
      coordinates: LatLng(6.4262, 3.4290),
    ),
    Place(
      placeId: 'mock_theatre',
      name: 'National Theatre',
      address: 'Iganmu, Lagos',
      coordinates: LatLng(6.4769, 3.3683),
    ),
    Place(
      placeId: 'mock_unilag',
      name: 'University of Lagos',
      address: 'Akoka, Yaba, Lagos',
      coordinates: LatLng(6.5158, 3.3966),
    ),
  ];

  static List<Place> get _all => [..._landmarks, ..._areas];

  static List<Place> _matching(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return [];
    return _all.where((place) => '${place.name} ${place.address}'.toLowerCase().contains(needle)).toList();
  }

  static Future<List<Place>> search(String query) async {
    await Future<void>.delayed(_latency);
    return _matching(query);
  }

  static Future<List<PlaceAutocomplete>> autocomplete(String query, {LatLng? origin}) async {
    await Future<void>.delayed(_latency);
    final matches = _matching(query);
    int? distanceTo(Place place) => origin == null ? null : place.coordinates!.metersTo(origin).round();
    if (origin != null) matches.sort((a, b) => distanceTo(a)!.compareTo(distanceTo(b)!));
    return [
      for (final place in matches.take(_maxResults))
        PlaceAutocomplete(
          placeId: place.placeId,
          description: '${place.name}, ${place.address}',
          mainText: place.name,
          secondaryText: place.address,
          distanceMeters: distanceTo(place),
        ),
    ];
  }

  static Future<Place?> details(String placeId) async {
    await Future<void>.delayed(_latency);
    for (final place in _all) {
      if (place.placeId == placeId) return place;
    }
    return null;
  }

  static Future<Place> nearest(LatLng position) async {
    await Future<void>.delayed(_latency);
    final area = _areas.reduce(
      (a, b) => a.coordinates!.metersTo(position) <= b.coordinates!.metersTo(position) ? a : b,
    );
    return Place(placeId: 'mock_current', name: area.name, address: area.address, coordinates: position);
  }
}
