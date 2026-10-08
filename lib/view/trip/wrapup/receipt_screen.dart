import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/trip/trip_receipt_controller.dart';
import 'package:sanga_ride/model/trip/wrapup/wrapup.dart';
import 'package:sanga_ride/view/trip/wrapup/widgets/receipt_delivery_card.dart';
import 'package:sanga_ride/view/trip/wrapup/widgets/receipt_paid_with.dart';
import 'package:sanga_ride/view/trip/wrapup/widgets/receipt_route_card.dart';
import 'package:sanga_ride/view/trip/wrapup/widgets/wrapup_async_body.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  final _receipt = Get.find<TripReceiptController>();

  @override
  void initState() {
    super.initState();
    unawaited(_receipt.open(widget.tripId));
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _receipt.state;
      return SangaPageLayout(
        title: state is ReceiptLoaded && state.receipt.isDelivery ? 'Delivery receipt' : 'Trip receipt',
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
            skeletonHeights: const [150, 160, 80],
            builder: (context) =>
                state is ReceiptLoaded ? _ReceiptBody(receipt: state.receipt) : const SizedBox.shrink(),
          ),
        ],
      );
    });
  }
}

class _ReceiptBody extends StatelessWidget {
  const _ReceiptBody({required this.receipt});

  final TripReceipt receipt;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: SangaSpacing.md,
      children: [
        ReceiptRouteCard(receipt: receipt),
        if (receipt.delivery case final ReceiptDelivery delivery) ReceiptDeliveryCard(delivery: delivery),
        SangaFareBreakdown(
          title: 'Fare breakdown',
          lines: [for (final line in receipt.lines) SangaFareLine(line.label, SangaMoney.naira(line.amount))],
          totalLabel: 'TOTAL PAID',
          total: SangaMoney.naira(receipt.total),
        ),
        ReceiptPaidWith(paidWith: receipt.paidWith, paidAt: receipt.paidAt),
      ],
    );
  }
}
