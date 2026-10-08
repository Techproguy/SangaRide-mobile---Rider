import 'dart:math' as math;

import 'package:sanga_ride/core/api/delivery_endpoints.dart';
import 'package:sanga_ride/core/api/mock/mock_delivery_live.dart';
import 'package:sanga_ride/core/api/mock/mock_server.dart';

abstract final class MockDelivery {
  static final List<MockRoute> routes = [
    MockRoute.post(DeliveryEndpoints.uploads, _upload),
    MockRoute.get(DeliveryEndpoints.catalog, (_) => catalog),
    MockRoute.post(DeliveryEndpoints.quote, _quote),
  ];

  static const String expiredHook = '#expired';
  static const String packagePhotoAsset = 'assets/images/package_photo.webp';
  static const String profilePhotoAsset = 'assets/images/service_someone.webp';
  static const String idDocumentAsset = 'assets/images/package_photo.webp';

  static const Duration _quoteLifetime = Duration(minutes: 10);
  static const int _maxUploadBytes = 8 * 1024 * 1024;
  static const Set<String> _imageExtensions = {'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'};
  static const int _maxDocumentBytes = 5 * 1024 * 1024;
  static const Map<String, String> _uploadAssets = {
    'package_photo': packagePhotoAsset,
    'profile_photo': profilePhotoAsset,
    'id_document': idDocumentAsset,
    'pickup_proof': MockDeliveryLive.pickupProofAsset,
    'delivery_proof': MockDeliveryLive.deliveryProofAsset,
  };

  static const int _highValueThreshold = 200000;
  static const int _maxDeclaredValue = 5000000;
  static const int _baseFare = 1500;
  static const int _perKm = 110;
  static const double _roadFactor = 1.3;
  static const double _etaMinutesPerKm = 1.2;
  static const Map<String, double> _tierMultipliers = {
    'standard': 1,
    'express': 1.4,
    'priority': 1.9,
    'premium_care': 2.4,
  };
  static const Map<String, int> _sizeSurcharges = {'small': 0, 'medium': 500, 'large': 1500};
  static const Map<String, int> _packageTypeSurcharges = {'fragile': 300, 'perishable': 200, 'not_fragile': 0};
  static const Map<String, String> _prohibited = {
    'weapon': 'Weapons can’t be sent on Sanga.',
    'gun': 'Weapons can’t be sent on Sanga.',
    'explosive': 'Explosives can’t be sent on Sanga.',
    'drug': 'Drugs and illegal substances can’t be sent on Sanga.',
    'alcohol': 'Alcohol can’t be sent on Sanga.',
    'fireworks': 'Fireworks can’t be sent on Sanga.',
  };

  static const Map<String, dynamic> _catalog = {
    'kinds': [
      {'id': 'documents', 'label': 'Documents', 'hint': 'Papers, contracts, files, folders'},
      {'id': 'package', 'label': 'Package', 'hint': 'Boxes, appliances, gifts'},
    ],
    'sizes': [
      {'id': 'small', 'label': 'Small', 'maxKg': 5},
      {'id': 'medium', 'label': 'Medium', 'maxKg': 20},
      {'id': 'large', 'label': 'Large', 'maxKg': 50},
    ],
    'packageTypes': [
      {'id': 'fragile', 'label': 'Fragile'},
      {'id': 'not_fragile', 'label': 'Not fragile'},
      {'id': 'perishable', 'label': 'Perishable'},
    ],
    'tiers': [
      {
        'id': 'standard',
        'label': 'Standard',
        'blurb': 'Reliable and affordable',
        'etaMinutes': [30, 60],
      },
      {
        'id': 'express',
        'label': 'Express',
        'blurb': 'Faster for urgent items',
        'etaMinutes': [20, 40],
      },
      {
        'id': 'priority',
        'label': 'Priority',
        'blurb': 'Straight to the drop off',
        'etaMinutes': [10, 25],
      },
      {
        'id': 'premium_care',
        'label': 'Premium Care',
        'blurb': 'For high value or fragile items',
        'etaMinutes': [30, 60],
      },
    ],
    'highValueThreshold': _highValueThreshold,
    'maxDeclaredValue': _maxDeclaredValue,
    'prohibitedNotice': 'Hazardous, illegal or restricted items are not allowed',
  };

  static Map<String, dynamic> get catalog => {..._catalog, 'serverTime': _isoNow()};

  static final Map<String, _MockQuote> _quotes = {};
  static final Map<String, String> _uploadUrls = {};
  static int _uploadCounter = 0;
  static int _quoteCounter = 0;

  static String? uploadUrlOf(String? id) => id == null ? null : _uploadUrls[id];

  static String _isoNow() => DateTime.now().toUtc().toIso8601String();

  static List<Map<String, dynamic>> get _tiers => (_catalog['tiers'] as List).cast<Map<String, dynamic>>();

