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

  static const Map<String, dynamic> savedPlaces = {
    'home': {
      'place_id': 'mock_home',
      'name': 'Home',
      'address': '12 Ajegule Street, Ikorodu, Lagos',
      'coordinates': {'lat': 6.6194, 'lng': 3.5105},
    },
    'work': {
      'place_id': 'mock_work',
      'name': 'Work',
      'address': 'Akeredolu Building, Agege, Lagos',
      'coordinates': {'lat': 6.6180, 'lng': 3.3209},
    },
  };

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
}
