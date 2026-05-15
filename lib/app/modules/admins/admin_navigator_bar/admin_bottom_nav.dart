import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../widgets/widget.dart';

/// A premium, reusable bottom navigation bar for admin pages.
///
/// Usage: just place `const AdminBottomNavBar()` in any Scaffold's
/// `bottomNavigationBar` property. It will automatically find the
/// shared [BottomNavController] via GetX.
class AdminBottomNavBar extends StatelessWidget {
  const AdminBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final navCtrl = Get.isRegistered<BottomNavController>()
        ? Get.find<BottomNavController>()
        : Get.put(BottomNavController(), permanent: true);

    return Obx(
      () => AppBottomNav(
        selectedIndex: navCtrl.selectedIndex.value,
        onTap: navCtrl.changeTab,
        items: const [
          AppNavItem(icon: Icons.dashboard_rounded, label: 'ໜ້າຫຼັກ'),
          AppNavItem(icon: Icons.verified_outlined, label: 'ການຢືນຢັນ'),
          AppNavItem(icon: Icons.notifications_outlined, label: 'ການປະກາດ'),
          AppNavItem(icon: Icons.assignment_outlined, label: 'ການປະເມີນ'),
          AppNavItem(icon: Icons.person_outline, label: 'ໂປຣໄຟລ໌'),
        ],
      ),
    );
  }
}
