import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../widgets/admin_app_bar/admin_app_bar_controllers.dart';
import '../../../widgets/widget.dart';

/// Thin admin-specific wrapper around [AppBottomNav].
///
/// Wires the five admin destinations to [BottomNavController] and exposes
/// the live pending-bookings count from [AdminAppBarControllers] as a badge
/// on the "ການຢືນຢັນ" tab.
///
/// Drop a `const AdminBottomNavBar()` into any admin Scaffold's
/// `bottomNavigationBar`. Both controllers are resolved (or registered) via
/// GetX so the bar is safe to use even from screens that did not include
/// the admin shell binding.
class AdminBottomNavBar extends StatelessWidget {
  const AdminBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final navCtrl = _ensureRegistered<BottomNavController>(
      () => BottomNavController(),
    );
    final appBarCtrl = _ensureRegistered<AdminAppBarControllers>(
      () => AdminAppBarControllers(),
    );

    return Obx(
      () => AppBottomNav(
        selectedIndex: navCtrl.selectedIndex.value,
        onTap: navCtrl.changeTab,
        items: [
          const AppNavItem(icon: Icons.dashboard_rounded, label: 'ໜ້າຫຼັກ'),
          AppNavItem(
            icon: Icons.verified_outlined,
            label: 'ການຢືນຢັນ',
            badgeCount: appBarCtrl.pendingRequestCount.value,
          ),
          const AppNavItem(
            icon: Icons.notifications_outlined,
            label: 'ການປະກາດ',
          ),
          const AppNavItem(
            icon: Icons.assignment_outlined,
            label: 'ການປະເມີນ',
          ),
          const AppNavItem(icon: Icons.person_outline, label: 'ໂປຣໄຟລ໌'),
        ],
      ),
    );
  }

  /// Return the registered instance of [T], or create one via [factory] and
  /// register it permanently so it survives tab switches.
  T _ensureRegistered<T>(T Function() factory) {
    if (Get.isRegistered<T>()) return Get.find<T>();
    return Get.put<T>(factory(), permanent: true);
  }
}
