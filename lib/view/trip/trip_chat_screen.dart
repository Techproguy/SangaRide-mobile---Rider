import 'dart:async';

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
    unawaited(_trip.openChat());
  }

  @override
  void dispose() {
    _trip.closeChat();
    _composer.dispose();
    super.dispose();
  }

  Widget _body(String firstName) {
    final status = _trip.chatStatus.value;
    final messages = _trip.messages;
    if (messages.isNotEmpty) return ChatMessageList(messages: [...messages], onRetry: _trip.retryMessage);
    return switch (status) {
      TripChatStatus.loading => const Center(child: SangaActivityIndicator(size: 40)),
      TripChatStatus.failed => Center(
        child: Padding(
          padding: const EdgeInsets.all(SangaSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: SangaSpacing.md,
            children: [
              Text('We couldn’t load your chat', style: SangaTextStyles.statusTitle, textAlign: TextAlign.center),
              Text('Check your connection and give it another go.', style: SangaTextStyles.statusMessage),
              SangaButton.primary(label: 'Try again', size: SangaButtonSize.compact, onPressed: _trip.reloadChat),
            ],
          ),
        ),
      ),
      TripChatStatus.ready => Center(
        child: Padding(
          padding: const EdgeInsets.all(SangaSpacing.xl),
          child: Text(
            'No messages yet. Say hi to $firstName.',
            textAlign: TextAlign.center,
            style: SangaTextStyles.statusMessage,
          ),
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
