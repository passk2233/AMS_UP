import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Reusable, accent-colored dialog helpers.
///
/// All four flavors (success / warning / error / confirmation) share the same
/// rounded white surface, circular icon badge, title, message, and footer
/// button(s). The private [_DialogShell] enforces that shared layout so the
/// public helpers stay tiny and side-by-side comparable.
class AppDialogs {
  AppDialogs._();

  /// Shows a success dialog with a green check badge and a single dismiss
  /// button.
  ///
  /// - [title]: bold headline shown under the icon.
  /// - [message]: secondary supporting copy below the title.
  static Future<void> showSuccess({
    required String title,
    required String message,
  }) {
    return _show(
      title: title,
      message: message,
      icon: Icons.check_circle_rounded,
      accent: AppColors.borderApproved,
      primaryLabel: 'ຕົກລົງ',
    );
  }

  /// Shows a warning dialog with an amber icon and a single dismiss button.
  ///
  /// - [title]: bold headline shown under the icon.
  /// - [message]: secondary supporting copy below the title.
  static Future<void> showWarning({
    required String title,
    required String message,
  }) {
    return _show(
      title: title,
      message: message,
      icon: Icons.warning_amber_rounded,
      accent: AppColors.borderPending,
      primaryLabel: 'ຕົກລົງ',
    );
  }

  /// Shows an error dialog with a red icon and an optional [detail] panel
  /// (typically a stringified API error from [buildDioErrorDetail]).
  ///
  /// - [title]: bold headline shown under the icon.
  /// - [message]: human-readable explanation of what went wrong.
  /// - [detail]: optional machine detail (status code, server message) shown
  ///   inside a gray code block.
  static Future<void> showError({
    required String title,
    required String message,
    String? detail,
  }) {
    return _show(
      title: title,
      message: message,
      icon: Icons.error_outline_rounded,
      accent: AppColors.rejectRed,
      primaryLabel: 'ປິດ',
      detail: detail,
    );
  }

  /// Shows a confirmation dialog with cancel + confirm buttons. Returns the
  /// user's choice — `true` for confirm, `false` for cancel, `null` if
  /// dismissed without choosing.
  ///
  /// - [title], [message]: the body copy.
  /// - [confirmText], [cancelText]: button labels (default Lao copy).
  /// - [confirmColor]: tint applied to the badge and confirm button.
  static Future<bool?> showConfirmation({
    required String title,
    required String message,
    String confirmText = 'ຢືນຢັນ',
    String cancelText = 'ຍົກເລີກ',
    Color confirmColor = AppColors.primaryFill,
  }) {
    return Get.dialog<bool>(
      _DialogShell(
        accent: confirmColor,
        icon: Icons.help_outline_rounded,
        title: title,
        message: message,
        footer: _ConfirmFooter(
          confirmText: confirmText,
          cancelText: cancelText,
          confirmColor: confirmColor,
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Build a multi-line, human-readable detail string from a [DioException].
  ///
  /// Includes (when available) HTTP status, server `error` / `message`,
  /// timeout categorization, and the request URL. Trim before display.
  static String buildDioErrorDetail(DioException e) {
    final buffer = StringBuffer();

    if (e.response?.statusCode != null) {
      buffer.writeln('Status: ${e.response!.statusCode}');
    }

    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      if (data['error'] != null) buffer.writeln('Error: ${data['error']}');
      if (data['message'] != null) buffer.writeln('Message: ${data['message']}');
    } else if (data != null) {
      buffer.writeln('Response: $data');
    }

    final timeoutMessage = _timeoutMessage(e.type);
    if (timeoutMessage != null) buffer.writeln(timeoutMessage);

    final uri = e.requestOptions.uri.toString();
    if (uri.isNotEmpty) buffer.writeln('URL: $uri');

    return buffer.toString().trim();
  }

  static String? _timeoutMessage(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionTimeout:
        return 'ການເຊື່ອມຕໍ່ໝົດເວລາ';
      case DioExceptionType.receiveTimeout:
        return 'ເຊີບເວີໃຊ້ເວລາດົນເກີນໄປ';
      case DioExceptionType.connectionError:
        return 'ບໍ່ສາມາດເຊື່ອມຕໍ່ກັບເຊີບເວີ';
      default:
        return null;
    }
  }

  static Future<void> _show({
    required String title,
    required String message,
    required IconData icon,
    required Color accent,
    required String primaryLabel,
    String? detail,
  }) {
    return Get.dialog(
      _DialogShell(
        accent: accent,
        icon: icon,
        title: title,
        message: message,
        detail: detail,
        footer: _SingleActionFooter(
          label: primaryLabel,
          color: accent,
          onPressed: () => Get.back(),
        ),
      ),
      barrierDismissible: true,
    );
  }
}

/// Shared visual layout used by every flavor in [AppDialogs].
///
/// Renders the rounded white card, the [_IconBadge] header, the title and
/// message, an optional [_DetailPanel], and a caller-supplied [footer].
class _DialogShell extends StatelessWidget {
  /// Tint applied to the icon badge and (by default) the primary button.
  final Color accent;

  /// Icon shown in the colored circular badge at the top.
  final IconData icon;

  /// Bold headline rendered under the badge.
  final String title;

  /// Supporting copy rendered under the title.
  final String message;

  /// Optional machine-readable detail (e.g. API error JSON).
  final String? detail;

  /// Footer area — typically one or two buttons.
  final Widget footer;

  const _DialogShell({
    required this.accent,
    required this.icon,
    required this.title,
    required this.message,
    required this.footer,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.cardRadius + 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _IconBadge(icon: icon, color: accent),
            const SizedBox(height: AppSpacing.m),
            Text(title, style: AppTypography.heading),
            const SizedBox(height: AppSpacing.s),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmallMuted,
            ),
            if (detail != null && detail!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s + 4),
              _DetailPanel(text: detail!),
            ],
            const SizedBox(height: AppSpacing.m + 4),
            footer,
          ],
        ),
      ),
    );
  }
}

