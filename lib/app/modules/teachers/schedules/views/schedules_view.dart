import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:frontend/app/widgets/widget.dart';

import '../controllers/schedules_controller.dart';

class SchedulesView extends GetView<SchedulesController> {
  const SchedulesView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SchedulesController>()) {
      Get.put(SchedulesController());
    }

    return GetBuilder<SchedulesController>(
      builder: (controller) => LayoutBuilder(
        builder: (context, constraints) {
          return AppPageScaffold(
            withBackground: true,
            title: 'ຕາຕະລາງສອນ',
            trailing: const NotiBellButton(route: '/teacher-noti'),
            body: Column(
              children: [
                _buildSemesterBanner(controller),
                _buildViewModeToggle(controller),
                _buildWeekSelector(controller),
                const SizedBox(height: 12),
                Obx(() => controller.viewMode.value == 'day'
                    ? _buildDateRow(controller)
                    : const SizedBox.shrink()),
                const SizedBox(height: 16),
                Expanded(child: _buildScheduleList(controller)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSemesterBanner(SchedulesController controller) {
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

  Widget _buildViewModeToggle(SchedulesController controller) {
    return Obx(() {
      Widget seg(String mode, String label, IconData icon) {
        final selected = controller.viewMode.value == mode;
        return Expanded(
          child: GestureDetector(
            onTap: () => controller.viewMode.value = mode,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.statsBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon,
                      size: 16,
                      color: selected ? Colors.white : AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          selected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              seg('day', 'ມື້ດຽວ', Icons.today_rounded),
              seg('week', 'ທັງອາທິດ', Icons.view_week_rounded),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildWeekSelector(SchedulesController controller) {
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

  Widget _buildDateRow(SchedulesController controller) {
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

  Widget _buildScheduleList(SchedulesController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return AppRefreshableLoader(
          onRefresh: controller.refreshData,
          child: const AppLoading.schedule(),
        );
      }
      if (controller.errorMessage.value.isNotEmpty &&
          controller.schedules.isEmpty) {
        return AppErrorState(
          message: controller.errorMessage.value,
          onRetry: controller.refreshData,
        );
      }

      if (controller.viewMode.value == 'week') {
        return _buildWeekList(controller);
      }

      if (!controller.isInSemester(controller.selectedDate.value)) {
        return RefreshIndicator(
          onRefresh: controller.refreshData,
          color: AppColors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 60),
              AppEmptyState(
                icon: Icons.event_busy_rounded,
                title: 'ບໍ່ຢູ່ໃນຊ່ວງພາກຮຽນ',
                subtitle: 'ກະລຸນາເລືອກວັນທີຢູ່ໃນຊ່ວງເລີ່ມ ແລະ ສຸດທ້າຍຂອງພາກຮຽນ',
              ),
            ],
          ),
        );
      }

      final filtered = controller.filteredSchedules;

      if (filtered.isEmpty) {
        return AppEmptyState(
          icon: Icons.event_available_rounded,
          title: 'ບໍ່ມີຫ້ອງຮຽນໃນວັນນີ້',
          subtitle: 'ເລືອກວັນອື່ນເພື່ອເບິ່ງຕາຕະລາງ',
          actionLabel: 'ກັບໄປວັນນີ້',
          actionIcon: Icons.today_rounded,
          onAction: () => controller.selectDate(DateTime.now()),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.refreshData,
        color: AppColors.primary,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final item = filtered[index];
            return AppClassCard(
              title: item['title'] as String? ?? '',
              subtitle: item['subtitle'] as String?,
              time: item['time'] as String?,
              instructor: item['instructor'] as String?,
              location: item['location'] as String?,
              color: item['color'] as Color? ?? AppColors.statsBlue,
            );
          },
        ),
      );
    });
  }

  Widget _buildWeekList(SchedulesController controller) {
    final groups = controller.weekScheduleByDay;
    if (groups.isEmpty) {
      return AppEmptyState(
        icon: Icons.event_available_rounded,
        title: 'ບໍ່ມີຫ້ອງຮຽນໃນອາທິດນີ້',
        subtitle: 'ລອງເປີດອາທິດອື່ນ',
        actionLabel: 'ກັບໄປວັນນີ້',
        actionIcon: Icons.today_rounded,
        onAction: () => controller.selectDate(DateTime.now()),
      );
    }
    return RefreshIndicator(
      onRefresh: controller.refreshData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          final classes = group['classes'] as List<Map<String, dynamic>>;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  group['dateLabel'] as String? ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              ...classes.map((item) => AppClassCard(
                    title: item['title'] as String? ?? '',
                    subtitle: item['subtitle'] as String?,
                    time: item['time'] as String?,
                    instructor: item['instructor'] as String?,
                    location: item['location'] as String?,
                    color: item['color'] as Color? ?? AppColors.statsBlue,
                  )),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }
}
