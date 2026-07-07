import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../widgets/widget.dart';
import '../../../data/models/class_cancellation_model.dart';
import '../../../data/models/study_plan_model.dart';
import '../../schedules/controllers/schedules_controller.dart';

/// Bottom sheet with one class occurrence's details. Active occurrences get
/// a cancel action; already-cancelled ones ([cancellation] non-null) get a
/// restore action instead.
Future<void> showClassDetailSheet(
  BuildContext context, {
  required SchedulesController controller,
  required StudyPlanModel plan,
  required DateTime date,
  ClassCancellationModel? cancellation,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ClassDetailSheet(
      controller: controller,
      plan: plan,
      date: date,
      cancellation: cancellation,
    ),
  );
}

class _ClassDetailSheet extends StatefulWidget {
  final SchedulesController controller;
  final StudyPlanModel plan;
  final DateTime date;
  final ClassCancellationModel? cancellation;

  const _ClassDetailSheet({
    required this.controller,
    required this.plan,
    required this.date,
    this.cancellation,
  });

  @override
  State<_ClassDetailSheet> createState() => _ClassDetailSheetState();
}

class _ClassDetailSheetState extends State<_ClassDetailSheet> {
  final _reasonCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmCancel() async {
    final ok = await AppDialogs.showConfirmation(
      title: 'ຍົກເລີກຄລາສ?',
      message:
          'ຄລາສນີ້ຈະຖືກຍົກເລີກສະເພາະວັນທີ ${DateFormat('dd/MM/yyyy').format(widget.date)} ແລະ ຫາຍໄປຈາກຕາຕະລາງສອນ',
      confirmText: 'ຍົກເລີກຄລາສ',
      confirmColor: AppColors.danger,
    );
    if (ok != true || !mounted) return;

    setState(() => _submitting = true);
    final success = await widget.controller.cancelClass(
      widget.plan,
      widget.date,
      reason: _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      Get.back(); // close the sheet
      AppDialogs.showSuccess(
        title: 'ຍົກເລີກສຳເລັດ',
        message: 'ຄລາສຖືກຍົກເລີກແລ້ວ ສາມາດກົດຄລາສເພື່ອກູ້ຄືນໄດ້',
      );
    } else {
      AppDialogs.showError(
        title: 'ຍົກເລີກບໍ່ສຳເລັດ',
        message: 'ບໍ່ສາມາດຍົກເລີກຄລາສໄດ້ ກະລຸນາລອງໃໝ່',
      );
    }
  }

  Future<void> _confirmRestore() async {
    final cancellation = widget.cancellation;
    if (cancellation == null) return;
    final ok = await AppDialogs.showConfirmation(
      title: 'ກູ້ຄືນຄລາສ?',
      message:
          'ຄລາສວັນທີ ${DateFormat('dd/MM/yyyy').format(widget.date)} ຈະກັບມາສອນຕາມປົກກະຕິ',
      confirmText: 'ກູ້ຄືນຄລາສ',
      confirmColor: AppColors.success,
    );
    if (ok != true || !mounted) return;

    setState(() => _submitting = true);
    final success = await widget.controller.restoreClass(cancellation);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      Get.back(); // close the sheet
      AppDialogs.showSuccess(
        title: 'ກູ້ຄືນສຳເລັດ',
        message: 'ຄລາສກັບມາຢູ່ໃນຕາຕະລາງສອນຕາມປົກກະຕິແລ້ວ',
      );
    } else {
      AppDialogs.showError(
        title: 'ກູ້ຄືນບໍ່ສຳເລັດ',
        message: 'ບໍ່ສາມາດກູ້ຄືນຄລາສໄດ້ ກະລຸນາລອງໃໝ່',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final subject = plan.subject?.nameLao ?? plan.subject?.nameEng ?? 'ວິຊາ';
    final code = plan.subject?.subjectCode ?? '';
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '$subject${code.isNotEmpty ? ' ($code)' : ''}',
              style: AppTypography.heading,
            ),
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.calendar_today_rounded,
              label: 'ວັນທີ',
              value: DateFormat('dd/MM/yyyy').format(widget.date),
            ),
            _DetailRow(
              icon: Icons.access_time_rounded,
              label: 'ເວລາ',
              value: '${plan.startTime ?? '-'} - ${plan.endTime ?? '-'}',
            ),
            _DetailRow(
              icon: Icons.meeting_room_rounded,
              label: 'ຫ້ອງ',
              value: plan.room?.roomCode ?? '-',
            ),
            _DetailRow(
              icon: Icons.groups_rounded,
              label: 'ກຸ່ມນັກສຶກສາ',
              value: plan.studentGroup?.stdGroupName ?? '-',
            ),
            if (widget.cancellation != null) ...[
              _DetailRow(
                icon: Icons.info_outline_rounded,
                label: 'ເຫດຜົນການຍົກເລີກ',
                value: widget.cancellation!.reason?.trim().isNotEmpty == true
                    ? widget.cancellation!.reason!
                    : '-',
              ),
              const SizedBox(height: 16),
              _ActionButton(
                submitting: _submitting,
                color: AppColors.success,
                icon: Icons.restore_rounded,
                label: 'ກູ້ຄືນຄລາສນີ້',
                busyLabel: 'ກຳລັງກູ້ຄືນ...',
                onPressed: _confirmRestore,
              ),
            ] else ...[
              const SizedBox(height: 16),
              TextField(
                controller: _reasonCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'ເຫດຜົນການຍົກເລີກ (ບໍ່ບັງຄັບ)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _ActionButton(
                submitting: _submitting,
                color: AppColors.danger,
                icon: Icons.event_busy_rounded,
                label: 'ຍົກເລີກຄລາສນີ້',
                busyLabel: 'ກຳລັງຍົກເລີກ...',
                onPressed: _confirmCancel,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Full-width sheet action button with a busy spinner state.
class _ActionButton extends StatelessWidget {
  final bool submitting;
  final Color color;
  final IconData icon;
  final String label;
  final String busyLabel;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.submitting,
    required this.color,
    required this.icon,
    required this.label,
    required this.busyLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: submitting ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: submitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon),
        label: Text(submitting ? busyLabel : label),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.info),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
