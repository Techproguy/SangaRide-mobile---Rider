import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/top_up_controller.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride/view/wallet/wallet_copy.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

const EdgeInsets _sheetPadding = EdgeInsets.fromLTRB(
  SangaSpacing.xl,
  SangaSpacing.xxl,
  SangaSpacing.xl,
  SangaSpacing.xl,
);

Future<bool?> showTopUpProcessingSheet({required BuildContext context, required TopUpController controller}) {
  return showSangaSheet<bool>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    padding: _sheetPadding,
    builder: (sheetContext) => PopScope(
      canPop: false,
      child: Obx(() {
        final isChecking = controller.state is TopUpChecking;
        return SangaStatusContent(
          status: SangaStatus.pending,
          title: isChecking ? WalletCopy.checkingTitle : WalletCopy.processingTitle,
          message: isChecking ? WalletCopy.checkingMessage : WalletCopy.processingMessage,
          secondary: SangaBusyEscape(
            message: WalletCopy.stillWorkingMessage,
            onClose: () => Navigator.of(sheetContext).pop(true),
          ),
        );
      }),
    ),
  );
}

Future<bool?> showTopUpUnknownSheet({required BuildContext context}) {
  return showSangaSheet<bool>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    padding: _sheetPadding,
    builder: (sheetContext) => PopScope(
      canPop: false,
      child: SangaStatusContent(
        status: SangaStatus.caution,
        icon: Icons.hourglass_top_rounded,
        title: WalletCopy.unknownTitle,
        message: WalletCopy.unknownMessage,
        action: SangaButton.primary(
          label: WalletCopy.checkMyWallet,
          onPressed: () => Navigator.of(sheetContext).pop(true),
        ),
        secondary: SangaTextAction(
          label: WalletCopy.checkAgain,
          onPressed: () => Navigator.of(sheetContext).pop(false),
        ),
      ),
    ),
  );
}
