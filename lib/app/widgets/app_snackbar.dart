import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Non-blocking toast feedback per design.txt §5.
///
/// Use for success or quick confirmations — for blocking error / confirm
/// flows use [AppDialogs] instead.
class AppSnackbar {
  AppSnackbar._();

  static void success(String message, {String title = 'ສຳເລັດ'}) {
    _show(
      title: title,
      message: message,
      color: AppColors.successGreen,
      icon: Icons.check_circle_rounded,
    );
  }

  static void error(String message, {String title = 'ຜິດພາດ'}) {
    _show(
      title: title,
      message: message,
      color: AppColors.rejectRed,
      icon: Icons.error_outline_rounded,
    );
  }

  static void warning(String message, {String title = 'ແຈ້ງເຕືອນ'}) {
    _show(
      title: title,
      message: message,
      color: AppColors.borderPending,
      icon: Icons.warning_amber_rounded,
      // White on amber is only 2.15:1; dark ink clears AA at 7.94:1.
      foreground: AppColors.textPrimary,
    );
  }

  static void info(String message, {String title = 'ຂໍ້ມູນ'}) {
    _show(
      title: title,
      message: message,
      color: AppColors.primaryFill,
      icon: Icons.info_outline_rounded,
    );
  }

  static void _show({
    required String title,
    required String message,
    required Color color,
    required IconData icon,
    Color foreground = Colors.white,
  }) {
    Get.snackbar(
      title,
      message,
      titleText: Text(
        title,
        style: TextStyle(
          color: foreground,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      messageText: Text(
        message,
        style: TextStyle(
          color: foreground,
          fontSize: 13,
          height: 1.3,
        ),
      ),
      snackPosition: SnackPosition.TOP,
      backgroundColor: color,
      colorText: foreground,
      icon: Icon(icon, color: foreground),
      shouldIconPulse: false,
      borderRadius: AppColors.cardRadius,
      margin: const EdgeInsets.all(AppSpacing.m),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: 14,
      ),
      duration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 250),
    );
  }
}
