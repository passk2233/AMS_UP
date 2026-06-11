import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/widget.dart';
import '../../../data/models/open_evaluation_model.dart';
import '../../evalutions/controllers/evalutions_controller.dart';
import 'eval_mode_toggle.dart';
import 'eval_window_form_dialog.dart';

/// Sub-page where the admin opens/closes the student evaluation window.
class EvalWindowPage extends StatelessWidget {
  /// Source of reactive state.
  final EvalutionController controller;

  const EvalWindowPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        EvalModeToggle(controller: controller),
        Expanded(
          child: Obx(() {
            if (controller.isLoadingWindow.value &&
                controller.openWindows.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.windowError.isNotEmpty &&
                controller.openWindows.isEmpty) {
              return AppErrorState(
                message: controller.windowError.value,
                onRetry: controller.fetchOpenWindow,
              );
            }
            return RefreshIndicator(
              onRefresh: controller.fetchOpenWindow,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                children: [
                  _WindowStatusCard(controller: controller),
                  const SizedBox(height: 16),
                  _WindowActions(controller: controller),
                  const SizedBox(height: 16),
                  _WindowHistorySection(controller: controller),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// Headline card showing the current state of the evaluation window.
class _WindowStatusCard extends StatelessWidget {
  /// Source of reactive state.
  final EvalutionController controller;

  const _WindowStatusCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final current = controller.currentWindow;
      final isOpen = controller.isEvaluationOpen;
      final accent = isOpen
          ? AppColors.borderApproved
          : AppColors.textSecondary;
      final statusLabel = isOpen ? 'ເປີດໃຊ້ງານຢູ່' : 'ປິດ';
      final icon = isOpen
          ? Icons.lock_open_rounded
          : Icons.lock_outline_rounded;

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppColors.cardRadius),
          border: Border(left: BorderSide(color: accent, width: 4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 22, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ສະຖານະການປະເມີນ',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (current != null) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _WindowRow(
                label: 'ເປີດ',
                value: current.openTime != null
                    ? _fmt(current.openTime!)
                    : 'ບໍ່ໄດ້ກຳນົດ',
              ),
              const SizedBox(height: 6),
              _WindowRow(
                label: 'ປິດ',
                value: current.closeTime != null
                    ? _fmt(current.closeTime!)
                    : 'ບໍ່ໄດ້ກຳນົດ',
              ),
            ],
          ],
        ),
      );
    });
  }

  static String _fmt(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year} '
        '${two(dt.hour)}:${two(dt.minute)}';
  }
}

/// One label/value row inside [_WindowStatusCard].
class _WindowRow extends StatelessWidget {
  /// Left-side label.
  final String label;

  /// Right-side value.
  final String value;

  const _WindowRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

/// Open / close call-to-action row under the status card.
class _WindowActions extends StatelessWidget {
  /// Source of reactive state.
  final EvalutionController controller;

  const _WindowActions({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isOpen = controller.isEvaluationOpen;
      final saving = controller.isSavingWindow.value;

      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: saving
                  ? null
                  : () async {
                      controller.prepareWindowForm();
                      final ok = await Get.dialog<bool>(
                        EvalWindowFormDialog(controller: controller),
                        barrierDismissible: false,
                      );
                      if (ok == true) await controller.openEvaluation();
                    },
              icon: Icon(
                isOpen ? Icons.edit_calendar_outlined : Icons.event_available,
                size: 18,
              ),
              label: Text(isOpen ? 'ແກ້ໄຂ / ຕໍ່ເວລາ' : 'ເປີດການປະເມີນ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.laoBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
          if (isOpen) ...[
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: saving ? null : controller.closeEvaluation,
                icon: const Icon(Icons.lock_outline_rounded, size: 18),
                label: const Text('ປິດການປະເມີນ'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.rejectRed,
                  side: const BorderSide(color: AppColors.rejectRed),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    });
  }
}

/// Past windows listed under the active one.
class _WindowHistorySection extends StatelessWidget {
  /// Source of reactive state.
  final EvalutionController controller;

  const _WindowHistorySection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final history = controller.openWindows.length > 1
          ? controller.openWindows.sublist(1)
          : const <OpenEvaluationModel>[];
      if (history.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'ປະຫວັດໄລຍະການປະເມີນ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          for (final w in history) _WindowHistoryTile(window: w),
        ],
      );
    });
  }
}

/// One closed-window history card.
class _WindowHistoryTile extends StatelessWidget {
  /// Window row to render.
  final OpenEvaluationModel window;

  const _WindowHistoryTile({required this.window});

  @override
  Widget build(BuildContext context) {
    String fmt(DateTime? dt) {
      if (dt == null) return '-';
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(dt.day)}/${two(dt.month)}/${dt.year}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.history_rounded, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${fmt(window.openTime)} → ${fmt(window.closeTime)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            window.inactive == 0 ? 'ເປີດ' : 'ປິດ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: window.inactive == 0
                  ? AppColors.borderApproved
                  : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
