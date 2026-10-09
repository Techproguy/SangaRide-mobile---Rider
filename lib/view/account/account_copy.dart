import 'package:intl/intl.dart';
import 'package:sanga_ride/core/format/number_formats.dart';
import 'package:sanga_ride/model/models.dart';

abstract final class AccountCopy {
  static final DateFormat _month = DateFormat('MMMM y');

  static const String phoneUpdated = 'Phone number updated';
  static const String sendCode = 'Send code';
  static const String verify = 'Verify';
  static const String useDifferentNumber = 'Use a different number';
  static const String changeYourNumber = 'Change your number';
  static const String enterOtp = 'Enter OTP';
  static const String changeNumberLead = 'We’ll text a code to your new number to make sure it’s yours';
  static const List<String> deletionConsequences = [
    'Your account is scheduled for deletion and disappears after 30 days',
    'Log back in during those 30 days and your account stays right where it was',
    'Your ride history and saved places go with it',
    'Records we must keep by law stay with us',
  ];
  static const String deleteConfirmTitle = 'Delete your account?';
  static const String deleteConfirmMessage = 'This is the last step. You’ll be logged out right away.';
  static const String deleteConfirmAction = 'Yes, delete it';
  static const String keepMyAccount = 'Keep my account';
  static const String deletionScheduled = 'Deletion scheduled';
  static const String deletionWindow = 'Log in within 30 days to keep your account.';
  static const String logOut = 'Log out';
  static const String checkAgain = 'Check again';
  static const String deleteMyAccount = 'Delete my account';
  static const String deleteAccount = 'Delete account';
  static const String beforeYouGo = 'Before you go';
  static const String deleteLead = 'Here’s what happens when you delete your account.';
  static const String whatToExpect = 'What to expect';
  static const String whyLeaving = 'Why are you leaving? (optional)';
  static const String understandDeletion = 'I understand my account will be deleted';
  static const String changeYourPhoto = 'Change your photo';
  static const String logOutTitle = 'Log out?';
  static const String logOutMessage = 'You’ll need your phone number to get back in.';
  static const String logOutAction = 'Yes, log out';
  static const String stayLoggedIn = 'Stay logged in';
  static const String tryAgain = 'Try again';
  static const String fullName = 'Full name';
  static const String phoneNumber = 'Phone number';
  static const String email = 'Email';
  static const String addEmail = 'Add your email';
  static const String dateOfBirth = 'Date of birth';
  static const String addBirthday = 'Add your birthday';
  static const String accountSection = 'Account';
  static const String removedAfter30Days = 'Removed after 30 days';
  static const String profileTitle = 'Profile';
  static const String yourName = 'Your name';
  static const String yourEmail = 'Your email';
  static const String yourBirthday = 'Your birthday';
  static const String profileUpdated = 'Profile updated';
  static const String firstName = 'First name';
  static const String lastName = 'Last name';
  static const String emailAddress = 'Email address';
  static const String save = 'Save';
  static const String changePhoto = 'Change photo';

  static String enterCodeLead(int length, String maskedPhone) => 'Enter the $length-digit code sent to $maskedPhone';

  static String deletionDate(String date) => 'Your account goes on $date. Log in before then to keep it.';

  static String phoneValue(String dialCode, String number) => '$dialCode $number';

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
