import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride/core/api/mock/mock_money.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class MockPlaceSpec {
  const MockPlaceSpec(this.id, this.name, this.address, this.lat, this.lng);

  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;

  Place get model => Place(placeId: id, name: name, address: address, coordinates: LatLng(lat, lng));

  Map<String, dynamic> get json => {
    'place_id': id,
    'name': name,
    'address': address,
    'coordinates': {'lat': lat, 'lng': lng},
  };

  Map<String, dynamic> get stop => {'name': name, 'address': address};
}

abstract final class MockRegion {
  static SangaRegion get current => MockMoney.region;

  static bool get isUnitedStates => MockMoney.isUnitedStates;

  static String get cityName => isUnitedStates ? 'Houston' : 'Lagos';

  static Map<String, dynamic> get weather => {'tempC': 28, 'condition': 'Sunny', 'icon': 'clear'};

  static List<MockPlaceSpec> get landmarks => isUnitedStates ? _houstonLandmarks : _lagosLandmarks;

  static List<MockPlaceSpec> get areas => isUnitedStates ? _houstonAreas : _lagosAreas;

  static List<MockPlaceSpec> get searchable => [...landmarks, ...areas];

  static MockPlaceSpec spec(String id) {
    final extras = isUnitedStates ? _houstonExtras : _lagosExtras;
    return [...searchable, ...extras].firstWhere((place) => place.id == id);
  }

  static Map<String, dynamic> place(String id) => spec(id).json;

  static Map<String, dynamic> stop(String id) => spec(id).stop;

  static Place model(String id) => spec(id).model;

  static List<Map<String, dynamic>> get recentPlaces => [for (final id in _recentIds) place(id)];

  static Map<String, dynamic> get fallbackPickup => isUnitedStates ? _houstonFallbackPickup : _lagosFallbackPickup;

  static Map<String, dynamic> get fallbackDropoff => isUnitedStates ? _houstonFallbackDropoff : _lagosFallbackDropoff;

  static String phone(String nigerianNational) {
    if (!isUnitedStates) return '+234$nigerianNational';
    final areaCode = _areaCodes[int.parse(nigerianNational.substring(0, 1)) % _areaCodes.length];
    return '+1${areaCode}555${nigerianNational.substring(nigerianNational.length - 4)}';
  }

  static String displayPhone(String e164) {
    final region = SangaPhoneNumber.regionOf(e164);
    if (region == SangaRegion.us) return SangaPhoneNumber.format(e164, region);
    final local = '0${SangaPhoneNumber.national(e164, region)}';
    return '${local.substring(0, 4)} ${local.substring(4, 7)} ${local.substring(7)}';
  }

  static String plate(String nigerianPlate) {
    if (!isUnitedStates) return nigerianPlate;
    final digits = nigerianPlate.replaceAll(RegExp(r'\D'), '').padRight(4, '1').substring(0, 4);
    return '${nigerianPlate.substring(0, 3)}-$digits';
  }

  static String get supportPhone => isUnitedStates ? '+18885550100' : '+2347000000000';

  static String get maskedCallNumber => isUnitedStates ? '+17135550199' : '+2342019990001';

  static String get walletBank => isUnitedStates ? 'Chase' : 'Wema';

  static const List<String> _areaCodes = ['713', '281', '832', '346'];

  static const List<String> _recentIds = ['mock_palms', 'mock_cv', 'mock_cr_ikeja'];

  static const Map<String, dynamic> _lagosFallbackPickup = {
    'name': 'Ikeja City Mall',
    'address': 'Obafemi Awolowo Way, Ikeja',
    'lat': 6.6145,
    'lng': 3.3569,
  };

  static const Map<String, dynamic> _lagosFallbackDropoff = {
    'name': 'Lekki Phase 1',
    'address': 'Admiralty Way, Lekki',
    'lat': 6.4478,
    'lng': 3.4723,
  };

  static const Map<String, dynamic> _houstonFallbackPickup = {
    'name': 'Memorial City Mall',
    'address': 'Memorial City Way, Houston',
    'lat': 29.7838,
    'lng': -95.5478,
  };

  static const Map<String, dynamic> _houstonFallbackDropoff = {
    'name': 'River Oaks',
    'address': 'Kirby Drive, River Oaks, Houston',
    'lat': 29.7561,
    'lng': -95.4189,
  };

