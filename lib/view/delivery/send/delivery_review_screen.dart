import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/delivery/send_delivery_controller.dart';
import 'package:sanga_ride/controller/rider/ride_match_controller.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/core/router/delivery_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/delivery/send/widgets/package_summary.dart';
import 'package:sanga_ride/view/delivery/send/widgets/review_edit_button.dart';
import 'package:sanga_ride/view/ride/matching/matching_flow.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class DeliveryReviewScreen extends StatefulWidget {
  const DeliveryReviewScreen({super.key});

  @override
  State<DeliveryReviewScreen> createState() => _DeliveryReviewScreenState();
}

class _DeliveryReviewScreenState extends State<DeliveryReviewScreen> {
  final _delivery = Get.find<SendDeliveryController>();
  final _ride = Get.find<RideRequestController>();
  final _match = Get.find<RideMatchController>();
  bool _isPreparing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _delivery.ensureQuote());
  }

  @override
  void dispose() {
    if (_match.isLive) scheduleMicrotask(_match.abandon);
    super.dispose();
  }

  Future<void> _edit(String path) async {
    await context.push(DeliveryRoutes.editing(path));
    if (mounted) unawaited(_delivery.ensureQuote());
  }

  Future<void> _submit() async {
    if (_isPreparing) return;
    setState(() => _isPreparing = true);
    final check = await _delivery.prepareSubmit();
    if (!mounted) return;
    setState(() => _isPreparing = false);
    switch (check) {
      case SubmitCheck.priceUnavailable:
        SangaToast.show(
          'We couldn’t refresh your price. Check your connection and go again.',
          tone: SangaToastTone.error,
        );
      case SubmitCheck.incomplete:
        SangaToast.show('Something’s missing. Check your details and go again.', tone: SangaToastTone.error);
      case SubmitCheck.priceRefreshed:
        await _announcePrice();
      case SubmitCheck.ready:
        await _findDriver();
    }
  }

  Future<void> _announcePrice() async {
    final tier = _delivery.selectedTier;
    final info = _delivery.selectedTierInfo;
    final keeps = await showSangaPromptSheet(
      context: context,
      icon: Icons.sell_outlined,
      title: 'Your price was refreshed',
      message: tier == null || info == null
          ? 'Have a look at the latest price, then go again.'
          : '${info.label} is now ${SangaMoney.naira(tier.fare)}. Happy with that?',
      actionLabel: 'Sounds good',
      dismissLabel: 'Change tier',
    );
    if (!keeps && mounted) await _edit(DeliveryRoutes.tier);
  }

  Future<void> _findDriver() async {
    await startMatching(context);
    if (!mounted) return;
    final state = _match.state;
    if (state is MatchFailed && state.code != null) await _handleRejection(state);
  }

  Future<void> _handleRejection(MatchFailed state) async {
    final failure = DeliveryFailure.fromCode(state.code);
    await showSangaStatusSheet(
      context: context,
      status: failure == DeliveryFailure.itemProhibited ? SangaStatus.failure : SangaStatus.caution,
      title: failure.title,
      message: failure.messageWith(state.data),
      actionLabel: failure.actionLabel,
    );
    if (!mounted) return;
    switch (failure) {
      case DeliveryFailure.quoteExpired:
        await _delivery.ensureQuote(force: true);
      case DeliveryFailure.itemProhibited:
        await _edit(DeliveryRoutes.item);
      case DeliveryFailure.invalidRecipientPhone:
        _delivery.flagRecipientPhone(failure);
        await _edit(DeliveryRoutes.recipient);
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => PopScope(
        canPop: !_match.isStarting && !_isPreparing,
        child: SangaPageLayout(
          title: 'Confirm delivery details',
          footer: SangaButton.primary(
            label: 'Find a driver',
            isLoading: _match.isStarting || _isPreparing,
            onPressed: _delivery.isReadyToSubmit && !_match.isLive ? _submit : null,
          ),
          children: [
            Column(spacing: SangaSpacing.md, children: [_routeCard(), _tierCard(), _packageCard(), _recipientCard()]),
          ],
        ),
      ),
    );
  }

  Widget _routeCard() => SangaSectionCard(
    title: 'Route',
    action: ReviewEditButton(label: 'Edit route', onPressed: () => _edit(DeliveryRoutes.route)),
    children: [
      Padding(
        padding: const EdgeInsets.all(SangaSpacing.md),
        child: SangaRouteSummary(
          pickup: _ride.pickup?.name ?? '',
          dropoff: _ride.dropoff?.name ?? '',
          stops: [for (final stop in _ride.stops) stop.name],
        ),
      ),
    ],
  );

  Widget _tierCard() {
    final state = _delivery.quoteState;
    final info = _delivery.selectedTierInfo;
    final tier = _delivery.selectedTier;
    if (state is QuoteFailed) {
      return SangaFailureMessage(
        title: 'We couldn’t get your price',
        message: state.failure.message,
        onRetry: () => _delivery.ensureQuote(force: true),
      );
    }
    if (state is QuoteIdle) {
      return SangaFailureMessage(
        title: 'We need a few more details',
        message: 'Pick your route and what you’re sending, then we’ll show your price.',
        icon: Icons.inventory_2_outlined,
        retryLabel: 'Check again',
        onRetry: () => _delivery.ensureQuote(force: true),
      );
    }
    if (info == null || tier == null || state is! QuoteReady) return const SangaSkeleton.block(height: 72);
    return SangaSectionCard(
      title: info.label,
      subtitle: '${info.blurb} · ${deliveryEtaLabel(tier.etaMinutes)}',
      action: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: SangaSpacing.sm,
        children: [
          Text(SangaMoney.naira(tier.fare), style: SangaTextStyles.cardValue),
          ReviewEditButton(label: 'Edit delivery tier', onPressed: () => _edit(DeliveryRoutes.tier)),
        ],
      ),
    );
  }

  Widget _packageCard() {
    final catalog = _delivery.catalog;
    final draft = _delivery.draft;
    final photo = _delivery.photo;
    final path = photo.localPath;
    final size = catalog?.sizeOf(draft.sizeId);
    final type = catalog?.packageTypeOf(draft.packageTypeId);
    final facts = _delivery.isDocuments ? (_delivery.kind?.label ?? '') : [?size?.label, ?type?.label].join(' · ');
    final value = draft.declaredValue;
    return SangaSectionCard(
      title: _delivery.isDocuments ? 'Document details' : 'Package details',
      action: ReviewEditButton(label: 'Edit package details', onPressed: () => _edit(DeliveryRoutes.item)),
      children: [
        PackageSummary(
          photo: path == null ? null : ResizeImage(FileImage(File(path)), width: 240),
          name: draft.name.trim(),
          description: draft.description.trim(),
          facts: facts,
          photoLabel: photo is PhotoUploaded ? 'Added' : 'Add one',
          valueLabel: value == null ? 'Add one' : SangaMoney.naira(value),
          onEditPhoto: () => _edit(DeliveryRoutes.photo),
          onEditValue: () => _edit(DeliveryRoutes.value),
        ),
      ],
    );
  }

  Widget _recipientCard() {
    final recipient = _delivery.draft.recipient;
    return SangaDetailList(
      title: 'Recipient',
      trailing: ReviewEditButton(label: 'Edit recipient', onPressed: () => _edit(DeliveryRoutes.recipient)),
      rows: [
        SangaDetailRow(icon: Icons.person_outline_rounded, label: 'Name', value: recipient?.name ?? ''),
        SangaDetailRow(
          icon: Icons.phone_outlined,
          label: 'Phone',
          value: recipient == null ? '' : '0${SangaPhoneNumber.national(recipient.phone)}',
        ),
        if (recipient?.email case final email?)
          SangaDetailRow(icon: Icons.mail_outline_rounded, label: 'Email', value: email),
      ],
    );
  }
}
