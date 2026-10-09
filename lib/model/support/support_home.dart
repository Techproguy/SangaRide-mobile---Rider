import 'package:sanga_ride/model/support/support_problem.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

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

  static SupportTopicIcon fromCode(Object? code) =>
      enumByCode(values, '$code', (icon) => icon.code, SupportTopicIcon.help);
}

class SupportTopic {
  const SupportTopic({required this.id, required this.label, required this.icon});

  factory SupportTopic.fromReader(JsonReader reader) => SupportTopic(
    id: reader.str('id'),
    label: reader.str('label'),
    icon: SupportTopicIcon.fromCode(reader.strOrNull('icon')),
  );

  final String id;
  final String label;
  final SupportTopicIcon icon;
}

class ArticleSummary {
  const ArticleSummary({required this.id, required this.title, required this.summary});

  factory ArticleSummary.fromReader(JsonReader reader) =>
      ArticleSummary(id: reader.str('id'), title: reader.str('title'), summary: reader.strOr('summary', ''));

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

  static SupportContact? tryFromReader(JsonReader? reader) {
    final phone = reader?.strOrNull('phone');
    if (reader == null || phone == null) return null;
    return SupportContact(
      phone: phone,
      hours: reader.strOr('hours', ''),
      chatAvailable: reader.boolOr('chatAvailable', false),
      chatWaitMinutes: reader.intOr('chatWaitMinutes', 0),
    );
  }

  final String phone;
  final String hours;
  final bool chatAvailable;
  final int chatWaitMinutes;
}

class SupportHome {
  const SupportHome({required this.topics, required this.popular, required this.contact});

  factory SupportHome.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return SupportHome(
      topics: reader.listOf('topics', SupportTopic.fromReader),
      popular: reader.listOf('popular', ArticleSummary.fromReader),
      contact: SupportContact.tryFromReader(reader.objectOrNull('contact')),
    );
  }

  final List<SupportTopic> topics;
  final List<ArticleSummary> popular;
  final SupportContact? contact;

  SupportTopic? topicById(String id) => topics.where((topic) => topic.id == id).firstOrNull;
}

sealed class SupportHomeState {
  const SupportHomeState();
}

final class SupportHomeLoading extends SupportHomeState {
  const SupportHomeLoading();
}

final class SupportHomeFailed extends SupportHomeState {
  const SupportHomeFailed(this.problem);

  final SupportProblem problem;
}

final class SupportHomeLoaded extends SupportHomeState {
  const SupportHomeLoaded(this.home);

  final SupportHome home;
}
