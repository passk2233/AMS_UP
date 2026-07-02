import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:frontend/app/widgets/widget.dart';

import '../../teacher_widgets/evaluation/overall_score_card.dart';
import '../../teacher_widgets/evaluation/semester_trend_card.dart';
import '../../teacher_widgets/evaluation/subject_eval_card.dart';
import '../controllers/teacher_evaluation_controller.dart';

class TeacherEvaluationView extends GetView<TeacherEvaluationController> {
  const TeacherEvaluationView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TeacherEvaluationController>(
      builder: (controller) => LayoutBuilder(
        builder: (context, constraints) {
          return AppPageScaffold(
            title: 'ການປະເມີນ',
            topBar: const AppTopBar(notiRoute: '/teacher-noti'),
            body: Obx(() {
              if (controller.isLoading.value) {
                return AppRefreshableLoader(
                  onRefresh: controller.refreshData,
                  child: const AppLoading.evaluation(),
                );
              }

              final err = controller.errorMessage.value;
              if (err.isNotEmpty) {
                return AppErrorState(
                  message: err,
                  onRetry: controller.refreshData,
                );
              }

              return RefreshIndicator(
                onRefresh: controller.refreshData,
                color: AppColors.primary,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    // ເບິ່ງຍ້ອນຫຼັງແຕ່ລະເທີມ — filters every stat + card below.
                    if (controller.semesterOptions.isNotEmpty) ...[
                      _SemesterFilterChips(controller: controller),
                      const SizedBox(height: AppSpacing.s),
                    ],
                    OverallScoreCard(average: controller.overallAverage),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AppStatCard(
                            label: 'ການປະເມີນ',
                            value: '${controller.totalEvaluations}',
                            icon: Icons.people_alt_outlined,
                            color: AppColors.statsBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppStatCard(
                            label: 'ວິຊາ',
                            value: '${controller.totalSubjects}',
                            icon: Icons.menu_book_rounded,
                            color: AppColors.borderPending,
                          ),
                        ),
                      ],
                    ),
                    // Trend compares the two most recent semesters, so it only
                    // makes sense on the unfiltered view.
                    if (controller.selectedSemesterId.value == 0 &&
                        controller.semesterTrendDelta != null) ...[
                      const SizedBox(height: 12),
                      SemesterTrendCard(
                        current: controller.currentSemesterAverage ?? 0,
                        previous: controller.previousSemesterAverage ?? 0,
                        delta: controller.semesterTrendDelta!,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.l),
                    const Padding(
                      padding: EdgeInsets.only(
                        left: 4,
                        bottom: AppSpacing.s + 4,
                      ),
                      child: Text(
                        'ການປະເມີນແຕ່ລະວິຊາ',
                        style: AppTypography.heading,
                      ),
                    ),
                    ...controller.subjectGroups.map(
                      (g) => SubjectEvalCard(group: g),
                    ),
                    if (controller.subjectGroups.isEmpty)
                      AppEmptyState(
                        icon: Icons.insert_chart_outlined,
                        title: controller.selectedSemesterId.value == 0
                            ? 'ຍັງບໍ່ມີຂໍ້ມູນການປະເມີນ'
                            : 'ບໍ່ມີຂໍ້ມູນການປະເມີນໃນເທີມນີ້',
                      ),
                  ],
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

/// Horizontal chip row: "ທັງໝົດ" + one chip per semester found in the data.
class _SemesterFilterChips extends StatelessWidget {
  final TeacherEvaluationController controller;

  const _SemesterFilterChips({required this.controller});

  @override
  Widget build(BuildContext context) {
    final options = controller.semesterOptions;
    final selectedIndex =
        1 + options.indexWhere((s) => s.id == controller.selectedSemesterId.value);
    return AppFilterChipRow(
      items: [
        const AppFilterChip(label: 'ທັງໝົດ'),
        for (final s in options) AppFilterChip(label: s.label),
      ],
      selectedIndex: selectedIndex < 1 ? 0 : selectedIndex,
      onSelected: (i) =>
          controller.selectSemester(i == 0 ? 0 : options[i - 1].id),
      activeColor: AppColors.primary,
      padding: EdgeInsets.zero,
    );
  }
}
