import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/trip/trip_controller.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/trip/widgets/call_driver.dart';
import 'package:sanga_ride/view/trip/widgets/chat_message_list.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TripChatScreen extends StatefulWidget {
  const TripChatScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<TripChatScreen> createState() => _TripChatScreenState();
}

class _TripChatScreenState extends State<TripChatScreen> {
  final _trip = Get.find<TripController>();
  final _composer = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _trip.open(widget.tripId);
      if (mounted) await _trip.openChat();
    });
  }

  @override
  void dispose() {
    _trip.closeChat();
    _trip.close(onlyTripId: widget.tripId);
    _composer.dispose();
    super.dispose();
  }

  Widget _body(String firstName) {
    final status = _trip.chatStatus.value;
    final messages = _trip.messages;
    if (messages.isNotEmpty) return ChatMessageList(messages: [...messages], onRetry: _trip.retryMessage);
    return switch (status) {
      TripChatStatus.loading => const Padding(padding: EdgeInsets.all(SangaSpacing.gutter), child: SangaSkeleton.heights([48, 48, 48])),
      TripChatStatus.failed => Center(
        child: SangaFailureMessage(
          title: 'We couldn’t load your chat',
          message: 'Check your connection and give it another go.',
          onRetry: _trip.reloadChat,
        ),
      ),
      TripChatStatus.ready => Center(
        child: SangaEmptyMessage(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'No messages yet',
          message: 'Say hi to $firstName.',
        ),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: SangaSystemUi.onLight,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Obx(() {
                final driver = _trip.trip?.driver;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(SangaSpacing.gutter, SangaSpacing.md, SangaSpacing.xs, 0),
                  child: Row(
                    children: [
                      const SangaCircleButton.back(),
                      Expanded(
                        child: Text(
                          driver?.name ?? '',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SangaTextStyles.toolbarTitle,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Call',
                        onPressed: driver == null ? null : () => callDriver(context, firstName: driver.firstName),
                        icon: const Icon(Icons.phone_rounded, color: SangaColors.primary),
                      ),
                    ],
                  ),
                );
              }),
              Obx(
                () => _trip.isChatStale && _trip.messages.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.gutter),
                        child: SangaStaleNotice(
                          message: 'Can’t refresh right now. Showing what we have.',
                          onRetry: _trip.reloadChat,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              Expanded(child: Obx(() => _body(_trip.trip?.driver.firstName ?? 'your driver'))),
              Padding(
                padding: const EdgeInsets.only(bottom: SangaSpacing.xs),
                child: SangaQuickReplies(replies: TripQuickReplies.rider, onSelected: _trip.sendMessage),
              ),
              SangaChatComposer(controller: _composer, onSend: _trip.sendMessage),
            ],
          ),
        ),
      ),
    );
  }
}
