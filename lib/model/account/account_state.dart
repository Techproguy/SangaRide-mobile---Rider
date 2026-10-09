import 'package:sanga_ride/model/account/account.dart';
import 'package:sanga_ride/model/account/account_problem.dart';

sealed class AccountState {
  const AccountState();

  Account? get accountOrNull => switch (this) {
    AccountLoaded(:final account) => account,
    _ => null,
  };
}

final class AccountLoading extends AccountState {
  const AccountLoading();
}

final class AccountFailed extends AccountState {
  const AccountFailed(this.problem);

  final AccountProblem problem;
}

final class AccountLoaded extends AccountState {
  const AccountLoaded(this.account, {this.isUploadingPhoto = false, this.photoProblem, this.hasPendingPhoto = false});

  final Account account;
  final bool isUploadingPhoto;
  final AccountProblem? photoProblem;
  final bool hasPendingPhoto;

  AccountLoaded copyWith({
    Account? account,
    bool? isUploadingPhoto,
    AccountProblem? Function()? photoProblem,
    bool? hasPendingPhoto,
  }) => AccountLoaded(
    account ?? this.account,
    isUploadingPhoto: isUploadingPhoto ?? this.isUploadingPhoto,
    photoProblem: photoProblem == null ? this.photoProblem : photoProblem(),
    hasPendingPhoto: hasPendingPhoto ?? this.hasPendingPhoto,
  );
}

sealed class PhoneChangeState {
  const PhoneChangeState();
}

final class PhoneEntry extends PhoneChangeState {
  const PhoneEntry({this.problem});

  final AccountProblem? problem;
}

final class PhoneSending extends PhoneChangeState {
  const PhoneSending();
}

final class PhoneCode extends PhoneChangeState {
  const PhoneCode(this.phone, this.sentAt, this.lifetime, {this.problem, this.isVerifying = false});

  final String phone;
  final DateTime sentAt;
  final Duration lifetime;
  final AccountProblem? problem;
  final bool isVerifying;
}

final class PhoneChanged extends PhoneChangeState {
  const PhoneChanged();
}

sealed class DeleteAccountState {
  const DeleteAccountState();
}

final class DeleteIdle extends DeleteAccountState {
  const DeleteIdle({this.block});

  final AccountProblem? block;
}

final class DeleteDeleting extends DeleteAccountState {
  const DeleteDeleting();
}

final class DeleteUnknown extends DeleteAccountState {
  const DeleteUnknown();
}

final class DeleteScheduled extends DeleteAccountState {
  const DeleteScheduled(this.deletesAt);

  final DateTime? deletesAt;
}
