import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/core/router/booking_routes.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

Future<void> showScheduledSuccess(BuildContext context, {required String title, required String message}) async {
  final viewScheduled = !await showSangaStatusSheet(
    context: context,
    status: SangaStatus.success,
    title: title,
    message: message,
    actionLabel: 'Done',
    secondaryLabel: 'View scheduled rides',
  );
  if (!context.mounted) return;
  context.go(SangaRoutes.home);
  if (viewScheduled) unawaited(context.push(BookingRoutes.scheduledRides));
}
