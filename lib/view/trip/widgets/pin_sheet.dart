import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class PinSheet extends StatefulWidget {
  const PinSheet({super.key, required this.trip, required this.isRefreshing, required this.onRefresh, this.onExpired});

  final Trip trip;
  final bool isRefreshing;
  final VoidCallback onRefresh;
  final VoidCallback? onExpired;

  @override
  State<PinSheet> createState() => _PinSheetState();
}

class _PinSheetState extends State<PinSheet> {
  bool _isHidden = true;

  @override
  Widget build(BuildContext context) {
    final code = widget.trip.pin ?? '';
    final expiresAt = widget.trip.pinExpiresAt;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: _LockTile()),
          const SizedBox(height: SangaSpacing.md),
          Text('Your trip PIN', textAlign: TextAlign.center, style: SangaTextStyles.statusTitle),
          const SizedBox(height: SangaSpacing.xs),
          Text(
            widget.trip.isDelivery
                ? 'Share these 4 digits with your driver to hand over the package'
                : 'Share these 4 digits with your driver to begin',
            textAlign: TextAlign.center,
            style: SangaTextStyles.statusMessage,
          ),
          const SizedBox(height: SangaSpacing.lg),
          if (expiresAt == null)
            const SizedBox.shrink()
          else
            SangaCountdown(
              endsAt: expiresAt,
              onFinished: widget.onExpired,
              builder: (context, remaining) => _body(code, remaining),
            ),
        ],
      ),
    );
  }

  Widget _body(String code, Duration remaining) {
    final isExpired = remaining == Duration.zero;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SangaPinDisplay(code: code, isHidden: _isHidden && !isExpired, isExpired: isExpired),
        ),
        const SizedBox(height: SangaSpacing.md),
        Center(child: _ExpiryLine(remaining: remaining)),
        const SizedBox(height: SangaSpacing.md),
        if (!isExpired) ...[
          const SangaNotice(message: 'Only share your PIN with the driver you just checked'),
          const SizedBox(height: SangaSpacing.lg),
          SangaButton.muted(
            label: _isHidden ? 'Show PIN' : 'Hide PIN',
            onPressed: () => setState(() => _isHidden = !_isHidden),
          ),
        ] else
          SangaButton.primary(label: 'Get a new PIN', isLoading: widget.isRefreshing, onPressed: widget.onRefresh),
      ],
    );
  }
}

class _LockTile extends StatelessWidget {
  const _LockTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: SangaColors.primaryTint,
        borderRadius: SangaRadii.field,
        border: Border.all(color: SangaColors.primary, width: 0.8),
      ),
      child: const Icon(Icons.lock_rounded, size: 30, color: SangaColors.primary),
    );
  }
}

class _ExpiryLine extends StatelessWidget {
  const _ExpiryLine({required this.remaining});

  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final isExpired = remaining == Duration.zero;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: SangaSpacing.xs,
      children: [
        const Icon(Icons.schedule_rounded, size: 18, color: SangaColors.textPrimary),
        if (isExpired)
          Text('PIN expired', style: SangaTextStyles.label.copyWith(color: SangaColors.dangerStrong))
        else
          Text.rich(
            TextSpan(
              style: SangaTextStyles.label,
              children: [
                const TextSpan(text: 'Expires in '),
                TextSpan(
                  text: remaining.minutesAndSeconds,
                  style: const TextStyle(color: SangaColors.dangerStrong),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
