import 'package:sanga_ride/model/support/support_problem.dart';

enum ChatStatus {
  queued('queued'),
  active('active'),
  ended('ended');

  const ChatStatus(this.code);

  final String code;

  static ChatStatus fromCode(Object? code) => values.where((status) => status.code == '$code').firstOrNull ?? queued;
}

enum ChatDelivery { sending, sent, read, failed }

enum ChatRole {
  rider('rider'),
  agent('agent'),
  system('system');

  const ChatRole(this.code);

  final String code;

  static ChatRole fromCode(Object? code) => values.where((role) => role.code == '$code').firstOrNull ?? system;
}

class ChatAgent {
  const ChatAgent({required this.name, required this.photoUrl});

  factory ChatAgent.fromJson(Map<String, dynamic> json) =>
      ChatAgent(name: json['name'] as String, photoUrl: json['photoUrl'] as String?);

  final String name;
  final String? photoUrl;
}

class SupportChat {
  const SupportChat({required this.id, required this.status, required this.agent, required this.queuePosition});

  factory SupportChat.fromJson(Map<String, dynamic> json) => SupportChat(
    id: json['id'] as String,
    status: ChatStatus.fromCode(json['status']),
    agent: json['agent'] == null ? null : ChatAgent.fromJson(Map<String, dynamic>.from(json['agent'] as Map)),
    queuePosition: (json['queuePosition'] as num?)?.toInt() ?? 0,
  );

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

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    clientId: json['clientId'] as String?,
    text: json['text'] as String,
    role: ChatRole.fromCode(json['senderRole']),
    sentAt: DateTime.parse('${json['createdAt']}').toLocal(),
    delivery: json['status'] == 'read' ? ChatDelivery.read : ChatDelivery.sent,
  );

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
  const ChatUpdate({required this.chat, required this.messages});

  factory ChatUpdate.fromJson(Map<String, dynamic> json) => ChatUpdate(
    chat: SupportChat.fromJson(Map<String, dynamic>.from(json['chat'] as Map)),
    messages: [
      for (final message in json['messages'] as List) ChatMessage.fromJson(Map<String, dynamic>.from(message as Map)),
    ],
  );

  final SupportChat chat;
  final List<ChatMessage> messages;
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

  bool get hasSentMessage => messages.any((message) => message.isMine);

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
