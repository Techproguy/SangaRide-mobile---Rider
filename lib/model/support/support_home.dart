enum SupportTopicIcon {
  flight('flight'),
  accident('accident'),
  lostItem('lost_item'),
  route('route'),
  cancel('cancel'),
  refund('refund'),
  payment('payment'),
  account('account'),
  safety('safety'),
  delivery('delivery'),
  help('help');

  const SupportTopicIcon(this.code);

  final String code;

  static SupportTopicIcon fromCode(Object? code) => values.where((icon) => icon.code == '$code').firstOrNull ?? help;
}

class SupportTopic {
  const SupportTopic({required this.id, required this.label, required this.icon});

  factory SupportTopic.fromJson(Map<String, dynamic> json) => SupportTopic(
    id: json['id'] as String,
    label: json['label'] as String,
    icon: SupportTopicIcon.fromCode(json['icon']),
  );

  final String id;
  final String label;
  final SupportTopicIcon icon;
}

class ArticleSummary {
  const ArticleSummary({required this.id, required this.title, required this.summary});

  factory ArticleSummary.fromJson(Map<String, dynamic> json) => ArticleSummary(
    id: json['id'] as String,
    title: json['title'] as String,
    summary: json['summary'] as String? ?? '',
  );

  final String id;
  final String title;
  final String summary;
}

class SupportContact {
  const SupportContact({
    required this.phone,
    required this.hours,
    required this.chatAvailable,
    required this.chatWaitMinutes,
  });

  factory SupportContact.fromJson(Map<String, dynamic> json) => SupportContact(
    phone: json['phone'] as String,
    hours: json['hours'] as String,
    chatAvailable: json['chatAvailable'] == true,
    chatWaitMinutes: (json['chatWaitMinutes'] as num?)?.toInt() ?? 0,
  );

  final String phone;
  final String hours;
  final bool chatAvailable;
  final int chatWaitMinutes;
}

class SupportHome {
  const SupportHome({required this.topics, required this.popular, required this.contact});

  factory SupportHome.fromJson(Map<String, dynamic> json) => SupportHome(
    topics: [
      for (final topic in json['topics'] as List) SupportTopic.fromJson(Map<String, dynamic>.from(topic as Map)),
    ],
    popular: [
      for (final article in json['popular'] as List) ArticleSummary.fromJson(Map<String, dynamic>.from(article as Map)),
    ],
    contact: SupportContact.fromJson(Map<String, dynamic>.from(json['contact'] as Map)),
  );

  final List<SupportTopic> topics;
  final List<ArticleSummary> popular;
  final SupportContact contact;

  SupportTopic? topicById(String id) => topics.where((topic) => topic.id == id).firstOrNull;
}

sealed class SupportHomeState {
  const SupportHomeState();
}

final class SupportHomeLoading extends SupportHomeState {
  const SupportHomeLoading();
}

final class SupportHomeFailed extends SupportHomeState {
  const SupportHomeFailed();
}

final class SupportHomeLoaded extends SupportHomeState {
  const SupportHomeLoaded(this.home);

  final SupportHome home;
}
