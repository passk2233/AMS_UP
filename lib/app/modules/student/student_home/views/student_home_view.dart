import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/widget.dart';
import '../controllers/student_home_controller.dart';

class HomeStudentView extends GetView<HomeStudentController> {
  const HomeStudentView({super.key});
  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeStudentController>(
      builder: (controller) => LayoutBuilder(
        builder: (context, constraints) {
          return Scaffold(
            body: Obx(() => controller.currentPage),
            bottomNavigationBar: Obx(
              () => AppBottomNav(
                selectedIndex: controller.selectedIndex.value,
                onTap: controller.changePage,
                items: const [
                  AppNavItem(icon: Icons.home_rounded, label: 'ໜ້າຫຼັກ'),
                  AppNavItem(icon: Icons.calendar_month_rounded, label: 'ຕາຕະລາງ'),
                  AppNavItem(icon: Icons.meeting_room_rounded, label: 'ຈອງຫ້ອງ'),
                  AppNavItem(icon: Icons.star_rounded, label: 'ຄະແນນ'),
                  AppNavItem(icon: Icons.person_rounded, label: 'ໂປຣໄຟລ໌'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
