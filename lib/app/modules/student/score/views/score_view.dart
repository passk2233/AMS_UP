import 'package:flutter/material.dart';
import 'package:frontend/app/widgets/widget.dart';
import 'package:get/get.dart';

import '../../student_widgets/score/score_list.dart';
import '../../student_widgets/score/semester_chips.dart';
import '../../student_widgets/score/semester_summary_card.dart';
import '../../student_widgets/score/transcript_stat_strip.dart';
import '../controllers/score_controller.dart';

class ScoreView extends GetView<ScoreController> {
  const ScoreView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ScoreController>()) {
      Get.put(ScoreController());
    }

    return AppPageScaffold(
      withBackground: true,
      title: 'ຄະແນນ',
      trailing: const NotiBellButton(route: '/student-noti'),
      body: Obx(() {
        if (controller.isLoading.value) {
          return AppRefreshableLoader(
            onRefresh: controller.fetchData,
            child: const AppLoading.score(),
          );
        }
        if (controller.errorMessage.value.isNotEmpty) {
          return AppErrorState(
            message: controller.errorMessage.value,
            onRetry: controller.fetchData,
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchData,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppProfileHeader(
                  name: controller.displayName,
                  subtitle: controller.studentCode,
                  caption: _captionText(),
                  photo: controller.photo,
                ),
                const SizedBox(height: AppSpacing.m),
                TranscriptStatStrip(
                  cells: [
                    TranscriptStatCell(
                      value: controller.totalSubjects.toString(),
                      label: 'ລວມວິຊາ',
                      color: AppColors.statsBlue,
                    ),
                    TranscriptStatCell(
                      value: controller.totalCredits.toString(),
                      label: 'ລວມໜ່ວຍກິດ',
                      color: AppColors.accentGreen,
                    ),
                    TranscriptStatCell(
                      value: controller.gpa.toStringAsFixed(2),
                      label: 'ເກຣດສະເລ່ຍລວມ',
                      // White value sits on this fill; bright primary is 2.43:1,
                      // the on-fill teal clears AA at 4.70:1. See DESIGN.md.
                      color: AppColors.primaryFill,
                    ),
                    TranscriptStatCell(
                      value:
                          '${controller.currentTermNumber}/${controller.totalProgramTerms}',
                      label: 'ເທີມ',
                      color: AppColors.accentYellow,
                      valueColor: AppColors.textPrimary,
                      labelColor: AppColors.textPrimary,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.l),
                const Text("ຄະແນນແຕ່ລະພາກຮຽນ", style: AppTypography.subheading),
                const SizedBox(height: AppSpacing.s + 2),
                SemesterChips(controller: controller),
                const Divider(height: 28),
                _buildSelectedSemester(),
              ],
            ),
          ),
        );
      }),
    );
  }

  String _captionText() {
    final curri = controller.curriculumName;
    final year = controller.currentAcademicYear;
    if (year <= 0) return curri;
    return '$curri · ປີ $year';
  }

  Widget _buildSelectedSemester() {
    // No grouping available — show every enrollment as a flat list.
    if (controller.semesters.isEmpty) {
      return ScoreList(items: controller.enrollments);
    }

    final semester = controller.selectedSemester;
    if (semester == null) {
      return const AppEmptyState(
        icon: Icons.school_outlined,
        title: 'ບໍ່ພົບຄະແນນ',
        subtitle: 'ຄະແນນຈະສະແດງຢູ່ບ່ອນນີ້',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          controller.labelFor(semester),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.s + 4),
        ScoreList(items: semester.enrollments),
        const SizedBox(height: AppSpacing.xs),
        SemesterSummaryCard(controller: controller),
      ],
    );
  }
}
