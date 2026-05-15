import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../teacher_bottom_nav_controller.dart';
import '../teacher_bottom_nav.dart';

import '../../teacher_home/views/teacher_home_view.dart';
import '../../schedules/views/schedules_view.dart';
import '../../booking/views/booking_view.dart';
import '../../teacher_evaluation/views/teacher_evaluation_view.dart';
import '../../teacher_profile/views/teacher_profile_view.dart';

class TeacherShellView extends GetView<TeacherBottomNavController> {
  const TeacherShellView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TeacherBottomNavController>(
      builder: (controller) => LayoutBuilder(
        builder: (context, constraints) {
          return Scaffold(
            body: Obx(() {
              return IndexedStack(
                index: controller.selectedIndex.value,
                children: const [
                  TeacherHomeView(),
                  SchedulesView(),
                  BookingView(),
                  TeacherEvaluationView(),
                  TeacherProfileView(),
                ],
              );
            }),
            bottomNavigationBar: const TeacherBottomNavBar(),
          );
        },
      ),
    );
  }
}

