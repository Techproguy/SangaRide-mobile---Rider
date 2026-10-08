import 'package:sanga_ride/model/location/place.dart';
import 'package:sanga_ride/model/ride/ride_request.dart';

enum HistoryKind {
  ride('ride'),
  delivery('delivery');

  const HistoryKind(this.code);

  final String code;

  bool get isDelivery => this == delivery;

  static HistoryKind fromCode(String code) => values.firstWhere(
    (kind) => kind.code == code,
    orElse: () => throw FormatException('Unknown history kind: $code'),
  );
}

enum HistoryStatus {
  completed('completed', 'Completed'),
  cancelled('cancelled', 'Cancelled');

  const HistoryStatus(this.code, this.label);

  final String code;
  final String label;

  static HistoryStatus fromCode(String code) => values.firstWhere(
    (status) => status.code == code,
    orElse: () => throw FormatException('Unknown history status: $code'),
  );
}

class HistoryRoute {
  const HistoryRoute({required this.pickup, required this.stops, required this.dropoff});

  factory HistoryRoute.fromJson(Map<String, dynamic> json) => HistoryRoute(
    pickup: Place.fromJson(Map<String, dynamic>.from(json['pickup'] as Map)),
    stops: [for (final stop in json['stops'] as List) Place.fromJson(Map<String, dynamic>.from(stop as Map))],
    dropoff: Place.fromJson(Map<String, dynamic>.from(json['dropoff'] as Map)),
  );

  final Place pickup;
  final List<Place> stops;
  final Place dropoff;
}

class HistoryItem {
  const HistoryItem({
    required this.id,
    required this.kind,
    required this.status,
    required this.category,
    required this.occurredAt,
    required this.route,
    required this.fare,
    this.itemName,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
    id: json['id'] as String,
    kind: HistoryKind.fromCode(json['kind'] as String),
    status: HistoryStatus.fromCode(json['status'] as String),
    category: RideCategory.values.asNameMap()[json['category']] ?? RideCategory.go,
    occurredAt: DateTime.parse(json['occurredAt'] as String).toLocal(),
    route: HistoryRoute.fromJson(json),
    fare: (json['fare'] as num).toInt(),
    itemName: json['itemName'] as String?,
  );

  final String id;
  final HistoryKind kind;
  final HistoryStatus status;
  final RideCategory category;
  final DateTime occurredAt;
  final HistoryRoute route;
  final int fare;
  final String? itemName;

  bool get canRebook => kind == HistoryKind.ride;
}

class HistoryPage {
  const HistoryPage({required this.items, required this.page, required this.hasMore});

  factory HistoryPage.fromJson(Map<String, dynamic> json) => HistoryPage(
    items: [for (final item in json['items'] as List) HistoryItem.fromJson(Map<String, dynamic>.from(item as Map))],
    page: (json['page'] as num).toInt(),
    hasMore: json['hasMore'] as bool,
  );

  final List<HistoryItem> items;
  final int page;
  final bool hasMore;
}

sealed class HistoryFeedState {
  const HistoryFeedState();
}

final class HistoryFeedLoading extends HistoryFeedState {
  const HistoryFeedLoading();
}

final class HistoryFeedFailed extends HistoryFeedState {
  const HistoryFeedFailed();
}

enum HistoryMore { idle, loading, failed }

final class HistoryFeedLoaded extends HistoryFeedState {
  const HistoryFeedLoaded({
    required this.items,
    required this.page,
    required this.hasMore,
    this.more = HistoryMore.idle,
  });

  final List<HistoryItem> items;
  final int page;
  final bool hasMore;
  final HistoryMore more;

  HistoryFeedLoaded copyWith({List<HistoryItem>? items, int? page, bool? hasMore, HistoryMore? more}) =>
      HistoryFeedLoaded(
        items: items ?? this.items,
        page: page ?? this.page,
        hasMore: hasMore ?? this.hasMore,
        more: more ?? this.more,
      );
}
