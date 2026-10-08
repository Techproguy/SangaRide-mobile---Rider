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

  factory TripMessage.fromJson(Map<String, dynamic> json) => TripMessage(
    id: json['id'] as String,
    clientId: json['clientId'] as String?,
    body: json['body'] as String,
    sentAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    isMine: json['senderRole'] == 'rider',
  );

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
