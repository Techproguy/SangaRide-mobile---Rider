class MockData {
  MockData._();

  static const String otpCode = '1234';

  static const String unregisteredPhone = '+2348000000000';

  static const Map<String, dynamic> tokens = {'accessToken': 'mock-access-token', 'refreshToken': 'mock-refresh-token'};

  static const Map<String, dynamic> user = {
    'id': 'usr_rider_001',
    'firstName': 'Ada',
    'lastName': 'Okafor',
    'email': 'ada.okafor@example.com',
    'phone': '+2348012345678',
    'avatarUrl': null,
    'rating': 4.9,
    'tripCount': 37,
  };

  static const Map<String, dynamic> weather = {'city': 'Lagos', 'temperatureC': 28, 'condition': 'sunny'};

  static const List<Map<String, dynamic>> recentPlaces = [
    {
      'place_id': 'mock_palms',
      'name': 'The Palms Mall',
      'address': 'Lekki Phase 1, Lagos',
      'coordinates': {'lat': 6.4352, 'lng': 3.4515},
    },
    {
      'place_id': 'mock_cv',
      'name': 'Computer Village',
      'address': 'Ikeja, Lagos',
      'coordinates': {'lat': 6.5951, 'lng': 3.3398},
    },
    {
      'place_id': 'mock_cr_ikeja',
      'name': 'Chicken Republic',
      'address': 'Allen Avenue, Ikeja, Lagos',
      'coordinates': {'lat': 6.6018, 'lng': 3.3515},
    },
  ];

  static const List<Map<String, dynamic>> rideOptions = [
    {
      'id': 'go',
      'category': 'go',
      'name': 'Sanga Go',
      'description': 'Economical everyday ride',
      'seats': '1-4',
      'pricePerKm': 1500,
    },
    {
      'id': 'plus',
      'category': 'plus',
      'name': 'Sanga Plus',
      'description': 'Comfortable, reliable rides',
      'seats': '1-4',
      'pricePerKm': 2000,
    },
    {
      'id': 'xl',
      'category': 'xl',
      'name': 'Sanga XL',
      'description': 'Spacious for groups',
      'seats': '1-6',
      'pricePerKm': 3000,
    },
    {
      'id': 'lux',
      'category': 'lux',
      'name': 'Sanga Lux',
      'description': 'Premium experience',
      'seats': '1-4',
      'pricePerKm': 5000,
    },
    {
      'id': 'moto',
      'category': 'moto',
      'name': 'Sanga Moto',
      'description': 'Beat traffic on a motorcycle',
      'seats': '1',
      'pricePerKm': 700,
    },
    {
      'id': 'assist',
      'category': 'assist',
      'name': 'Sanga Assist',
      'description': 'Extra help and accessibility',
      'seats': '1-4',
      'pricePerKm': 3000,
    },
  ];

  static const List<String> matchStepLabels = [
    'Searching for nearby drivers',
    'Checking availability',
    'Sending request',
    'Finding a match',
  ];

  static const Map<String, dynamic> driverVehicle = {
    'make': 'Toyota',
    'model': 'Corolla',
    'year': 2007,
    'colour': 'blue',
    'plate': 'BDJ822FQ',
    'features': ['Air conditioned'],
  };

  static const List<Map<String, dynamic>> driverOffers = [
    {
      'id': 'offer_kamaru',
      'status': 'pending',
      'counterMarkup': 0.1,
      'etaMinutes': 20,
      'distanceKm': 4.0,
      'matchLabel': 'Perfect match',
      'driver': {
        'id': 'drv_kamaru',
        'name': 'Kamaru U.',
        'firstName': 'Kamaru',
        'photoUrl': null,
        'verified': true,
        'rating': 4.0,
        'ridesCompleted': 150,
      },
    },
    {
      'id': 'offer_george',
      'status': 'pending',
      'counterMarkup': null,
      'etaMinutes': 25,
      'distanceKm': 6.0,
      'matchLabel': null,
      'driver': {
        'id': 'drv_george',
        'name': 'George A.',
        'firstName': 'George',
        'photoUrl': null,
        'verified': true,
        'rating': 3.0,
        'ridesCompleted': 88,
      },
    },
    {
      'id': 'offer_john',
      'status': 'pending',
      'counterMarkup': 0.05,
      'etaMinutes': 25,
      'distanceKm': 7.0,
      'matchLabel': null,
      'driver': {
        'id': 'drv_john',
        'name': 'John A.',
        'firstName': 'John',
        'photoUrl': null,
        'verified': true,
        'rating': 5.0,
        'ridesCompleted': 312,
      },
    },
    {
      'id': 'offer_ibrahim',
      'status': 'withdrawn',
      'counterMarkup': null,
      'etaMinutes': 25,
      'distanceKm': 9.0,
      'matchLabel': null,
      'driver': {
        'id': 'drv_ibrahim',
        'name': 'Ibrahim S.',
        'firstName': 'Ibrahim',
        'photoUrl': null,
        'verified': false,
        'rating': 3.0,
        'ridesCompleted': 42,
      },
    },
  ];
}
