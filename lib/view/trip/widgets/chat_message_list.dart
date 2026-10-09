import 'package:flutter/material.dart';
import 'package:sanga_ride/core/format/clock_formats.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ChatMessageList extends StatelessWidget {
  const ChatMessageList({super.key, required this.messages, required this.onRetry});

  final List<TripMessage> messages;
  final ValueChanged<String> onRetry;

  static String dayLabel(DateTime day, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(day.year, day.month, day.day);
    final gap = today.difference(date).inDays;
    if (gap == 0) return 'Today';
    if (gap == 1) return 'Yesterday';
    return ClockFormats.dayMonth(date);
  }

  static SangaMessageState stateOf(TripMessageDelivery delivery) => switch (delivery) {
    TripMessageDelivery.sending => SangaMessageState.sending,
    TripMessageDelivery.sent => SangaMessageState.sent,
    TripMessageDelivery.failed => SangaMessageState.failed,
  };

  bool _startsNewDay(int index) {
    if (index == 0) return true;
    final before = messages[index - 1].sentAt;
    final current = messages[index].sentAt;
    return before.year != current.year || before.month != current.month || before.day != current.day;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
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
            if (_startsNewDay(index)) SangaDateChip(label: dayLabel(message.sentAt, now)),
            Padding(
              padding: const EdgeInsets.only(bottom: SangaSpacing.xs),
              child: SangaChatBubble(
                text: message.body,
                time: ClockFormats.time(message.sentAt),
                isMine: message.isMine,
                state: stateOf(message.delivery),
                onRetry: message.clientId == null ? null : () => onRetry(message.clientId!),
              ),
            ),
          ],
        );
      },
    );
  }
}
