import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

enum _SosPhase { activating, sending, active, failed }

class SosSheetView extends StatelessWidget {
  const SosSheetView({
    super.key,
    required this.state,
    required this.contactCount,
    required this.grace,
    required this.emergencyNumber,
    required this.onGraceComplete,
    required this.onCancel,
    required this.onRetry,
    required this.onCloseFailure,
    required this.onEnd,
    required this.onCallEmergency,
    required this.onOpenContacts,
  });

  final SosState state;
  final int contactCount;
  final Duration grace;
  final String emergencyNumber;
  final VoidCallback onGraceComplete;
  final VoidCallback onCancel;
  final VoidCallback onRetry;
  final VoidCallback onCloseFailure;
  final VoidCallback onEnd;
  final VoidCallback onCallEmergency;
  final VoidCallback onOpenContacts;

  _SosPhase get _phase => switch (state) {
    SosIdle() || SosActivating() => _SosPhase.activating,
    SosSending() => _SosPhase.sending,
    SosActive() || SosEnding() => _SosPhase.active,
    SosFailed() => _SosPhase.failed,
  };

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: SangaMotion.morph,
      curve: SangaMotion.springBlock,
      alignment: Alignment.bottomCenter,
      child: SangaHandoff(value: _phase, child: _content()),
    );
  }

  Widget _content() => switch (state) {
    SosIdle() => const SizedBox.shrink(),
    SosActivating(:final startedAt) => _activating(startedAt),
    SosSending() => _sending(),
    SosActive(:final sos) => _active(sos, isEnding: false),
    SosEnding(:final sos) => _active(sos, isEnding: true),
    SosFailed(:final problem) => _failed(problem),
  };

  Widget _activating(DateTime startedAt) {
    return SangaSosSheetContent(
      title: 'Activating SOS',
      message: contactCount > 0
          ? 'We’re alerting your emergency contacts and the Sanga safety team'
          : 'We’re alerting the Sanga safety team',
      body: SangaSosProgress(
        startedAt: startedAt,
        duration: grace,
        onComplete: onGraceComplete,
        semanticLabel: 'Activating SOS',
      ),
      action: SangaButton.muted(label: 'Cancel SOS', onPressed: onCancel),
    );
  }

  Widget _sending() {
    return const SangaSosSheetContent(
      title: 'Sending your SOS',
      message: 'Hang tight. We’re getting your alert out.',
      status: SangaActivityIndicator(size: 28),
    );
  }

  Widget _active(Sos sos, {required bool isEnding}) {
    return SangaSosSheetContent(
      title: 'SOS active',
      message: sos.hasNotifiedContacts
          ? 'Your emergency contacts and the Sanga safety team have been notified'
          : 'The Sanga safety team has been notified',
      status: SangaElapsedTimer(since: sos.startedAt, serverOffset: sos.serverOffset),
      body: _channels(sos),
      action: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: SangaSpacing.xs,
        children: [
          _CallEmergencyLink(number: emergencyNumber, onPressed: isEnding ? null : onCallEmergency),
          SangaButton.muted(label: 'End SOS', isLoading: isEnding, onPressed: onEnd),
        ],
      ),
    );
  }

  Widget _channels(Sos sos) {
    return Column(
      spacing: SangaSpacing.sm,
      children: [
        SangaSafetyChannelRow(
          icon: Icons.share_location_rounded,
          title: 'Live location sharing',
          subtitle: sos.liveLocation ? 'Sharing in real time' : 'We couldn’t get your location',
          tone: sos.liveLocation ? SangaSafetyTone.success : SangaSafetyTone.primary,
        ),
        SangaSafetyChannelRow(
          icon: Icons.person_rounded,
          title: 'Emergency contacts',
          subtitle: sos.hasNotifiedContacts
              ? '${sos.contactsNotified} ${sos.contactsNotified == 1 ? 'contact' : 'contacts'} notified'
              : 'No contacts to notify yet',
          onTap: onOpenContacts,
        ),
        SangaSafetyChannelRow(
          icon: Icons.shield_rounded,
          title: 'Sanga safety team',
          subtitle: switch (sos.safetyTeam) {
            SafetyTeamStatus.alerted => 'Alerted',
            SafetyTeamStatus.monitoring => 'Alerted and monitoring',
          },
        ),
      ],
    );
  }

  Widget _failed(SafetyProblem problem) {
    return SangaSosSheetContent(
      title: 'We couldn’t send your SOS',
      message: problem.message,
      action: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: SangaSpacing.xs,
        children: [
          SangaButton.primary(label: 'Try again', onPressed: onRetry),
          _CallEmergencyLink(number: emergencyNumber, onPressed: onCallEmergency),
          SangaButton.muted(label: 'Close', onPressed: onCloseFailure),
        ],
      ),
    );
  }
}

class _CallEmergencyLink extends StatelessWidget {
  const _CallEmergencyLink({required this.number, required this.onPressed});

  final String number;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.phone_rounded, size: 18, color: SangaColors.primary),
      label: Text('Call $number', style: SangaTextStyles.label.copyWith(color: SangaColors.primary)),
    );
  }
}
