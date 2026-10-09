import 'package:sanga_ride/model/support/support_problem.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

enum IssueContext {
  trip('trip'),
  delivery('delivery'),
  account('account'),
  payment('payment');

  const IssueContext(this.code);

  final String code;

  static IssueContext fromCode(String? code) => enumByCode(values, code, (value) => value.code, IssueContext.trip);
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

  static IssueIcon fromCode(Object? code) => enumByCode(values, '$code', (icon) => icon.code, IssueIcon.other);
}

class IssueType {
  const IssueType({required this.id, required this.label, required this.hint, required this.icon});

  factory IssueType.fromReader(JsonReader reader) => IssueType(
    id: reader.str('id'),
    label: reader.str('label'),
    hint: reader.strOr('hint', ''),
    icon: IssueIcon.fromCode(reader.strOrNull('icon')),
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
  closed('closed'),
  unknown('unknown');

  const TicketStatus(this.code);

  final String code;

  bool get isOpen => this == reported || this == investigating || this == actionNeeded;

  bool get isWaiting => this == reported || this == investigating;

  static TicketStatus fromCode(Object? code) =>
      enumByCode(values, '$code', (status) => status.code, TicketStatus.unknown);
}

enum TicketEventType {
  reported('reported'),
  investigating('investigating'),
  actionRequested('action_requested'),
  actionTaken('action_taken'),
  resolved('resolved');

  const TicketEventType(this.code);

  final String code;

  static TicketEventType? fromCode(Object? code) {
    for (final type in values) {
      if (type.code == '$code') return type;
    }
    return null;
  }
}

class TicketEvent {
  const TicketEvent({required this.type, required this.at, required this.detail});

  final TicketEventType type;
  final DateTime? at;
  final String detail;

  static TicketEvent? tryFromReader(JsonReader reader) {
    final type = TicketEventType.fromCode(reader.strOrNull('type'));
    if (type == null) return null;
    return TicketEvent(type: type, at: reader.timeOrNull('at')?.toLocal(), detail: reader.strOr('detail', ''));
  }
}

class ResolutionOption {
  const ResolutionOption({required this.id, required this.label, required this.hint});

  factory ResolutionOption.fromReader(JsonReader reader) =>
      ResolutionOption(id: reader.str('id'), label: reader.str('label'), hint: reader.strOr('hint', ''));

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

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return SupportTicket(
      id: reader.str('id'),
      reference: reader.strOr('reference', ''),
      type: reader.strOr('type', ''),
      typeLabel: reader.strOr('typeLabel', ''),
      status: TicketStatus.fromCode(reader.strOrNull('status')),
      events: [for (final event in reader.listOf('events', TicketEvent.tryFromReader)) ?event],
      resolutionOptions: reader.listOf('resolutionOptions', ResolutionOption.fromReader),
      tripId: reader.strOrNull('tripId'),
    );
  }

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

  factory TicketSummary.fromReader(JsonReader reader) => TicketSummary(
    id: reader.str('id'),
    reference: reader.strOr('reference', ''),
    typeLabel: reader.strOr('typeLabel', ''),
    status: TicketStatus.fromCode(reader.strOrNull('status')),
    createdAt: reader.time('createdAt').toLocal(),
  );

  final String id;
  final String reference;
  final String typeLabel;
  final TicketStatus status;
  final DateTime createdAt;
}

class TicketsPage {
  const TicketsPage({required this.items, required this.page, required this.hasMore});

  factory TicketsPage.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return TicketsPage(
      items: reader.listOf('items', TicketSummary.fromReader),
      page: reader.intOr('page', 1),
      hasMore: reader.boolOr('hasMore', false),
    );
  }

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
  const TicketsFailed(this.problem);

  final SupportProblem problem;
}

final class TicketsLoaded extends TicketsState {
  const TicketsLoaded(
    this.items, {
    required this.page,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
    this.isStale = false,
  });

  final List<TicketSummary> items;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final bool loadMoreFailed;
  final bool isStale;

  TicketsLoaded copyWith({bool? isLoadingMore, bool? loadMoreFailed, bool? isStale}) => TicketsLoaded(
    items,
    page: page,
    hasMore: hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    isStale: isStale ?? this.isStale,
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
