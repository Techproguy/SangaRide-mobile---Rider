import 'package:sanga_ride/model/support/support_problem.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

enum ChatStatus {
  queued('queued'),
  active('active'),
  ended('ended');

  const ChatStatus(this.code);

  final String code;

  static ChatStatus fromCode(Object? code) => codedEnum(values, (status) => status.code, code, orElse: queued);
}

enum ChatDelivery {
  sending('sending'),
  sent('sent'),
  read('read'),
  failed('failed');

  const ChatDelivery(this.code);

  final String code;
}

enum ChatRole {
  rider('rider'),
  agent('agent'),
  system('system');

  const ChatRole(this.code);

  final String code;

  static ChatRole fromCode(Object? code) => codedEnum(values, (role) => role.code, code, orElse: system);
}

class ChatAgent {
  const ChatAgent({required this.name, required this.photoUrl});

  static ChatAgent? tryFromReader(JsonReader? reader) {
    final name = reader?.strOrNull('name');
    if (reader == null || name == null) return null;
    return ChatAgent(name: name, photoUrl: reader.strOrNull('photoUrl'));
  }

  final String name;
  final String? photoUrl;
}

class SupportChat {
  const SupportChat({required this.id, required this.status, required this.agent, required this.queuePosition});

  factory SupportChat.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return SupportChat(
      id: reader.str('id'),
      status: ChatStatus.fromCode(reader.strOrNull('status')),
      agent: ChatAgent.tryFromReader(reader.objectOrNull('agent')),
      queuePosition: reader.intOr('queuePosition', 0),
    );
  }

  final String id;
  final ChatStatus status;
  final ChatAgent? agent;
  final int queuePosition;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.clientId,
    required this.text,
    required this.role,
    required this.sentAt,
    required this.delivery,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return ChatMessage(
      id: reader.str('id'),
      clientId: reader.strOrNull('clientId'),
      text: reader.strOr('text', ''),
      role: ChatRole.fromCode(reader.strOrNull('senderRole')),
      sentAt: reader.timeOrNull('createdAt')?.toLocal() ?? DateTime.now(),
      delivery: reader.strOrNull('status') == ChatDelivery.read.code ? ChatDelivery.read : ChatDelivery.sent,
    );
  }

  factory ChatMessage.pending({required String clientId, required String text}) => ChatMessage(
    id: clientId,
    clientId: clientId,
    text: text,
    role: ChatRole.rider,
    sentAt: DateTime.now(),
    delivery: ChatDelivery.sending,
  );

  final String id;
  final String? clientId;
  final String text;
  final ChatRole role;
  final DateTime sentAt;
  final ChatDelivery delivery;

  bool get isMine => role == ChatRole.rider;

  ChatMessage withDelivery(ChatDelivery next) =>
      ChatMessage(id: id, clientId: clientId, text: text, role: role, sentAt: sentAt, delivery: next);
}

class ChatUpdate {
  const ChatUpdate({required this.chat, required this.messages, this.cursor});

  factory ChatUpdate.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    final raw = reader.raw['messages'];
    return ChatUpdate(
      chat: SupportChat.fromJson(reader.object('chat').raw),
      messages: reader.listOf('messages', (item) => ChatMessage.fromJson(item.raw)),
      cursor: raw is List && raw.isNotEmpty ? JsonReader.of(raw.last).strOrNull('id') : null,
    );
  }

  final SupportChat chat;
  final List<ChatMessage> messages;
  final String? cursor;
}

sealed class ChatState {
  const ChatState();
}

final class ChatConnecting extends ChatState {
  const ChatConnecting();
}

final class ChatUnavailable extends ChatState {
  const ChatUnavailable(this.problem);

  final SupportProblem problem;
}

final class ChatLive extends ChatState {
  const ChatLive(this.chat, this.messages, {this.isEnding = false, this.problem});

  final SupportChat chat;
  final List<ChatMessage> messages;
  final bool isEnding;
  final SupportProblem? problem;

  ChatLive copyWith({
    SupportChat? chat,
    List<ChatMessage>? messages,
    bool? isEnding,
    SupportProblem? problem,
    bool clearProblem = false,
  }) => ChatLive(
    chat ?? this.chat,
    messages ?? this.messages,
    isEnding: isEnding ?? this.isEnding,
    problem: clearProblem ? null : problem ?? this.problem,
  );
}