/// Circular colored badge with a glyph inside — the visual signature for
/// each dialog flavor.
class _IconBadge extends StatelessWidget {
  /// Glyph shown inside the badge.
  final IconData icon;

  /// Tint of both the badge background and the glyph.
  final Color color;

  const _IconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 48),
    );
  }
}

/// Read-only monospaced panel used to surface raw error detail.
class _DetailPanel extends StatelessWidget {
  /// Verbatim detail text rendered inside the panel.
  final String text;

  const _DetailPanel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s + 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(AppSpacing.s),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ລາຍລະອຽດ:',
            style: AppTypography.captionStrong.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: AppTypography.caption.copyWith(
              color: Colors.grey.shade700,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

/// Footer with a single full-width filled button (success / warning / error).
class _SingleActionFooter extends StatelessWidget {
  /// Button label.
  final String label;

  /// Button background.
  final Color color;

  /// Tap callback — usually closes the dialog.
  final VoidCallback onPressed;

  const _SingleActionFooter({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s + 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.s + 2),
          ),
        ),
        child: Text(label, style: const TextStyle(fontSize: 15)),
      ),
    );
  }
}

/// Two-button footer used by [AppDialogs.showConfirmation].
class _ConfirmFooter extends StatelessWidget {
  /// Label for the destructive / accept action.
  final String confirmText;

  /// Label for the cancel action.
  final String cancelText;

  /// Tint for the confirm button background.
  final Color confirmColor;

  const _ConfirmFooter({
    required this.confirmText,
    required this.cancelText,
    required this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Get.back(result: false),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: BorderSide(color: Colors.grey.shade300),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s + 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.s + 2),
              ),
            ),
            child: Text(cancelText, style: const TextStyle(fontSize: 15)),
          ),
        ),
        const SizedBox(width: AppSpacing.s + 4),
        Expanded(
          child: ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s + 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.s + 2),
              ),
            ),
            child: Text(confirmText, style: const TextStyle(fontSize: 15)),
          ),
        ),
      ],
    );
  }
}
