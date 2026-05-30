import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../admin_profile/views/admin_profile_view.dart';
import '../../announcement/views/announcement_view.dart';
import '../../approve/views/approve_view.dart';
import '../../evalutions/views/evalutions_view.dart';
import '../../home/views/home_view.dart';
import '../admin_bottom_nav.dart';
import '../bottom_nav_controller.dart';

/// Top-level shell for every admin destination.
///
/// Uses an [IndexedStack] so child screens keep their state when the admin
/// switches tabs. Selection state lives in [BottomNavController]; the shell
/// itself stays dumb.
class AdminShellView extends GetView<BottomNavController> {
  const AdminShellView({super.key});

  /// Screens addressed by [BottomNavController.selectedIndex].
  static const List<Widget> _tabs = <Widget>[
    AdminHomeView(),
    ApproveView(),
    AnnouncementView(),
    EvalutionView(),
    AdminProfileView(),
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
      bottomNavigationBar: const AdminBottomNavBar(),
    );
  }
}
