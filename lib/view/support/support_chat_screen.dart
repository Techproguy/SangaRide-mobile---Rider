import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/support/support_chat_controller.dart';
import 'package:sanga_ride/controller/rider/support/support_help_controller.dart';
import 'package:sanga_ride/core/router/support_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart' show LinkState;
import 'package:sanga_ride/view/support/support_copy.dart';
import 'package:sanga_ride/view/support/widgets/support_message_list.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key, this.ticketId, this.tripId});

  final String? ticketId;
  final String? tripId;

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final _controller = Get.find<SupportChatController>();
  final _help = Get.find<SupportHelpController>();
  final _composer = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_help.loadHome());
      unawaited(_controller.open(ticketId: widget.ticketId, tripId: widget.tripId));
    });
  }

  @override
  void dispose() {
    _controller.close();
    _composer.dispose();
    super.dispose();
  }

  SupportContact? get _contact => switch (_help.home) {
    SupportHomeLoaded(:final home) => home.contact,
    _ => null,
  };

  Future<void> _call() async {
    final phone = _contact?.phone;
    if (phone == null) return;
    final isLaunched = await launchUrl(Uri(scheme: 'tel', path: phone));
    if (!isLaunched) {
      SangaToast.show('We couldn’t open your phone app. You can reach us on $phone.', tone: SangaToastTone.error);
    }
  }

  Future<void> _end() async {
    final isConfirmed = await showSangaPromptSheet(
      context: context,
      icon: Icons.chat_bubble_outline_rounded,
      title: 'End this chat?',
      message: 'You can always start a new one if you need us again.',
      actionLabel: 'End chat',
      dismissLabel: 'Keep chatting',
    );
    if (!isConfirmed || !mounted) return;
    final isEnded = await _controller.end();
    if (!isEnded && mounted) SangaToast.show(SupportProblem.connection.message, tone: SangaToastTone.error);
  }

  String _title(ChatState state) => switch (state) {
    ChatLive(:final chat) when chat.agent != null => chat.agent!.name,
    _ => 'Customer support',
  };

  Widget _header(ChatState state) {
    final live = state is ChatLive && state.chat.status != ChatStatus.ended ? state : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(SangaSpacing.gutter, SangaSpacing.md, SangaSpacing.xs, 0),
      child: Row(
        children: [
          const SangaCircleButton.back(),
          Expanded(
            child: Text(
              _title(state),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SangaTextStyles.toolbarTitle,
            ),
          ),
          if (_contact != null)
            IconButton(
              tooltip: 'Call support',
              onPressed: _call,
              icon: const Icon(Icons.phone_rounded, color: SangaColors.primary),
            ),
          if (live != null)
            IconButton(
              tooltip: 'End chat',
              onPressed: live.isEnding ? null : _end,
              icon: const Icon(Icons.more_vert_rounded, color: SangaColors.textPrimary),
            )
          else
            const SizedBox(width: SangaSpacing.xs),
        ],
      ),
    );
  }

  Widget _banner(ChatLive live) {
    final chat = live.chat;
    final text = switch (chat.status) {
      ChatStatus.queued => SupportCopy.waitLine(chat, _contact),
      ChatStatus.ended => null,
      ChatStatus.active => null,
    };
    final problem = live.problem;
    final link = _controller.linkRx.value;
    if (link != LinkState.live && chat.status != ChatStatus.ended) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(SangaSpacing.gutter, SangaSpacing.sm, SangaSpacing.gutter, 0),
        child: SangaNotice(
          tone: SangaTone.warning,
          message: link == LinkState.lost ? SupportCopy.chatLost : SupportCopy.chatReconnecting,
        ),
      );
    }
    if (text == null && problem == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(SangaSpacing.gutter, SangaSpacing.sm, SangaSpacing.gutter, 0),
      child: SangaNotice(
        tone: problem == null ? SangaTone.neutral : SangaTone.danger,
        icon: problem == null ? Icons.hourglass_top_rounded : Icons.error_outline_rounded,
        message: problem?.message ?? text!,
      ),
    );
  }

  Widget _empty(ChatLive live) {
    final isQueued = live.chat.status == ChatStatus.queued;
    return Center(
      child: SangaEmptyMessage(
        icon: Icons.chat_bubble_outline_rounded,
        title: isQueued ? 'Hang tight' : 'Say hi',
        message: isQueued ? 'An agent will join you shortly.' : 'Tell us what’s going on.',
      ),
    );
  }

  Widget _ended() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(SangaSpacing.gutter, SangaSpacing.sm, SangaSpacing.gutter, SangaSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: SangaSpacing.xs,
          children: [
            Text('This chat has ended.', textAlign: TextAlign.center, style: SangaTextStyles.caption),
            SangaButton.outline(
              label: 'Back to support',
              size: SangaButtonSize.compact,
              onPressed: () => context.go(SupportRoutes.home),
            ),
          ],
        ),
      ),
    );
  }

  Widget _live(ChatLive live) {
    final isEnded = live.chat.status == ChatStatus.ended;
    return Column(
      children: [
        _banner(live),
        Expanded(
          child: live.messages.isEmpty
              ? _empty(live)
              : SupportMessageList(messages: live.messages, onRetry: _controller.retry),
        ),
        if (isEnded) _ended() else SangaChatComposer(controller: _composer, onSend: _controller.send),
      ],
    );
  }

  Widget _unavailable(SupportProblem problem) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SangaSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: SangaSpacing.md,
          children: [
            SangaFailureMessage(
              title: 'Chat isn’t available',
              message: problem.message,
              onRetry: () => _controller.open(ticketId: widget.ticketId, tripId: widget.tripId),
            ),
            SangaButton.outline(
              label: 'Report an issue',
              size: SangaButtonSize.compact,
              onPressed: () => context.push(SupportRoutes.reportOf()),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: SangaSystemUi.onLight,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Obx(() {
            final state = _controller.state;
            return Column(
              children: [
                _header(state),
                Expanded(
                  child: switch (state) {
                    ChatConnecting() => const Center(child: SangaActivityIndicator(size: 32)),
                    ChatUnavailable(:final problem) => _unavailable(problem),
                    final ChatLive live => _live(live),
                  },
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
