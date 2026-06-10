import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/app_colors.dart';
import '../../../../widgets/app_spacing.dart';
import '../controllers/announcement_controller.dart';

/// Confirmation dialog rendered before [AnnouncementController.sendNotification]
/// POSTs the payload.
class SendConfirmationDialog extends StatelessWidget {
  /// Source of reactive state — provides the rows + reach estimate.
  final AnnouncementController controller;

  const SendConfirmationDialog({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.cardRadius + 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SendIconBadge(),
            const SizedBox(height: 14),
            const Text(
              'ຢືນຢັນການສົ່ງ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'ກະລຸນາກວດສອບລາຍລະອຽດ',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            _ConfirmationRows(rows: controller.buildConfirmationRows()),
            const SizedBox(height: 10),
            Obx(
              () => _EstimatedReachPill(
                count: controller.estimatedReach.value,
                loading: controller.isEstimatingReach.value,
              ),
            ),
            const SizedBox(height: 18),
            _DialogFooter(
              cancelLabel: 'ຍົກເລີກ',
              confirmLabel: 'ສົ່ງ',
              confirmIcon: Icons.send_rounded,
              confirmColor: AppColors.laoBlue,
            ),
          ],
        ),
      ),
    );
  }
}

/// Indigo icon badge at the top of [SendConfirmationDialog].
class _SendIconBadge extends StatelessWidget {
  const _SendIconBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.laoBlue.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.send_rounded, color: AppColors.laoBlue, size: 36),
    );
  }
}

/// Boxed list of `label : value` rows inside [SendConfirmationDialog].
class _ConfirmationRows extends StatelessWidget {
  /// Pre-built label/value rows from [AnnouncementController.buildConfirmationRows].
  final List<AnnouncementInfoRow> rows;

  const _ConfirmationRows({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      '${r.label}:',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      r.value,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Pill below the confirmation rows that announces the estimated recipient
/// count, or a loading placeholder while the count is being fetched.
class _EstimatedReachPill extends StatelessWidget {
  /// Last computed count; `null` means "couldn't estimate".
  final int? count;

  /// Whether the estimate is currently in flight.
  final bool loading;

  const _EstimatedReachPill({required this.count, required this.loading});

  @override
  Widget build(BuildContext context) {
    final label = loading
        ? 'ກຳລັງປະເມີນຜູ້ຮັບ...'
        : (count == null ? 'ປະເມີນຜູ້ຮັບບໍ່ໄດ້' : 'ຈະສົ່ງຫາປະມານ $count ຄົນ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.laoBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.laoBlue.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.groups_2_rounded,
            color: AppColors.laoBlue,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.laoBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Edit-notification dialog rendered by [AnnouncementController.editNotification].
class EditNotificationDialog extends StatelessWidget {
  /// Source of the title / message text controllers.
  final AnnouncementController controller;

  const EditNotificationDialog({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.cardRadius + 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ແກ້ໄຂການແຈ້ງເຕືອນ',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            const _FieldLabel('ຫົວຂໍ້'),
            const SizedBox(height: 4),
            _DialogTextField(controller: controller.editTitleCtrl),
            const SizedBox(height: 10),
            const _FieldLabel('ເນື້ອຫາ'),
            const SizedBox(height: 4),
            _DialogTextField(
              controller: controller.editMessageCtrl,
              maxLines: 4,
            ),
            Obx(() {
              final count = controller.editingFilesCount.value;
              if (count == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _EditRemoveFileRow(controller: controller, count: count),
              );
            }),
            const SizedBox(height: 16),
            _DialogFooter(
              cancelLabel: 'ຍົກເລີກ',
              confirmLabel: 'ບັນທຶກ',
              confirmColor: AppColors.laoBlue,
            ),
          ],
        ),
      ),
    );
  }
}

/// Row inside [EditNotificationDialog] showing how many attachments the
/// notification has, with a toggle to clear them on save. Tapping "ລຶບ" flips
/// [AnnouncementController.editRemoveFile]; the row reflects the pending
/// removal with a strikethrough so the choice is reversible before saving.
class _EditRemoveFileRow extends StatelessWidget {
  /// Owner of [AnnouncementController.editRemoveFile].
  final AnnouncementController controller;

  /// Number of existing attachments.
  final int count;

  const _EditRemoveFileRow({required this.controller, required this.count});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final remove = controller.editRemoveFile.value;
      final muted = Colors.grey.shade400;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.scaffoldBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(
              Icons.attach_file_rounded,
              size: 18,
              color: remove ? muted : AppColors.laoBlue,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$count ໄຟລ໌ແນບ',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: remove ? muted : AppColors.textPrimary,
                  decoration: remove ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: controller.editRemoveFile.toggle,
              icon: Icon(
                remove ? Icons.undo_rounded : Icons.delete_outline_rounded,
                size: 16,
                color: remove ? AppColors.laoBlue : AppColors.rejectRed,
              ),
              label: Text(
                remove ? 'ກູ້ຄືນ' : 'ລຶບ',
                style: TextStyle(
                  fontSize: 12,
                  color: remove ? AppColors.laoBlue : AppColors.rejectRed,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 36),
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// Small caption used as a field label inside [EditNotificationDialog].
class _FieldLabel extends StatelessWidget {
  /// Caption text.
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}

/// Filled, rounded text field used inside [EditNotificationDialog].
class _DialogTextField extends StatelessWidget {
  /// Backing text controller.
  final TextEditingController controller;

  /// Vertical line count.
  final int maxLines;

  const _DialogTextField({required this.controller, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.scaffoldBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: maxLines > 1 ? 12 : 10,
        ),
      ),
    );
  }
}

/// Two-button footer (cancel + confirm) reused by both dialogs.
class _DialogFooter extends StatelessWidget {
  /// Cancel button caption — returns `false`.
  final String cancelLabel;

  /// Confirm button caption — returns `true`.
  final String confirmLabel;

  /// Tint applied to the confirm button.
  final Color confirmColor;

  /// Optional leading icon for the confirm button.
  final IconData? confirmIcon;

  const _DialogFooter({
    required this.cancelLabel,
    required this.confirmLabel,
    required this.confirmColor,
    this.confirmIcon,
  });

  @override
  Widget build(BuildContext context) {
    final confirmChild = confirmIcon == null
        ? Text(confirmLabel, style: const TextStyle(fontSize: 15))
        : null;
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
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(cancelLabel, style: const TextStyle(fontSize: 15)),
          ),
        ),
        const SizedBox(width: AppSpacing.s + 4),
        Expanded(
          child: confirmIcon == null
              ? ElevatedButton(
                  onPressed: () => Get.back(result: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.s + 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: confirmChild!,
                )
              : ElevatedButton.icon(
                  onPressed: () => Get.back(result: true),
                  icon: Icon(confirmIcon, size: 18),
                  label: Text(
                    confirmLabel,
                    style: const TextStyle(fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.s + 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
