import 'package:flutter/widgets.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_schedule_format.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

List<SangaFareLine> airportReviewLines(BuildContext context, AirportBooking booking) {
  final details = booking.details;
  return [
    SangaFareLine('Trip', 'Airport pickup'),
    SangaFareLine('Flight', booking.flight.number),
    SangaFareLine('Arrives', formatRideSchedule(context, booking.flight.estimatedArrival)),
    SangaFareLine('Pick up', booking.pickupType.label),
    SangaFareLine('Passengers', '${details.passengers}'),
    SangaFareLine('Luggage', details.luggageLabel),
    if (details.assistance != Assistance.none) SangaFareLine('Assistance', details.assistance.label),
  ];
}
