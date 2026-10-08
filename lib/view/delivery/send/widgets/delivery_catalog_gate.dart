import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/delivery/send_delivery_controller.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_async_state.dart';

class DeliveryCatalogGate extends StatelessWidget {
  const DeliveryCatalogGate({super.key, required this.builder, this.skeletonCount = 2, this.skeletonHeight = 72});

  final Widget Function(BuildContext context, DeliveryCatalog catalog) builder;
  final int skeletonCount;
  final double skeletonHeight;

  @override
  Widget build(BuildContext context) {
    final delivery = Get.find<SendDeliveryController>();
    return Obx(() {
      final state = delivery.catalogState;
      return RideOptionAsyncState(
        isLoading: state is DeliveryCatalogLoading,
        hasFailed: state is DeliveryCatalogFailed,
        errorTitle: 'We couldn’t load delivery options',
        onRetry: delivery.loadCatalog,
        skeletonCount: skeletonCount,
        skeletonHeight: skeletonHeight,
        builder: (context) {
          final catalog = delivery.catalog;
          return catalog == null ? const SizedBox.shrink() : builder(context, catalog);
        },
      );
    });
  }
}
