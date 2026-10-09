import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class SupportMessageList extends StatelessWidget {
  const SupportMessageList({super.key, required this.messages, required this.onRetry});

  static final DateFormat _clock = DateFormat('h:mm a');

  final List<ChatMessage> messages;
  final ValueChanged<String> onRetry;

  static SangaMessageState stateOf(ChatDelivery delivery) => switch (delivery) {
    ChatDelivery.sending => SangaMessageState.sending,
    ChatDelivery.sent => SangaMessageState.sent,
    ChatDelivery.read => SangaMessageState.read,
    ChatDelivery.failed => SangaMessageState.failed,
  };

  bool _startsNewDay(int index) {
    if (index == 0) return true;
    return !DateUtils.isSameDay(messages[index - 1].sentAt, messages[index].sentAt);
  }

  Widget _bubble(ChatMessage message) {
    if (message.role == ChatRole.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: SangaSpacing.xs),
        child: Text(message.text, textAlign: TextAlign.center, style: SangaTextStyles.caption),
      );
    }
    final clientId = message.clientId;
    return Padding(
      padding: const EdgeInsets.only(bottom: SangaSpacing.xs),
      child: SangaChatBubble(
        text: message.text,
        time: _clock.format(message.sentAt),
        isMine: message.isMine,
        state: stateOf(message.delivery),
        onRetry: clientId == null ? null : () => onRetry(clientId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      reverse: true,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.gutter, vertical: SangaSpacing.md),
      itemCount: messages.length,
      itemBuilder: (context, reversedIndex) {
        final index = messages.length - 1 - reversedIndex;
        final message = messages[index];
        return Column(
          key: ValueKey(message.clientId ?? message.id),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_startsNewDay(index)) SangaDateChip(label: TimeFormat.daySeparator(message.sentAt)),
            _bubble(message),
          ],
        );
      },
    );
  }
}
