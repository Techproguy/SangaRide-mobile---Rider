import 'package:sanga_ride/model/location/place.dart';
import 'package:sanga_ride/model/account/load_problem.dart';
import 'package:sanga_ride/model/ride/ride_request.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

enum HistoryKind {
  ride('ride'),
  delivery('delivery'),
  unknown('unknown');

  const HistoryKind(this.code);

  final String code;

  bool get isDelivery => this == delivery;

  static HistoryKind fromCode(String? code) => enumByCode(values, code, (kind) => kind.code, HistoryKind.unknown);
}

enum HistoryStatus {
  completed('completed', 'Completed'),
  cancelled('cancelled', 'Cancelled'),
  unknown('unknown', 'Updating');

  const HistoryStatus(this.code, this.label);

  final String code;
  final String label;

  static const List<HistoryStatus> tabs = [completed, cancelled];

  static HistoryStatus fromCode(String? code) =>
      enumByCode(values, code, (status) => status.code, HistoryStatus.unknown);
}

class HistoryRoute {
  const HistoryRoute({required this.pickup, required this.stops, required this.dropoff});

  factory HistoryRoute.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return HistoryRoute(
      pickup: Place.fromJson(reader.object('pickup').raw),
      stops: reader.listOf('stops', (stop) => Place.fromJson(stop.raw)),
      dropoff: Place.fromJson(reader.object('dropoff').raw),
    );
  }

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
    this.memberName,
    this.purpose,
    this.packagePhotoUrl,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return HistoryItem(
      id: reader.str('id'),
      kind: HistoryKind.fromCode(reader.strOrNull('kind')),
      status: HistoryStatus.fromCode(reader.strOrNull('status')),
      category: RideCategory.values.asNameMap()[reader.strOrNull('category')] ?? RideCategory.go,
      occurredAt: reader.time('occurredAt').toLocal(),
      route: HistoryRoute.fromJson(json),
      fare: reader.intOr('fare', 0),
      itemName: reader.strOrNull('itemName'),
      memberName: reader.strOrNull('memberName'),
      purpose: reader.strOrNull('purpose'),
      packagePhotoUrl: reader.strOrNull('packagePhotoUrl'),
    );
  }

  final String id;
  final HistoryKind kind;
  final HistoryStatus status;
  final RideCategory category;
  final DateTime occurredAt;
  final HistoryRoute route;
  final int fare;
  final String? itemName;
  final String? memberName;
  final String? purpose;
  final String? packagePhotoUrl;

  bool get canRebook => kind == HistoryKind.ride;
}

class HistoryPage {
  const HistoryPage({required this.items, required this.page, required this.hasMore});

  factory HistoryPage.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return HistoryPage(
      items: reader.listOf('items', (item) => HistoryItem.fromJson(item.raw)),
      page: reader.intOr('page', 1),
      hasMore: reader.boolOr('hasMore', false),
    );
  }

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
  const HistoryFeedFailed(this.problem);

  final LoadProblem problem;
}

enum HistoryMore { idle, loading, failed }

final class HistoryFeedLoaded extends HistoryFeedState {
  const HistoryFeedLoaded({
    required this.items,
    required this.page,
    required this.hasMore,
    this.more = HistoryMore.idle,
    this.isStale = false,
  });

  final List<HistoryItem> items;
  final int page;
  final bool hasMore;
  final HistoryMore more;
  final bool isStale;

  HistoryFeedLoaded copyWith({List<HistoryItem>? items, int? page, bool? hasMore, HistoryMore? more, bool? isStale}) =>
      HistoryFeedLoaded(
        items: items ?? this.items,
        page: page ?? this.page,
        hasMore: hasMore ?? this.hasMore,
        more: more ?? this.more,
        isStale: isStale ?? this.isStale,
      );
}
