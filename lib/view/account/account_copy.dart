import 'package:intl/intl.dart';
import 'package:sanga_ride/core/format/number_formats.dart';
import 'package:sanga_ride/model/models.dart';

abstract final class AccountCopy {
  static final DateFormat _month = DateFormat('MMMM y');

  static const List<String> deletionConsequences = [
    'Your account is scheduled for deletion and disappears after 30 days',
    'Log back in during those 30 days and your account stays right where it was',
    'Your ride history and saved places go with it',
    'Records we must keep by law stay with us',
  ];
  static const String checkAgain = 'Check again';
  static const String email = 'Email';
  static const String removedAfter30Days = 'Removed after 30 days';
  static const String save = 'Save';

  static String tripsLine(Account account) {
    final rides = account.ridesCount;
    return rides == 1 ? '1 trip' : '${NumberFormats.grouped.format(rides)} trips';
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
