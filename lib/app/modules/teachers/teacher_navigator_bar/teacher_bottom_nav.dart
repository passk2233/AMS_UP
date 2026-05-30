import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../widgets/widget.dart';
import 'teacher_bottom_nav_controller.dart';

/// Teacher-specific wrapper around [AppBottomNav].
///
/// Wires the five teacher destinations to [TeacherBottomNavController].
/// The controller is resolved (or registered) via GetX so this bar is safe
/// to drop into any teacher Scaffold's `bottomNavigationBar`.
class TeacherBottomNavBar extends StatelessWidget {
  const TeacherBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final navCtrl = Get.isRegistered<TeacherBottomNavController>()
        ? Get.find<TeacherBottomNavController>()
        : Get.put(TeacherBottomNavController(), permanent: true);

    return Obx(
      () => AppBottomNav(
        selectedIndex: navCtrl.selectedIndex.value,
        onTap: navCtrl.changeTab,
        items: const [
          AppNavItem(icon: Icons.home_rounded, label: 'ໜ້າຫຼັກ'),
          AppNavItem(icon: Icons.calendar_month_rounded, label: 'ຕາຕະລາງ'),
          AppNavItem(icon: Icons.meeting_room_rounded, label: 'ຈອງຫ້ອງ'),
          AppNavItem(icon: Icons.bar_chart_rounded, label: 'ປະເມີນ'),
          AppNavItem(icon: Icons.person_rounded, label: 'ໂປຣໄຟລ໌'),
        ],
      ),
    );
  }
}
