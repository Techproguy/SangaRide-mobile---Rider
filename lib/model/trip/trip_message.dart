import 'package:sanga_ride/model/support/support_chat.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

enum TripMessageDelivery { sending, sent, failed }

class TripMessage {
  const TripMessage({
    required this.id,
    required this.clientId,
    required this.body,
    required this.sentAt,
    required this.isMine,
    this.delivery = TripMessageDelivery.sent,
  });

  factory TripMessage.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader.of(json);
    final sender = reader.strOrNull('senderRole') ?? reader.strOrNull('senderType') ?? reader.strOrNull('sender');
    return TripMessage(
      id: reader.str('id'),
      clientId: reader.strOrNull('clientId'),
      body: reader.strOr('body', reader.strOr('message', '')),
      sentAt: (reader.timeOrNull('createdAt') ?? reader.timeOrNull('sentAt') ?? DateTime.now()).toLocal(),
      isMine: sender == ChatRole.rider.code,
    );
  }

  factory TripMessage.fromResponse(Map<String, dynamic> data) =>
      TripMessage.fromJson(JsonReader.of(data['message']).raw.isEmpty ? data : JsonReader.of(data['message']).raw);

  static List<TripMessage> listFrom(Object? body) {
    final data = body is Map ? body['data'] : null;
    final items = data is List ? data : (data is Map ? data['messages'] : null);
    return JsonReader({'items': items}).listOf('items', (item) => TripMessage.fromJson(item.raw));
  }

  factory TripMessage.pending({required String clientId, required String body}) => TripMessage(
    id: clientId,
    clientId: clientId,
    body: body,
    sentAt: DateTime.now(),
    isMine: true,
    delivery: TripMessageDelivery.sending,
  );

  final String id;
  final String? clientId;
  final String body;
  final DateTime sentAt;
  final bool isMine;
  final TripMessageDelivery delivery;

  TripMessage withDelivery(TripMessageDelivery delivery) =>
      TripMessage(id: id, clientId: clientId, body: body, sentAt: sentAt, isMine: isMine, delivery: delivery);
}

abstract final class TripQuickReplies {
  static const List<String> rider = ['I’m on my way out', 'I’m at the pickup', 'Please call me when you arrive'];
}
