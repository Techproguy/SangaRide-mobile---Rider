import 'package:sanga_ride/model/support/support_problem.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

enum IssueContext {
  trip('trip', 'ride'),
  delivery('delivery', 'delivery'),
  account('account', null),
  payment('payment', null);

  const IssueContext(this.code, this.appliesToCode);

  final String code;
  final String? appliesToCode;

  static IssueContext fromCode(String? code) => codedEnum(values, (value) => value.code, code, orElse: trip);
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

  static IssueIcon fromCode(Object? code) => codedEnum(values, (icon) => icon.code, code, orElse: other);

  static IssueIcon ofCategory(String category) => switch (category) {
    'driver_not_moving' => notMoving,
    'cannot_reach_driver' || 'cannot_reach_passenger' || 'recipient_unavailable' => unreachable,
    'wrong_location' => location,
    'extra_payment_requested' => payment,
    'unable_to_complete_delivery' => incomplete,
    'lost_item' => package,
    'safety_concern' => safety,
    _ => other,
  };
}

class IssueType {
  const IssueType({
    required this.id,
    required this.label,
    required this.hint,
    required this.icon,
    required this.appliesTo,
    required this.requiresDescription,
  });

  static const String otherId = 'other';

  factory IssueType.fromReader(JsonReader reader) {
    final id = reader.str('code');
    return IssueType(
      id: id,
      label: reader.str('title'),
      hint: reader.strOr('subtitle', ''),
      icon: IssueIcon.ofCategory(id),
      appliesTo: reader.strings('appliesTo'),
      requiresDescription: reader.boolOr('requiresDescription', false),
    );
  }

  final String id;
  final String label;
  final String hint;
  final IssueIcon icon;
  final List<String> appliesTo;
  final bool requiresDescription;

  bool isOffered(IssueContext context) {
    final scope = context.appliesToCode;
    return scope == null ? id == otherId : appliesTo.isEmpty || appliesTo.contains(scope);
  }
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

  static TicketStatus fromCode(Object? code) => codedEnum(values, (status) => status.code, code, orElse: unknown);
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

class TicketStep {
  const TicketStep({required this.title, required this.detail, required this.at});

  final String title;
  final String detail;
  final DateTime? at;

  bool get isDone => at != null;

  static TicketStep? tryFromReader(JsonReader reader) {
    final title = reader.strOrNull('title');
    if (title == null) return null;
    return TicketStep(title: title, detail: reader.strOr('description', ''), at: reader.timeOrNull('at')?.toLocal());
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
    required this.steps,
    required this.resolutionOptions,
    required this.tripId,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    final id = reader.strOr('id', '');
    return SupportTicket(
      id: id,
      reference: reader.strOrNull('reference') ?? id,
      type: reader.strOrNull('type') ?? reader.strOr('category', ''),
      typeLabel: reader.strOrNull('typeLabel') ?? reader.strOr('categoryTitle', ''),
      status: TicketStatus.fromCode(reader.strOrNull('status')),
      events: [for (final event in reader.listOf('events', TicketEvent.tryFromReader)) ?event],
      steps: [for (final step in reader.listOf('timeline', TicketStep.tryFromReader)) ?step],
      resolutionOptions: reader.listOf('resolutionOptions', ResolutionOption.fromReader),
      tripId: reader.strOrNull('tripId') ?? reader.strOrNull('rideId'),
    );
  }

  final String id;
  final String reference;
  final String type;
  final String typeLabel;
  final TicketStatus status;
  final List<TicketEvent> events;
  final List<TicketStep> steps;
  final List<ResolutionOption> resolutionOptions;
  final String? tripId;

  TicketEvent? eventOf(TicketEventType type) => events.where((event) => event.type == type).firstOrNull;
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
    typeLabel: reader.strOrNull('typeLabel') ?? reader.strOr('categoryTitle', ''),
    status: TicketStatus.fromCode(reader.strOrNull('status')),
    createdAt: (reader.timeOrNull('createdAt') ?? reader.time('reportedAt')).toLocal(),
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
      items: reader.listOf('issues', TicketSummary.fromReader),
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
