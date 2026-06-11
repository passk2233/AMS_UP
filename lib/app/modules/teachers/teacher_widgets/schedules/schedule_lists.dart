import 'package:flutter/material.dart';
import 'package:frontend/app/widgets/widget.dart';
import 'package:get/get.dart';

import '../../schedules/controllers/schedules_controller.dart';

/// Loading / error / day / week switch for the teacher schedule body.
class TeacherScheduleList extends StatelessWidget {
  /// Source of reactive schedule state.
  final SchedulesController controller;

  const TeacherScheduleList({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
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
        return _WeekList(controller: controller);
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
}

/// Whole-week class list grouped under date headers.
class _WeekList extends StatelessWidget {
  /// Source of the grouped week schedule.
  final SchedulesController controller;

  const _WeekList({required this.controller});

  @override
  Widget build(BuildContext context) {
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
