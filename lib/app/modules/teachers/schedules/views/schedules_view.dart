import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:frontend/app/widgets/widget.dart';

import '../../teacher_widgets/schedules/schedule_lists.dart';
import '../../teacher_widgets/schedules/schedule_selectors.dart';
import '../../teacher_widgets/schedules/semester_banner.dart';
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
                SemesterBanner(controller: controller),
                ScheduleViewModeToggle(controller: controller),
                ScheduleWeekSelector(controller: controller),
                const SizedBox(height: 12),
                Obx(() => controller.viewMode.value == 'day'
                    ? ScheduleDateRow(controller: controller)
                    : const SizedBox.shrink()),
                const SizedBox(height: 16),
                Expanded(child: TeacherScheduleList(controller: controller)),
              ],
            ),
          );
        },
      ),
    );
  }
}
