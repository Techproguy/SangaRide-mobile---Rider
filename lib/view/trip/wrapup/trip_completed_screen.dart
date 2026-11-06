import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/trip/trip_receipt_controller.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/core/router/trip_wrapup_routes.dart';
import 'package:sanga_ride/model/trip/wrapup/wrapup.dart';
import 'package:sanga_ride/view/trip/wrapup/widgets/completed_summary.dart';
import 'package:sanga_ride/view/trip/wrapup/widgets/wrapup_async_body.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TripCompletedScreen extends StatefulWidget {
  const TripCompletedScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<TripCompletedScreen> createState() => _TripCompletedScreenState();
}

class _TripCompletedScreenState extends State<TripCompletedScreen> {
  final _receipt = Get.find<TripReceiptController>();

  @override
  void initState() {
    super.initState();
    unawaited(_receipt.open(widget.tripId));
  }

  void _home() => context.go(SangaRoutes.home);

  @override
  Widget build(BuildContext context) {
    return SangaBackScope(
      canPop: false,
      onBack: _home,
      child: AnnotatedRegion(
        value: SangaSystemUi.onLight,
        child: Scaffold(
          appBar: SangaAppBar(
            leading: SangaStepLeading.none,
            topInset: SangaSpacing.xs,
            actions: [SangaTextAction(label: 'Done', onPressed: _home)],
          ),
          body: Column(
            children: [
              Expanded(
                child: Obx(() {
                  final state = _receipt.state;
                  const padding = EdgeInsets.fromLTRB(
                    SangaSpacing.gutter,
                    SangaSpacing.xs,
                    SangaSpacing.gutter,
                    SangaSpacing.xl,
                  );
                  return ListView(
                    padding: _receipt.receipt == null ? padding.withBottomInset(context) : padding,
                    children: [
                      WrapUpAsyncBody(
                        isLoading: state is ReceiptLoading,
                        failure: switch (state) {
                          ReceiptFailed(:final reason) => WrapUpFailure(
                            title: reason.title,
                            message: reason.message,
                            onRetry: reason.canRetry ? _receipt.reload : null,
                          ),
                          ReceiptLoading() || ReceiptLoaded() => null,
                        },
                        skeletonHeights: const [120, 64, 80, 80],
                        builder: (context) =>
                            state is ReceiptLoaded ? CompletedSummary(receipt: state.receipt) : const SizedBox.shrink(),
                      ),
                    ],
                  );
                }),
              ),
              Obx(() {
                final receipt = _receipt.receipt;
                if (receipt == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                    SangaSpacing.gutter,
                    0,
                    SangaSpacing.gutter,
                    SangaSpacing.md,
                  ).withBottomInset(context),
                  child: Column(
                    spacing: SangaSpacing.sm,
                    children: [
                      SangaButton.primary(
                        label: 'View receipt',
                        onPressed: () => context.push(TripWrapUpRoutes.receiptOf(widget.tripId)),
                      ),
                      if (!receipt.isRated)
                        SangaButton.muted(
                          label: receipt.isDelivery ? 'Rate your driver' : 'Rate your ride',
                          onPressed: () => context.push(TripWrapUpRoutes.rateOf(widget.tripId)),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
