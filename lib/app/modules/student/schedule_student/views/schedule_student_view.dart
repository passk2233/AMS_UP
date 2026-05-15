import 'package:flutter/material.dart';
import 'package:frontend/app/widgets/widget.dart';
import 'package:get/get.dart';
import '../controllers/schedule_student_controller.dart';

class ScheduleStudentView extends GetView<ScheduleStudentController> {
  const ScheduleStudentView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ScheduleStudentController>()) {
      Get.put(ScheduleStudentController());
    }

    return GetBuilder<ScheduleStudentController>(
      builder: (controller) => LayoutBuilder(
        builder: (context, constraints) {
          return AppPageScaffold(
            withBackground: true,
            title: 'ຕາຕະລາງຮຽນ',
            body: Column(
              children: [
                _buildSemesterBanner(),
                _buildWeekSelector(),
                const SizedBox(height: 12),
                _buildDateRow(),
                const SizedBox(height: 16),
                Expanded(child: _buildScheduleList()),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSemesterBanner() {
    return Obx(() {
      final label = controller.semesterLabel;
      final range = controller.semesterDateRange;
      if (label.isEmpty && range.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.statsBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppColors.cardRadius),
          ),
          child: Row(
            children: [
              Icon(Icons.event_note_rounded,
                  size: 18, color: AppColors.statsBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (label.isNotEmpty)
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    if (range.isNotEmpty)
                      Text(
                        range,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildWeekSelector() {
    return Obx(() {
      final canPrev = controller.canGoPrevWeek;
      final canNext = controller.canGoNextWeek;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Opacity(
              opacity: canPrev ? 1 : 0.4,
              child: AppIconBubble(
                icon: Icons.chevron_left_rounded,
                onTap: canPrev ? () => controller.changeWeek(-7) : null,
              ),
            ),
            Text(
              controller.currentMonthYear,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Opacity(
              opacity: canNext ? 1 : 0.4,
              child: AppIconBubble(
                icon: Icons.chevron_right_rounded,
                onTap: canNext ? () => controller.changeWeek(7) : null,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildDateRow() {
    const dayLabels = ['ອ', 'ຈ', 'ອ', 'ພ', 'ພຫ', 'ສ', 'ສ'];

    return Obx(() {
      final week = controller.currentWeek;
      final selected = controller.selectedDate.value;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (i) {
            if (i >= week.length) return const SizedBox.shrink();
            final date = week[i];
            final isSelected = date.day == selected.day &&
                date.month == selected.month &&
                date.year == selected.year;
            final isToday = date.day == DateTime.now().day &&
                date.month == DateTime.now().month &&
                date.year == DateTime.now().year;
            final inRange = controller.isInSemester(date);

            return GestureDetector(
              onTap: inRange ? () => controller.selectDate(date) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                constraints: const BoxConstraints(
                  minWidth: AppColors.minTouchTarget,
                  minHeight: 64,
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.statsBlue
                      : isToday && inRange
                          ? AppColors.statsBlue.withValues(alpha: 0.1)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppColors.buttonRadius),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.statsBlue.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Opacity(
                  opacity: inRange ? 1 : 0.35,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dayLabels[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white70
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      );
    });
  }

  Widget _buildScheduleList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const AppLoading.schedule();
      }
      if (controller.errorMessage.value.isNotEmpty &&
          controller.studyPlans.isEmpty) {
        return AppErrorState(
          message: controller.errorMessage.value,
          onRetry: controller.refreshData,
        );
      }

      if (!controller.isInSemester(controller.selectedDate.value)) {
        return const AppEmptyState(
          icon: Icons.event_busy_rounded,
          title: 'ບໍ່ຢູ່ໃນຊ່ວງພາກຮຽນ',
          subtitle: 'ກະລຸນາເລືອກວັນທີຢູ່ໃນຊ່ວງເລີ່ມ ແລະ ສຸດທ້າຍຂອງພາກຮຽນ',
        );
      }

      final schedules = controller.filteredSchedules;

      if (schedules.isEmpty) {
        return const AppEmptyState(
          icon: Icons.event_available_rounded,
          title: 'ບໍ່ມີຫ້ອງຮຽນໃນວັນນີ້',
          subtitle: 'ເລືອກວັນອື່ນເພື່ອເບິ່ງຕາຕະລາງ',
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: schedules.length,
        itemBuilder: (context, index) {
          final item = schedules[index];
          return AppClassCard(
            title: item['title'] as String? ?? '',
            subtitle: item['subtitle'] as String?,
            time: item['time'] as String?,
            instructor: item['instructor'] as String?,
            location: item['location'] as String?,
            color: item['color'] as Color? ?? AppColors.statsBlue,
          );
        },
      );
    });
  }
}
