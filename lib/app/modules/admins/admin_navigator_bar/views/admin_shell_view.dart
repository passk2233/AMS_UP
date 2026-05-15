import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../bottom_nav_controller.dart';
import '../admin_bottom_nav.dart';

import '../../home/views/home_view.dart';
import '../../approve/views/approve_view.dart';
import '../../announcement/views/announcement_view.dart';
import '../../evalutions/views/evalutions_view.dart';
import '../../admin_profile/views/admin_profile_view.dart';

class AdminShellView extends GetView<BottomNavController> {
  const AdminShellView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BottomNavController>(
      builder: (controller) => LayoutBuilder(builder: (context, constraints) {
        return Scaffold(
          body: Obx(() {
            return IndexedStack(
              index: controller.selectedIndex.value,
              children: const [
                AdminHomeView(),
                ApproveView(),
                AnnouncementView(),
                EvalutionView(),
                AdminProfileView(),
              ],
            );
          }),
          bottomNavigationBar: const AdminBottomNavBar(),
        );
      }),
    );
  }
}
