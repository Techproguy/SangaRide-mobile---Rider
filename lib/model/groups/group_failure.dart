import 'package:sanga_ride/core/api/server_codes.dart';
import 'package:sanga_ride/core/copy/common_copy.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

enum GroupFailure {
  alreadyInGroup(
    'already_in_group',
    'You’re already in a group like this',
    'Leave your current one first, then you can start or join another.',
  ),
  nameRequired(ServerCode.nameRequired, 'Name your group', 'Give it a name so everyone knows what it is.'),
  invalidCode('invalid_code', 'That code doesn’t match', 'Check the code with whoever sent it and try again.'),
  expiredCode('expired_code', 'That code has expired', 'Ask for a fresh code and try again.'),
  phoneInGroup('phone_in_group', 'They’re already in', 'That number is already part of this group.'),
  invalidPhone(ServerCode.invalidPhone, 'We can’t text that number', 'Check the number and try again.'),
  lastAdmin('last_admin', 'Someone has to stay in charge', 'Make another person an admin first, then try again.'),
  notAllowed('not_allowed', 'Only admins can do that', 'Ask an admin of the group to do it for you.'),
  groupNotFound('group_not_found', 'We can’t find that group', 'It may have been removed. Head back and try again.'),
  inviteNotFound('invite_not_found', 'That invite is gone', 'It may have expired or been taken back.'),
  approvalNotFound('approval_not_found', 'Already handled', 'Someone already answered that request.'),
  approvalAlreadyDecided('approval_already_decided', 'Already handled', 'Someone already answered that request.'),
  approvalExpired('approval_expired', 'That request ran out of time', 'Nobody answered in time, so it has closed.'),
  rideCancelled('ride_cancelled', 'The ride was cancelled', 'The rider cancelled before anyone answered.'),
  memberNotFound('member_not_found', 'They’re no longer here', 'That person has already left or been removed.'),
  connection('connection', CommonCopy.unreachableTitle, CommonCopy.connectionBody),
  unknown('unknown', CommonCopy.serverTroubleTitle, CommonCopy.tryAgainInAMoment),
  unconfirmed(
    'unconfirmed',
    'We’re not sure that went through',
    'We refreshed the list so you can see what happened before you try again.',
  );

  const GroupFailure(this.code, this.title, this.message);

  final String code;
  final String title;
  final String message;

  bool get isNotFound => this == groupNotFound;

  bool get closesApproval =>
      this == approvalNotFound || this == approvalAlreadyDecided || this == approvalExpired || this == rideCancelled;

  bool get isGone => this == groupNotFound || this == notAllowed;

  static GroupFailure fromCode(String? code) =>
      enumByCode(values, code, (failure) => failure.code, GroupFailure.unknown);

  static GroupFailure of(Object error) => switch (ProblemKind.of(error)) {
    ProblemOffline() => connection,
    ProblemRejected(:final code) => fromCode(code),
    _ => unknown,
  };
}

enum GroupRideBlock {
  spendingLimitReached(
    'spending_limit_reached',
    'Over your monthly limit',
    'This ride goes past your monthly limit. Ask an admin to raise it, or pay for this one yourself.',
  ),
  outsideTimeWindow(
    'outside_time_window',
    'Not at this time',
    'Group rides are only allowed during set hours, and this isn’t one of them.',
  ),
  rideTypeNotAllowed(
    'ride_type_not_allowed',
    'That ride type isn’t allowed',
    'Pick one of the ride types your group allows.',
  ),
  placeNotApproved(
    'place_not_approved',
    'That place isn’t on your list',
    'Group rides can only go to places an admin approved.',
  ),
  dailyRideLimit('daily_ride_limit', 'That’s all for today', 'You’ve used up today’s group rides. Try again tomorrow.'),
  ridesNotAllowed(
    'group_rides_not_allowed',
    'Group rides are switched off',
    'An admin turned off group rides for this person.',
  ),
  approvalDeclined(
    'approval_declined',
    'Your ride wasn’t approved',
    'An admin said no to this ride. You can still book and pay another way.',
  ),
  approvalExpired(
    'approval_expired',
    'The request ran out of time',
    'Nobody answered in time. Send the ride again or ask an admin directly.',
  );

  const GroupRideBlock(this.code, this.title, this.message);

  final String code;
  final String title;
  final String message;

  static GroupRideBlock? tryFromCode(String? code) => values.where((block) => block.code == code).firstOrNull;
}
