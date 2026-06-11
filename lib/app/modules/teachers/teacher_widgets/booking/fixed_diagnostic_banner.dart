import 'package:flutter/material.dart';

import '../../../../widgets/widget.dart';
import '../../booking/controllers/booking_controller.dart';

/// Empty-state banner shown when a teacher has no fixed class occurrences.
/// The list is derived purely from study plans (semester window × weekday
/// expansion), so the gap is always one of: no active semester, semester
/// missing dates, account not linked to a teacher, or no study plans
/// assigned — surface those inputs instead of an empty silent list.
class FixedDiagnosticBanner extends StatelessWidget {
  /// Source of the schedule-input state.
  final BookingController controller;

  const FixedDiagnosticBanner({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final sem = c.activeSemester.value;
    final user = c.currentUser.value;

    String semLine;
    if (sem == null) {
      semLine = 'ບໍ່ມີ (none)';
    } else if (sem.startDate == null || sem.endDate == null) {
      semLine = '${sem.semasterCode} — ບໍ່ມີວັນທີ';
    } else {
      final s = sem.startDate!;
      final e = sem.endDate!;
      semLine =
          '${sem.semasterCode} '
          '(${s.day}/${s.month}/${s.year} → ${e.day}/${e.month}/${e.year})';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.borderPending.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderPending.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.borderPending,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'ບໍ່ມີຄາບການຮຽນປະຈຳ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'ຄາບການຮຽນສ້າງຈາກ study_plan ຂອງອາຈານໃນພາກຮຽນປັດຈຸບັນ. '
            'ກວດສະຖານະຂ້າງລຸ່ມ ແລ້ວກົດ ດຶງຂໍ້ມູນຄືນ.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
          ),
          const SizedBox(height: AppSpacing.s),
          _KeyValueRow(label: 'ພາກຮຽນ:', value: semLine),
          _KeyValueRow(
            label: 'ລະຫັດອາຈານ:',
            value: user?.teacherId?.toString() ?? 'ບໍ່ມີ (ບໍ່ແມ່ນບັນຊີອາຈານ)',
          ),
          _KeyValueRow(
            label: 'ແຜນການສຶກສາໂຫຼດ:',
            value: '${c.studyPlans.length}',
          ),
          const SizedBox(height: AppSpacing.m),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: c.resyncFixedBookings,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('ດຶງຂໍ້ມູນຄືນ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryFill,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.m,
                  vertical: AppSpacing.s,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One label/value row inside [FixedDiagnosticBanner].
class _KeyValueRow extends StatelessWidget {
  /// Left-side label.
  final String label;

  /// Right-side value.
  final String value;

  const _KeyValueRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
