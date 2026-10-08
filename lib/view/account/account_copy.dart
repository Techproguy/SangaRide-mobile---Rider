import 'package:intl/intl.dart';
import 'package:sanga_ride/model/models.dart';

abstract final class AccountCopy {
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
