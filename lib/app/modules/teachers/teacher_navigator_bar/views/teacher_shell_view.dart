import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../booking/views/booking_view.dart';
import '../../schedules/views/schedules_view.dart';
import '../../teacher_evaluation/views/teacher_evaluation_view.dart';
import '../../teacher_home/views/teacher_home_view.dart';
import '../../teacher_profile/views/teacher_profile_view.dart';
import '../teacher_bottom_nav.dart';
import '../teacher_bottom_nav_controller.dart';

/// Top-level shell for every teacher destination.
///
/// Uses an [IndexedStack] so child screens keep their state when the user
/// switches tabs. Selection state lives in [TeacherBottomNavController];
/// the shell itself stays dumb.
class TeacherShellView extends GetView<TeacherBottomNavController> {
  const TeacherShellView({super.key});

  /// Screens addressed by [TeacherBottomNavController.selectedIndex].
  static const List<Widget> _tabs = <Widget>[
    TeacherHomeView(),
    SchedulesView(),
    BookingView(),
    TeacherEvaluationView(),
    TeacherProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => IndexedStack(
          index: controller.selectedIndex.value,
          children: _tabs,
        ),
      ),
      bottomNavigationBar: const TeacherBottomNavBar(),
    );
  }
}