  static Object? _upload(MockRequest request) {
    final purpose = request.body['purpose'] as String?;
    final asset = _uploadAssets[purpose];
    if (asset == null) throw const MockFailure(422, 'We can’t use that upload.', code: 'invalid_purpose');
    final file = request.body['file'];
    if (file is Map) {
      final extension = (file['name'] as String? ?? '').split('.').last.toLowerCase();
      if (!_imageExtensions.contains(extension)) {
        throw const MockFailure(415, 'That file type isn’t supported.', code: 'unsupported_type');
      }
      final limit = purpose == 'id_document' ? _maxDocumentBytes : _maxUploadBytes;
      if ((file['length'] as num? ?? 0) > limit) {
        throw const MockFailure(413, 'That photo is too big.', code: 'file_too_large');
      }
    }
    final id = 'upl_${++_uploadCounter}';
    _uploadUrls[id] = asset;
    return {'id': id, 'url': asset, 'purpose': purpose, 'serverTime': _isoNow()};
  }

  static Object? _quote(MockRequest request) {
    final body = request.body;
    final declaredValue = (body['declaredValue'] as num?)?.toInt();
    if (declaredValue != null && declaredValue > _maxDeclaredValue) {
      throw const MockFailure(422, 'That value is too high.', code: 'declared_value_too_high');
    }
    final points = [body['pickup'], ...(body['stops'] as List? ?? const []), body['dropoff']];
    if (points.any((point) => point is! Map || point['coordinates'] is! Map)) {
      throw const MockFailure(422, 'Add a pickup and drop off first.', code: 'route_incomplete');
    }
    final km = _routeKm([for (final point in points) (point as Map)['coordinates'] as Map]);
    final surcharge = (_sizeSurcharges[body['size']] ?? 0) + (_packageTypeSurcharges[body['packageType']] ?? 0);
    final recommended = declaredValue != null && declaredValue >= _highValueThreshold ? 'premium_care' : null;
    final extraMinutes = (km * _etaMinutesPerKm).round();
    final fares = <String, int>{
      for (final tier in _tiers)
        tier['id'] as String: _roundTo50((_baseFare + _perKm * km) * _tierMultipliers[tier['id']]! + surcharge),
    };
    final id = 'qt_${++_quoteCounter}';
    final expiresAt = DateTime.now().add(_quoteLifetime);
    _quotes[id] = _MockQuote(expiresAt: expiresAt, fares: fares);
    return {
      'quoteId': id,
      'expiresAt': expiresAt.toUtc().toIso8601String(),
      'serverTime': _isoNow(),
      'tiers': [
        for (final tier in _tiers)
          {
            'id': tier['id'],
            'fare': fares[tier['id']],
            'etaMinutes': [for (final minutes in tier['etaMinutes'] as List) (minutes as int) + extraMinutes],
            'recommended': tier['id'] == recommended,
          },
      ],
      'recommendedTier': recommended,
    };
  }

  static void validateRequest(Map<String, dynamic> body) {
    final delivery = Map<String, dynamic>.from(body['delivery'] as Map);
    final item = Map<String, dynamic>.from(delivery['item'] as Map? ?? const {});
    final recipient = Map<String, dynamic>.from(delivery['recipient'] as Map? ?? const {});
    final text = '${item['name']} ${item['description']}'.toLowerCase();
    final quote = _quotes[delivery['quoteId']];
    if (quote == null || quote.isExpired || text.contains(expiredHook)) {
      throw const MockFailure(409, 'That price has timed out.', code: 'quote_expired');
    }
    if (!quote.fares.containsKey(delivery['tier'])) {
      throw const MockFailure(422, 'Pick a delivery tier.', code: 'invalid_tier');
    }
    final reason = _prohibited.entries.where((entry) => text.contains(entry.key)).firstOrNull?.value;
    if (reason != null) {
      throw MockFailure(422, 'We can’t carry that item.', code: 'item_prohibited', data: {'reason': reason});
    }
    if (!_isDeliverablePhone(recipient['phone'] as String? ?? '')) {
      throw const MockFailure(422, 'That phone number looks off.', code: 'invalid_recipient_phone');
    }
  }

  static bool _isDeliverablePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^234[789]\d{9}$').hasMatch(digits)) return false;
    final national = digits.substring(3);
    return national.split('').toSet().length > 1 && !national.endsWith('000000');
  }

  static int _roundTo50(num value) => (value / 50).round() * 50;

  static double _routeKm(List<Map> points) {
    var km = 0.0;
    for (var i = 1; i < points.length; i++) {
      km += _distanceKm(points[i - 1], points[i]);
    }
    return (km * _roadFactor).clamp(1, 120).toDouble();
  }

  static double _distanceKm(Map a, Map b) {
    const earthRadiusKm = 6371.0;
    double radians(num degrees) => degrees * math.pi / 180;
    final dLat = radians((b['lat'] as num) - (a['lat'] as num));
    final dLng = radians((b['lng'] as num) - (a['lng'] as num));
    final h =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(radians(a['lat'] as num)) * math.cos(radians(b['lat'] as num)) * math.pow(math.sin(dLng / 2), 2);
    return 2 * earthRadiusKm * math.asin(math.sqrt(h));
  }
}

class _MockQuote {
  const _MockQuote({required this.expiresAt, required this.fares});

  final DateTime expiresAt;
  final Map<String, int> fares;

  bool get isExpired => !expiresAt.isAfter(DateTime.now());
}
