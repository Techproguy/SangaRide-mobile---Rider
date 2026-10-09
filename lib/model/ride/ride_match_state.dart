import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride/model/ride/ride_load_problem.dart';
import 'package:sanga_ride/model/ride/ride_match.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

sealed class RideMatchState {
  const RideMatchState();
}

final class MatchIdle extends RideMatchState {
  const MatchIdle();
}

final class MatchStarting extends RideMatchState {
  const MatchStarting({this.isChecking = false});

  final bool isChecking;
}

final class MatchResuming extends RideMatchState {
  const MatchResuming();
}

final class MatchSearching extends RideMatchState {
  const MatchSearching(this.request, {this.link = LinkState.live});

  final MatchRequest request;
  final LinkState link;

  bool get isReconnecting => link != LinkState.live;
}

final class MatchOffersReady extends RideMatchState {
  const MatchOffersReady({required this.request, required this.continueAt});

  final MatchRequest request;
  final DateTime continueAt;
}

final class MatchScheduled extends RideMatchState {
  const MatchScheduled(this.booking);

  final ScheduledBooking booking;
}

final class MatchNoDriver extends RideMatchState {
  const MatchNoDriver();
}

final class MatchCancelled extends RideMatchState {
  const MatchCancelled({this.isConfirmed = true});

  final bool isConfirmed;
}

final class MatchAwaitingApproval extends RideMatchState {
  const MatchAwaitingApproval(this.approval);

  final PendingApproval approval;
}

final class MatchBlocked extends RideMatchState {
  const MatchBlocked(this.block);

  final GroupRideBlock block;
}

final class MatchFailed extends RideMatchState {
  const MatchFailed(this.reason, {this.code, this.data = const {}});

  final MatchFailure reason;
  final String? code;
  final Map<String, dynamic> data;
}

final class MatchOffersLoading extends RideMatchState {
  const MatchOffersLoading();
}

final class MatchOffersFailed extends RideMatchState {
  const MatchOffersFailed({this.problem = RideLoadProblem.connection});

  final RideLoadProblem problem;
}

sealed class MatchBrowsing extends RideMatchState {
  const MatchBrowsing(this.rows);

  final List<OfferRow> rows;

  MatchBrowsing withRows(List<OfferRow> rows);
}

final class MatchOffersListed extends MatchBrowsing {
  const MatchOffersListed(super.rows, {this.acceptingOfferId});

  final String? acceptingOfferId;

  @override
  MatchOffersListed withRows(List<OfferRow> rows) => MatchOffersListed(rows, acceptingOfferId: acceptingOfferId);
}

final class MatchHolding extends MatchBrowsing {
  const MatchHolding(super.rows, {required this.hold, this.isConfirming = false});

  final DriverHold hold;
  final bool isConfirming;

  @override
  MatchHolding withRows(List<OfferRow> rows) => MatchHolding(rows, hold: hold, isConfirming: isConfirming);
}

final class MatchConfirmed extends RideMatchState {
  const MatchConfirmed(this.trip);

  final ConfirmedTrip trip;
}
