import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/widget.dart';
import '../../evalutions/controllers/evalutions_controller.dart';
import 'eval_mode_toggle.dart';
import 'eval_teacher_card.dart';

/// Teacher list page (the second mode).
class EvalResultsPage extends StatelessWidget {
  /// Source of reactive state.
  final EvalutionController controller;

  const EvalResultsPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        EvalModeToggle(controller: controller),
        Expanded(
          child: Obx(() {
            if (controller.isLoadingResults.value) {
              return const AppLoading.resultsList();
            }
            if (controller.resultsError.isNotEmpty &&
                controller.results.isEmpty) {
              return AppErrorState(
                message: controller.resultsError.value,
                onRetry: controller.fetchResults,
              );
            }
            return _TeacherListSection(controller: controller);
          }),
        ),
      ],
    );
  }
}

/// Search bar + the filtered list of teachers.
class _TeacherListSection extends StatelessWidget {
  /// Source of reactive state.
  final EvalutionController controller;

  const _TeacherListSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Obx(
            () => AppSearchBar(
              hint: 'ຄົ້ນຫາ ຊື່ອາຈານ, ລະຫັດ, ພາກ...',
              controller: controller.teacherSearchCtrl,
              onChanged: controller.onTeacherSearchChanged,
              currentQuery: controller.teacherSearch.value,
              onClear: controller.clearTeacherSearch,
            ),
          ),
        ),
        // Semester filter — same picker the web admin page has.
        Obx(() {
          final options = controller.semesterOptions;
          if (options.isEmpty) return const SizedBox.shrink();
          final selectedIndex = 1 +
              options.indexWhere(
                (s) => s.id == controller.selectedSemesterId.value,
              );
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppFilterChipRow(
              items: [
                const AppFilterChip(label: 'ທັງໝົດ'),
                for (final s in options) AppFilterChip(label: s.label),
              ],
              selectedIndex: selectedIndex < 1 ? 0 : selectedIndex,
              onSelected: (i) =>
                  controller.selectSemester(i == 0 ? 0 : options[i - 1].id),
              activeColor: AppColors.laoBlue,
              padding: EdgeInsets.zero,
            ),
          );
        }),
        Expanded(
          child: Obx(() {
            final list = controller.filteredSummaries;
            if (list.isEmpty && controller.results.isEmpty) {
              return const AppEmptyState(
                icon: Icons.bar_chart_rounded,
                title: 'ຍັງບໍ່ມີຜົນການປະເມີນ',
              );
            }
            if (list.isEmpty) {
              return AppEmptyState(
                icon: Icons.search_off_rounded,
                title: controller.teacherSearch.value.isEmpty &&
                        controller.selectedSemesterId.value != 0
                    ? 'ບໍ່ມີຂໍ້ມູນການປະເມີນໃນເທີມນີ້'
                    : 'ບໍ່ພົບຜົນການຄົ້ນຫາ',
              );
            }
            return RefreshIndicator(
              onRefresh: controller.fetchResults,
              color: AppColors.primary,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                itemCount: list.length,
                itemBuilder: (_, i) => EvalTeacherCard(
                  summary: list[i],
                  rank: i + 1,
                  onTap: () => controller.openTeacherDetail(list[i]),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