  static const List<MockPlaceSpec> _lagosLandmarks = [
    MockPlaceSpec('mock_yabatech', 'Yaba College of Technology', 'Herbert Macaulay Way, Yaba, Lagos', 6.5191, 3.3741),
    MockPlaceSpec('mock_cr_ikeja', 'Chicken Republic', 'Allen Avenue, Ikeja, Lagos', 6.6018, 3.3515),
    MockPlaceSpec('mock_cr_idumota', 'Chicken Republic', 'Nnamdi Azikiwe Street, Idumota, Lagos', 6.4601, 3.3895),
    MockPlaceSpec('mock_cr_vi', 'Chicken Republic', 'Adeola Odeku Street, Victoria Island, Lagos', 6.4310, 3.4180),
    MockPlaceSpec('mock_cr_lekki', 'Chicken Republic', 'Admiralty Way, Lekki Phase 1, Lagos', 6.4441, 3.4691),
    MockPlaceSpec('mock_palms', 'The Palms Mall', 'Lekki Phase 1, Lagos', 6.4352, 3.4515),
    MockPlaceSpec('mock_cv', 'Computer Village', 'Ikeja, Lagos', 6.5951, 3.3398),
    MockPlaceSpec('mock_icm', 'Ikeja City Mall', 'Obafemi Awolowo Way, Ikeja, Lagos', 6.6142, 3.3576),
    MockPlaceSpec('mock_airport', 'Murtala Muhammed International Airport', 'Ikeja, Lagos', 6.5774, 3.3212),
    MockPlaceSpec('mock_lcc', 'Lekki Conservation Centre', 'Lekki Peninsula, Lagos', 6.4412, 3.5352),
    MockPlaceSpec(
      'mock_eko',
      'Eko Hotel and Suites',
      'Adetokunbo Ademola Street, Victoria Island, Lagos',
      6.4262,
      3.4290,
    ),
    MockPlaceSpec('mock_theatre', 'National Theatre', 'Iganmu, Lagos', 6.4769, 3.3683),
    MockPlaceSpec('mock_unilag', 'University of Lagos', 'Akoka, Yaba, Lagos', 6.5158, 3.3966),
  ];

  static const List<MockPlaceSpec> _lagosAreas = [
    MockPlaceSpec('mock_yaba', 'Yaba', 'Yaba, Lagos', 6.5095, 3.3711),
    MockPlaceSpec('mock_bariga', 'Bariga', 'Bariga, Yaba, Lagos', 6.5397, 3.3889),
    MockPlaceSpec('mock_lekki', 'Lekki Phase 1', 'Lekki Phase 1, Lagos', 6.4474, 3.4723),
    MockPlaceSpec('mock_ikeja', 'Ikeja GRA', 'Ikeja GRA, Ikeja, Lagos', 6.5833, 3.3500),
    MockPlaceSpec('mock_surulere', 'Surulere', 'Surulere, Lagos', 6.5000, 3.3500),
    MockPlaceSpec('mock_vi', 'Victoria Island', 'Victoria Island, Lagos', 6.4281, 3.4219),
    MockPlaceSpec('mock_ajah', 'Ajah', 'Ajah, Lekki, Lagos', 6.4698, 3.5852),
    MockPlaceSpec('mock_idumota', 'Idumota', 'Idumota, Lagos Island', 6.4596, 3.3887),
    MockPlaceSpec('mock_bodija', 'Bodija', 'Bodija, Ibadan, Oyo', 7.4352, 3.9133),
    MockPlaceSpec('mock_wuse', 'Wuse 2', 'Wuse 2, Abuja, FCT', 9.0790, 7.4700),
    MockPlaceSpec('mock_gra_benin', 'GRA Benin', 'GRA, Benin City, Edo', 6.3176, 5.6145),
    MockPlaceSpec('mock_gra_ph', 'Old GRA', 'Old GRA, Port Harcourt, Rivers', 4.7900, 7.0130),
  ];

  static const List<MockPlaceSpec> _lagosExtras = [
    MockPlaceSpec('mock_home', '12 Ajegule Street', '12 Ajegule Street, Ikorodu, Lagos', 6.6194, 3.5105),
    MockPlaceSpec('mock_work', 'Akeredolu Building', 'Akeredolu Building, Agege, Lagos', 6.6180, 3.3209),
    MockPlaceSpec('mock_maryland', 'Maryland College', 'Iyana Ipaja, Lagos', 6.6126, 3.2873),
  ];

