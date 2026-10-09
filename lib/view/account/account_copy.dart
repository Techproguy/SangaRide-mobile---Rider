import 'package:intl/intl.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

abstract final class AccountCopy {
  static List<String> deletionLines(int graceDays) => [
    'Your account is scheduled for deletion and disappears after $graceDays days',
    'Log back in during those $graceDays days and your account stays right where it was',
    'Your ride history and saved places go with it',
    'Records we must keep by law stay with us',
  ];

  static String walletWarning(int balance) =>
      'You have ${SangaMoney.naira(balance)} in your wallet. It goes with your account, so use it before you delete.';

  static const String transferWarning = 'A top up is still on its way. Let it land before you delete.';

  static String groupWarning(OwnedGroup group) {
    final others = group.membersCount - 1;
    if (others <= 0) return 'You own ${group.name}. It goes away with your account.';
    final people = others == 1 ? '1 other member' : '$others other members';
    return 'You own ${group.name}. Its $people lose access when your account goes.';
  }

  static final DateFormat _month = DateFormat('MMMM y');
  static final NumberFormat _count = NumberFormat('#,##0');

  static String tripsLine(Account account) {
    final rides = account.ridesCount;
    return rides == 1 ? '1 trip' : '${_count.format(rides)} trips';
  }

  static String memberLine(Account account) {
    final since = account.memberSince;
    return since == null ? tripsLine(account) : 'Riding with Sanga since ${_month.format(since)}';
  }

  static String verificationLabel(VerificationStatus status) => switch (status) {
    VerificationStatus.verified => 'Verified',
    VerificationStatus.pending => 'In review',
    VerificationStatus.rejected || VerificationStatus.actionNeeded => 'Action needed',
    VerificationStatus.unverified => 'Not verified',
  };

  static String unreadLabel(int count) => count > 99 ? '99+' : '$count';
}
