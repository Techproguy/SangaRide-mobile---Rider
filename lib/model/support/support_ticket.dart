import 'package:sanga_ride/model/support/support_problem.dart';

enum IssueContext {
  trip('trip'),
  delivery('delivery'),
  account('account'),
  payment('payment');

  const IssueContext(this.code);

  final String code;

  static IssueContext fromCode(String? code) => values.where((value) => value.code == code).firstOrNull ?? trip;
}

enum IssueIcon {
  notMoving('not_moving'),
  unreachable('unreachable'),
  location('location'),
  payment('payment'),
  incomplete('incomplete'),
  package('package'),
  safety('safety'),
  account('account'),
  receipt('receipt'),
  other('other');

  const IssueIcon(this.code);

  final String code;

  static IssueIcon fromCode(Object? code) => values.where((icon) => icon.code == '$code').firstOrNull ?? other;
}

class IssueType {
  const IssueType({required this.id, required this.label, required this.hint, required this.icon});

  factory IssueType.fromJson(Map<String, dynamic> json) => IssueType(
    id: json['id'] as String,
    label: json['label'] as String,
    hint: json['hint'] as String? ?? '',
    icon: IssueIcon.fromCode(json['icon']),
  );

  final String id;
  final String label;
  final String hint;
  final IssueIcon icon;
}

enum TicketStatus {
  reported('reported'),
  investigating('investigating'),
  actionNeeded('action_needed'),
  resolved('resolved'),
  closed('closed');

  const TicketStatus(this.code);

  final String code;

  bool get isOpen => this == reported || this == investigating || this == actionNeeded;

  bool get isWaiting => this == reported || this == investigating;

  static TicketStatus fromCode(Object? code) =>
      values.where((status) => status.code == '$code').firstOrNull ?? reported;
}

enum TicketEventType {
  reported('reported'),
  investigating('investigating'),
  actionRequested('action_requested'),
  actionTaken('action_taken'),
  resolved('resolved');

  const TicketEventType(this.code);

  final String code;

  static TicketEventType? fromCode(Object? code) => values.where((type) => type.code == '$code').firstOrNull;
}

class TicketEvent {
  const TicketEvent({required this.type, required this.at, required this.detail});

  final TicketEventType type;
  final DateTime? at;
  final String detail;

  static TicketEvent? fromJson(Map<String, dynamic> json) {
    final type = TicketEventType.fromCode(json['type']);
    if (type == null) return null;
    return TicketEvent(
      type: type,
      at: json['at'] == null ? null : DateTime.parse('${json['at']}').toLocal(),
      detail: json['detail'] as String? ?? '',
    );
  }
}

class ResolutionOption {
  const ResolutionOption({required this.id, required this.label, required this.hint});

  factory ResolutionOption.fromJson(Map<String, dynamic> json) =>
      ResolutionOption(id: json['id'] as String, label: json['label'] as String, hint: json['hint'] as String? ?? '');

  final String id;
  final String label;
  final String hint;
}

class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.reference,
    required this.type,
    required this.typeLabel,
    required this.status,
    required this.events,
    required this.resolutionOptions,
    required this.tripId,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(
    id: json['id'] as String,
    reference: json['reference'] as String,
    type: json['type'] as String,
    typeLabel: json['typeLabel'] as String? ?? '',
    status: TicketStatus.fromCode(json['status']),
    events: [
      for (final event in json['events'] as List) ?TicketEvent.fromJson(Map<String, dynamic>.from(event as Map)),
    ],
    resolutionOptions: json['resolutionOptions'] == null
        ? const []
        : [
            for (final option in json['resolutionOptions'] as List)
              ResolutionOption.fromJson(Map<String, dynamic>.from(option as Map)),
          ],
    tripId: json['tripId'] as String?,
  );

  final String id;
  final String reference;
  final String type;
  final String typeLabel;
  final TicketStatus status;
  final List<TicketEvent> events;
  final List<ResolutionOption> resolutionOptions;
  final String? tripId;

  TicketEvent? eventOf(TicketEventType type) => events.where((event) => event.type == type).firstOrNull;

  TicketEvent? get latestEvent => events.lastOrNull;
}

class TicketSummary {
  const TicketSummary({
    required this.id,
    required this.reference,
    required this.typeLabel,
    required this.status,
    required this.createdAt,
  });

  factory TicketSummary.fromJson(Map<String, dynamic> json) => TicketSummary(
    id: json['id'] as String,
    reference: json['reference'] as String,
    typeLabel: json['typeLabel'] as String,
    status: TicketStatus.fromCode(json['status']),
    createdAt: DateTime.parse('${json['createdAt']}').toLocal(),
  );

  final String id;
  final String reference;
  final String typeLabel;
  final TicketStatus status;
  final DateTime createdAt;
}

class TicketsPage {
  const TicketsPage({required this.items, required this.page, required this.hasMore});

  factory TicketsPage.fromJson(Map<String, dynamic> json) => TicketsPage(
    items: [for (final item in json['items'] as List) TicketSummary.fromJson(Map<String, dynamic>.from(item as Map))],
    page: (json['page'] as num).toInt(),
    hasMore: json['hasMore'] == true,
  );

  final List<TicketSummary> items;
  final int page;
  final bool hasMore;
}

sealed class TicketsState {
  const TicketsState();
}

final class TicketsLoading extends TicketsState {
  const TicketsLoading();
}

final class TicketsFailed extends TicketsState {
  const TicketsFailed();
}

final class TicketsLoaded extends TicketsState {
  const TicketsLoaded(
    this.items, {
    required this.page,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  final List<TicketSummary> items;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final bool loadMoreFailed;

  TicketsLoaded copyWith({bool? isLoadingMore, bool? loadMoreFailed}) => TicketsLoaded(
    items,
    page: page,
    hasMore: hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
  );
}

sealed class TicketState {
  const TicketState();
}

final class TicketLoading extends TicketState {
  const TicketLoading();
}

final class TicketFailed extends TicketState {
  const TicketFailed(this.problem);

  final SupportProblem problem;
}

final class TicketLoaded extends TicketState {
  const TicketLoaded(this.ticket, {this.isChoosing = false, this.problem});

  final SupportTicket ticket;
  final bool isChoosing;
  final SupportProblem? problem;
}