  static const List<MockPlaceSpec> _houstonLandmarks = [
    MockPlaceSpec(
      'mock_yabatech',
      'Texas Southern University',
      '3100 Cleburne Street, Third Ward, Houston, TX',
      29.7233,
      -95.3590,
    ),
    MockPlaceSpec('mock_cr_ikeja', 'Whataburger', 'Westheimer Road, Montrose, Houston, TX', 29.7433, -95.3913),
    MockPlaceSpec('mock_cr_idumota', 'Whataburger', 'Navigation Boulevard, EaDo, Houston, TX', 29.7497, -95.3452),
    MockPlaceSpec('mock_cr_vi', 'Whataburger', 'Main Street, Downtown, Houston, TX', 29.7592, -95.3659),
    MockPlaceSpec('mock_cr_lekki', 'Whataburger', 'Richmond Avenue, Galleria, Houston, TX', 29.7332, -95.4644),
    MockPlaceSpec('mock_palms', 'Houston Galleria', '5085 Westheimer Road, Galleria, Houston, TX', 29.7396, -95.4618),
    MockPlaceSpec('mock_cv', 'Rice Village', 'Rice Boulevard, Rice Village, Houston, TX', 29.7167, -95.4003),
    MockPlaceSpec(
      'mock_icm',
      'Memorial City Mall',
      '303 Memorial City Way, Memorial City, Houston, TX',
      29.7840,
      -95.5480,
    ),
    MockPlaceSpec(
      'mock_airport',
      'George Bush Intercontinental Airport',
      '2800 North Terminal Road, Houston, TX',
      29.9902,
      -95.3368,
    ),
    MockPlaceSpec('mock_lcc', 'Buffalo Bayou Park', '1800 Allen Parkway, Houston, TX', 29.7623, -95.3862),
    MockPlaceSpec('mock_eko', 'Hilton Americas-Houston', '1600 Lamar Street, Downtown, Houston, TX', 29.7523, -95.3592),
    MockPlaceSpec(
      'mock_theatre',
      'Wortham Theater Center',
      '501 Texas Avenue, Downtown, Houston, TX',
      29.7613,
      -95.3667,
    ),
    MockPlaceSpec(
      'mock_unilag',
      'University of Houston',
      '4300 University Drive, Third Ward, Houston, TX',
      29.7199,
      -95.3422,
    ),
  ];

  static const List<MockPlaceSpec> _houstonAreas = [
    MockPlaceSpec('mock_yaba', 'Midtown', 'Midtown, Houston, TX', 29.7410, -95.3790),
    MockPlaceSpec('mock_bariga', 'Montrose', 'Montrose, Houston, TX', 29.7458, -95.3899),
    MockPlaceSpec('mock_lekki', 'River Oaks', 'River Oaks, Houston, TX', 29.7557, -95.4183),
    MockPlaceSpec('mock_ikeja', 'The Heights', 'The Heights, Houston, TX', 29.7985, -95.3988),
    MockPlaceSpec('mock_surulere', 'Museum District', 'Museum District, Houston, TX', 29.7222, -95.3897),
    MockPlaceSpec('mock_vi', 'Downtown Houston', 'Downtown, Houston, TX', 29.7604, -95.3698),
    MockPlaceSpec('mock_ajah', 'Sugar Land', 'Sugar Land, TX', 29.5994, -95.6141),
    MockPlaceSpec('mock_idumota', 'EaDo', 'EaDo, Houston, TX', 29.7488, -95.3498),
    MockPlaceSpec('mock_bodija', 'Zilker', 'Zilker, Austin, TX', 30.2639, -97.7704),
    MockPlaceSpec('mock_wuse', 'Uptown Dallas', 'Uptown, Dallas, TX', 32.8003, -96.8040),
    MockPlaceSpec('mock_gra_benin', 'Alamo Heights', 'Alamo Heights, San Antonio, TX', 29.4863, -98.4660),
    MockPlaceSpec('mock_gra_ph', 'The Strand', 'The Strand, Galveston, TX', 29.3085, -94.7885),
  ];

  static const List<MockPlaceSpec> _houstonExtras = [
    MockPlaceSpec('mock_home', '2412 Dunlavy Street', '2412 Dunlavy Street, Montrose, Houston, TX', 29.7452, -95.3948),
    MockPlaceSpec('mock_work', 'Chase Tower', 'Chase Tower, Downtown, Houston, TX', 29.7595, -95.3657),
    MockPlaceSpec('mock_maryland', 'Rice University', '6100 Main Street, Houston, TX', 29.7174, -95.4018),
  ];
}
