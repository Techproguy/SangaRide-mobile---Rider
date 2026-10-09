import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/account/account_controller.dart';
import 'package:sanga_ride/core/router/account_routes.dart';
import 'package:sanga_ride/core/services/permission_center.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/account/account_copy.dart';
import 'package:sanga_ride/view/account/widgets/account_image.dart';
import 'package:sanga_ride/view/account/widgets/profile_edit_sheet.dart';
import 'package:sanga_ride/view/account/widgets/profile_photo_editor.dart';
import 'package:sanga_ride/view/delivery/send/widgets/photo_source_sheet.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _controller = Get.find<AccountController>();
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_controller.load());
    });
  }

  Future<void> _changePhoto() async {
    final source = await showPhotoSourceSheet(context, title: 'Change your photo');
    if (source == null || !mounted) return;
    if (source == PhotoSource.camera) {
      final access = await Get.find<PermissionCenter>().prime(PermissionKind.camera, context);
      if (!mounted) return;
      if (!access.isUsable) {
        if (access.needsSettings) _controller.denyPhoto(source);
        return;
      }
    }
    await _controller.changePhoto(source);
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    final isConfirmed = await showSangaPromptSheet(
      context: context,
      icon: Icons.logout_rounded,
      title: 'Log out?',
      message: 'You’ll need your phone number to get back in.',
      actionLabel: 'Yes, log out',
      dismissLabel: 'Stay logged in',
    );
    if (!isConfirmed || !mounted) return;
    setState(() => _isLoggingOut = true);
    await _controller.logout();
    if (mounted) setState(() => _isLoggingOut = false);
  }

  Widget _header(AccountLoaded state) {
    final account = state.account;
    final rating = account.rating;
    return Column(
      spacing: SangaSpacing.xs,
      children: [
        ProfilePhotoEditor(
          name: account.fullName,
          image: accountImageOf(account.photoUrl),
          isUploading: state.isUploadingPhoto,
          onEdit: _changePhoto,
        ),
        const SizedBox(height: SangaSpacing.xs),
        Text(account.fullName, textAlign: TextAlign.center, style: SangaTextStyles.title),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: SangaSpacing.sm,
          children: [
            if (rating != null) SangaStarRating(rating: rating, size: 15),
            Text(AccountCopy.tripsLine(account), style: SangaTextStyles.body),
          ],
        ),
      ],
    );
  }

  Widget _photoNotice(AccountLoaded state) {
    final problem = state.photoProblem;
    if (problem == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: SangaSpacing.md),
      child: Column(
        spacing: SangaSpacing.sm,
        children: [
          SangaNotice(message: problem.message),
          if (problem.opensSettings)
            SangaButton.outline(
              label: 'Open Settings',
              size: SangaButtonSize.compact,
              onPressed: Get.find<PermissionCenter>().openSettings,
            ),
          if (state.hasPendingPhoto)
            SangaButton.outline(
              label: 'Try again',
              size: SangaButtonSize.compact,
              onPressed: () => unawaited(_controller.retryPhoto()),
            ),
        ],
      ),
    );
  }

  Widget _fields(Account account) {
    final email = account.email;
    final birthday = account.dateOfBirth;
    return Column(
      spacing: SangaSpacing.sm,
      children: [
        SangaProfileFieldTile(
          label: 'Full name',
          value: account.fullName,
          onTap: () => showProfileEditSheet(context, field: ProfileField.name, account: account),
        ),
        SangaProfileFieldTile(
          label: 'Phone number',
          value: '${SangaPhoneNumber.dialCode} ${SangaPhoneNumber.format(account.phone)}',
          onTap: () => context.push(AccountRoutes.phone),
        ),
        SangaProfileFieldTile(
          label: 'Email',
          value: email ?? 'Add your email',
          isEmpty: email == null,
          onTap: () => showProfileEditSheet(context, field: ProfileField.email, account: account),
        ),
        SangaProfileFieldTile(
          label: 'Date of birth',
          value: birthday == null ? 'Add your birthday' : TimeFormat.longDate(birthday),
          isEmpty: birthday == null,
          icon: Icons.calendar_month_rounded,
          onTap: () => showProfileEditSheet(context, field: ProfileField.birthday, account: account),
        ),
      ],
    );
  }

  Widget _accountActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.xs,
      children: [
        const SangaSectionHeader('Account'),
        SangaListGroup(
          children: [
            SangaListRow(
              leading: const Icon(Icons.logout_rounded, size: 22, color: SangaColors.textPrimary),
              title: 'Log out',
              trailing: _isLoggingOut ? SangaListRow.spinner : const SizedBox.shrink(),
              onTap: _isLoggingOut ? null : _logout,
            ),
            SangaListRow(
              leading: const Icon(Icons.delete_outline_rounded, size: 22, color: SangaColors.dangerStrong),
              title: 'Delete account',
              subtitle: 'Removed after 30 days',
              titleMaxLines: 2,
              onTap: () => context.push(AccountRoutes.delete),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _loaded(AccountLoaded state) {
    final account = state.account;
    return [
      _header(state),
      _photoNotice(state),
      const SizedBox(height: SangaSpacing.xl),
      _fields(account),
      const SizedBox(height: SangaSpacing.lg),
      Text(AccountCopy.memberLine(account), textAlign: TextAlign.center, style: SangaTextStyles.caption),
      const SizedBox(height: SangaSpacing.xxl),
      _accountActions(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _controller.state;
      return SangaPageLayout(
        title: 'Profile',
        children: [
          switch (state) {
            AccountLoading() => const SangaSkeleton.heights([96, 24, 56, 56, 56, 56]),
            AccountFailed(:final problem) => SangaFailureMessage(message: problem.message, onRetry: _controller.retry),
            AccountLoaded() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _loaded(state)),
          },
        ],
      );
    });
  }
}
