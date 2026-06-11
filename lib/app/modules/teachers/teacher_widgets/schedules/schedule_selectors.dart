import 'package:flutter/material.dart';
import 'package:frontend/app/widgets/widget.dart';
import 'package:get/get.dart';

import '../../schedules/controllers/schedules_controller.dart';

/// Day / week segmented toggle.
class ScheduleViewModeToggle extends StatelessWidget {
  /// Source of the reactive view mode.
  final SchedulesController controller;

  const ScheduleViewModeToggle({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
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
}

/// Previous / next week arrows around the current month-year label.
class ScheduleWeekSelector extends StatelessWidget {
  /// Source of week navigation state.
  final SchedulesController controller;

  const ScheduleWeekSelector({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
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
}

/// Seven-day date strip for day mode — highlights today and the selection,
/// dims days outside the semester range.
class ScheduleDateRow extends StatelessWidget {
  /// Source of week + selection state.
  final SchedulesController controller;

  const ScheduleDateRow({super.key, required this.controller});

  static const _dayLabels = ['ອ', 'ຈ', 'ອ', 'ພ', 'ພຫ', 'ສ', 'ສ'];

  @override
  Widget build(BuildContext context) {
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
                        _dayLabels[i],
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
}
