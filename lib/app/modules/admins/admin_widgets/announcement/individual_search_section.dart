import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/widget.dart';
import '../../../data/models/student_model.dart';
import '../../announcement/controllers/announcement_controller.dart';
import 'announcement_form_blocks.dart';

/// Individual-student lookup field + lookup result card.
class IndividualSearchSection extends StatelessWidget {
  /// Source of reactive search state.
  final AnnouncementController controller;

  const IndividualSearchSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AnnFieldLabel('ຄົ້ນຫານັກສຶກສາ (ລະຫັດ ຫຼື ຊື່)'),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: AnnFilledTextField(
                controller: controller.individualSearchCtrl,
                hint: 'ເຊັ່ນ: 64010001 ຫຼື ຊື່ນັກສຶກສາ',
                keyboardType: TextInputType.text,
              ),
            ),
            const SizedBox(width: 8),
            Obx(
              () => SizedBox(
                height: AppColors.minTouchTarget,
                child: ElevatedButton.icon(
                  onPressed: controller.isSearching.value
                      ? null
                      : controller.searchStudents,
                  icon: controller.isSearching.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.search, size: 18),
                  label: const Text('ຄົ້ນຫາ', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.laoBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Obx(() {
          final selected = controller.foundStudent.value;
          if (selected != null) {
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _FoundStudentCard(
                student: selected,
                onClear: controller.clearIndividualSelection,
              ),
            );
          }

          final results = controller.searchResults;
          if (results.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnnFieldLabel('ຜົນການຄົ້ນຫາ (${results.length})'),
                const SizedBox(height: 6),
                for (final s in results)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _StudentResultRow(
                      student: s,
                      onTap: () => controller.selectStudent(s),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

/// Tappable row for one search match — picks the student as the recipient.
class _StudentResultRow extends StatelessWidget {
  /// The matched student.
  final StudentModel student;

  /// Selects this student.
  final VoidCallback onTap;

  const _StudentResultRow({required this.student, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = student;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.scaffoldBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.laoBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.laoBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${s.nameLao} ${s.surnameLao ?? ''}'.trim(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ລະຫັດ: ${s.stdCode}  •  ກຸ່ມ: ${s.studentGroup?.stdGroupName ?? '-'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }
}

/// Green-tinted card summarizing the selected student.
class _FoundStudentCard extends StatelessWidget {
  /// The selected student.
  final StudentModel student;

  /// Tap handler for the close button.
  final VoidCallback onClear;

  const _FoundStudentCard({required this.student, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final s = student;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.borderApproved.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.borderApproved.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.borderApproved.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.borderApproved,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${s.nameLao} ${s.surnameLao ?? ''}'.trim(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ລະຫັດ: ${s.stdCode}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  'ກຸ່ມ: ${s.studentGroup?.stdGroupName ?? '-'}  •  ປະເພດ: ${s.studentType?.stdTypeNameLao ?? '-'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
